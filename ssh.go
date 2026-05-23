package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net"
	"os"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/ssh"
)

var (
	globalSSH   *ssh.Client
	globalDB    *pgxpool.Pool
	globalPodIP string
	globalPodNS string
	globalPod   string
)

// dialSSH opens an SSH connection using current sshUser/sshHost globals.
func dialSSH(keyPath string) (*ssh.Client, error) {
	keyData, err := os.ReadFile(keyPath)
	if err != nil {
		return nil, fmt.Errorf("read key %s: %w", keyPath, err)
	}
	signer, err := ssh.ParsePrivateKey(keyData)
	if err != nil {
		return nil, fmt.Errorf("parse key: %w", err)
	}
	client, err := ssh.Dial("tcp", sshHost, &ssh.ClientConfig{
		User:            sshUser,
		Auth:            []ssh.AuthMethod{ssh.PublicKeys(signer)},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	})
	if err != nil {
		return nil, fmt.Errorf("SSH dial: %w", err)
	}
	return client, nil
}

// discoverDBPod uses kubectl to find the DB pod and returns (namespace, podName, podIP).
func discoverDBPod(client *ssh.Client) (ns, pod, podIP string, err error) {
	sess, err := client.NewSession()
	if err != nil {
		return "", "", "", fmt.Errorf("SSH session: %w", err)
	}
	// Use jsonpath to extract namespace + podIP directly — avoids awk column
	// miscount when RESTARTS shows "1 (32m ago)" instead of "0".
	out, err := sess.CombinedOutput(
		`sudo kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.status.podIP}{"\n"}{end}' 2>/dev/null | grep db-dbdepl-sts | head -1`)
	sess.Close()
	if err != nil {
		return "", "", "", fmt.Errorf("kubectl: %w", err)
	}
	parts := strings.Fields(strings.TrimSpace(string(out)))
	if len(parts) < 3 {
		return "", "", "", fmt.Errorf("database pod not found in cluster")
	}
	return parts[0], parts[1], parts[2], nil
}

// cmdConnect connects to the database. In direct mode it opens a standard TCP
// connection; in ssh mode it dials SSH, discovers the DB pod, then tunnels.
func cmdConnect() Msg {
	if connectionMode == "direct" {
		return cmdConnectDirect()
	}
	return cmdConnectSSH()
}

// cmdConnectDirect opens a PostgreSQL connection directly (no SSH tunnel).
func cmdConnectDirect() Msg {
	pool, err := connectDBDirect(context.Background())
	if err != nil {
		return msgConnect{err: fmt.Errorf("DB connect: %w", err)}
	}
	globalDB = pool
	return msgConnect{}
}

// cmdConnectSSH dials SSH, discovers the DB pod, then opens a pgx connection tunnelled through SSH.
func cmdConnectSSH() Msg {
	keyPath := resolveKeyPath()
	client, err := dialSSH(keyPath)
	if err != nil {
		return msgConnect{err: err}
	}

	ns, pod, podIP, err := discoverDBPod(client)
	if err != nil {
		client.Close()
		return msgConnect{err: err}
	}
	globalPodNS = ns
	globalPod = pod
	globalPodIP = podIP
	globalSSH = client

	pool, err := connectDB(context.Background(), dbUser, dbPass)
	if err != nil {
		client.Close()
		globalSSH = nil
		return msgConnect{err: fmt.Errorf("DB connect: %w", err)}
	}
	globalDB = pool
	return msgConnect{}
}

func connectDB(ctx context.Context, user, pass string) (*pgxpool.Pool, error) {
	connStr := fmt.Sprintf(
		"host=127.0.0.1 port=%d user=%s password=%s dbname=%s sslmode=disable",
		dbPort, user, pass, dbName)
	poolCfg, err := pgxpool.ParseConfig(connStr)
	if err != nil {
		return nil, err
	}
	poolCfg.AfterConnect = func(ctx context.Context, conn *pgx.Conn) error {
		_, err := conn.Exec(ctx, fmt.Sprintf(`SET search_path TO %s, public`, pgx.Identifier{dbSchema}.Sanitize()))
		return err
	}
	poolCfg.ConnConfig.LookupFunc = func(_ context.Context, _ string) ([]string, error) {
		return []string{globalPodIP}, nil
	}
	poolCfg.ConnConfig.DialFunc = func(_ context.Context, _, _ string) (net.Conn, error) {
		return globalSSH.Dial("tcp", fmt.Sprintf("%s:%d", globalPodIP, dbPort))
	}
	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	dbUser = user
	dbPass = pass
	return pool, nil
}

// connectDBDirect opens a standard PostgreSQL connection without SSH tunneling.
func connectDBDirect(ctx context.Context) (*pgxpool.Pool, error) {
	connStr := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPass, dbName)
	poolCfg, err := pgxpool.ParseConfig(connStr)
	if err != nil {
		return nil, err
	}
	poolCfg.AfterConnect = func(ctx context.Context, conn *pgx.Conn) error {
		_, err := conn.Exec(ctx, fmt.Sprintf(`SET search_path TO %s, public`, pgx.Identifier{dbSchema}.Sanitize()))
		return err
	}
	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return pool, nil
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", "'\\''") + "'"
}

// battlegroupFromPod extracts the battlegroup name from a pod name.
// Pod naming pattern: <battlegroup>-db-dbdepl-sts-<N>
func battlegroupFromPod(pod string) string {
	const suffix = "-db-dbdepl-sts-"
	if idx := strings.LastIndex(pod, suffix); idx != -1 {
		return pod[:idx]
	}
	return ""
}

// listBattlegroups returns battlegroup names by running `battlegroup list` via
// a login shell (so PATH includes the battlegroup binary).
func listBattlegroups(client *ssh.Client) []string {
	sess, err := client.NewSession()
	if err != nil {
		return nil
	}
	defer sess.Close()
	out, err := sess.CombinedOutput("bash -lc 'battlegroup list' 2>/dev/null")
	if err != nil || strings.TrimSpace(string(out)) == "" {
		return nil
	}
	var names []string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "- ") {
			if name := strings.TrimSpace(line[2:]); name != "" {
				names = append(names, name)
			}
		}
	}
	return names
}

// extractPasswordFromYAML reads the DB user and password from a battlegroup YAML file
// via SSH. Credentials live at spec.database.template.spec.deployment.spec.{user,password}.
func extractPasswordFromYAML(client *ssh.Client, filePath string) (user, pass string) {
	sess, err := client.NewSession()
	if err != nil {
		return "", ""
	}
	defer sess.Close()
	// Expand ~ on the remote side so the path resolves correctly.
	out, err := sess.CombinedOutput(fmt.Sprintf("cat %s 2>/dev/null", shellQuote(filePath)))
	if err != nil || len(out) == 0 {
		// Try with shell expansion for the tilde.
		sess2, err2 := client.NewSession()
		if err2 != nil {
			return "", ""
		}
		defer sess2.Close()
		out, err = sess2.CombinedOutput(fmt.Sprintf(`bash -c 'cat %s'`, filePath))
		if err != nil || len(out) == 0 {
			return "", ""
		}
	}
	return parseDeploymentCredentials(out)
}

// sshExec runs a command on the remote VM and returns combined stdout+stderr.
func sshExec(cmd string) (string, error) {
	if globalSSH == nil {
		return "", fmt.Errorf("not connected")
	}
	sess, err := globalSSH.NewSession()
	if err != nil {
		return "", err
	}
	defer sess.Close()
	out, err := sess.CombinedOutput(cmd)
	return strings.TrimSpace(string(out)), err
}

// sshPipeToWriter runs cmd over SSH and streams stdout directly into w.
// Intended for binary file downloads where buffering the whole output is wasteful.
func sshPipeToWriter(cmd string, w io.Writer) error {
	if globalSSH == nil {
		return fmt.Errorf("not connected")
	}
	sess, err := globalSSH.NewSession()
	if err != nil {
		return err
	}
	defer sess.Close()
	sess.Stdout = w
	return sess.Run(cmd)
}

// sshStream opens a remote command and returns a channel that receives one
// line per send, plus a cancel func that closes the session. The caller must
// return listenForLogLine(ch) from Update to keep reading.
func sshStream(cmd string) (<-chan string, func(), error) {
	if globalSSH == nil {
		return nil, func() {}, fmt.Errorf("not connected")
	}
	sess, err := globalSSH.NewSession()
	if err != nil {
		return nil, func() {}, err
	}
	pipe, err := sess.StdoutPipe()
	if err != nil {
		sess.Close()
		return nil, func() {}, err
	}
	if err := sess.Start(cmd); err != nil {
		sess.Close()
		return nil, func() {}, err
	}
	ch := make(chan string, 256)
	go func() {
		defer close(ch)
		sc := bufio.NewScanner(pipe)
		for sc.Scan() {
			ch <- sc.Text()
		}
		sess.Wait()
	}()
	cancel := func() { sess.Close() }
	return ch, cancel, nil
}

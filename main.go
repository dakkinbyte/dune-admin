package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

var version = "dev" // set by goreleaser ldflags

// ── config ────────────────────────────────────────────────────────────────────

var (
	captureMode     bool
	setupMode       bool
	sqlQuery        string
	connectionMode   string
	containerName    string
	containerUser    string
	containerLogPath string
	directorURL      string
	sshHost          string
	sshUser         string
	sshKeyPath      string
	itemDataPath    string
	scripCurrencyID int
	dbHost          string
	dbPort          int
	dbUser          string
	dbPass          string
	dbName          string
	dbSchema        string
	listenAddr      string
)

func loadDotEnv() {
	f, err := os.Open(".env")
	if err != nil {
		return
	}
	defer f.Close()
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		k, v, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		k, v = strings.TrimSpace(k), strings.TrimSpace(v)
		if len(v) >= 2 && ((v[0] == '"' && v[len(v)-1] == '"') || (v[0] == '\'' && v[len(v)-1] == '\'')) {
			v = v[1 : len(v)-1]
		}
		if os.Getenv(k) == "" {
			os.Setenv(k, v)
		}
	}
}

// envOr returns the environment variable value if set, otherwise def.
func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envIntOr(key string, def int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return def
}

func init() {
	loadDotEnv()
	flag.StringVar(&connectionMode, "mode", envOr("CONNECTION_MODE", "direct"), "Connection mode: 'direct' or 'ssh'")
	flag.StringVar(&containerName, "container", envOr("CONTAINER_NAME", "AMP_MehDune01"), "Podman container name (direct mode)")
	flag.StringVar(&containerUser, "container-user", envOr("CONTAINER_USER", "amp"), "User that runs the container (direct mode)")
	flag.StringVar(&containerLogPath, "logpath", envOr("CONTAINER_LOG_PATH", "/AMP/duneawakening/logs"), "Log path inside container (direct mode)")
	flag.StringVar(&directorURL, "director", envOr("DIRECTOR_URL", "http://127.0.0.1:11717"), "Battlegroup Director URL (direct mode)")
	flag.StringVar(&sshHost, "host", envOr("SSH_HOST", "192.168.0.72:22"), "SSH host:port")
	flag.StringVar(&sshUser, "user", envOr("SSH_USER", "dune"), "SSH user")
	flag.StringVar(&sshKeyPath, "key", envOr("SSH_KEY", ""), "SSH private key path (auto-detected if empty)")
	flag.StringVar(&itemDataPath, "itemdata", envOr("ITEM_DATA", ""), "Item data JSON path")
	flag.IntVar(&scripCurrencyID, "scripcurrency", envIntOr("SCRIP_CURRENCY", 1), "Scrip currency id")
	flag.StringVar(&dbHost, "dbhost", envOr("DB_HOST", "127.0.0.1"), "PostgreSQL host")
	flag.IntVar(&dbPort, "dbport", envIntOr("DB_PORT", 15432), "PostgreSQL port")
	flag.StringVar(&dbUser, "dbuser", envOr("DB_USER", "dune"), "PostgreSQL user")
	flag.StringVar(&dbPass, "dbpass", envOr("DB_PASS", ""), "PostgreSQL password")
	flag.StringVar(&dbName, "dbname", envOr("DB_NAME", "dune"), "PostgreSQL database name")
	flag.StringVar(&dbSchema, "schema", envOr("DB_SCHEMA", "dune"), "PostgreSQL schema")
	flag.StringVar(&listenAddr, "addr", envOr("LISTEN_ADDR", ":9090"), "HTTP listen address")
	flag.BoolVar(&captureMode, "capture", false, "Capture RabbitMQ messages (grant + notifications) and print to stdout")
	flag.BoolVar(&setupMode, "setup", false, "Interactive setup wizard — writes .env from SSH autodiscovery")
	flag.StringVar(&sqlQuery, "sql", "", "Run a SQL query and print results to stdout, then exit")
}

func resolveKeyPath() string {
	if sshKeyPath != "" {
		return sshKeyPath
	}
	candidates := []string{
		filepath.Join(os.Getenv("HOME"), ".ssh", "id_ed25519"),
		filepath.Join(os.Getenv("HOME"), ".ssh", "id_rsa"),
		filepath.Join(os.Getenv("HOME"), ".ssh", "dune"),
		"../sshKey",
		"./sshKey",
	}
	for _, p := range candidates {
		if _, err := os.Stat(p); err == nil { // #nosec G703 -- paths are hardcoded candidates, not user input
			return p
		}
	}
	return candidates[0]
}

func resolveItemDataPath() string {
	if itemDataPath != "" {
		return itemDataPath
	}
	candidates := []string{"./item-data.json", "../item-data.json"}
	for _, p := range candidates {
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	return ""
}

var itemData itemDataFile

func loadItemData() error {
	path := resolveItemDataPath()
	if path == "" {
		return nil
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read item data %s: %w", path, err)
	}
	var parsed itemDataFile
	if err := json.Unmarshal(data, &parsed); err != nil {
		return fmt.Errorf("parse item data %s: %w", path, err)
	}
	normalizedItems := make(map[string]itemRule, len(parsed.Items))
	for k, v := range parsed.Items {
		normalizedItems[strings.ToLower(k)] = v
	}
	parsed.Items = normalizedItems
	normalizedNames := make(map[string]string, len(parsed.Names))
	for k, v := range parsed.Names {
		normalizedNames[strings.ToLower(k)] = v
	}
	parsed.Names = normalizedNames
	itemData = parsed
	return nil
}

// ── main ──────────────────────────────────────────────────────────────────────

func needsSetup() bool {
	_, err := os.Stat(".env")
	if os.IsNotExist(err) {
		return true
	}
	// .env exists but is empty or missing the discovered DB password.
	return dbPass == ""
}

func main() {
	flag.Parse()

	// Explicit -setup flag: reconfigure and exit (don't start server).
	if setupMode {
		runSetup()
		return
	}

	if captureMode {
		if connectionMode == "direct" {
			fmt.Fprintln(os.Stderr, "capture mode requires SSH connection mode (-mode ssh)")
			os.Exit(1)
		}
		if msg, ok := cmdConnect().(msgConnect); ok && msg.err != nil {
			fmt.Fprintln(os.Stderr, "SSH connect:", msg.err)
			os.Exit(1)
		}
		runCapture()
		return
	}

	if sqlQuery != "" {
		if msg, ok := cmdConnect().(msgConnect); ok && msg.err != nil {
			fmt.Fprintln(os.Stderr, "connect:", msg.err)
			os.Exit(1)
		}
		if msg, ok := cmdRunSQL(sqlQuery)().(msgSQL); ok {
			if msg.err != nil {
				fmt.Fprintln(os.Stderr, msg.err)
				os.Exit(1)
			}
			fmt.Println(msg.result)
		}
		return
	}

	if err := loadItemData(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	// Auto-run setup wizard when no .env exists — setup leaves us connected.
	alreadyConnected := false
	if needsSetup() {
		runSetup()
		alreadyConnected = true
		fmt.Println()
		fmt.Printf("Starting server on %s...\n", listenAddr)
	}

	defer func() {
		if globalDB != nil {
			globalDB.Close()
		}
		if globalSSH != nil {
			globalSSH.Close()
		}
	}()

	if !alreadyConnected {
		if msg, ok := cmdConnect().(msgConnect); ok && msg.err != nil {
			fmt.Fprintln(os.Stderr, "connect:", msg.err)
			fmt.Fprintln(os.Stderr, "Starting server anyway — use /api/v1/reconnect to retry")
		} else {
			if msg, ok := cmdFetchItemTemplates().(msgItemTemplates); ok {
				mergeItemTemplates(msg.templates)
			}
		}
	} else {
		if msg, ok := cmdFetchItemTemplates().(msgItemTemplates); ok {
			mergeItemTemplates(msg.templates)
		}
	}

	fmt.Printf("Connection mode: %s\n", connectionMode)
	startServer(listenAddr)
}

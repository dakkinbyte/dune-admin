package main

import (
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os/exec"
	"strings"
	"time"
	"unicode/utf8"

	jwt "github.com/golang-jwt/jwt/v5"
	amqp "github.com/rabbitmq/amqp091-go"
)

// ── JWT generation ────────────────────────────────────────────────────────────

// captureJWT reads the BGD pod's ServiceAuthToken to extract HostId and
// ServiceAuthKey, then generates a fresh token signed with our own key.
func captureJWT() (hostID, token string, err error) {
	// Find the BGD pod.
	pod, err := sshExec(fmt.Sprintf(
		"sudo kubectl get pods -n %s --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | grep bgd | head -1",
		globalPodNS))
	if err != nil || strings.TrimSpace(pod) == "" {
		return "", "", fmt.Errorf("find bgd pod: %w", err)
	}
	pod = strings.TrimSpace(pod)

	// Read the existing ServiceAuthToken from the BGD pod.
	existingToken, err := sshExec(fmt.Sprintf(
		"sudo kubectl exec -n %s %s -- env 2>/dev/null | grep FuncomLiveServices__ServiceAuthToken | cut -d= -f2-",
		globalPodNS, pod))
	if err != nil || strings.TrimSpace(existingToken) == "" {
		return "", "", fmt.Errorf("read ServiceAuthToken: %w", err)
	}
	existingToken = strings.TrimSpace(existingToken)

	// Decode the JWT payload to extract HostId and ServiceAuthKey.
	parts := strings.Split(existingToken, ".")
	if len(parts) != 3 {
		return "", "", fmt.Errorf("malformed JWT")
	}
	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", "", fmt.Errorf("decode JWT payload: %w", err)
	}
	var claims map[string]any
	if err := json.Unmarshal(payloadBytes, &claims); err != nil {
		return "", "", fmt.Errorf("parse JWT payload: %w", err)
	}

	hostID = fmt.Sprintf("%v", claims["HostId"])
	serviceAuthKey := fmt.Sprintf("%v", claims["ServiceAuthKey"])

	fmt.Printf("[capture] HostId=%s ServiceHostType=%v\n", hostID, claims["ServiceHostType"])

	// Decode the signing secret (base64-standard, may have padding).
	secret := "wus017CIPIkSB6+MhjvIAhWF+a+kVj+nW1AMb1mN1LfkUmcClqlmKeL69OT8BYuUA+Y4Vv44aUji4JBLeFfhxQ=="
	keyBytes, err := base64.StdEncoding.DecodeString(secret)
	if err != nil {
		// Try without padding.
		keyBytes, err = base64.RawStdEncoding.DecodeString(secret)
		if err != nil {
			return "", "", fmt.Errorf("decode signing secret: %w", err)
		}
	}

	// Generate a new token with the same structure but fresh timestamps.
	now := time.Now()
	newClaims := jwt.MapClaims{
		"HostId":          hostID,
		"TokenIndex":      "1",
		"ServiceAuthKey":  serviceAuthKey,
		"ServiceHostType": claims["ServiceHostType"],
		"nbf":             now.Unix(),
		"iat":             now.Unix(),
		"exp":             now.Add(365 * 24 * time.Hour).Unix(),
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, newClaims)
	token, err = tok.SignedString(keyBytes)
	if err != nil {
		return "", "", fmt.Errorf("sign JWT: %w", err)
	}

	fmt.Printf("[capture] generated JWT (%d bytes)\n", len(token))
	return hostID, token, nil
}

// ── AMQP dialers ─────────────────────────────────────────────────────────────

// sshDial creates a TCP connection to addr through the existing SSH client.
func sshDial(addr string) (net.Conn, error) {
	if globalSSH == nil {
		return nil, fmt.Errorf("SSH not connected")
	}
	return globalSSH.Dial("tcp", addr)
}

func dialAMQP(internalAddr, user, pass string, useTLS bool) (*amqp.Connection, error) {
	if connectionMode == "direct" {
		return dialAMQPDirect(internalAddr, user, pass, useTLS)
	}
	cfg := amqp.Config{
		SASL: []amqp.Authentication{
			&amqp.PlainAuth{Username: user, Password: pass},
		},
		Vhost:     "/",
		Locale:    "en_US",
		Heartbeat: 10 * time.Second,
		Dial: func(network, addr string) (net.Conn, error) {
			return sshDial(internalAddr)
		},
	}
	if useTLS {
		cfg.TLSClientConfig = &tls.Config{InsecureSkipVerify: true} // #nosec G402 -- internal RabbitMQ tunnel over SSH, self-signed cert
		return amqp.DialConfig("amqps://"+internalAddr+"/", cfg)
	}
	return amqp.DialConfig("amqp://"+internalAddr+"/", cfg)
}

func dialAMQPDirect(addr, user, pass string, useTLS bool) (*amqp.Connection, error) {
	scheme := "amqp"
	if useTLS {
		scheme = "amqps"
	}
	connURL := fmt.Sprintf("%s://%s:%s@%s/", scheme, url.PathEscape(user), url.PathEscape(pass), addr)
	cfg := amqp.Config{
		Heartbeat: 10 * time.Second,
	}
	if useTLS {
		cfg.TLSClientConfig = &tls.Config{InsecureSkipVerify: true} // #nosec G402 -- internal RabbitMQ, self-signed cert
	}
	return amqp.DialConfig(connURL, cfg)
}

// ── Capture entry point ───────────────────────────────────────────────────────

// listExchanges queries a broker pod for all non-default exchange names (SSH mode).
func listExchanges(podPattern string) []binding {
	out, err := sshExec(fmt.Sprintf(
		"sudo kubectl get pods -n %s --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | grep %s | head -1",
		globalPodNS, podPattern))
	if err != nil || strings.TrimSpace(out) == "" {
		return nil
	}
	pod := strings.TrimSpace(out)
	raw, err := sshExec(fmt.Sprintf(
		"sudo kubectl exec -n %s %s -- rabbitmqctl list_exchanges name 2>/dev/null",
		globalPodNS, pod))
	if err != nil {
		return nil
	}
	var bindings []binding
	for _, line := range strings.Split(raw, "\n") {
		name := strings.TrimSpace(line)
		if name == "" || name == "name" || name == "Listing exchanges for vhost / ..." ||
			strings.HasPrefix(name, "amq.") {
			continue
		}
		bindings = append(bindings, binding{exchange: name, key: "#"})
	}
	return bindings
}

// captureJWTDirect reads the ServiceAuthToken from game server process args.
func captureJWTDirect() (hostID, token string, err error) {
	out, err := exec.Command("bash", "-c",
		`ps aux | grep DuneSandboxServer | grep -oP 'ServiceAuthToken=\K[^ ]+' | head -1`,
	).Output()
	if err != nil || len(strings.TrimSpace(string(out))) == 0 {
		return "", "", fmt.Errorf("could not find ServiceAuthToken in process args")
	}
	token = strings.TrimSpace(string(out))

	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return "", "", fmt.Errorf("malformed JWT")
	}
	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", "", fmt.Errorf("decode JWT payload: %w", err)
	}
	var claims map[string]any
	if err := json.Unmarshal(payloadBytes, &claims); err != nil {
		return "", "", fmt.Errorf("parse JWT payload: %w", err)
	}
	hostID = fmt.Sprintf("%v", claims["HostId"])
	fmt.Printf("[capture] HostId=%s\n", hostID)
	return hostID, token, nil
}

// listExchangesDirect discovers exchange names from the Director API.
func listExchangesDirect() []binding {
	resp, err := http.Get(directorURL + "/v0/battlegroup")
	if err != nil {
		fmt.Printf("[capture] Director API error: %v\n", err)
		return nil
	}
	defer resp.Body.Close()
	var bg map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&bg); err != nil {
		return nil
	}

	var bindings []binding
	// Known exchange patterns from the game
	knownExchanges := []string{"notifications", "grants", "server_state", "travel", "player_state"}

	// Extract broadcastExchange from each map config
	for _, section := range []string{"singleServerMaps", "dimensionMaps", "instancedMaps"} {
		maps, ok := bg[section].(map[string]any)
		if !ok {
			continue
		}
		for _, mapData := range maps {
			md, ok := mapData.(map[string]any)
			if !ok {
				continue
			}
			if ex, ok := md["broadcastExchange"].(string); ok && ex != "" {
				bindings = append(bindings, binding{exchange: ex, key: "#"})
			}
		}
	}

	for _, name := range knownExchanges {
		bindings = append(bindings, binding{exchange: name, key: "#"})
	}
	return bindings
}

func runCapture() {
	if connectionMode == "direct" {
		runCaptureDirect()
		return
	}

	ensureCaptureUser()

	fmt.Println("=== Dune Admin — RabbitMQ Message Capture ===")
	fmt.Println("Press Ctrl-C to stop.")
	fmt.Println()

	hostID, token, err := captureJWT()
	if err != nil {
		fmt.Printf("[capture] JWT error: %v\n", err)
		fmt.Println("[capture] Falling back to dune_cap user (may not work)")
		hostID = capUser
		token = capPass
	}

	adminBindings := listExchanges("mq-admin")
	gameBindings := listExchanges("mq-game")
	fmt.Printf("[capture] mq-admin: %d exchanges\n", len(adminBindings))
	fmt.Printf("[capture] mq-game:  %d exchanges\n", len(gameBindings))

	done := make(chan struct{}, 2)

	go func() {
		for {
			time.Sleep(15 * time.Second)
			ensureCaptureUser()
		}
	}()

	go func() {
		defer func() { done <- struct{}{} }()
		if err := captureBroker("mq-admin", "10.43.189.193:5672", false, hostID, token, adminBindings); err != nil {
			fmt.Printf("[WARN] mq-admin: %v\n\n", err)
		}
	}()

	go func() {
		defer func() { done <- struct{}{} }()
		if err := captureBroker("mq-game", "10.43.48.246:5672", true, hostID, token, gameBindings); err != nil {
			fmt.Printf("[WARN] mq-game: %v\n\n", err)
		}
	}()

	<-done
	<-done
}

func runCaptureDirect() {
	fmt.Println("=== Dune Admin — RabbitMQ Message Capture (Direct Mode) ===")
	fmt.Println("Press Ctrl-C to stop.")
	fmt.Println()

	// Self-heal: apply dune_cap user + auth backends now and refresh every 15s.
	// RabbitMQ's in-memory state is wiped on broker restart, so this keeps the
	// capture tool working through Dune instance restarts without the manual
	// post-restart playbook (see rabbitmq-research.md).
	ensureCaptureUserDirect()
	go func() {
		for {
			time.Sleep(15 * time.Second)
			ensureCaptureUserDirect()
		}
	}()

	// List actual exchanges from both brokers via rabbitmqctl
	adminExchanges := listExchangesDirect_ctl("rabbit-admin@localhost", "DJUYYPFKOWCCNJIXEBAQ")
	gameExchanges := listExchangesDirect_ctl("rabbit-game@localhost", "MDRQZKETDUYQCAQYSNNL")
	fmt.Printf("[capture] mq-admin: %d exchanges\n", len(adminExchanges))
	fmt.Printf("[capture] mq-game:  %d exchanges\n", len(gameExchanges))
	fmt.Println()

	done := make(chan struct{}, 2)

	// mq-admin: plain AMQP on localhost:5672
	go func() {
		defer func() { done <- struct{}{} }()
		if err := captureBroker("mq-admin", "127.0.0.1:5672", false, capUser, capPass, adminExchanges); err != nil {
			fmt.Printf("[WARN] mq-admin: %v\n\n", err)
		}
	}()

	// mq-game: AMQP+TLS on localhost:5673
	go func() {
		defer func() { done <- struct{}{} }()
		if err := captureBroker("mq-game", "127.0.0.1:5673", true, capUser, capPass, gameExchanges); err != nil {
			fmt.Printf("[WARN] mq-game: %v\n\n", err)
		}
	}()

	<-done
	<-done
}

// ensureBrokerDirect re-applies the dune_cap user + permissions + auth backend
// chain on a local broker. Idempotent: works whether the user exists or not.
// In-memory state in RabbitMQ resets on broker restart, so this must be called
// at capture-tool startup AND on a refresh loop to survive Dune instance
// restarts without manual intervention.
func ensureBrokerDirect(node, cookie, label string) {
	base := fmt.Sprintf("sudo RABBITMQ_ERLANG_COOKIE=%s rabbitmqctl -n %s", cookie, node)
	// add_user fails harmlessly if it already exists; ignore error.
	exec.Command("bash", "-c", fmt.Sprintf("%s add_user %s %s 2>&1", base, capUser, capPass)).Run() //nolint:errcheck
	// change_password ensures the password matches what we use.
	exec.Command("bash", "-c", fmt.Sprintf("%s change_password %s %s 2>&1", base, capUser, capPass)).Run() //nolint:errcheck
	// Wide-open vhost permissions for dune_cap (admin-only capture user).
	exec.Command("bash", "-c", fmt.Sprintf("%s set_permissions -p / %s '.*' '.*' '.*' 2>&1", base, capUser)).Run() //nolint:errcheck
	// Auth backend chain: HTTP cache first (the game's auth path) + internal
	// (so dune_cap from the user database resolves).
	exec.Command("bash", "-c", fmt.Sprintf("%s eval 'application:set_env(rabbit, auth_backends, [{rabbit_auth_backend_cache, rabbit_auth_backend_http}, rabbit_auth_backend_internal]).' 2>&1", base)).Run() //nolint:errcheck
	// Long TTL on the HTTP auth cache so capture doesn't hammer the auth API.
	exec.Command("bash", "-c", fmt.Sprintf("%s eval 'application:set_env(rabbitmq_auth_backend_cache, cache_ttl, 86400000).' 2>&1", base)).Run() //nolint:errcheck
	fmt.Printf("[capture] [%s] auth ensured\n", label)
}

func ensureCaptureUserDirect() {
	ensureBrokerDirect("rabbit-admin@localhost", "DJUYYPFKOWCCNJIXEBAQ", "mq-admin")
	ensureBrokerDirect("rabbit-game@localhost", "MDRQZKETDUYQCAQYSNNL", "mq-game")
}

// listExchangesDirect_ctl lists exchanges using rabbitmqctl on the host.
func listExchangesDirect_ctl(node, cookie string) []binding {
	cmd := fmt.Sprintf("sudo RABBITMQ_ERLANG_COOKIE=%s rabbitmqctl -n %s list_exchanges name 2>/dev/null", cookie, node)
	out, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		fmt.Printf("[capture] rabbitmqctl error for %s: %v (using fallback list)\n", node, err)
		// Fallback: return known exchanges
		if strings.Contains(node, "admin") {
			return []binding{
				{exchange: "grant", key: "#"}, {exchange: "travel", key: "#"},
				{exchange: "heartbeats", key: "#"}, {exchange: "completions", key: "#"},
				{exchange: "rpc", key: "#"}, {exchange: "response", key: "#"},
				{exchange: "settingsUpdate", key: "#"}, {exchange: "director_respawned", key: "#"},
				{exchange: "travelQueueStatus", key: "#"},
			}
		}
		return []binding{
			{exchange: "notifications", key: "#"}, {exchange: "login_grant", key: "#"},
			{exchange: "login_request", key: "#"}, {exchange: "login_response", key: "#"},
			{exchange: "rpc", key: "#"}, {exchange: "chat.map", key: "#"},
			{exchange: "chat.whispers", key: "#"}, {exchange: "chat.proximity", key: "#"},
			{exchange: "director_respawned", key: "#"},
		}
	}
	var bindings []binding
	for _, line := range strings.Split(string(out), "\n") {
		name := strings.TrimSpace(line)
		if name == "" || name == "name" || strings.HasPrefix(name, "Listing") || strings.HasPrefix(name, "amq.") {
			continue
		}
		bindings = append(bindings, binding{exchange: name, key: "#"})
	}
	return bindings
}

// ── Per-broker capture ────────────────────────────────────────────────────────

type binding struct {
	exchange string
	key      string
}

const (
	capUser = "dune_cap"
	capPass = "dunecap123"
)

func captureBroker(name, addr string, useTLS bool, user, pass string, bindings []binding) error {
	attempts := []struct{ u, p string }{
		{capUser, capPass},
		{user, pass},
		{pass, user},
	}

	for {

		var conn *amqp.Connection
		var connErr error
		for _, a := range attempts {
			conn, connErr = dialAMQP(addr, a.u, a.p, useTLS)
			if connErr == nil {
				fmt.Printf("[%s] connected (user=%s)\n", name, a.u)
				break
			}
		}
		if connErr != nil {
			return fmt.Errorf("connect (tried %d credential sets): %w", len(attempts), connErr)
		}

		func() {
			defer conn.Close()

			ch, err := conn.Channel()
			if err != nil {
				fmt.Printf("[%s] channel error: %v — reconnecting\n", name, err)
				return
			}
			defer ch.Close()

			q, err := ch.QueueDeclare("admin_capture_"+name, false, true, false, false, nil)
			if err != nil {
				fmt.Printf("[%s] queue error: %v — reconnecting\n", name, err)
				return
			}

			for _, b := range bindings {
				if err := ch.QueueBind(q.Name, b.key, b.exchange, false, nil); err != nil {
					fmt.Printf("[%s] bind %s: %v (skipping)\n", name, b.exchange, err)
					continue
				}
				fmt.Printf("[%s] ← %s (routing_key=%s)\n", name, b.exchange, b.key)
			}
			fmt.Printf("[%s] listening...\n\n", name)

			msgs, err := ch.Consume(q.Name, "", true, false, false, false, nil)
			if err != nil {
				fmt.Printf("[%s] consume error: %v — reconnecting\n", name, err)
				return
			}

			for msg := range msgs {
				printMessage(name, msg)
			}
			fmt.Printf("[%s] channel closed — reconnecting\n\n", name)
		}()

		time.Sleep(2 * time.Second)
	}
}

// ── Message printer ───────────────────────────────────────────────────────────

func printMessage(broker string, msg amqp.Delivery) {
	ts := time.Now().Format("15:04:05.000")
	body := msg.Body

	fmt.Printf("╔══ [%s] %s ═══════════════════════════════\n", broker, ts)
	fmt.Printf("║  Exchange:   %s\n", msg.Exchange)
	fmt.Printf("║  RoutingKey: %s\n", msg.RoutingKey)
	if msg.ContentType != "" {
		fmt.Printf("║  Type:       %s\n", msg.ContentType)
	}
	for k, v := range msg.Headers {
		fmt.Printf("║  Header[%s]: %v\n", k, v)
	}

	if isJSON(body) {
		var pretty any
		if err := json.Unmarshal(body, &pretty); err == nil {
			indented, _ := json.MarshalIndent(pretty, "║    ", "  ")
			fmt.Printf("║  Body:\n║    %s\n", indented)
		} else {
			fmt.Printf("║  Body: %s\n", body)
		}
	} else if utf8.Valid(body) && len(body) > 0 {
		fmt.Printf("║  Body (text): %s\n", body)
	} else if len(body) > 0 {
		fmt.Printf("║  Body (%d bytes hex): %x\n", len(body), body)
	} else {
		fmt.Printf("║  Body: (empty)\n")
	}
	fmt.Println("╚════════════════════════════════════════════")
	fmt.Println()
}

func isJSON(b []byte) bool {
	return len(b) > 0 && (b[0] == '{' || b[0] == '[')
}

func ensureBroker(podPattern, label string) {
	pod, err := sshExec(fmt.Sprintf(
		"sudo kubectl get pods -n %s --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | grep %s | head -1",
		globalPodNS, podPattern))
	if err != nil || strings.TrimSpace(pod) == "" {
		fmt.Printf("[capture] could not find %s pod\n", label)
		return
	}
	pod = strings.TrimSpace(pod)
	base := fmt.Sprintf("sudo kubectl exec -n %s %s --", globalPodNS, pod)

	out, _ := sshExec(fmt.Sprintf("%s rabbitmqctl add_user %s %s 2>&1", base, capUser, capPass))
	if !strings.Contains(out, "already exists") {
		fmt.Printf("[capture] [%s] created user %s\n", label, capUser)
	}
	sshExec(fmt.Sprintf("%s rabbitmqctl set_permissions -p / %s '.*' '.*' '.*' 2>&1", base, capUser))
	sshExec(fmt.Sprintf(
		"%s rabbitmqctl eval 'application:set_env(rabbit, auth_backends, [{rabbit_auth_backend_cache, rabbit_auth_backend_http}, rabbit_auth_backend_internal]).' 2>&1",
		base))
	sshExec(fmt.Sprintf(
		"%s rabbitmqctl eval 'application:set_env(rabbitmq_auth_backend_cache, cache_ttl, 86400000).' 2>&1",
		base))
	fmt.Printf("[capture] [%s] auth backends updated\n", label)
}

func ensureCaptureUser() {
	ensureBroker("mq-admin", "mq-admin")
	ensureBroker("mq-game", "mq-game")
}

package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"gopkg.in/yaml.v3"
)

// exitSetup prints a pause prompt on Windows (so the CMD window doesn't vanish
// before the user can read the error), then exits with the given code.
func exitSetup(code int) {
	if runtime.GOOS == "windows" {
		fmt.Println()
		fmt.Println("Press Enter to close...")
		bufio.NewReader(os.Stdin).ReadString('\n')
	}
	os.Exit(code)
}

func runSetup() {
	r := bufio.NewReader(os.Stdin)

	ask := func(label, def string) string {
		if def != "" {
			fmt.Printf("  %s [%s]: ", label, def)
		} else {
			fmt.Printf("  %s: ", label)
		}
		line, _ := r.ReadString('\n')
		line = strings.TrimSpace(line)
		if line == "" {
			return def
		}
		return line
	}

	ok := func(msg string) { fmt.Printf("  ✓ %s\n", msg) }
	fail := func(msg string) { fmt.Printf("  ✗ %s\n", msg) }

	fmt.Println()
	fmt.Println("=== dune-admin setup ===")
	fmt.Println()

	// ── 1. SSH key ─────────────────────────────────────────────────────────────

	fmt.Println("Checking for SSH key...")
	keyPath := resolveKeyPath()
	if _, err := os.Stat(keyPath); err != nil {
		fail("SSH key not found (checked ~/.dune-admin/sshKey, next to binary, ./sshKey)")
		fmt.Println()
		sshKeyPath = ask("Path to SSH private key", "")
		if sshKeyPath == "" {
			fmt.Fprintln(os.Stderr, "SSH key is required. Aborting.")
			exitSetup(1)
		}
		if _, err := os.Stat(sshKeyPath); err != nil {
			fmt.Fprintf(os.Stderr, "Key not found at %s. Aborting.\n", sshKeyPath)
			exitSetup(1)
		}
		keyPath = sshKeyPath
	} else {
		ok("SSH key: " + keyPath)
		sshKeyPath = keyPath
	}
	fmt.Println()

	// ── 2. Connection details ──────────────────────────────────────────────────

	fmt.Println("SSH connection:")
	sshHost = ask("VM host:port", sshHost)
	sshUser = ask("SSH user", sshUser)
	fmt.Println()

	// ── 3. SSH dial ────────────────────────────────────────────────────────────

	fmt.Printf("Connecting via SSH to %s...\n", sshHost)
	client, err := dialSSH(keyPath)
	if err != nil {
		fail("SSH failed: " + err.Error())
		fmt.Println()
		fmt.Printf("  Attempted:  user=%s  host=%s  key=%s\n", sshUser, sshHost, keyPath)
		fmt.Println()
		fmt.Println("  Make sure:")
		fmt.Println("    - The VM is reachable at the given host:port")
		fmt.Println("    - The correct SSH private key is specified")
		fmt.Println("    - That key's public key is in ~/.ssh/authorized_keys on the VM")
		fmt.Println("    - The SSH user matches the account on the VM (default: dune)")
		fmt.Println("    - The SSH user has passwordless sudo for kubectl")
		exitSetup(1)
	}
	ok("SSH connected")
	fmt.Println()

	// ── 4. Discover DB pod ─────────────────────────────────────────────────────

	fmt.Println("Discovering database pod...")
	ns, pod, podIP, err := discoverDBPod(client)
	if err != nil {
		fail("Pod discovery failed: " + err.Error())
		fmt.Println()
		fmt.Println("  Make sure the SSH user can run: sudo kubectl get pods -A")
		exitSetup(1)
	}
	globalSSH = client
	globalPodNS = ns
	globalPod = pod
	globalPodIP = podIP
	ok("Database pod: " + pod)
	fmt.Println()

	// ── 5. Discover DB password ────────────────────────────────────────────────

	fmt.Println("Discovering database password...")

	discoveredUser := "postgres"
	discoveredPass := ""

	// Try 1: battlegroup YAML — application-level credentials.
	// Derive the battlegroup name from the already-discovered pod name, then
	// fall back to `battlegroup list` if that doesn't work.
	var battlegroups []string
	if bg := battlegroupFromPod(globalPod); bg != "" {
		battlegroups = []string{bg}
	} else {
		battlegroups = listBattlegroups(client)
	}

	if len(battlegroups) == 0 {
		fmt.Println("  Could not determine battlegroup name")
	} else {
		chosen := battlegroups[0]
		if len(battlegroups) > 1 {
			fmt.Println("  Available battlegroups:")
			for i, bg := range battlegroups {
				fmt.Printf("    [%d] %s\n", i+1, bg)
			}
			fmt.Println()
			idxStr := ask(fmt.Sprintf("Which battlegroup? [1-%d]", len(battlegroups)), "1")
			idx := 1
			fmt.Sscanf(idxStr, "%d", &idx)
			if idx >= 1 && idx <= len(battlegroups) {
				chosen = battlegroups[idx-1]
			}
		}

		yamlPath := fmt.Sprintf("~/.dune/%s.yaml", chosen)
		if u, pass := extractPasswordFromYAML(client, yamlPath); pass != "" {
			discoveredUser = u
			discoveredPass = pass
			ok(fmt.Sprintf("Password found in %s (user: %s)", yamlPath, u))
		} else {
			fail("No password found in " + yamlPath)
		}
	}

	// Try 2: manual prompt
	if discoveredPass == "" {
		fmt.Println()
		fmt.Println("  Could not auto-discover the database password.")
		discoveredUser = ask("Database user", "postgres")
		discoveredPass = ask("Database password", "")
		if discoveredPass == "" {
			fmt.Fprintln(os.Stderr, "Database password is required. Aborting.")
			exitSetup(1)
		}
	}
	fmt.Println()

	// ── 6. Connect to database ─────────────────────────────────────────────────

	fmt.Println("Connecting to database...")
	dbUser = discoveredUser
	dbPass = discoveredPass
	pool, err := connectDB(context.Background(), discoveredUser, discoveredPass)
	if err != nil {
		fail("DB connect failed: " + err.Error())
		fmt.Println()
		fmt.Printf("  The password may be wrong. Delete %s and re-run to try again.\n", configPath())
		exitSetup(1)
	}
	globalDB = pool
	ok("Database connected as: " + dbUser)
	fmt.Println()

	// ── 7. Listen address ──────────────────────────────────────────────────────

	fmt.Println("Server config:")
	listenAddr = ask("HTTP listen address", listenAddr)
	fmt.Println()

	// ── 8. Write ~/.dune-admin/config.yaml ────────────────────────────────────

	// Always store an absolute path so the config works regardless of where
	// the binary is launched from.
	if abs, err := filepath.Abs(keyPath); err == nil {
		keyPath = abs
	}

	cfgDir := configDir()
	if err := os.MkdirAll(cfgDir, 0700); err != nil {
		fail("Failed to create config directory: " + err.Error())
		exitSetup(1)
	}

	cfg := appConfig{
		SSHHost:       sshHost,
		SSHUser:       sshUser,
		SSHKey:        keyPath,
		DBPort:        dbPort,
		DBUser:        dbUser,
		DBPass:        dbPass,
		DBName:        dbName,
		DBSchema:      dbSchema,
		ScripCurrency: scripCurrencyID,
		ListenAddr:    listenAddr,
	}
	cfgData, err := yaml.Marshal(cfg)
	if err != nil {
		fail("Failed to marshal config: " + err.Error())
		exitSetup(1)
	}
	cfgFile := configPath()
	if err := os.WriteFile(cfgFile, cfgData, 0600); err != nil {
		fail("Failed to write config: " + err.Error())
		exitSetup(1)
	}
	ok("Config written to " + cfgFile)
	fmt.Println()

	fmt.Println("Setup complete.")
	fmt.Println()
	fmt.Println("  Run: dune-admin")
	fmt.Println()
}

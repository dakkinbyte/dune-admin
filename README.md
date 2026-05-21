# dune-admin

Web-based admin panel for a Dune Awakening private server. Connects to the server VM over SSH, then tunnels into the k3s cluster to reach PostgreSQL directly — no exposed ports, no VPN required.

## Architecture

```
your machine
  └─ SSH tunnel → VM
       └─ kubectl discover → DB pod IP
            └─ TCP tunnel → PostgreSQL (port 15432)

browser (Cloudflare Pages) → http://localhost:8080/api/v1
```

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **Go 1.21+** | Install from https://go.dev/dl/ or `brew install go` |
| **`sshKey`** | Private key for the VM — place it at the repo root as `./sshKey` |
| **VM access** | Port 22 must be reachable; SSH user needs passwordless `sudo kubectl` |

That's it. The setup wizard handles everything else — database credentials are read from your battlegroup YAML.

---

## Quick start

```bash
git clone https://github.com/Icehunter/dune-admin
cd dune-admin

# Place your SSH private key here:
cp /path/to/your/key ./sshKey
chmod 600 ./sshKey

# Run the setup wizard — connects via SSH, discovers config, writes .env:
make setup

# Build and launch:
make build && ./dune-admin
```

Open the hosted frontend at **https://dune-admin.layout.tools** and point it at `http://localhost:8080`.

---

## Setup wizard

`make setup` (or `go run . -setup`) runs an interactive wizard that:

1. Finds your SSH key (checks `./sshKey`, `~/.ssh/dune`, `~/.ssh/id_ed25519`)
2. Prompts for VM host:port and SSH user
3. SSHes in, finds the database pod via `kubectl`
4. Derives the battlegroup name from the pod and reads credentials from `~/.dune/<battlegroup>.yaml`
5. Writes a `.env` file (chmod 600, never committed)

Re-run `make setup` any time your VM IP or credentials change.

---

## Makefile targets

| Target | Description |
|--------|-------------|
| `make setup` | Run the interactive setup wizard |
| `make build` | Build the Go binary |
| `make linux` | Cross-compile a Linux amd64 binary |
| `make dev-server` | Run without building (`go run .`) |
| `make web` | Build the frontend only (for local inspection) |
| `make deploy-web` | Build + deploy frontend to Cloudflare Pages |

---

## Configuration

Config is read from `.env` (written by `make setup`) or environment variables. All flags can also be passed on the command line.

| Env var | Flag | Default | Description |
|---------|------|---------|-------------|
| `SSH_HOST` | `-host` | `192.168.0.72:22` | VM host:port |
| `SSH_USER` | `-user` | `dune` | SSH user |
| `SSH_KEY` | `-key` | *(auto-detected)* | SSH private key path |
| `DB_PORT` | `-dbport` | `15432` | PostgreSQL port inside the cluster |
| `DB_USER` | `-dbuser` | `dune` | PostgreSQL user |
| `DB_PASS` | `-dbpass` | *(from battlegroup YAML)* | PostgreSQL password |
| `DB_NAME` | `-dbname` | `dune` | PostgreSQL database |
| `DB_SCHEMA` | `-schema` | `dune` | PostgreSQL schema |
| `SCRIP_CURRENCY` | `-scripcurrency` | `1` | Scrip currency ID |
| `LISTEN_ADDR` | `-addr` | `:8080` | HTTP listen address |

### SSH key lookup order

If `SSH_KEY` / `-key` is not set, the binary checks these in order:

1. `./sshKey`
2. `../sshKey`
3. `~/.ssh/dune`
4. `~/.ssh/id_ed25519`
5. `~/.ssh/id_rsa`

---

## Hosted frontend (optional)

The frontend can be deployed to Cloudflare Pages and pointed at a locally-running binary — useful for sharing the panel with multiple people without exposing SSH.

```bash
# Build and deploy (one-time or on update):
cd web && npm ci && npm run build
wrangler pages deploy dist --project-name dune-admin
```

When visiting the hosted URL, the app prompts for the backend URL on first load (e.g. `http://localhost:8080`). This is saved in `localStorage` and never re-prompted.

The binary adds CORS headers automatically — no extra configuration needed.

> **Note:** Modern browsers allow HTTPS pages to connect to HTTP localhost without mixed-content errors, so `https://your-site.pages.dev` → `http://localhost:8080` works out of the box.

---

## Item data (optional enrichment)

`item-data.json` provides friendly item names, stack limits, volume, tier, and rarity. It ships with the repo but can be regenerated from game PAK files using the [dune-item-data](https://github.com/Icehunter/dune-item-data) build script.

Without it the panel still works — inventory items just show raw template IDs.

---

## Tabs

| Tab | What it does |
|-----|-------------|
| **Players** | Browse players; view/edit inventory, specs, currency, XP, faction rep; journey nodes; teleport; history |
| **Battlegroup** | Start/stop the game server; stream pod logs |
| **Database** | Run raw SQL against the game DB; browse tables |
| **Blueprints** | View all unlockable blueprint definitions |
| **Storage** | Browse server-side storage containers |
| **Logs** | Stream live pod logs; view cheat detection events |

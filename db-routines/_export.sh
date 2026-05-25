#!/usr/bin/env bash
# Exports every function and procedure in the dune schema as one .sql file per routine,
# categorized by name. Also writes _all.sql (concatenated) and _manifest.tsv (metadata).
#
# Usage: bash db-routines/_export.sh
# Re-runs are idempotent: functions/ and procedures/ are wiped first.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_KEY="$REPO_DIR/sshKey"
SSH_HOST="dune@192.168.0.72"
NS="funcom-seabass-sh-ec68e59f636959ac-coyzzx"
POD="sh-ec68e59f636959ac-coyzzx-db-dbdepl-sts-0"
PGUSER="postgres"
PGDB="dune"
PGPORT="15432"

# Fetch the DB password from the pod's environment so we never commit it.
# Override by exporting PGPASS before running.
if [[ -z "${PGPASS:-}" ]]; then
  PGPASS=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_HOST" \
    "sudo -n kubectl exec -n $NS $POD -- printenv POSTGRES_PASSWORD" | tr -d '\r\n')
  if [[ -z "$PGPASS" ]]; then
    echo "ERROR: could not retrieve POSTGRES_PASSWORD from pod" >&2; exit 1
  fi
fi

RAW="$SCRIPT_DIR/_raw_dump.txt"
MANIFEST="$SCRIPT_DIR/_manifest.tsv"
ALL="$SCRIPT_DIR/_all.sql"

rm -rf "$SCRIPT_DIR/functions" "$SCRIPT_DIR/procedures"
mkdir -p "$SCRIPT_DIR/functions" "$SCRIPT_DIR/procedures"

echo "==> Querying $POD for all dune.* routines…"

SQL=$(cat <<'EOSQL'
SELECT format(
  E'@@@RTN@@@%s\n%s\n%s\n%s\n%s\n%s\n@@@BODY@@@\n%s\n@@@ENDRTN@@@',
  p.oid::text,
  p.prokind,
  p.proname,
  pg_get_function_identity_arguments(p.oid),
  CASE WHEN p.prokind = 'p' THEN '' ELSE pg_get_function_result(p.oid) END,
  replace(COALESCE(obj_description(p.oid, 'pg_proc'), ''), E'\n', ' '),
  pg_get_functiondef(p.oid)
)
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'dune'
ORDER BY p.proname, p.oid;
EOSQL
)

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_HOST" \
  "sudo -n kubectl exec -n $NS $POD -- env PGPASSWORD=$PGPASS \
     psql -h 127.0.0.1 -p $PGPORT -U $PGUSER -d $PGDB -At -X -P pager=off -c \"$SQL\"" \
  > "$RAW"

bytes=$(wc -c < "$RAW")
echo "==> Captured $bytes bytes of raw output to $RAW"

echo "==> Splitting into per-routine files…"

python3 - "$RAW" "$SCRIPT_DIR" "$MANIFEST" "$ALL" <<'PYEOF'
import os, re, sys, pathlib

raw_path, out_dir, manifest_path, all_path = sys.argv[1:5]
raw = pathlib.Path(raw_path).read_text()

# Category classifier (first match wins, ordered for specificity)
def has(n, *kws): return any(k in n for k in kws)
RULES = [
    ('debug',              lambda n: n.startswith('debug_') or n.startswith('_debug')),
    ('base_backup',        lambda n: 'base_backup' in n),
    ('vehicle',            lambda n: has(n, 'recovered_vehicle','backup_vehicle','_vehicle','vehicle_') or n in ('store_recovered_vehicle','restore_recovered_vehicle','load_recovered_vehicles','store_recovered_vehicles_wiped_before_spawn')),
    ('transfer',           lambda n: 'character_transfer' in n or 'character_migration' in n or n.startswith('migrate_') or n in ('delete_account','can_takeover_account','cleanup_account_log_and_orphaned_actors','cleanup_accounts_marked_for_deletion_in_fls') or 'unsaved' in n or 'unbacked_up' in n),
    ('encryption',         lambda n: 'user_data_encryption' in n or n in ('decrypt_user_data','encrypt_user_data','setup_user_data_encryption')),
    ('inventory',          lambda n: n.startswith(('inventory_','load_item','load_items','save_item','delete_item','delete_inventory','merge_inventory','move_inventory','update_inventory','merge_or_move_inventory','get_inventory')) or n in ('advance_items_id_sequencer','remove_items_from_inventory') or '_item_' in n and 'log' not in n),
    ('landsraad',          lambda n: 'landsraad' in n),
    ('journey_progression',lambda n: n.startswith('journey_') or has(n, 'journey_story','tutorial','mnemonic','coriolis','progression','dunipedia','big_moments') or 'complete_journey' in n or 'delete_journey' in n or 'save_journey' in n),
    ('contracts',          lambda n: 'contract' in n),
    ('anticheat',          lambda n: n.startswith(('flag_player','log_cheating','verify_item_dup','add_actor_audit'))),
    ('event_log',          lambda n: 'event_log' in n),
    ('faction',            lambda n: 'faction' in n or 'reputation' in n),
    ('currency',           lambda n: 'currency' in n or 'solaris' in n or 'scrip' in n or has(n, 'balance','wallet')),
    ('lookup',             lambda n: n.startswith(('admin_','get_player_infos','dune_get_account','is_player_','get_player','get_character','get_online','get_login','get_learned','get_traveling','get_best','get_all','get_stored','fetch_')) or 'lookup' in n),
    ('character_mod',      lambda n: has(n,'specialization','keystone','skill','player_tags','player_state','character_name','returning_player','welcome','login_account','delete_character','set_character','set_player')),
    ('guild',              lambda n: 'guild' in n),
    ('party',              lambda n: 'party' in n),
    ('map_areas',          lambda n: has(n,'map_areas','overmap','sinkchart','crafted_map','set_map_seed','map_seed','map_for_player','map_id')),
    ('permission',         lambda n: 'permission' in n),
    ('actors',             lambda n: n.startswith('delete_actors') or n in ('assign_actor_id','unassign_actor_id','delete_actor_states_travel','delete_actor_states') or 'actor' in n and not 'audit' in n),
    ('partition',          lambda n: 'partition' in n),
    ('dungeon',            lambda n: 'dungeon' in n),
    ('farm',               lambda n: 'farm' in n),
    ('igwo',               lambda n: 'igwo' in n),
    ('taxation',           lambda n: 'taxation' in n),
    ('exchange',           lambda n: 'exchange' in n),
    ('communinet',         lambda n: 'communinet' in n),
    ('travel',             lambda n: 'travel' in n),
    ('markers',            lambda n: 'markers' in n or 'marker' in n),
    ('stock_vendor',       lambda n: 'stock' in n or 'vendor' in n),
    ('building_blueprint', lambda n: has(n,'blueprint','building_','_building','placeable','totem')),
    ('dialogue',           lambda n: 'dialogue' in n),
    ('spice_field',        lambda n: 'spice' in n or 'spicefield' in n),
    ('shifting_sand',      lambda n: 'shifting_sand' in n),
    ('landclaim',          lambda n: 'landclaim' in n),
    ('spawner',            lambda n: 'spawner' in n or 'respawn' in n),
    ('takeover',           lambda n: 'takeover' in n),
    ('schema_meta',        lambda n: n in ('get_applied_patches','get_schema_version','get_universe_time','update_universe_time') or 'demo_account' in n or 'demo_state' in n),
    ('items_purge',        lambda n: 'remove_items' in n or 'remove_resourcefield' in n or 'update_removed_items' in n or 'get_items_to_remove' in n or 'get_recipes_to_remove' in n),
    ('player_persistence', lambda n: n in ('save_player','save_player_pawn','save_tracked_journey_cards','record_logoff_persistence_end_time','perform_notify_on_character_delete','update_death_location') or '_add_item_' in n),
    ('battlegroup',        lambda n: 'battlegroup' in n),
    ('server',             lambda n: n.startswith('update_server_') or 'server_player_access' in n or n.startswith('register_') or n.startswith('initialize_') or n in ('get_active_servers_for_gateway','server_info_match','mark_server_dead')),
    ('cleanup',            lambda n: n.startswith(('clean_','cleanup_','wipe_','clear_','reset_'))),
    ('contracts',          lambda n: 'contract' in n),
]
def categorize(name: str) -> str:
    for cat, fn in RULES:
        if fn(name):
            return cat
    return 'misc'

# Split into records on @@@RTN@@@<oid>\n
records = re.split(r'(?m)^@@@RTN@@@', raw)
records = [r for r in records if r.strip()]

manifest_rows = [['oid','kind','category','name','args','return','comment','file']]
all_chunks = []
written = 0
seen_paths = {}

for rec in records:
    # Strip trailing @@@ENDRTN@@@ line
    rec = rec.rstrip()
    if rec.endswith('@@@ENDRTN@@@'):
        rec = rec[:-len('@@@ENDRTN@@@')].rstrip('\n')
    # header lines: oid, kind, name, args, return, comment
    lines = rec.split('\n')
    try:
        body_idx = lines.index('@@@BODY@@@')
    except ValueError:
        print(f'WARN: malformed record, skipping (head={lines[:3]})', file=sys.stderr)
        continue
    header = lines[:body_idx]
    if len(header) < 6:
        # pad missing trailing fields (e.g. empty comment that produced no line)
        while len(header) < 6:
            header.append('')
    oid, kind, name, args, rettype, comment = header[:6]
    body = '\n'.join(lines[body_idx+1:])

    cat = categorize(name)
    sub = 'procedures' if kind == 'p' else f'functions/{cat}'
    target_dir = pathlib.Path(out_dir) / sub
    target_dir.mkdir(parents=True, exist_ok=True)

    arg_count = 0 if not args.strip() else (args.count(',') + 1)
    base = f'{name}__{arg_count}args.sql'
    # avoid collisions on overloads with identical arg counts
    path = target_dir / base
    if path.exists():
        base = f'{name}__{arg_count}args__oid{oid}.sql'
        path = target_dir / base

    header_comment = (
        f'-- {name}({args}) -> {rettype or "void"}\n'
        f'-- oid: {oid}  kind: {"PROCEDURE" if kind=="p" else "FUNCTION"}  category: {cat}\n'
        + (f'-- comment: {comment}\n' if comment else '')
        + '\n'
    )
    path.write_text(header_comment + body.rstrip() + '\n')

    rel = path.relative_to(pathlib.Path(out_dir))
    manifest_rows.append([oid, kind, cat, name, args, rettype, comment, str(rel)])
    all_chunks.append(header_comment + body.rstrip() + '\n')
    written += 1

# write manifest
with open(manifest_path, 'w') as f:
    for row in manifest_rows:
        f.write('\t'.join(c.replace('\t',' ').replace('\n',' ') for c in row) + '\n')

# write _all.sql
with open(all_path, 'w') as f:
    f.write('-- All routines in dune schema, concatenated. Generated by _export.sh\n\n')
    f.write('\n\n'.join(all_chunks))

print(f'wrote {written} routines, manifest at {manifest_path}, _all.sql at {all_path}')
PYEOF

echo "==> File counts:"
find "$SCRIPT_DIR/functions" "$SCRIPT_DIR/procedures" -name '*.sql' | wc -l
echo "==> Categories:"
find "$SCRIPT_DIR/functions" -mindepth 1 -maxdepth 1 -type d -printf '%f\t' -exec sh -c 'find "$1" -name "*.sql" | wc -l' _ {} \; 2>/dev/null || \
  for d in "$SCRIPT_DIR"/functions/*/; do
    printf '%s\t%d\n' "$(basename "$d")" "$(find "$d" -name '*.sql' | wc -l)"
  done

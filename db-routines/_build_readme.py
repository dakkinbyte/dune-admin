#!/usr/bin/env python3
"""Generate db-routines/README.md from _manifest.tsv and dune-admin Go source grep."""
import os, re, sys, subprocess, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parent
REPO = ROOT.parent
MANIFEST = ROOT / '_manifest.tsv'
README = ROOT / 'README.md'

# Curated one-line descriptions for the well-known 50 (sourced from prior memory work).
CURATED = {
    'set_specialization_xp_and_level': 'Directly set spec XP and level for a player on a given track.',
    'reset_specialization_tracks': 'Wipe all specialization tracks for a player.',
    'reset_specialization_keystones': 'Wipe all purchased keystones for a player.',
    'purchase_specialization_keystone': 'Validate-then-record a keystone purchase. Returns bool.',
    'update_player_tags': 'Add and/or remove gameplay tags for an account in one call.',
    'admin_read_player_tags': 'Read tags for an account (admin).',
    'set_character_name': 'Rename a character.',
    'delete_all_tutorial_entries': 'Clear tutorial completion state for a player.',
    'adjust_player_virtual_currency_balance': 'Atomic delta on Solaris/Scrip balance; returns new balance.',
    'migrate_character': 'Cross-server character migration; clamps Solaris to allowed cap.',
    'migrate_clamp_max_allow_solaris': 'Clamp currency on migration.',
    'update_coriolis_for_player': 'Apply Coriolis storm processing for a player; returns whether processed.',
    'returning_player_award_given': 'Stamp last_returning_player_awarded_time = now() for an account.',
    'update_returning_player_status': 'Recalculate returning-player eligibility on login.',
    'login_account': 'Full login flow; returns player description (called by game server).',
    'admin_get_character_ids': 'Admin player search by partial name/id.',
    'admin_get_inventory_details': 'Admin: read inventory for an account.',
    'dune_get_account_id_by_user': 'Resolve FLS id → account id.',
    'is_player_offline': 'Return true if player has no live session.',
    'get_player_virtual_currency_balances': 'List wallet balances for a controller.',
    'get_solaris_id': 'Currency id used for Solaris.',
    'save_item': 'Insert/update a single inventory item.',
    'delete_item': 'Delete one inventory item by id.',
    'delete_items': 'Delete a batch of inventory items by id.',
    'delete_inventory_item': 'Partial delete (decrement count); removes when count hits 0.',
    'move_inventory_item': 'Relocate an item within/between inventories.',
    'merge_inventory_item': 'Merge stackable items.',
    'merge_or_move_inventory_item': 'Merge if possible, otherwise move.',
    'update_inventory': 'Bulk inventory mutator (delete, stack, quality, stats, location lists).',
    'load_items': 'Read all items in an inventory.',
    'load_item': 'Read a single item.',
    'get_inventory_data': 'Read inventory metadata.',
    'update_inventories_data': 'Update inventory metadata for a list.',
    'base_backup_save_from_totem': 'Snapshot a single base keyed by totem id; returns backup id.',
    'base_backup_save_all_totems_from_player_owner': 'Snapshot every base a player owns; returns set of backup ids.',
    'base_backup_find_totems_from_player_owner': 'List totem ids owned by a player (read-only).',
    'base_backup_get_available_backups': 'List stored backups for a player.',
    'base_backup_get_data': 'Read backup metadata.',
    'base_backup_get_buildable_data': 'Read buildable-piece data for a backup.',
    'base_backup_delete': 'Delete a stored base backup.',
    'base_backup_recycle': 'Recycle a stored base backup into an inventory.',
    'base_backup_finish_placing': 'Finalize placement of a restored backup.',
    'base_backup_get_actors_to_spawn': 'Read actors to spawn for backup placement.',
    'store_backup_vehicle': 'Move a vehicle into the backup slot.',
    'restore_backup_vehicle': 'Spawn a backed-up vehicle for an account; returns vehicle id.',
    'load_backup_vehicle': 'Read backed-up vehicle metadata for an account.',
    'store_recovered_vehicle': 'Save a recovered vehicle (with chassis durability/customization).',
    'store_recovered_vehicles_wiped_before_spawn': 'Bulk: save recovered vehicles, optionally delete their items.',
    'restore_recovered_vehicle': 'Recover a vehicle into world; supports a time limit.',
    'load_recovered_vehicles': 'List recoverable vehicles for an account.',
    'get_unsaved_base_totem_ids_for_account': 'Bases not yet backed up (pre-transfer check).',
    'get_unbacked_up_vehicle_ids_for_account': 'Vehicles not yet backed up (pre-transfer check).',
    'character_transfer_get_unsaved_counts': 'Pre-transfer counts of unsaved bases/vehicles.',
    'character_transfer_export': 'Export a character (incl. inventory, journey, etc.) as jsonb.',
    'character_transfer_import': 'Import a jsonb character payload; returns new account id.',
    'character_migration_export': 'Export character for migration.',
    'delete_account': 'Hard-delete an account by FLS id; returns bool.',
    'flag_player_as_cheater': 'Mark account as a cheater of given type.',
    'log_cheating': 'Append cheating event.',
    'verify_item_dup_backup_tool': 'Anti-dup check around backup tool flow.',
    'set_player_faction_reputation': 'Set a player\'s faction rep value directly (audited).',
    'change_player_faction': 'Switch a player\'s faction allegiance.',
    'complete_journey_story_nodes_for_player': 'Bulk-mark journey story nodes complete for a player.',
    'delete_all_journey_story_nodes': 'Wipe all journey nodes for a player.',
    'delete_mnemonic_recall_lesson_all': 'Wipe codex / mnemonic recall lessons.',
}

def short_purpose(name: str, comment: str) -> str:
    if name in CURATED: return CURATED[name]
    if comment.strip(): return comment.strip()
    # name-derived stub
    parts = name.lstrip('_').split('_')
    return ' '.join(parts).capitalize() + '.'

# Load manifest
rows = []
with open(MANIFEST) as f:
    header = f.readline()  # skip
    for line in f:
        cells = line.rstrip('\n').split('\t')
        if len(cells) < 8: continue
        oid, kind, cat, name, args, ret, comment, fpath = cells[:8]
        rows.append({'oid':oid,'kind':kind,'cat':cat,'name':name,'args':args,
                     'ret':ret,'comment':comment,'file':fpath})

# Build name → list of (file, line) call sites from Go source.
# Pattern: dune.<name>(  — appears in SQL string literals inside Go.
name_re = re.compile(r'\bdune\.([a-z_][a-z_0-9]*)\s*\(')
calls = collections.defaultdict(list)
fn_names = {r['name'] for r in rows}
for go in REPO.glob('*.go'):
    rel = go.name
    for ln, line in enumerate(go.read_text().splitlines(), 1):
        for m in name_re.finditer(line):
            n = m.group(1)
            if n in fn_names:
                calls[n].append(f'{rel}:{ln}')

# Group rows by category
by_cat = collections.defaultdict(list)
for r in rows:
    by_cat[r['cat']].append(r)
for cat in by_cat:
    by_cat[cat].sort(key=lambda r: r['name'])

# Compute counts
total = len(rows)
fns = sum(1 for r in rows if r['kind']=='f')
procs = sum(1 for r in rows if r['kind']=='p')
used = sum(1 for r in rows if r['name'] in calls)
unused = total - used

# Render
out = []
out.append('# Dune Schema Routines — Reference & Cross-Map')
out.append('')
out.append(f'Complete export of every function and procedure in the `dune` schema of the game-server Postgres '
           f'(PG 17.4, pod `sh-ec68e59f636959ac-coyzzx-db-dbdepl-sts-0`). Generated by `_export.sh` + `_build_readme.py`.')
out.append('')
out.append('## Inventory')
out.append('')
out.append(f'- **Total routines:** {total}')
out.append(f'- **Functions:** {fns}')
out.append(f'- **Procedures:** {procs}')
out.append(f'- **Called from dune-admin Go source:** {used} (see Cross-reference column)')
out.append(f'- **Not called from dune-admin:** {unused}')
out.append('')
out.append('Per-routine SQL lives in `functions/<category>/<name>__<argcount>args.sql` and `procedures/<name>__<argcount>args.sql`. '
           'A single concatenated dump is at `_all.sql`. A TSV index is at `_manifest.tsv`.')
out.append('')

out.append('## Access path (read-only)')
out.append('')
out.append('```')
out.append('ssh -i ./sshKey dune@192.168.0.72 \\')
out.append('  "sudo -n kubectl exec -n funcom-seabass-sh-ec68e59f636959ac-coyzzx \\')
out.append('     sh-ec68e59f636959ac-coyzzx-db-dbdepl-sts-0 -- \\')
out.append('     env PGPASSWORD=<pw> psql -h 127.0.0.1 -p 15432 -U postgres -d dune <args>"')
out.append('```')
out.append('')
out.append('Passwordless `sudo` works on the VM. The password is also visible inside the pod via `env | grep POSTGRES_PASSWORD`.')
out.append('')

out.append('## Categories')
out.append('')
out.append('| Category | Count |')
out.append('|---|---:|')
for cat in sorted(by_cat.keys()):
    out.append(f'| [{cat}](#{cat.replace("_","-")}) | {len(by_cat[cat])} |')
out.append('')

# Per category detail
for cat in sorted(by_cat.keys()):
    out.append(f'### {cat}')
    out.append('')
    out.append('| Routine | Args → Returns | Used by | Purpose |')
    out.append('|---|---|---|---|')
    for r in by_cat[cat]:
        sig = f'`{r["name"]}({r["args"]})`'
        ret = r['ret'] or ('void' if r['kind']=='p' else '')
        argret = f'{r["args"] or "()"} → {ret}'
        # escape pipes for markdown table
        argret = argret.replace('|','\\|')
        used_cells = calls.get(r['name'], [])
        used_str = '<br>'.join(f'`{c}`' for c in used_cells) if used_cells else '—'
        purpose = short_purpose(r['name'], r['comment']).replace('|','\\|')
        kind_tag = ' _(proc)_' if r['kind']=='p' else ''
        out.append(f'| `{r["name"]}`{kind_tag} | {argret} | {used_str} | {purpose} |')
    out.append('')

out.append('## Cross-reference summary — what dune-admin already uses')
out.append('')
out.append('| Routine | Called at |')
out.append('|---|---|')
for name in sorted(calls.keys()):
    locs = '<br>'.join(f'`{c}`' for c in calls[name])
    out.append(f'| `{name}` | {locs} |')
out.append('')

out.append('## Proposed additions and fixes to dune-admin')
out.append('')
out.append('Concrete, high-confidence gaps where the DB already provides the right primitive but the admin tool either rolls its own SQL or has no UI for it. Each item is independently shippable.')
out.append('')

PUNCH = [
    ('Vehicle backup / recovery UI',
     ['store_backup_vehicle','restore_backup_vehicle','load_backup_vehicle',
      'store_recovered_vehicle','store_recovered_vehicles_wiped_before_spawn',
      'restore_recovered_vehicle','load_recovered_vehicles'],
     'Admin has zero coverage of vehicle backup/recovery. Add a `handlers_vehicles.go` mirroring the base backup pattern. The DB primitives lock `backup_vehicles` exclusively so concurrent-safe; admin just needs the UI + RPC wiring.'),
    ('Character-transfer pre-flight checks',
     ['character_transfer_get_unsaved_counts','get_unsaved_base_totem_ids_for_account','get_unbacked_up_vehicle_ids_for_account'],
     '`handlers_players.go:522` calls `character_transfer_export` directly. The v1.40.1 safety helpers above exist specifically to gate this. Call `character_transfer_get_unsaved_counts(fls_id)` before export and either refuse or surface a confirmation listing the unsaved totem and vehicle IDs.'),
    ('Base backup / restore UI',
     ['base_backup_save_from_totem','base_backup_save_all_totems_from_player_owner','base_backup_find_totems_from_player_owner',
      'base_backup_get_available_backups','base_backup_get_data','base_backup_get_buildable_data',
      'base_backup_delete','base_backup_recycle','base_backup_finish_placing','base_backup_get_actors_to_spawn'],
     '`handlers_bases.go` currently walks raw actor/building tables. Wrap the dedicated procs above for save / list / restore / delete / recycle so behavior matches the in-game flow (and audit trail).'),
    ('Use admin_get_character_ids for player search',
     ['admin_get_character_ids'],
     'Replaces hand-rolled `LIKE` queries with the indexed admin function so dune-admin agrees with other internal tools on what counts as a match.'),
    ('Replace raw returning-player UPDATE with procs',
     ['update_returning_player_status','returning_player_award_given'],
     'Currently the admin issues raw `UPDATE encrypted_player_state SET last_returning_player_*` (see memory note about the "sticky welcome-back modal" footgun). Route through these two functions to keep the timestamp pair coherent with the login flow.'),
    ('Keystone purchases via purchase_specialization_keystone',
     ['purchase_specialization_keystone'],
     'Admin grants keystones with raw inserts; the proc returns bool after running game-side validation. Route through it so granting from dune-admin behaves identically to in-game purchase.'),
    ('Bulk inventory edits via update_inventory',
     ['update_inventory','update_inventories_data','merge_or_move_inventory_item'],
     'Replace N-round-trip CRUD with the single bulk mutator. Reduces lock churn and matches the game-side write pattern.'),
    ('Anti-cheat surfacing',
     ['flag_player_as_cheater','log_cheating','verify_item_dup_backup_tool'],
     'No admin UI for marking a flagged player or browsing the cheat log. Add a read view over `log_cheating` results and an admin-action to flag.'),
    ('Account takeover / deletion lifecycle',
     ['can_takeover_account','set_account_as_takeoverable','load_takeoverable_user_ids','takeover_account',
      'cleanup_account_log_and_orphaned_actors','cleanup_accounts_marked_for_deletion_in_fls'],
     'The takeover and deletion-cleanup helpers are not exposed. Worth a dedicated admin screen, especially `cleanup_accounts_marked_for_deletion_in_fls` for periodic operator maintenance.'),
    ('Schema/version visibility',
     ['get_applied_patches','get_schema_version'],
     'Surface the schema version in the dune-admin status bar so operators know which DB rev they\'re looking at without exec-ing into the pod.'),
    ('Spice field operator controls',
     ['try_prime_spicefield','try_restart_spicefield','try_spawn_spicefield','request_spawn_spice_field',
      'record_deactivated_spice_field','update_spice_field_spawn_state','update_global_spice_field_rules'],
     'Spice-field manipulation is a known operator chore; the DB exposes prime/restart/spawn primitives that an admin "spice fields" tab could wrap.'),
    ('Landsraad voting / decree management',
     ['landsraad_insert_tasks','landsraad_nominate_decrees_for_voting','landsraad_update_decrees','landsraad_update_factions'],
     'Five Landsraad PROCEDUREs (insert tasks, nominate decrees, update decrees, update factions, create_event_log_partition_table). The 35 functions are mostly read-side. An admin tab that shows the current term and lets ops force-advance/update decrees would be high-value during live ops.'),
]
for title, names, body in PUNCH:
    out.append(f'### {title}')
    out.append('')
    out.append(body)
    out.append('')
    out.append('Routines:')
    for n in names:
        r = next((x for x in rows if x['name']==n), None)
        sig = f'`dune.{n}({r["args"] if r else "?"})`' if r else f'`dune.{n}(?)`'
        purpose = short_purpose(n, r['comment'] if r else '') if r else ''
        out.append(f'- {sig} — {purpose}')
    out.append('')

out.append('## Notes & caveats')
out.append('')
out.append('- Purpose blurbs come from three sources, in order: curated descriptions for the well-known ~60 routines; the Postgres COMMENT (`obj_description(oid)`) when present; otherwise a name-derived stub. The DB had almost no COMMENTs set, so most stubs are name-derived.')
out.append('- The categorizer is rule-based on routine name. Edge cases land in `misc`; if you add an obvious cluster, edit `RULES` in `_export.sh` and re-run.')
out.append('- Overloaded routines (same name, different signatures) get separate files; if two share an arg count the OID is appended.')
out.append('- The Go cross-reference is a literal regex search for `dune.<name>(` in `*.go` files at the repo root. False negatives possible if a query is built with computed names; spot-check the routine you care about by hand.')

README.write_text('\n'.join(out) + '\n')
print(f'wrote {README} ({README.stat().st_size} bytes, {len(out)} lines)')

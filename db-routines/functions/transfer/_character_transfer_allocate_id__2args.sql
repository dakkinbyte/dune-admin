-- _character_transfer_allocate_id(kind dune._charactertransferentrykind, data jsonb) -> bigint
-- oid: 58095  kind: FUNCTION  category: transfer

CREATE OR REPLACE FUNCTION dune._character_transfer_allocate_id(kind dune._charactertransferentrykind, data jsonb)
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE
AS $function$
	select case
		when kind = 'acc' then nextval('encrypted_accounts_id_seq')
		when kind = 'act' then nextval('actors_id_seq')
		when kind = 'inv' then nextval('inventories_id_seq')
		when kind = 'itm' then nextval('items_id_seq')
		when kind = 'fgl' then nextval('character_transfer_fgl_entities_entity_id_seq')
		when kind = 'bbp' then nextval('building_blueprints_id_seq')

		when kind = 'VehicleModule' then nextval('vehicle_modules_id_seq')

		when kind = 'Faction' then (select id from factions where "name" = data->>'name')
		when kind = 'Tutorial' then (select id from tutorials where "name" = data->>'name')
		when kind = 'Keystone' then (select id from specialization_keystones_map where "name" = data->>'name')

		when kind = 'BaseBackup' then nextval('base_backups_id_seq')
		when kind = 'TaxInvoice' then nextval('tax_invoice_id_seq')

		when kind = 'DungeonCompletion' then nextval('dungeon_completion_completion_id_seq')
		else null
	end;
$function$

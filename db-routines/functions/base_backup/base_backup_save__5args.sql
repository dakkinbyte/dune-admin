-- base_backup_save(in_player_actor_id bigint, in_base_backup_name text, in_building_pieces_to_link dune.basebackupbuildingitem[], in_placeables_to_link bigint[], in_placeables_to_remove_totem_owner bigint[]) -> bigint
-- oid: 58152  kind: FUNCTION  category: base_backup

CREATE OR REPLACE FUNCTION dune.base_backup_save(in_player_actor_id bigint, in_base_backup_name text, in_building_pieces_to_link dune.basebackupbuildingitem[], in_placeables_to_link bigint[], in_placeables_to_remove_totem_owner bigint[])
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_backup_id BIGINT;
    totem_id BIGINT;
BEGIN
    -- Find and Validate the Totem exists in the list
    SELECT t.id INTO totem_id
        FROM totems t
            JOIN unnest(in_placeables_to_link) AS ai(actor_id) ON t.id = ai.actor_id
        LIMIT 1;

    IF totem_id IS NULL THEN
        RAISE EXCEPTION 'No totem found for base_backup_save';
    END IF;

    INSERT INTO base_backups(player_id, base_backup_name)
        VALUES (in_player_actor_id, in_base_backup_name) RETURNING id INTO v_backup_id;

    -- for each building_id, create a new actor for those building pieces and then assign that new building_id to the building pieces.
    with
        input as (select DISTINCT building_id from unnest(in_building_pieces_to_link)),
        instances_input as (select building_id, instance_id from unnest(in_building_pieces_to_link)),
        new_actor_ids as (select nextval('actors_id_seq') as new_id, building_id as old_id from input),
        _copy_building_actors as (
            insert into actors("id", "class", "map", "transform", "partition_id", "dimension_index")
            select i.new_id, a."class", a."map", a."transform", a."partition_id", a."dimension_index"
            from new_actor_ids i join actors a on (i.old_id = a.id)),
        _insert_actor_states as (insert into actor_state(actor_id, state) select new_id, 'BaseBackup' from new_actor_ids),
        _insert_buildings as (insert into buildings("id") select new_id from new_actor_ids),
        _insert_base_backup_linked_actors as (insert into base_backup_linked_actors("id", "actor_id") select v_backup_id, new_id from new_actor_ids)
    update building_instances bi set building_id = ids.new_id from new_actor_ids ids join instances_input i on (ids.old_id = i.building_id) where bi.building_id = ids.old_id and bi.instance_id = i.instance_id;

    -- Link all placeables to the linked_base_backup_id and set them to BaseBackup ActorState in actor_state
    INSERT INTO base_backup_linked_actors(id, actor_id)
        SELECT v_backup_id, unnest(in_placeables_to_link);

    INSERT INTO actor_state(actor_id, state)
        SELECT unnest(in_placeables_to_link), 'BaseBackup'::ActorState;

    UPDATE placeables
        SET owner_entity_id = NULL
        WHERE id = ANY(in_placeables_to_remove_totem_owner);

    -- We need to remove permissions for the Totem
    PERFORM permission_actor_destroy(totem_id);

    -- Remove all invoices from the totem
    PERFORM taxation_remove_invoices_from_totem(totem_id);

    RETURN v_backup_id;
END
$function$

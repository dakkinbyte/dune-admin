-- admin_get_inventory_details(in_account_id bigint) -> TABLE(inventory_id bigint, item_id bigint, stack_size integer, template_id text, acquisition_time bigint)
-- oid: 58132  kind: FUNCTION  category: lookup

CREATE OR REPLACE FUNCTION dune.admin_get_inventory_details(in_account_id bigint)
 RETURNS TABLE(inventory_id bigint, item_id bigint, stack_size integer, template_id text, acquisition_time bigint)
 LANGUAGE sql
AS $function$
	select
		inventories.id as inventory_id, items.id as item_id, items.stack_size, items.template_id, items.acquisition_time
	from
		items
	left join
		inventories on inventories.id = items.inventory_id
	left join
		player_state on inventories.actor_id = player_state.player_pawn_id
	where
		player_state.account_id = in_account_id
	order by
		template_id;
$function$

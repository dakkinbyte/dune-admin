-- taxation_get_all_invoices_for_player(in_player_id bigint) -> TABLE(id bigint, totem_id bigint, reference_timestamp bigint, invoice_status smallint, amount integer, actor_name text)
-- oid: 58603  kind: FUNCTION  category: taxation

CREATE OR REPLACE FUNCTION dune.taxation_get_all_invoices_for_player(in_player_id bigint)
 RETURNS TABLE(id bigint, totem_id bigint, reference_timestamp bigint, invoice_status smallint, amount integer, actor_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT tax_invoice.id, tax_invoice.totem_id, tax_invoice.reference_timespan, tax_invoice.invoice_status, tax_invoice.amount, permission_actor.actor_name
	FROM tax_invoice 
	JOIN permission_actor ON permission_actor.actor_id = tax_invoice.totem_id
    JOIN permission_actor_rank ON permission_actor.actor_id = permission_actor_rank.permission_actor_id
    WHERE permission_actor_rank.player_id = in_player_id    
    ORDER BY tax_invoice.reference_timespan;
END
$function$

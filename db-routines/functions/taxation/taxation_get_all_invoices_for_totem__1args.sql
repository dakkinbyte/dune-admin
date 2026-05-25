-- taxation_get_all_invoices_for_totem(in_totem_id bigint) -> TABLE(id bigint, totem_id bigint, reference_timestamp bigint, invoice_status smallint, amount integer, actor_name text)
-- oid: 58605  kind: FUNCTION  category: taxation

CREATE OR REPLACE FUNCTION dune.taxation_get_all_invoices_for_totem(in_totem_id bigint)
 RETURNS TABLE(id bigint, totem_id bigint, reference_timestamp bigint, invoice_status smallint, amount integer, actor_name text)
 LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY SELECT tax_invoice.id, actors.id, tax_invoice.reference_timespan, tax_invoice.invoice_status, tax_invoice.amount, permission_actor.actor_name
	FROM tax_invoice 
    JOIN permission_actor ON permission_actor.actor_id = tax_invoice.totem_id
	JOIN actors ON actors.id = tax_invoice.totem_id 
    WHERE actors.id = in_totem_id
    ORDER BY tax_invoice.reference_timespan;
END
$function$

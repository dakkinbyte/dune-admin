-- taxation_remove_invoices_from_totem(totem_actor_id bigint) -> void
-- oid: 58608  kind: FUNCTION  category: taxation

CREATE OR REPLACE FUNCTION dune.taxation_remove_invoices_from_totem(totem_actor_id bigint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	invoice_ids BIGINT[];
BEGIN
    SELECT array_agg(id) from tax_invoice into invoice_ids WHERE totem_id = totem_actor_id;

    DELETE FROM tax_invoice WHERE totem_id = totem_actor_id;
    PERFORM pg_notify('taxation_notify_channel', format('remove_invoice|{"InvoiceIds" : %s}', to_json(invoice_ids)::text));
END
$function$

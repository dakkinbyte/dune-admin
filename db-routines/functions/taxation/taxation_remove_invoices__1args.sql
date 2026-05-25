-- taxation_remove_invoices(invoices_to_remove bigint[]) -> void
-- oid: 58607  kind: FUNCTION  category: taxation

CREATE OR REPLACE FUNCTION dune.taxation_remove_invoices(invoices_to_remove bigint[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    DELETE FROM tax_invoice WHERE id = ANY(invoices_to_remove);
    PERFORM pg_notify('taxation_notify_channel', format('remove_invoice|{"InvoiceIds" : %s}', to_json(invoices_to_remove)::text));
END
$function$

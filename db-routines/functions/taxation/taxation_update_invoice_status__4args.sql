-- taxation_update_invoice_status(invoices_to_overdue bigint[], invoices_to_defaulted bigint[], overdue_invoice_status smallint, defaulted_invoice_status smallint) -> void
-- oid: 58609  kind: FUNCTION  category: taxation

CREATE OR REPLACE FUNCTION dune.taxation_update_invoice_status(invoices_to_overdue bigint[], invoices_to_defaulted bigint[], overdue_invoice_status smallint, defaulted_invoice_status smallint)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF array_length(invoices_to_overdue, 1) > 0 THEN
        UPDATE tax_invoice SET invoice_status = overdue_invoice_status WHERE id = ANY(invoices_to_overdue);
        PERFORM pg_notify('taxation_notify_channel', format('update_invoice_status|{"InvoiceStatus" : %s, "InvoiceIds" : %s}', overdue_invoice_status, to_json(invoices_to_overdue)::text));
    END IF;

    IF array_length(invoices_to_defaulted, 1) > 0 THEN
        UPDATE tax_invoice SET invoice_status = defaulted_invoice_status WHERE id = ANY(invoices_to_defaulted);
        PERFORM pg_notify('taxation_notify_channel', format('update_invoice_status|{"InvoiceStatus" : %s, "InvoiceIds" : %s}', defaulted_invoice_status, to_json(invoices_to_defaulted)::text));
    END IF;
END
$function$

-- taxation_pay_invoice(invoice_id bigint, paid_invoice_status smallint) -> bigint
-- oid: 58606  kind: FUNCTION  category: taxation

CREATE OR REPLACE FUNCTION dune.taxation_pay_invoice(invoice_id bigint, paid_invoice_status smallint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	found_invoice_id BIGINT;
BEGIN
    UPDATE tax_invoice SET invoice_status = paid_invoice_status WHERE tax_invoice.id = invoice_id AND tax_invoice.invoice_status != paid_invoice_status RETURNING id INTO found_invoice_id;
    if found_invoice_id IS NOT NULL THEN
        PERFORM pg_notify('taxation_notify_channel', format('pay_invoice|{"InvoiceId" : %s }', invoice_id));
    END IF;
    RETURN found_invoice_id;
END
$function$

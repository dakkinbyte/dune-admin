-- taxation_emit_invoices(new_tax_invoices dune.taxinvoicedata[]) -> void
-- oid: 58602  kind: FUNCTION  category: taxation

CREATE OR REPLACE FUNCTION dune.taxation_emit_invoices(new_tax_invoices dune.taxinvoicedata[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	invoice_ids BIGINT[];
    new_invoice_id BIGINT;
    new_tax_invoice TaxInvoiceData;
BEGIN
    IF array_length(new_tax_invoices, 1) > 0 THEN
		FOREACH new_tax_invoice IN ARRAY new_tax_invoices LOOP
        
            INSERT INTO tax_invoice("totem_id", "reference_timespan", "invoice_status", "amount") 
                VALUES(new_tax_invoice.totem_id, new_tax_invoice.reference_timespan, new_tax_invoice.invoice_status, new_tax_invoice.amount) RETURNING id INTO new_invoice_id;
            
            invoice_ids := array_append(invoice_ids, new_invoice_id);
		END LOOP;

        PERFORM pg_notify('taxation_notify_channel', format('emit_invoices|{"InvoiceIds" : %s, "InvoiceData" : %s}', to_json(invoice_ids)::text, to_json(new_tax_invoices)::text));
	END IF;
END
$function$

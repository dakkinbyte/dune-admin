-- try_update_exchange_categories_hash(in_new_hash integer) -> TABLE(item_template_id text, mask integer, depth smallint)
-- oid: 58613  kind: FUNCTION  category: exchange

CREATE OR REPLACE FUNCTION dune.try_update_exchange_categories_hash(in_new_hash integer)
 RETURNS TABLE(item_template_id text, mask integer, depth smallint)
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	IF NOT EXISTS (SELECT * FROM dune_exchange_categories_hash) FOR UPDATE THEN
		INSERT INTO dune_exchange_categories_hash(id, hash) VALUES(1, in_new_hash);
		RETURN;
	END IF;
	IF NOT in_new_hash IN (SELECT hash FROM dune_exchange_categories_hash FOR SHARE) THEN
		UPDATE dune_exchange_categories_hash SET hash = in_new_hash WHERE dune_exchange_categories_hash.id = 1;
		RETURN QUERY SELECT DISTINCT template_id, category_mask, category_depth FROM dune_exchange_orders;
	END IF;
	RETURN;
END
$function$

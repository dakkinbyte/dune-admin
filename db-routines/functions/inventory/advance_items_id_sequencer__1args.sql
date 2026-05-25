-- advance_items_id_sequencer(count bigint) -> bigint
-- oid: 58139  kind: FUNCTION  category: inventory

CREATE OR REPLACE FUNCTION dune.advance_items_id_sequencer(count bigint DEFAULT 1)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
  next_val  BIGINT;
  next_free BIGINT;
BEGIN
  IF count < 1 THEN
    RAISE EXCEPTION 'count must be >= 1';
  END IF;

  PERFORM pg_advisory_xact_lock(('items_id_seq'::regclass)::oid::bigint);
  
  next_val := nextval('items_id_seq'::regclass);

  -- next free id after reserving `count` ids starting at next_val
  next_free := next_val + count;

  -- make the next nextval() return next_free
  PERFORM setval('items_id_seq'::regclass, next_free, false);

  RETURN next_val;
END $function$

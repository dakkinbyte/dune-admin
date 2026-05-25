-- _building_validate_totem_owner_id(in_totem_owner_id bigint) -> bigint
-- oid: 58094  kind: FUNCTION  category: building_blueprint

CREATE OR REPLACE FUNCTION dune._building_validate_totem_owner_id(in_totem_owner_id bigint)
 RETURNS bigint
 LANGUAGE sql
BEGIN ATOMIC
 SELECT
         CASE
             WHEN (in_totem_owner_id = 0) THEN NULL::bigint
             WHEN (EXISTS ( SELECT 1
                FROM dune.fgl_entities
               WHERE (fgl_entities.entity_id = _building_validate_totem_owner_id.in_totem_owner_id))) THEN in_totem_owner_id
             ELSE NULL::bigint
         END AS "case";
END

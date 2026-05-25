-- zero_transform() -> dune.transform
-- oid: 58651  kind: FUNCTION  category: misc

CREATE OR REPLACE FUNCTION dune.zero_transform()
 RETURNS dune.transform
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
	RETURN (
		ROW(
      		ROW(0.0, 0.0, 0.0)::Vector,
      		ROW(0.0, 0.0, 0.0, 1.0)::Quaternion
    	)::Transform
  	);
END;
$function$

-- save_tracked_journey_cards(in_player_id bigint, in_tracked_journey_card text, in_tracked_landsraad_card text) -> void
-- oid: 58572  kind: FUNCTION  category: player_persistence

CREATE OR REPLACE FUNCTION dune.save_tracked_journey_cards(in_player_id bigint, in_tracked_journey_card text, in_tracked_landsraad_card text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	INSERT INTO journey_tracked_cards (player_id, tracked_journey_card, tracked_landsraad_card) Values(in_player_id, in_tracked_journey_card, in_tracked_landsraad_card)
	ON CONFLICT(player_id) DO
	UPDATE SET tracked_journey_card = in_tracked_journey_card, tracked_landsraad_card = in_tracked_landsraad_card;
END $function$

-- Домашний сервер: добыча на любом корабле.
--
--   * майнеры, стрип-майнеры, ледовые харвестеры, модулированные лазеры (группы 54, 464, 483):
--       - снято ограничение «только баржи и эксумеры» (canFitShipGroup1/2 = 463/543);
--       - дальность (maxRange) 250 км — это и потолок захвата цели в Crucible;
--   * выработка за цикл (miningAmount) ×100 — у модулей и у майнинг-дронов (группа 101);
--   * навык Drones: +20 активных дронов за уровень вместо +1 — 100 дронов на пятом уровне;
--   * у каждого корабля есть отсек дронов хотя бы на 10 майнинг-дронов (50 м³) и канал на 5 из них (25 Мбит/с):
--     иначе на корабль без дронов их не взять.  Это после ×10 из 20261109120000-home-ship-holds, поэтому тем, у
--     кого отсек и так больше, ничего не меняется.
--
-- Майнинг-дроны сами ищут астероиды и возят руду в рудный трюм — это в коде (DroneAI, world.droneAutoMine).

-- +migrate Up
DELETE d FROM dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
 WHERE t.groupID IN (54, 464, 483) AND d.attributeID IN (1298, 1299);

UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
   SET d.valueFloat = 250000, d.valueInt = NULL
 WHERE t.groupID IN (54, 464, 483) AND d.attributeID = 54;

UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
   SET d.valueInt = d.valueInt * 100, d.valueFloat = d.valueFloat * 100
 WHERE t.groupID IN (54, 464, 483, 101) AND d.attributeID = 77;

-- Drones (3436): maxActiveDroneBonus
UPDATE dgmTypeAttributes SET valueInt = NULL, valueFloat = 20 WHERE typeID = 3436 AND attributeID = 353;

INSERT INTO dgmTypeAttributes (typeID, attributeID, valueInt, valueFloat)
  SELECT t.typeID, 283, NULL, 50
    FROM invTypes t JOIN invGroups g ON g.groupID = t.groupID
   WHERE g.categoryID = 6
  ON DUPLICATE KEY UPDATE
    valueFloat = GREATEST(COALESCE(dgmTypeAttributes.valueFloat, dgmTypeAttributes.valueInt, 0), 50),
    valueInt = NULL;

INSERT INTO dgmTypeAttributes (typeID, attributeID, valueInt, valueFloat)
  SELECT t.typeID, 1271, NULL, 25
    FROM invTypes t JOIN invGroups g ON g.groupID = t.groupID
   WHERE g.categoryID = 6
  ON DUPLICATE KEY UPDATE
    valueFloat = GREATEST(COALESCE(dgmTypeAttributes.valueFloat, dgmTypeAttributes.valueInt, 0), 25),
    valueInt = NULL;

-- +migrate Down
-- исходные дальности и ограничения лежат в sql/base (dgmTypeAttributes) — откат = переустановка базы.
SELECT 1;

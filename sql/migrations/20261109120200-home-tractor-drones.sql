-- Домашний сервер: тяговые лучи и скорость дронов.
--
--   * тяговые лучи (группа 650): дальность 250 км (потолок захвата цели в Crucible), скорость подтягивания ×10.
--     Сам луч перекладывает содержимое обломка или контейнера в трюм и переходит к следующему — это в коде
--     (ActiveModule::TractorCycle, world.tractorAutoLoot);
--   * все дроны и истребители (категория 18): максимальная скорость (maxVelocity) ×100 — подлёт к цели и возврат.
--     Скорость на орбите (entityCruiseSpeed) прежняя, иначе дроны на сотнях км/с не удержат орбиту.

-- +migrate Up
UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
   SET d.valueFloat = 250000, d.valueInt = NULL
 WHERE t.groupID = 650 AND d.attributeID = 54;

UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
   SET d.valueInt = d.valueInt * 10, d.valueFloat = d.valueFloat * 10
 WHERE t.groupID = 650 AND d.attributeID = 1045;

UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
  JOIN invGroups g ON g.groupID = t.groupID
   SET d.valueInt = d.valueInt * 100, d.valueFloat = d.valueFloat * 100
 WHERE g.categoryID = 18 AND d.attributeID = 37;

-- +migrate Down
UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
  JOIN invGroups g ON g.groupID = t.groupID
   SET d.valueInt = d.valueInt / 100, d.valueFloat = d.valueFloat / 100
 WHERE g.categoryID = 18 AND d.attributeID = 37;

UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
   SET d.valueInt = d.valueInt / 10, d.valueFloat = d.valueFloat / 10
 WHERE t.groupID = 650 AND d.attributeID = 1045;
-- исходные дальности лучей — в sql/base (dgmTypeAttributes)

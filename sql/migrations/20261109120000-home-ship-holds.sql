-- Домашний сервер: трюмы всех кораблей (категория 6 — Ship).
--
-- Что меняется (пожелания владельца сервера):
--   * грузовой трюм (invTypes.capacity)                 ×100
--   * рудный трюм (специальный, атрибут 1556)            = базовый грузовой трюм ×1000 — теперь у КАЖДОГО корабля;
--                                                          у кого он был (Orca, Rorqual…) — берётся большее из двух
--   * отсек дронов (атрибут 283 droneCapacity)           ×10
--   * пропускная способность дронов (1271 droneBandwidth) ×10
--
-- Почему в статических данных, а не в коде:  сервер берёт атрибуты корабля из типа (ItemType::CopyAttributes) и
--  заново применяет их при каждом пересчёте (AttributeMap::Load(reset)), так что расширители трюма, навыки и бонусы
--  корпуса считаются уже от увеличенной базы — как будто корабль таким и сделан.  Добыча модулями сама кладёт руду в
--  рудный трюм, если он есть у корабля (MiningLaser.cpp).
--
-- Клиент:  окно трюма спрашивает вместимость у сервера, а вот «Информация» о типе корабля и цифры фита в станции клиент
--  считает по своим данным — там останутся старые числа.
--
-- Порядок важен:  рудный трюм считается от ИСХОДНОГО грузового, поэтому он идёт до умножения capacity.

-- +migrate Up
INSERT INTO dgmTypeAttributes (typeID, attributeID, valueInt, valueFloat)
  SELECT t.typeID, 1556, NULL, t.capacity * 1000
    FROM invTypes t JOIN invGroups g ON g.groupID = t.groupID
   WHERE g.categoryID = 6 AND t.capacity > 0
  ON DUPLICATE KEY UPDATE
    valueFloat = GREATEST(COALESCE(dgmTypeAttributes.valueFloat, dgmTypeAttributes.valueInt, 0), VALUES(valueFloat)),
    valueInt = NULL;

UPDATE invTypes t JOIN invGroups g ON g.groupID = t.groupID
   SET t.capacity = t.capacity * 100
 WHERE g.categoryID = 6;

UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
  JOIN invGroups g ON g.groupID = t.groupID
   SET d.valueInt = d.valueInt * 10, d.valueFloat = d.valueFloat * 10
 WHERE g.categoryID = 6 AND d.attributeID IN (283, 1271);

-- +migrate Down
UPDATE dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
  JOIN invGroups g ON g.groupID = t.groupID
   SET d.valueInt = d.valueInt / 10, d.valueFloat = d.valueFloat / 10
 WHERE g.categoryID = 6 AND d.attributeID IN (283, 1271);

UPDATE invTypes t JOIN invGroups g ON g.groupID = t.groupID
   SET t.capacity = t.capacity / 100
 WHERE g.categoryID = 6;

-- рудные трюмы, которых в исходных данных не было (у Orca/Rorqual/Cockroach исходное значение не восстановить — оставляем)
DELETE d FROM dgmTypeAttributes d
  JOIN invTypes t ON t.typeID = d.typeID
  JOIN invGroups g ON g.groupID = t.groupID
 WHERE g.categoryID = 6 AND d.attributeID = 1556 AND t.typeID NOT IN (11019, 28352, 28606);

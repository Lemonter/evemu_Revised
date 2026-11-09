/**
 * WreckSalvage.cpp
 *      what a wreck gives when it is salvaged — shared by the salvager module (Prospector) and salvage drones (DroneAI)
 */

#include "eve-server.h"

#include "Client.h"
#include "EVEServerConfig.h"
#include "StaticDataMgr.h"
#include "exploration/WreckSalvage.h"
#include "inventory/AttributeEnum.h"
#include "inventory/Inventory.h"
#include "ship/Ship.h"
#include "system/Container.h"
#include "system/DestinyManager.h"
#include "system/SystemManager.h"

namespace {
    // tech 2 salvaged materials (Telemetry Processor .. Enhanced Ward Console), the ones tech 2 rigs need
    const uint32 T2_SALVAGE_FIRST = 25607;
    const uint32 T2_SALVAGE_LAST  = 25625;
}

uint32 WreckSalvage::Salvage(SystemEntity* pTarget, ShipItemRef shipRef, Client* pClient, EVEItemFlags holdFlag, bool& overloaded)
{
    WreckSE* pWreck(pTarget->GetWreckSE());
    uint32 dropped(0);
    overloaded = false;
    std::vector<uint32> list;
    sDataMgr.GetSalvage(atoi(pTarget->GetSelf()->customInfo().c_str()), list);
    // home server (rates.T2SalvageChance):  any NPC wreck may also give one tech 2 material
    if (!list.empty() and (sConfig.rates.T2SalvageChance > 0.0f) and (MakeRandomFloat() < sConfig.rates.T2SalvageChance))
        list.push_back(T2_SALVAGE_FIRST + static_cast<uint32>(MakeRandomInt(0, T2_SALVAGE_LAST - T2_SALVAGE_FIRST)));
    if (!list.empty()) {
        uint8 drop = 1;
        switch (pTarget->GetSelf()->GetAttribute(AttrAccessDifficulty).get_int()) {       // drop qty * rate in config
            case  30: drop = 1; break;  //  1 to 3
            case  20: drop = 2; break;  //  2 to 6
            case  10: drop = 3; break;  //  3 to 9
            case   0: drop = 4; break;  //  4 to 12
            case -10: drop = 5; break;  //  5 to 15
            case -20: drop = 6; break;  //  6 to 18
        }

        InventoryItemRef iRef(nullptr);
        Inventory* sInv(shipRef->GetMyInventory());
        uint32 quantity = 0, minDrop = drop, maxDrop = (drop * sConfig.rates.DropSalvage);
        for (auto cur : list) {
            // each drop has 50/50 chance.  may need to change this later.   base on char's salvage skill?
            if (IsEven(MakeRandomInt(0,10)))
                continue;
            quantity = (MakeRandomInt(minDrop, maxDrop));
            if (quantity < 1)
                quantity = 1;
            ItemData iLoot(cur, pClient->GetCharacterID(), locTemp, flagNone, quantity);
            iRef = sItemFactory.SpawnItem(iLoot);
            if (iRef.get() == nullptr) // we'll get over it...continue
                continue;
            if (sInv->HasAvailableSpace(holdFlag, iRef)) {
                iRef->MergeTypesInCargo(shipRef.get(), holdFlag);
                ++dropped;
                _log(MODULE__DEBUG, "Prospector::OnSalvageSuccess - dropped %u %s of %u/%u", quantity, iRef->name(), minDrop, maxDrop);
            } else {
                _log(MODULE__DEBUG, "Prospector::OnSalvageSuccess - %s's %s is full.", shipRef->name(), sDataMgr.GetFlagName(holdFlag));
                // what doesn't fit is destroyed in the process
                iRef->Delete();
                overloaded = true;
                break;
            }
        }
    }

    if (!pTarget->GetSelf()->GetMyInventory()->IsEmpty()) {
        // tell wreck it's being salvaged, so do not broadcast slim updates...may no longer need this.  jetcan set to initial location 0
        pWreck->Salvaged();

        std::map<uint32, InventoryItemRef> shipLoot;
        shipLoot.clear();
        pTarget->GetSelf()->GetMyInventory()->GetInventoryMap(shipLoot);

        // create new container
        ItemData p_idata(23,   // 23 = cargo container
                        pTarget->GetSelf()->ownerID(),
                        locTemp,
                        flagNone,
                        "Jettisoned Loot Container",
                        pTarget->GetPosition());

        CargoContainerRef jetCanRef = sItemFactory.SpawnCargoContainer(p_idata);
        if (jetCanRef.get() != nullptr) {
            for (auto cur : shipLoot)
                cur.second->Move(jetCanRef->itemID(),flagNone);
            FactionData data = FactionData();
                data.allianceID = pTarget->GetAllianceID();
                data.corporationID = pTarget->GetCorporationID();
                data.factionID = pTarget->GetWarFactionID();
                data.ownerID = pTarget->GetSelf()->ownerID();
            ContainerSE* cSE = new ContainerSE(jetCanRef, pTarget->GetServices(), pTarget->SystemMgr(), data);
            jetCanRef->SetMySE(cSE);
            pTarget->SystemMgr()->AddEntity(cSE);
            pTarget->DestinyMgr()->SendJettisonPacket();
        }
    }


    return dropped;
}

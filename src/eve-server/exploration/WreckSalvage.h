/**
 * WreckSalvage.h
 *      what a wreck gives when it is salvaged — shared by the salvager module (Prospector) and salvage drones (DroneAI)
 */

#ifndef EVEMU_EXPLORATION_WRECKSALVAGE_H_
#define EVEMU_EXPLORATION_WRECKSALVAGE_H_

#include "inventory/ItemRef.h"
#include "../eve-common/EVE_Flags.h"

class Client;
class SystemEntity;

namespace WreckSalvage {
    /* rolls the wreck's salvage into the ship's hold (plus, with rates.T2SalvageChance, one tech 2 material) and spills
     *  whatever the wreck still held into a jetcan.  the caller marks the wreck done and deletes it.
     *  returns how many stacks dropped;  overloaded is set when the hold filled up and the rest was lost
     */
    uint32 Salvage(SystemEntity* pTarget, ShipItemRef shipRef, Client* pClient, EVEItemFlags holdFlag, bool& overloaded);
}

#endif  // EVEMU_EXPLORATION_WRECKSALVAGE_H_

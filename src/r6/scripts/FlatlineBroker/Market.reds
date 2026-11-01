// Flatline Broker: who buys flatlines.
//
// Shards are junk-typed records so they behave like loot, but they are not
// junk: only BD dealers (Config.IsBDDealer) take them, and they never ride
// along with the sell-all-junk or disassemble-junk buttons.

module FlatlineBroker

// The per-item check behind the vendor sell list and the sell action.
@wrapMethod(Vendor)
public final const func PlayerCanSell(itemID: ItemID, allowQuestItems: Bool, excludeEquipped: Bool) -> Bool {
  if FlatlineBroker_HasShardTag(itemID) && !Config.IsBDDealer(this.GetVendorTweakID()) {
    return false;
  }
  return wrappedMethod(itemID, allowQuestItems, excludeEquipped);
}

// The bulk list the vendor screen builds its sell tab from; it filters by tag
// only and never asks PlayerCanSell.
@wrapMethod(VendorDataManager)
public final func GetItemsPlayerCanSellFast(player: wref<GameObject>, opt excludeEquipped: Bool) -> [wref<gameItemData>] {
  let items: array<wref<gameItemData>> = wrappedMethod(player, excludeEquipped);
  let record: wref<Vendor_Record> = this.GetVendorRecord();
  if IsDefined(record) && Config.IsBDDealer(record.GetID()) {
    return items;
  }
  let i: Int32 = ArraySize(items) - 1;
  while i >= 0 {
    if IsDefined(items[i]) && items[i].HasTag(Config.ShardTag()) {
      ArrayErase(items, i);
    }
    i -= 1;
  }
  return items;
}

// Sell-all-junk at a vendor: shards always sell one by one, by hand.
@wrapMethod(FullscreenVendorGameController)
private final func GetSellableJunk() -> [wref<gameItemData>] {
  let items: array<wref<gameItemData>> = wrappedMethod();
  let i: Int32 = ArraySize(items) - 1;
  while i >= 0 {
    if IsDefined(items[i]) && items[i].HasTag(Config.ShardTag()) {
      ArrayErase(items, i);
    }
    i -= 1;
  }
  return items;
}

// Disassemble-junk in the backpack builds its list from IsJunk().
@wrapMethod(UIInventoryItem)
public final func IsJunk() -> Bool {
  if FlatlineBroker_HasShardTag(this.GetID()) {
    return false;
  }
  return wrappedMethod();
}

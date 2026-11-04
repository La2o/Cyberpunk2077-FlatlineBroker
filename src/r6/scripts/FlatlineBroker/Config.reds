// Flatline Broker: shared constants and record lookups.
//
// Every TweakDBID literal here must match a record in r6/tweaks/FlatlineBroker.
// A TweakDBID literal is a compile-time hash, so a typo compiles cleanly and
// silently never matches.

module FlatlineBroker

public enum FlatlineKind {
  Street = 0,
  Ghost = 1,
  Snuff = 2,
  Corpo = 3,
  Psycho = 4
}

public abstract class Config {

  // Seconds between NCPD proximity checks while the player carries shards.
  public static func PatrolInterval() -> Float = 15.0

  // An officer has to be this close (meters) to notice the shards.
  public static func PatrolRadius() -> Float = 10.0

  // Chance per check that a nearby officer flags the player: a base chance
  // plus a share per carried shard, capped.
  public static func ScanChanceBase() -> Float = 0.05
  public static func ScanChancePerShard() -> Float = 0.03
  public static func ScanChanceMax() -> Float = 0.35

  // After a scan bust, NCPD leaves the player alone for this long (seconds).
  public static func ScanCooldown() -> Float = 180.0

  // Civilians and crowd NPCs are not recorded. Flatlines of nobodies do not
  // sell, and it keeps the scroller from turning into a crowd-farming tool.
  public static func RecordCivilians() -> Bool = false

  public static func ScrollerID() -> TweakDBID = t"Items.FlatlineBroker_BDScroller"

  public static func ShardTag() -> CName = n"FlatlineShard"

  public static func ShardID(kind: FlatlineKind, grade: Int32) -> TweakDBID {
    let g: Int32 = Clamp(grade, 1, 3);
    switch kind {
      case FlatlineKind.Psycho:
        return g == 3 ? t"Items.FlatlineBroker_Shard_Psycho_3" : (g == 2 ? t"Items.FlatlineBroker_Shard_Psycho_2" : t"Items.FlatlineBroker_Shard_Psycho_1");
      case FlatlineKind.Corpo:
        return g == 3 ? t"Items.FlatlineBroker_Shard_Corpo_3" : (g == 2 ? t"Items.FlatlineBroker_Shard_Corpo_2" : t"Items.FlatlineBroker_Shard_Corpo_1");
      case FlatlineKind.Snuff:
        return g == 3 ? t"Items.FlatlineBroker_Shard_Snuff_3" : (g == 2 ? t"Items.FlatlineBroker_Shard_Snuff_2" : t"Items.FlatlineBroker_Shard_Snuff_1");
      case FlatlineKind.Ghost:
        return g == 3 ? t"Items.FlatlineBroker_Shard_Ghost_3" : (g == 2 ? t"Items.FlatlineBroker_Shard_Ghost_2" : t"Items.FlatlineBroker_Shard_Ghost_1");
    }
    return g == 3 ? t"Items.FlatlineBroker_Shard_Street_3" : (g == 2 ? t"Items.FlatlineBroker_Shard_Street_2" : t"Items.FlatlineBroker_Shard_Street_1");
  }

  public static func KindKey(kind: FlatlineKind) -> String {
    switch kind {
      case FlatlineKind.Psycho: return "Psycho";
      case FlatlineKind.Corpo: return "Corpo";
      case FlatlineKind.Snuff: return "Snuff";
      case FlatlineKind.Ghost: return "Ghost";
    }
    return "Street";
  }

  // Who deals in black-market braindances. Only they buy flatlines:
  // the fences: every vendor the map shows as a Junk Vendor (vendor type Junk
  // or TechJunk), across Watson, Westbrook, Heywood, the Badlands and Dogtown.
  // Matching on type rather than a list of IDs keeps them easy to find, and
  // picks up junk shops added by the game or other mods.
  //
  // 1.0 used a hand-picked ID list instead. Half of it turned out to be
  // skill-trainer or food vendors, some never placed in the world, and players
  // could not tell which junk shops were dealers.
  public static func IsBDDealer(vendorID: TweakDBID) -> Bool {
    // Junk-typed records that are not shops a player walks up to.
    if vendorID == t"Vendors.IceMachine"
      || vendorID == t"Vendors.q303_casino_cashier_EP1"
      || vendorID == t"Vendors.mq303_shank" {
      return false;
    }
    let record: ref<Vendor_Record> = TweakDBInterface.GetVendorRecord(vendorID);
    if !IsDefined(record) || !IsDefined(record.VendorType()) {
      return false;
    }
    let vendorType: gamedataVendorType = record.VendorType().Type();
    return Equals(vendorType, gamedataVendorType.Junk) || Equals(vendorType, gamedataVendorType.TechJunk);
  }

  public static func IsCorpo(affiliation: gamedataAffiliation) -> Bool {
    switch affiliation {
      case gamedataAffiliation.Arasaka:
      case gamedataAffiliation.Militech:
      case gamedataAffiliation.KangTao:
      case gamedataAffiliation.Biotechnica:
      case gamedataAffiliation.Zetatech:
      case gamedataAffiliation.UnaffiliatedCorpo:
      case gamedataAffiliation.NetWatch:
      case gamedataAffiliation.SSI:
        return true;
    }
    return false;
  }
}

public static func FlatlineBroker_HasShardTag(itemID: ItemID) -> Bool {
  let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
  return IsDefined(record) && record.TagsContains(Config.ShardTag());
}

public static func FlatlineBroker_Notify(game: GameInstance, text: String) -> Void {
  let msg: SimpleScreenMessage;
  msg.isShown = true;
  msg.duration = 4.0;
  msg.message = text;
  GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().UI_Notifications)
    .SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
}

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

  // Vendors who deal in black-market braindances. Only they buy flatlines:
  // netrunner dens and fences in Kabuki, Jig-Jig Street, Japantown, Little
  // China, Heywood and Dogtown.
  public static func IsBDDealer(vendorID: TweakDBID) -> Bool {
    return vendorID == t"Vendors.wat_kab_netrunner_01"
      || vendorID == t"Vendors.wat_kab_junkshop_01"
      || vendorID == t"Vendors.wat_lch_netrunner_01"
      || vendorID == t"Vendors.wbr_jpn_netrunner_01"
      || vendorID == t"Vendors.wbr_jpn_netrunner_02"
      || vendorID == t"Vendors.wbr_jpn_junkshop_01"
      || vendorID == t"Vendors.wbr_jpn_junkshop_02"
      || vendorID == t"Vendors.wbr_jpn_junkshop_03"
      || vendorID == t"Vendors.wbr_jpn_jig_bar_01"
      || vendorID == t"Vendors.hey_rey_netrunner_01"
      || vendorID == t"Vendors.hey_rey_junkshop_01"
      || vendorID == t"Vendors.cz_con_netrunner_01"
      || vendorID == t"Vendors.cz_con_junkshop_01"
      || vendorID == t"Vendors.cz_stadium_netrunner_01";
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

// Flatline Broker: records the player's kills as flatline braindance shards.
//
// Hooked at NPCPuppet.OnDeath. The last hit event is still held by the puppet
// at that point, so the hit flags and attack type of the killing blow are
// readable. The player's combat flag is read before the death is processed:
// a victim who dies while V is out of combat never saw it coming.

module FlatlineBroker

@addField(NPCPuppet)
private let m_flatlineRecorded: Bool;

@addMethod(NPCPuppet)
public final func FlatlineBroker_LastHitHas(flag: hitFlag) -> Bool {
  return this.HasLastHitFlag(flag);
}

@addMethod(NPCPuppet)
public final func FlatlineBroker_LastHitType() -> gamedataAttackType {
  return this.GetLastHitAttackType();
}

@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  let byPlayer: Bool = false;
  let playerInCombat: Bool = false;
  if IsDefined(player) && !this.m_flatlineRecorded {
    byPlayer = (IsDefined(evt.instigator) && evt.instigator.IsPlayer())
      || (IsDefined(this.GetLastHitInstigator()) && this.GetLastHitInstigator().IsPlayer());
    playerInCombat = player.IsInCombat();
  }
  let result: Bool = wrappedMethod(evt);
  if byPlayer {
    this.m_flatlineRecorded = true;
    Recorder.Record(this, player, playerInCombat);
  }
  return result;
}

public abstract class Recorder {

  public static func Record(npc: ref<NPCPuppet>, player: ref<PlayerPuppet>, playerInCombat: Bool) -> Void {
    if !Recorder.HasScroller(player) || !Recorder.IsRecordable(npc) {
      return;
    }
    let kind: FlatlineKind = Recorder.Classify(npc, playerInCombat);
    let grade: Int32 = Recorder.Grade(npc);
    let game: GameInstance = player.GetGame();
    GameInstance.GetTransactionSystem(game).GiveItemByTDBID(player, Config.ShardID(kind, grade), 1);
    FlatlineBroker_Notify(game, Loc.Format(game, "flatline_msg_recorded", Loc.Get(game, "flatline_kind_" + Config.KindKey(kind)), IntToString(grade)));
  }

  public static func HasScroller(player: ref<PlayerPuppet>) -> Bool {
    let data: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(player);
    if !IsDefined(data) {
      return false;
    }
    let area: gamedataEquipmentArea = gamedataEquipmentArea.FrontalCortexCW;
    let count: Int32 = data.GetNumberOfSlots(area, false);
    let i: Int32 = 0;
    while i < count {
      if ItemID.GetTDBID(data.GetItemInEquipSlot(area, i)) == Config.ScrollerID() {
        return true;
      }
      i += 1;
    }
    return false;
  }

  // Humans only: drones, mechs and androids have no sensorium to record.
  public static func IsRecordable(npc: ref<NPCPuppet>) -> Bool {
    if NotEquals(npc.GetNPCType(), gamedataNPCType.Human) {
      return false;
    }
    if !Config.RecordCivilians() && (npc.IsCrowd() || npc.IsCharacterCivilian()) {
      return false;
    }
    return true;
  }

  // Most valuable kind wins: a stealth kill on an Arasaka guard sells as corpo.
  public static func Classify(npc: ref<NPCPuppet>, playerInCombat: Bool) -> FlatlineKind {
    if npc.IsCharacterCyberpsycho() {
      return FlatlineKind.Psycho;
    }
    let record: ref<Character_Record> = npc.GetRecord();
    if IsDefined(record) && IsDefined(record.Affiliation()) && Config.IsCorpo(record.Affiliation().Type()) {
      return FlatlineKind.Corpo;
    }
    if !playerInCombat || npc.FlatlineBroker_LastHitHas(hitFlag.StealthHit) || npc.FlatlineBroker_LastHitHas(hitFlag.SilentKillModifier) {
      return FlatlineKind.Ghost;
    }
    if npc.FlatlineBroker_LastHitHas(hitFlag.Headshot)
      || npc.FlatlineBroker_LastHitHas(hitFlag.FinisherTriggered)
      || npc.FlatlineBroker_LastHitHas(hitFlag.ForceDismember)
      || Equals(npc.FlatlineBroker_LastHitType(), gamedataAttackType.Explosion) {
      return FlatlineKind.Snuff;
    }
    return FlatlineKind.Street;
  }

  public static func Grade(npc: ref<NPCPuppet>) -> Int32 {
    switch npc.GetNPCRarity() {
      case gamedataNPCRarity.Boss:
      case gamedataNPCRarity.MaxTac:
        return 3;
      case gamedataNPCRarity.Rare:
      case gamedataNPCRarity.Officer:
      case gamedataNPCRarity.Elite:
        return 2;
    }
    return 1;
  }
}

// Flatline Broker: NCPD heat for carrying flatlines.
//
// Two ways to get caught:
//
//   Patrol scan  While the player carries shards and is not wanted, every
//                PatrolInterval seconds a police officer within PatrolRadius
//                may scan them. The chance grows with the number of shards.
//                A bust sets one star.
//
//   Manifest     When the player becomes wanted for any other reason while
//                carrying shards, NCPD pulls their shard manifest and adds one
//                more star, once per wanted episode.
//
// Heat is raised through PreventionSystem.ChangeHeatStage, the same call the
// game's own heat pipeline ends in, and only when CanPreventionReactToInput()
// says the system is live: quest scenes and police-locked areas are left alone.

module FlatlineBroker

public class FlatlineHeatSystem extends ScriptableSystem {

  private let m_patrolDelay: DelayID;
  private let m_lastBustTime: Float;
  private let m_manifestPulled: Bool;

  public static func Get(game: GameInstance) -> ref<FlatlineHeatSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"FlatlineBroker.FlatlineHeatSystem") as FlatlineHeatSystem;
  }

  private func OnAttach() -> Void {
    this.m_lastBustTime = -1000.0;
  }

  public func Start() -> Void {
    this.Schedule();
  }

  private func Schedule() -> Void {
    let game: GameInstance = this.GetGameInstance();
    let delays: ref<DelaySystem> = GameInstance.GetDelaySystem(game);
    if this.m_patrolDelay != GetInvalidDelayID() {
      delays.CancelCallback(this.m_patrolDelay);
    }
    let callback: ref<FlatlinePatrolCallback> = new FlatlinePatrolCallback();
    callback.m_system = this;
    this.m_patrolDelay = delays.DelayCallback(callback, Config.PatrolInterval(), false);
  }

  public func OnPatrolTick() -> Void {
    this.m_patrolDelay = GetInvalidDelayID();
    this.PatrolCheck();
    this.Schedule();
  }

  private func Now() -> Float {
    return EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance()));
  }

  public static func ShardCount(player: ref<PlayerPuppet>) -> Int32 {
    return GameInstance.GetTransactionSystem(player.GetGame()).GetItemQuantityByTag(player, Config.ShardTag());
  }

  private func PatrolCheck() -> Void {
    let game: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(game);
    if !IsDefined(player) || player.IsDead() {
      return;
    }
    let shards: Int32 = FlatlineHeatSystem.ShardCount(player);
    if shards <= 0 {
      return;
    }
    let prevention: ref<PreventionSystem> = GameInstance.GetScriptableSystemsContainer(game).Get(n"PreventionSystem") as PreventionSystem;
    if !IsDefined(prevention) || !prevention.CanPreventionReactToInput() || NotEquals(prevention.GetHeatStage(), EPreventionHeatStage.Heat_0) {
      return;
    }
    if this.Now() - this.m_lastBustTime < Config.ScanCooldown() {
      return;
    }
    if !FlatlineHeatSystem.OfficerNearby(player) {
      return;
    }
    let chance: Float = MinF(Config.ScanChanceBase() + Config.ScanChancePerShard() * Cast<Float>(shards), Config.ScanChanceMax());
    if RandF() >= chance {
      return;
    }
    this.m_lastBustTime = this.Now();
    this.m_manifestPulled = true;
    prevention.FlatlineBroker_RaiseHeat(EPreventionHeatStage.Heat_1);
    FlatlineBroker_Notify(game, Loc.Get(game, "flatline_msg_scanned"));
  }

  public static func OfficerNearby(player: ref<PlayerPuppet>) -> Bool {
    let query: TargetSearchQuery;
    let targets: array<TS_TargetPartInfo>;
    query.testedSet = TargetingSet.Complete;
    query.searchFilter = TSF_NPC();
    query.includeSecondaryTargets = false;
    query.maxDistance = Config.PatrolRadius();
    query.filterObjectByDistance = true;
    GameInstance.GetTargetingSystem(player.GetGame()).GetTargetParts(player, query, targets);
    let i: Int32 = 0;
    while i < ArraySize(targets) {
      let puppet: ref<ScriptedPuppet> = TS_TargetPartInfo.GetComponent(targets[i]).GetEntity() as ScriptedPuppet;
      if IsDefined(puppet) && puppet.IsPrevention() && ScriptedPuppet.IsActive(puppet) {
        return true;
      }
      i += 1;
    }
    return false;
  }

  // Called from the PreventionSystem wrapper after every heat change.
  public func OnHeatChanged(previous: EPreventionHeatStage, current: EPreventionHeatStage) -> Void {
    if Equals(current, EPreventionHeatStage.Heat_0) {
      this.m_manifestPulled = false;
      return;
    }
    if this.m_manifestPulled || NotEquals(previous, EPreventionHeatStage.Heat_0) {
      return;
    }
    let game: GameInstance = this.GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(game);
    if !IsDefined(player) || FlatlineHeatSystem.ShardCount(player) <= 0 {
      return;
    }
    this.m_manifestPulled = true;
    // Deferred: the wrapper runs inside ChangeHeatStage and must not re-enter it.
    let callback: ref<FlatlineManifestCallback> = new FlatlineManifestCallback();
    callback.m_system = this;
    GameInstance.GetDelaySystem(game).DelayCallback(callback, 2.0, false);
  }

  public func OnManifestPulled() -> Void {
    let game: GameInstance = this.GetGameInstance();
    let prevention: ref<PreventionSystem> = GameInstance.GetScriptableSystemsContainer(game).Get(n"PreventionSystem") as PreventionSystem;
    if !IsDefined(prevention) || !prevention.CanPreventionReactToInput() {
      return;
    }
    let heat: Int32 = EnumInt(prevention.GetHeatStage());
    if heat <= 0 || heat >= 5 {
      return;
    }
    prevention.FlatlineBroker_RaiseHeat(IntToEPreventionHeatStage(heat + 1));
    FlatlineBroker_Notify(game, Loc.Get(game, "flatline_msg_manifest"));
  }
}

public class FlatlinePatrolCallback extends DelayCallback {
  public let m_system: wref<FlatlineHeatSystem>;

  public func Call() -> Void {
    if IsDefined(this.m_system) {
      this.m_system.OnPatrolTick();
    }
  }
}

public class FlatlineManifestCallback extends DelayCallback {
  public let m_system: wref<FlatlineHeatSystem>;

  public func Call() -> Void {
    if IsDefined(this.m_system) {
      this.m_system.OnManifestPulled();
    }
  }
}

@addMethod(PreventionSystem)
public final func FlatlineBroker_RaiseHeat(stage: EPreventionHeatStage) -> Void {
  if EnumInt(stage) > EnumInt(this.m_heatStage) {
    this.ChangeHeatStage(stage, "FlatlineBroker");
  }
}

@wrapMethod(PreventionSystem)
private final func OnHeatChanged(previousHeat: EPreventionHeatStage) -> Void {
  wrappedMethod(previousHeat);
  let heat: ref<FlatlineHeatSystem> = FlatlineHeatSystem.Get(this.GetGameInstance());
  if IsDefined(heat) {
    heat.OnHeatChanged(previousHeat, this.m_heatStage);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  if !this.IsReplacer() {
    let heat: ref<FlatlineHeatSystem> = FlatlineHeatSystem.Get(this.GetGame());
    if IsDefined(heat) {
      heat.Start();
    }
  }
  return result;
}

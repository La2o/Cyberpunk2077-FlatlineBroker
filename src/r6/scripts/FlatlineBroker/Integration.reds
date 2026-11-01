// Flatline Broker: optional integration with other mods.
//
// Everything here compiles only when the other mod is installed, so Flatline
// Broker has no hard dependency on any of them.
//
// Wannabe Edgerunner drains humanity per kill and per cyberware use, but never
// for installed chrome, so the BD Scroller itself is invisible to it. Recording
// a flatline means scrolling through the victim's death, so each recorded shard
// costs extra humanity on top of WE's own kill cost: one point per grade.
//
// Dark Future needs nothing here: it scales humanity loss by allocated
// cyberware capacity, which already counts the Scroller.

module FlatlineBroker

@if(ModuleExists("Edgerunning.System"))
import Edgerunning.System.*

public abstract class Integration {

  public static func HumanityPerGrade() -> Float = 1.0

  public static func OnFlatlineRecorded(player: ref<PlayerPuppet>, grade: Int32) -> Void {
    Integration.ChargeEdgerunnerHumanity(player, Cast<Float>(grade) * Integration.HumanityPerGrade());
  }

  @if(ModuleExists("Edgerunning.System"))
  private static func ChargeEdgerunnerHumanity(player: ref<PlayerPuppet>, cost: Float) -> Void {
    let edgerunning: ref<EdgerunningSystem> = EdgerunningSystem.GetInstance(player.GetGame());
    if IsDefined(edgerunning) {
      edgerunning.AddHumanityDamage(cost);
    }
  }

  @if(!ModuleExists("Edgerunning.System"))
  private static func ChargeEdgerunnerHumanity(player: ref<PlayerPuppet>, cost: Float) -> Void {}
}

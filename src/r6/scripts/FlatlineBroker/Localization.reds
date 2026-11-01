// Flatline Broker: display strings, served through Codeware's localization
// provider. TweakDB records reference these keys as LocKey#<key>.

module FlatlineBroker

import Codeware.Localization.*

public class FlatlineLocalization extends ModLocalizationProvider {

  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    return new FlatlineEnglishText();
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

public class FlatlineEnglishText extends ModLocalizationPackage {

  protected func DefineTexts() {
    this.Text("flatline_scroller_name", "Zetatech BD Scroller");
    this.Text("flatline_scroller_desc",
      "Grey-market recording rig spliced into the frontal cortex. Scrolls a full-sensory braindance of every kill you make "
      + "and cuts it to a shard: a flatline. BD dealers pay well for them. NCPD does not ask questions before it shoots.");

    this.Text("flatline_shard_Street_1_name", "Flatline: Street Hit");
    this.Text("flatline_shard_Street_2_name", "Flatline: Street Hit (Lieutenant)");
    this.Text("flatline_shard_Street_3_name", "Flatline: Street Hit (Kingpin)");
    this.Text("flatline_shard_Ghost_1_name", "Flatline: Ghost");
    this.Text("flatline_shard_Ghost_2_name", "Flatline: Ghost (Lieutenant)");
    this.Text("flatline_shard_Ghost_3_name", "Flatline: Ghost (Kingpin)");
    this.Text("flatline_shard_Snuff_1_name", "Flatline: Snuff Reel");
    this.Text("flatline_shard_Snuff_2_name", "Flatline: Snuff Reel (Lieutenant)");
    this.Text("flatline_shard_Snuff_3_name", "Flatline: Snuff Reel (Kingpin)");
    this.Text("flatline_shard_Corpo_1_name", "Flatline: Corpo Exit");
    this.Text("flatline_shard_Corpo_2_name", "Flatline: Corpo Exit (Executive)");
    this.Text("flatline_shard_Corpo_3_name", "Flatline: Corpo Exit (Board Level)");
    this.Text("flatline_shard_Psycho_1_name", "Flatline: Psycho Takedown");
    this.Text("flatline_shard_Psycho_2_name", "Flatline: Psycho Takedown (Full Chrome)");
    this.Text("flatline_shard_Psycho_3_name", "Flatline: Psycho Takedown (Legend)");

    this.Text("flatline_shard_Street_desc",
      "A black-market braindance of a street killing, recorded from the killer's side. Common stock, steady sales. "
      + "Only BD dealers will touch it. Carrying it past NCPD is a felony.");
    this.Text("flatline_shard_Ghost_desc",
      "The mark never saw it coming. Collectors pay a premium for the quiet, intimate ones. "
      + "Only BD dealers will touch it. Carrying it past NCPD is a felony.");
    this.Text("flatline_shard_Snuff_desc",
      "Headshot, blade or blast: a death with a show. Snuff connoisseurs love the spectacle. "
      + "Only BD dealers will touch it. Carrying it past NCPD is a felony.");
    this.Text("flatline_shard_Corpo_desc",
      "A corporate employee's last moments. Rival corps, blackmailers and thrill-seeking suits all want one. "
      + "Only BD dealers will touch it. Carrying it past NCPD is a felony.");
    this.Text("flatline_shard_Psycho_desc",
      "Recorded inside a cyberpsycho fight. Raw, chaotic and rare: the most sought-after flatline on the market. "
      + "Only BD dealers will touch it. Carrying it past NCPD is a felony.");

    this.Text("flatline_kind_Street", "Street Hit");
    this.Text("flatline_kind_Ghost", "Ghost");
    this.Text("flatline_kind_Snuff", "Snuff Reel");
    this.Text("flatline_kind_Corpo", "Corpo Exit");
    this.Text("flatline_kind_Psycho", "Psycho Takedown");

    this.Text("flatline_msg_recorded", "FLATLINE RECORDED // {0} // grade {1}");
    this.Text("flatline_msg_scanned", "NCPD scanned your flatline shards. You're wanted.");
    this.Text("flatline_msg_manifest", "NCPD pulled your shard manifest. Heat rising.");
  }
}

public abstract class Loc {

  public static func Get(game: GameInstance, key: String) -> String {
    let system: ref<LocalizationSystem> = LocalizationSystem.GetInstance(game);
    if !IsDefined(system) {
      return key;
    }
    let text: String = system.GetText(key);
    return StrLen(text) > 0 ? text : key;
  }

  public static func Format(game: GameInstance, key: String, a: String, b: String) -> String {
    let text: String = Loc.Get(game, key);
    text = StrReplace(text, "{0}", a);
    text = StrReplace(text, "{1}", b);
    return text;
  }
}

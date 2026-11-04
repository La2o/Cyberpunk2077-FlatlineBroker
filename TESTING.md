# Test log

Game 2.5 (Steam build 26161058), redscript 0.5.32, RED4ext 1.31.0, TweakXL 1.12.0,
Codeware 1.21.2, CET 1.38.1. The harness is `tools/cet/flatline_test` plus
`tools/run-ingame-test.ps1`. It auto-loads the last save, spawns and kills test
NPCs, and writes PASS/FAIL lines. It is dev-only: remove it from the game after
testing. Saves are backed up before every run.

## 1.1.1 (2026-11-04)

Report on Nexus: flatlines could not be sold anywhere players looked.

- Cause, confirmed with `tools/cet/flatline_probe`, which dumps every vendor
  record. 1.0's dealer list had 14 IDs. 7 were skill-trainer vendors and 1 a
  food vendor. 3 of them have no name, so they are probably not placed in the
  world. Only 6 were junk shops, and nothing told players which ones.
- Fix: every vendor of type Junk or TechJunk is a dealer, apart from the hotel
  ice machine, a casino cashier and a quest-only vendor.
- Harness: 33/33 pass. That covers 6 junk shops that buy, 5 non-dealers that
  refuse (including Edge Net, a netrunner from the old list), junk still
  selling, and the kill, patrol and manifest checks.
- Real sale through the vendor screen at the Badlands junk shop
  (`Vendors.bls_ina_se1_junkshop_01`, not on the 1.0 list). A Psycho
  Takedown (Legend) shard sold for €$9,000. V's money went up by €$9,000, the
  vendor's went from €$20,000 to €$11,000, and the shard appeared under Buy Back.
- Saves: only AutoSave-11, AutoSave-12 and user.gls changed (autosave
  rotation). The backup is in `GameSaveBackups\Cyberpunk2077\2026-11-04_165248-before-dealer-fix-test`.

Not tested: refusal through the vendor screen at a non-dealer (only through
`PlayerCanSell`); the sell-all-junk button skipping shards (code only);
Wannabe Edgerunner with WE installed; Snuff Reel (needs real weapon hits).

## 1.1.0 (2026-11-01)

Compiles with and without Wannabe Edgerunner. Decompiling confirmed each build
picked the right version of the integration function. Harness: 28/28.

## 1.0.0 (2026-11-01)

Harness: 28/28. Shards seen in the backpack (screenshot from the user).

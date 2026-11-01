-- Flatline Broker end-to-end test (developer tool, not shipped).
-- Runs automatically once a save is loaded and writes flatline_test.log next to
-- this file. Steps run on a timer so spawns and heat changes have time to land.

local log = io.open("flatline_test.log", "w")
local function out(s) log:write(s .. "\n"); log:flush(); print("[FlatlineTest] " .. s) end
local function check(name, ok, detail) out((ok and "PASS " or "FAIL ") .. name .. (detail and ("  -- " .. detail) or "")) end

local SCROLLER = "Items.FlatlineBroker_BDScroller"
local KINDS = { "Street", "Ghost", "Snuff", "Corpo", "Psycho" }

local function shardCounts(player)
  local ts = Game.GetTransactionSystem()
  local c = {}
  for _, k in ipairs(KINDS) do
    for g = 1, 3 do
      local id = "Items.FlatlineBroker_Shard_" .. k .. "_" .. g
      local n = ts:GetItemQuantity(player, ItemID.FromTDBID(TweakDBID.new(id)))
      if n > 0 then c[id] = n end
    end
  end
  return c
end

local function diff(before, after)
  for id, n in pairs(after) do
    if (before[id] or 0) < n then return id end
  end
  return nil
end

local function gains(before, after)
  local list = {}
  for id, n in pairs(after) do
    if (before[id] or 0) < n then table.insert(list, id .. " +" .. (n - (before[id] or 0))) end
  end
  return list
end

local function spawnAhead(record, tag, dist)
  local player = Game.GetPlayer()
  local pos = player:GetWorldPosition()
  local fwd = player:GetWorldForward()
  local spec = DynamicEntitySpec.new()
  spec.recordID = TweakDBID.new(record)
  spec.position = Vector4.new(pos.x + fwd.x * dist, pos.y + fwd.y * dist, pos.z, 1)
  spec.orientation = EulerAngles.ToQuat(EulerAngles.new(0, 0, player:GetWorldYaw() + 180))
  spec.alwaysSpawned = true
  spec.tags = { CName.new(tag) }
  return Game.GetDynamicEntitySystem():CreateEntity(spec)
end

local function heatNow()
  return tonumber(EnumInt(Game.GetScriptableSystemsContainer():Get("PreventionSystem"):GetHeatStage()))
end

local function setSafe()
  local safe = PreventionConsoleInstructionRequest.new()
  safe.instruction = EPreventionSystemInstruction.Safe
  Game.GetScriptableSystemsContainer():Get("PreventionSystem"):QueueRequest(safe)
end

local function cleanSlate()
  local des = Game.GetDynamicEntitySystem()
  for _, tag in ipairs({ "FlatlineTestA", "FlatlineTestB", "FlatlineTestP", "FlatlineTestCop" }) do des:DeleteTagged(tag) end
  local safe = PreventionConsoleInstructionRequest.new()
  safe.instruction = EPreventionSystemInstruction.Safe
  Game.GetScriptableSystemsContainer():Get("PreventionSystem"):QueueRequest(safe)
end

local steps, t, idx, started, ctx = {}, 0, 1, false, {}
local function step(delay, fn) table.insert(steps, { delay = delay, fn = fn }) end

step(0, function()
  out("== Flatline Broker test, game time " .. tostring(Game.GetTimeSystem():GetGameTime()))
  check("scroller record exists", TweakDB:GetRecord(SCROLLER) ~= nil)
  local all = true
  for _, k in ipairs(KINDS) do for g = 1, 3 do
    if TweakDB:GetRecord("Items.FlatlineBroker_Shard_" .. k .. "_" .. g) == nil then all = false; out("  missing shard " .. k .. g) end
  end end
  check("15 shard records exist", all)
  local tags = TweakDB:GetFlat("Items.FlatlineBroker_Shard_Ghost_2.tags")
  local hasTag = false
  for _, tg in ipairs(tags or {}) do if Game.NameToString(tg) == "FlatlineShard" then hasTag = true end end
  check("shards carry FlatlineShard tag", hasTag)
  local function dumpTags(rec)
    local names = {}
    for _, tg in ipairs(TweakDB:GetFlat(rec .. ".tags") or {}) do table.insert(names, Game.NameToString(tg)) end
    local it = TweakDB:GetFlat(rec .. ".itemType")
    out("  " .. rec .. " tags=[" .. table.concat(names, ",") .. "] itemType=" .. tostring(it and TDBID.ToStringDEBUG(it)))
  end
  local okd, errd = pcall(function() dumpTags("Items.FlatlineBroker_Shard_Street_1"); dumpTags("Items.GenericJunkItem1") end)
  if not okd then out("  (tag dump failed: " .. tostring(errd) .. ")") end
  local stock = TweakDB:GetFlat("Vendors.wat_kab_ripperdoc_01.itemStock") or {}
  local inStock = false
  for _, rid in ipairs(stock) do
    local item = TweakDB:GetFlat(TweakDBID.new(rid, ".item"))
    if item and item == TweakDBID.new(SCROLLER) then inStock = true end
  end
  check("scroller stocked at Kabuki ripperdoc", inStock, #stock .. " stock entries")
  local loc = Game.GetScriptableSystemsContainer():Get("Codeware.Localization.LocalizationSystem")
  local nm = loc and loc:GetText("flatline_scroller_name") or ""
  check("Codeware localization serves item name", nm == "Zetatech BD Scroller", nm)
  local heat = Game.GetScriptableSystemsContainer():Get("FlatlineBroker.FlatlineHeatSystem")
  check("FlatlineHeatSystem instantiated", heat ~= nil)
end)

step(1, function()
  cleanSlate()
  local player = Game.GetPlayer()
  local id = ItemID.FromTDBID(TweakDBID.new(SCROLLER))
  Game.GetTransactionSystem():GiveItem(player, id, 1)
  local req = EquipRequest.new()
  req.owner = player
  req.itemID = id
  req.addToInventory = true
  Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):QueueRequest(req)
end)

step(3, function()
  local player = Game.GetPlayer()
  local data = EquipmentSystem.GetData(player)
  local found = false
  local n = data:GetNumberOfSlots(gamedataEquipmentArea.FrontalCortexCW, false)
  for i = 0, n - 1 do
    local it = data:GetItemInEquipSlot(gamedataEquipmentArea.FrontalCortexCW, i)
    if ItemID.GetTDBID(it) == TweakDBID.new(SCROLLER) then found = true end
  end
  check("scroller equipped in frontal cortex", found, n .. " cortex slots")
  -- One NPC at a time: a hostile in view would put V in combat and turn the
  -- next kill into a Street hit (by design), so the Ghost case goes first and
  -- spawns behind V.
  ctx.before = shardCounts(player)
  ctx.street = spawnAhead("Character.maelstrom_grunt1_ranged1_copperhead_ma", "FlatlineTestB", -15)
end)

step(3, function()
  local player = Game.GetPlayer()
  local b = Game.GetDynamicEntitySystem():GetEntity(ctx.street)
  check("test NPC spawned (Maelstrom)", b ~= nil)
  out("  V in combat before kill: " .. tostring(player:IsInCombat()))
  if b then b:Kill(player, false, false) end
  out("SHOT:10_ghost_flatline_recorded")
end)

step(2, function()
  local player = Game.GetPlayer()
  local after = shardCounts(player)
  local gained = gains(ctx.before, after)
  check("out-of-combat kill on Maelstrom records one Ghost shard", #gained == 1 and string.find(gained[1], "Ghost") ~= nil, table.concat(gained, ", "))
  ctx.before = after
  ctx.psycho = spawnAhead("Character.ma_cct_dtn_03_cyberpsycho", "FlatlineTestP", -20)
end)

step(3, function()
  local p = Game.GetDynamicEntitySystem():GetEntity(ctx.psycho)
  check("test NPC spawned (cyberpsycho)", p ~= nil and p:IsCharacterCyberpsycho())
  if p then p:Kill(Game.GetPlayer(), false, false) end
  out("SHOT:10b_psycho_flatline_recorded")
end)

step(2, function()
  local player = Game.GetPlayer()
  local after = shardCounts(player)
  local gained = gains(ctx.before, after)
  check("killing a cyberpsycho records one Psycho shard", #gained == 1 and string.find(gained[1], "Psycho") ~= nil, table.concat(gained, ", "))
  ctx.before = after
  ctx.arasaka = spawnAhead("Character.arasaka_agent_fshotgun2_tactician_ma_rare", "FlatlineTestA", 5)
end)

step(3, function()
  local a = Game.GetDynamicEntitySystem():GetEntity(ctx.arasaka)
  check("test NPC spawned (Arasaka)", a ~= nil)
  if a then a:Kill(Game.GetPlayer(), false, false) end
  out("SHOT:11_corpo_flatline_recorded")
end)

step(2, function()
  local player = Game.GetPlayer()
  local after = shardCounts(player)
  local gained = gains(ctx.before, after)
  check("killing Arasaka agent records one Corpo shard", #gained == 1 and string.find(gained[1], "Corpo") ~= nil, table.concat(gained, ", "))
  local n = Game.GetTransactionSystem():GetItemQuantityByTag(player, "FlatlineShard")
  check("shards counted by tag", n >= 2, tostring(n))

  -- Selling: only BD dealers take flatlines; ordinary junk sells anywhere.
  local shard = ItemID.FromTDBID(TweakDBID.new("Items.FlatlineBroker_Shard_Ghost_1"))
  local junk = ItemID.FromTDBID(TweakDBID.new("Items.GenericJunkItem1"))
  Game.GetTransactionSystem():GiveItem(player, junk, 1)
  -- Real vendor objects come from MarketSystem (created once the save has met
  -- the vendor); a bare Vendor.new() is tried as a fallback.
  local ms = Game.GetScriptableSystemsContainer():Get("MarketSystem")
  local function vendorFor(vendorID)
    local id = TweakDBID.new(vendorID)
    local ok, v = pcall(function() return ms:GetVendorByTDBID(id) end)
    if ok and v then return v, "market" end
    local nv = Vendor.new()
    -- CET fills GameInstance parameters itself, so Initialize is (vendorID, vendorObject).
    for _, args in ipairs({ { id, player }, { id } }) do
      if pcall(function() nv:Initialize(table.unpack(args)) end) and nv:GetVendorTweakID() == id then return nv, "new/" .. #args end
    end
    return nil, "unavailable"
  end
  local function canSell(vendorID, item)
    local v, how = vendorFor(vendorID)
    if not v then return nil, how end
    return v:PlayerCanSell(item, false, false), how
  end
  local ok, err = pcall(function()
    for _, vid in ipairs({ "Vendors.wat_kab_netrunner_01", "Vendors.wat_kab_junkshop_01", "Vendors.cz_con_junkshop_01" }) do
      local r, how = canSell(vid, shard)
      check("BD dealer " .. vid .. " buys flatlines", r == true, how)
    end
    for _, vid in ipairs({ "Vendors.wat_kab_gunsmith_01", "Vendors.wat_kab_medicstore_01", "Vendors.cz_con_ripdoc_01" }) do
      local r, how = canSell(vid, shard)
      check("non-dealer " .. vid .. " refuses flatlines", r == false, how)
    end
    local r, how = canSell("Vendors.wat_kab_junkshop_01", junk)
    check("dealer still buys ordinary junk", r == true, how)
  end)
  if not ok then out("ERROR in vendor checks: " .. tostring(err)) end

  -- Heat tests start from zero; shards are set aside for the control run.
  ctx.stash = shardCounts(player)
  local ts = Game.GetTransactionSystem()
  for id, n in pairs(ctx.stash) do ts:RemoveItem(player, ItemID.FromTDBID(TweakDBID.new(id)), n) end
  setSafe()
  ctx.cop = spawnAhead("Character.ncpd_constable_ranged1_lexington_ma", "FlatlineTestCop", 3)
end)

step(6, function()
  local cop = Game.GetDynamicEntitySystem():GetEntity(ctx.cop)
  check("test NCPD officer spawned", cop ~= nil and cop:IsPrevention())
  local player = Game.GetPlayer()
  local shards = tonumber(Game.GetTransactionSystem():GetItemQuantityByTag(player, "FlatlineShard"))
  out("  control: heat=" .. heatNow() .. " shards=" .. shards)
  check("control precondition: not wanted, no shards", heatNow() == 0 and shards == 0)
  local hs = Game.GetScriptableSystemsContainer():Get("FlatlineBroker.FlatlineHeatSystem")
  for _ = 1, 40 do hs:OnPatrolTick() end
  check("control: 40 patrol checks next to a cop with no shards never bust", heatNow() == 0, "heat=" .. heatNow())
end)

step(2, function()
  local player = Game.GetPlayer()
  out("  patrol: heat=" .. heatNow())
  check("patrol precondition: not wanted", heatNow() == 0)
  local hs = Game.GetScriptableSystemsContainer():Get("FlatlineBroker.FlatlineHeatSystem")
  -- Hand the shards back, clear the cooldown and scan within this one frame, so
  -- the mod's own 15 s patrol timer cannot fire in between.
  local ts = Game.GetTransactionSystem()
  for id, n in pairs(ctx.stash) do ts:GiveItem(player, ItemID.FromTDBID(TweakDBID.new(id)), n) end
  ts:GiveItem(player, ItemID.FromTDBID(TweakDBID.new("Items.FlatlineBroker_Shard_Street_1")), 8)
  out("  patrol: shards=" .. tonumber(ts:GetItemQuantityByTag(player, "FlatlineShard")))
  -- A bust starts a 3-minute cooldown, and the mod's own 15 s patrol timer may
  -- already have busted V during an earlier run. Clear it so this run measures
  -- the scan itself.
  pcall(function() hs.lastBustTime = -1000.0 end)
  pcall(function() hs.m_lastBustTime = -1000.0 end)
  out("  patrol: cooldown reset, lastBustTime=" .. tostring(hs.lastBustTime or hs.m_lastBustTime))
  local tries = 0
  while tries < 40 and heatNow() == 0 do
    hs:OnPatrolTick()
    tries = tries + 1
  end
  local bustAt = tonumber(hs.lastBustTime or hs.m_lastBustTime) or -1000
  check("patrol scan busts a shard carrier next to a cop", heatNow() == 1 and tries >= 1 and bustAt > 0, "heat=" .. heatNow() .. " after " .. tries .. " checks, bust recorded at " .. bustAt)
  -- Probe each gate of FlatlineHeatSystem.PatrolCheck.
  pcall(function()
    local ps = Game.GetScriptableSystemsContainer():Get("PreventionSystem")
    out("  gate CanPreventionReactToInput=" .. tostring(ps:CanPreventionReactToInput()))
  end)
  pcall(function()
    local cop = Game.GetDynamicEntitySystem():GetEntity(ctx.cop)
    out("  gate cop distance=" .. tostring(Vector4.Distance(cop:GetWorldPosition(), player:GetWorldPosition()))
      .. " IsPrevention=" .. tostring(cop:IsPrevention()) .. " IsActive=" .. tostring(ScriptedPuppet.IsActive(cop)))
  end)
  local okq, errq = pcall(function()
    local q = TargetSearchQuery.new()
    q.testedSet = TargetingSet.Complete
    q.searchFilter = Game["TSF_NPC;"]()
    q.includeSecondaryTargets = false
    q.maxDistance = 10
    q.filterObjectByDistance = true
    local _, parts = Game.GetTargetingSystem():GetTargetParts(player, q)
    local n, cops = 0, 0
    for _, part in ipairs(parts or {}) do
      n = n + 1
      local e = TS_TargetPartInfo.GetComponent(part):GetEntity()
      if e and e:IsA("ScriptedPuppet") and e:IsPrevention() then cops = cops + 1 end
    end
    out("  gate targeting query: " .. n .. " parts, " .. cops .. " police")
  end)
  if not okq then out("  gate targeting query failed: " .. tostring(errq)) end
  pcall(function()
    out("  gate sim time=" .. tostring(EngineTime.ToFloat(Game.GetSimTime())) .. " lastBustTime=" .. tostring(hs.lastBustTime or hs.m_lastBustTime))
  end)
  out("SHOT:12b_patrol_scan_bust")
end)

step(4, function()
  Game.GetDynamicEntitySystem():DeleteTagged("FlatlineTestCop")
  -- Manifest rule: becoming wanted while carrying shards adds a star.
  setSafe()
end)

step(3, function()
  out("  manifest: heat before=" .. heatNow())
  check("manifest precondition: not wanted", heatNow() == 0)
  local req = PreventionConsoleInstructionRequest.new()
  req.instruction = EPreventionSystemInstruction.Active
  req.heatStage = EPreventionHeatStage.Heat_1
  Game.GetScriptableSystemsContainer():Get("PreventionSystem"):QueueRequest(req)
end)

step(5, function()
  check("manifest rule raises heat 1 -> 2 while carrying shards", heatNow() == 2, "heat=" .. heatNow())
  out("SHOT:13_manifest_heat")
end)

step(2, function()
  -- Leave the world as we found it: no wanted level, no test NPCs.
  cleanSlate()
  out("== done")
end)

-- Main menu: load the most recent save once per launch, so the test needs no input.
local autoLoaded = false
registerForEvent("onInit", function()
  Observe("SingleplayerMenuGameController", "OnSavesForLoadReady", function(self, saves)
    if autoLoaded or #saves == 0 then return end
    autoLoaded = true
    out("auto-loading last save")
    self:GetSystemRequestsHandler():LoadLastCheckpoint(false)
  end)
  -- A fresh session (save loaded) restarts the test.
  Observe("PlayerPuppet", "OnGameAttached", function(self)
    if self:IsReplacer() then return end
    idx, t, started, ctx = 1, 0, false, {}
  end)
end)

registerForEvent("onUpdate", function(dt)
  if idx > #steps then return end
  local player = Game.GetPlayer()
  if not player or not player:IsAttached() then return end
  if not started then
    -- OnGameAttached fires during the loading screen; wait for gameplay systems.
    if not Game.GetDynamicEntitySystem():IsReady() then return end
    if Game.GetSystemRequestsHandler():IsPreGame() then return end
    if EquipmentSystem.GetData(player) == nil then return end
    local loc = Game.GetScriptableSystemsContainer():Get("Codeware.Localization.LocalizationSystem")
    if not loc or loc:GetText("flatline_scroller_name") == "flatline_scroller_name" then return end
    started = true; t = -10 -- let the world settle after load
  end
  t = t + dt
  if t >= steps[idx].delay then
    t = 0
    local ok, err = pcall(steps[idx].fn)
    if not ok then out("ERROR in step " .. idx .. ": " .. tostring(err)) end
    idx = idx + 1
  end
end)

-- Flatline Broker vendor probe (developer tool, not shipped).
-- At startup, dumps every vendor record (ID, type, localized name) to
-- vendor_probe.log next to this file. Needs no save loaded.

registerForEvent("onInit", function()
  local log = io.open("vendor_probe.log", "w")
  local function out(s) log:write(s .. "\n") end
  local records = TweakDB:GetRecords("gamedataVendor_Record") or {}
  out("total vendor records: " .. #records)
  for _, r in ipairs(records) do
    local ok, line = pcall(function()
      local id = TDBID.ToStringDEBUG(r:GetID())
      local vt = r:VendorType()
      local typeName = vt and tostring(vt:Type()) or "?"
      local name = r:LocalizedName() or ""
      local nameText = (name ~= "" and Game.GetLocalizedText(name)) or ""
      return id .. " | " .. typeName .. " | " .. nameText .. " | " .. name
    end)
    out(ok and line or ("error: " .. tostring(line)))
  end
  out("== done")
  log:close()
end)

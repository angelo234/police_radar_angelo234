-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}

local police_radar_system = require('scripts/police_radar_angelo234/policeRadar')

local function onExtensionLoaded()
  police_radar_system.init()
end

local function onVehicleSwitched(oid, nid, player)
  
end

local function onUpdate(dt)
  police_radar_system.update(dt)
end

local function onExtensionUnloaded()
  police_radar_system.cleanUp()
end

M.onExtensionLoaded = onExtensionLoaded
M.onVehicleSwitched = onVehicleSwitched
M.onUpdate = onUpdate
M.onExtensionUnloaded = onExtensionUnloaded

return M

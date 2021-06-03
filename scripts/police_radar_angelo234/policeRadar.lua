-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}

--Radar beam width in degrees
local radar_beam_size = 10

local max_range = 200

local sfx_initialized = false

local function init()

end

local function getBeamSpread()
  local radar_beam_size_rads = radar_beam_size * math.pi / 180.0
  
  return max_range * math.tan(radar_beam_size_rads / 2.0)
end

local function getBeamDimensions(my_veh)
  local my_veh_dir = vec3(my_veh.obj:getDirectionVector()):normalized()
  local my_veh_dir_up = vec3(my_veh.obj:getDirectionVectorUp()):normalized()
  local my_veh_dir_right = my_veh_dir:cross(my_veh_dir_up):normalized()
  
  local radar_pos = vec3(my_veh:getSpawnWorldOOBB():getCenter())

  local beam_spread = getBeamSpread()
  
  local p1 = radar_pos + my_veh_dir * max_range + my_veh_dir_right * beam_spread
  local p2 = radar_pos + my_veh_dir * max_range + my_veh_dir_right * -beam_spread
  
  return radar_pos, p1, p2
end

local function getVehiclesInRadarBeam()
  local vehs = {}
  
  local my_veh = be:getPlayerVehicle(0)
  
  local radar_pos, p1, p2 = getBeamDimensions(my_veh)

  debugDrawer:setSolidTriCulling(false)

  debugDrawer:drawQuadSolid(radar_pos:toPoint3F(), (radar_pos + vec3(0,0,0.1)):toPoint3F(), (p1 + vec3(0,0,0.1)):toPoint3F(), p1:toPoint3F(), ColorF(1,0,0,0.5)) 
  debugDrawer:drawQuadSolid(radar_pos:toPoint3F(), (radar_pos + vec3(0,0,0.1)):toPoint3F(), (p2 + vec3(0,0,0.1)):toPoint3F(), p2:toPoint3F(), ColorF(1,0,0,0.5))

  debugDrawer:drawSphere(p1:toPoint3F(), 1, ColorF(1,0,0,1))
  debugDrawer:drawSphere(p2:toPoint3F(), 1, ColorF(1,0,0,1))
  
  local vehicles = getAllVehicles()
  
  for _, other_veh in pairs(vehicles) do
    if other_veh:getJBeamFilename() ~= "unicycle" 
    and other_veh:getID() ~= my_veh:getID() then
    
      local other_veh_pos = vec3(other_veh:getSpawnWorldOOBB():getCenter())

      local hit_dist = intersectsRay_Triangle(other_veh_pos, vec3(0,0,1), radar_pos, p1, p2)
      local hit_dist2 = intersectsRay_Triangle(other_veh_pos, vec3(0,0,-1), radar_pos, p1, p2)
      
      if (hit_dist ~= math.huge and hit_dist ~= -math.huge) or (hit_dist2 ~= math.huge and hit_dist2 ~= -math.huge) then
        local raycast_dist = castRayStatic(radar_pos:toPoint3F(), (other_veh_pos - radar_pos):normalized():toPoint3F(), max_range)
        local dist_between = (other_veh_pos - radar_pos):length()
        
        --Check if no obstacles in way
        if raycast_dist >= dist_between then   
          table.insert(vehs, other_veh)
        end
      end
    end
  end
  
  return vehs
end

local function getStrongestVehicle(vehs)
  local radar_pos = vec3(be:getPlayerVehicle(0):getSpawnWorldOOBB():getCenter())
  
  local min_dist = 999999
  local speed = 0
  
  for _, veh in pairs(vehs) do
    local dist = (radar_pos - vec3(veh:getPosition())):length()
    
    if dist < min_dist then
      local veh_speed = vec3(veh:getVelocity()):length()
    
      min_dist = dist
      speed = veh_speed
    end
  end
  
  return speed
end

local function getFastestVehicle(vehs)
  local max_speed = 0
  
  for _, veh in pairs(vehs) do
    local veh_speed = vec3(veh:getVelocity()):length()
    
    if veh_speed > max_speed then
      max_speed = veh_speed
    end
  end
  
  return max_speed
end

local function playTone(speed)
  local pitch = math.max(speed / 13.4112, 0)

  be:getPlayerVehicle(0):queueLuaCommand("obj:setVolumePitch(sfx_source, 1, " .. string.format("%.2f", pitch) ..")")
end

local function update(dt)
  if be:getPlayerVehicle(0) == nil then return end
  
  if not sfx_initialized then
    be:getPlayerVehicle(0):queueLuaCommand("sfx_source = obj:createSFXSource('art/sound/550hz.wav', 'AudioDefaultLoop3D', '', 1)")
    sfx_initialized = true
  end
  
  local vehs = getVehiclesInRadarBeam()

  local strongest_speed = getStrongestVehicle(vehs) + math.random() * 0.5 - 0.25
  local fastest_speed = getFastestVehicle(vehs) + math.random() * 0.5 - 0.25
  
  playTone(fastest_speed)
  
  local data = {}
  data.strongest_speed = strongest_speed
  data.fastest_speed = fastest_speed
  data.patrol_speed = vec3(be:getPlayerVehicle(0):getVelocity()):length()
  
  guihooks.trigger('sendRadarInfo', data)
  
  --print("Max speed: " .. (max_speed * 3.6) .. " km/h")
end

local function cleanUp()
  be:getPlayerVehicle(0):queueLuaCommand("obj:stopSFX(sfx_source)")
end

M.init = init
M.update = update
M.cleanUp = cleanUp

return M

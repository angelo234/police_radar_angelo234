-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local audio = require('lua/common/controller/policeRadarAudio')

local M = {}

--Radar beam width in degrees
local radar_beam_size = 20
local max_range = 500

--Antenna rotation in degrees
local yaw_angle = -3

local middle_display_mode = "fastest_speed"

local radar_xmitting = false
local lock_strongest_speed_flag = false
local lock_fastest_speed_flag = false

local locked_speed = 0

local function toggleRadarXmitting()
  radar_xmitting = not radar_xmitting
  
  local msg = "OFF"
  
  audio.setDopplerSoundOn(radar_xmitting)
  
  if radar_xmitting then
    msg = "ON"
  end
  
  ui_message("Radar Transmitting " .. msg)
  
  audio.playSelectSound()
end

local function lockStrongestSpeed()
  lock_strongest_speed_flag = true
  
  middle_display_mode = "locked_speed"
  
  audio.playSelectSound()
end

local function lockFastestSpeed()
  lock_fastest_speed_flag = true
  
  middle_display_mode = "locked_speed"
  
  audio.playSelectSound()
end

local function init(jbeamData)

end

local function getBeamSpread()
  local radar_beam_size_rads = radar_beam_size * math.pi / 180.0
  
  return max_range * math.tan(radar_beam_size_rads / 2.0)
end

local function getBeamDimensions(radar_pos)
  local my_veh_dir = vec3(obj:getDirectionVector())
  local my_veh_dir_up = vec3(obj:getDirectionVectorUp())
  
  local radar_dir = quatFromAxisAngle(my_veh_dir_up, yaw_angle * math.pi / 180.0) * my_veh_dir
  local radar_dir_right = radar_dir:cross(my_veh_dir_up)
  
  local beam_spread = getBeamSpread()
  
  local p1 = radar_pos + radar_dir * max_range + radar_dir_right * beam_spread
  local p2 = radar_pos + radar_dir * max_range + radar_dir_right * -beam_spread

  return p1, p2
end

local function getVehiclesInRadarBeam(radar_pos)
  local vehs = {}

  local p1, p2 = getBeamDimensions(radar_pos)

  --debugDrawer:setSolidTriCulling(false)

  obj.debugDrawProxy:drawLine(radar_pos:toFloat3(), p1:toFloat3(), color(255,0,0,255)) 
  obj.debugDrawProxy:drawLine(radar_pos:toFloat3(), p2:toFloat3(), color(255,0,0,255)) 

  --obj.debugDrawProxy:drawSphere(0.25, radar_pos:toFloat3(), color(255,0,0,255))

  --debugDrawer:drawSphere(p1:toFloat3(), 1, color(255,0,0,255))
  --debugDrawer:drawSphere(p2:toFloat3(), 1, color(255,0,0,255))
  
  local vehicles = mapmgr.objects
  
  for _, other_veh in pairs(vehicles) do
    --if other_veh:getJBeamFilename() ~= "unicycle" 
    --and other_veh:getID() ~= my_veh:getID() then
    if other_veh.id ~= obj:getID() then
      local hit_dist = intersectsRay_Triangle(other_veh.pos, vec3(0,0,1), radar_pos, p1, p2)
      local hit_dist2 = intersectsRay_Triangle(other_veh.pos, vec3(0,0,-1), radar_pos, p1, p2)
      
      if (hit_dist ~= math.huge and hit_dist ~= -math.huge) or (hit_dist2 ~= math.huge and hit_dist2 ~= -math.huge) then
        local raycast_dist = obj:castRayStatic(radar_pos:toFloat3(), (other_veh.pos - radar_pos):normalized():toFloat3(), max_range)
        local dist_between = (other_veh.pos - radar_pos):length()
        
        --Check if no obstacles in way
        if raycast_dist >= dist_between then   
          table.insert(vehs, other_veh)
        end
      end
    end
  end
  
  return vehs
end

local function getStrongestVehicle(vehs, radar_pos)
  local min_dist = 999999
  local speed = nil
  
  for _, veh in pairs(vehs) do
    local dist = (radar_pos - vec3(veh.pos)):length()
    
    if dist < min_dist then
      local veh_speed = vec3(veh.vel):length()
    
      min_dist = dist
      speed = veh_speed
    end
  end
  
  return speed
end

local function getFastestVehicle(vehs)
  local max_speed = 0
  
  for _, veh in pairs(vehs) do
    local veh_speed = vec3(veh.vel):length()
    
    if veh_speed > max_speed then
      max_speed = veh_speed
    end
  end
  
  return max_speed
end

local function getRadarPos()
  local my_veh_dir = vec3(obj:getDirectionVector())
  local my_veh_dir_up = vec3(obj:getDirectionVectorUp())
  local my_veh_dir_right = vec3(obj:getDirectionVectorRight())

  return vec3(obj:getFrontPosition()) + my_veh_dir_up * 0.85 - my_veh_dir * 1.5 + my_veh_dir_right * 0.4
end

local first_update = false

local function updateGFX(dt)
  if not first_update then
    audio.init()
    
    first_update = true
  end
  
  local radar_pos = getRadarPos()
  
  local strongest_speed = nil
  local fastest_speed = nil
  local patrol_speed = nil
  
  local data = {}

  data.middle_display_mode = middle_display_mode
  data.radar_xmitting = radar_xmitting
  
  if radar_xmitting then
    data.patrol_speed = vec3(obj:getVelocity()):length()
    
    local vehs = getVehiclesInRadarBeam(radar_pos)
  
    strongest_speed = getStrongestVehicle(vehs, radar_pos)
    
    --Check if vehicle in beam first of all
    if strongest_speed then
      fastest_speed = getFastestVehicle(vehs)
      data.strongest_speed = strongest_speed
    
      --Only display fastest speed if greater than strongest source speed
      if fastest_speed > strongest_speed then
        data.fastest_speed = fastest_speed
      else
        data.fastest_speed = nil
      end
      
      if lock_strongest_speed_flag then
        locked_speed = strongest_speed
        
        audio.playLockedSpeedVoice("front", "stationary", "closing")   
      end
      
      if lock_fastest_speed_flag then
        locked_speed = fastest_speed
        
        audio.playLockedSpeedVoice("front", "stationary", "closing")  
      end
    end
    
    lock_strongest_speed_flag = false
    lock_fastest_speed_flag = false

    data.locked_speed = locked_speed
    
    local noise_val = math.random() * 0.5 - 0.25
    
    local tone_speed = fastest_speed or 0
    
    audio.setDopplerSoundPitch(tone_speed + noise_val)
  end

  guihooks.trigger('sendRadarInfo', data)
  
  --print("Max speed: " .. (max_speed * 3.6) .. " km/h")
end

--[[
local function cleanUp()
  obj:stopSFX(radar_doppler_sfx)
end
]]--

M.toggleRadarXmitting = toggleRadarXmitting
M.lockStrongestSpeed = lockStrongestSpeed
M.lockFastestSpeed = lockFastestSpeed
M.init = init
M.updateGFX = updateGFX

return M
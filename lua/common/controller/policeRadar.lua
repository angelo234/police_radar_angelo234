-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local audio = require('lua/common/controller/policeRadarAudio')

local M = {}

--Radar beam width in degrees
local radar_beam_size = 20
local max_range = 500

--Antenna rotation in degrees
local antenna_yaw_angle = -3

local antenna_relative_x_pos = 1.5
local antenna_relative_y_pos = 0.4
local antenna_relative_z_pos = 0.85

local beam_spread = 0

local show_radar_beam = false

local middle_display_mode = "fastest_speed"

local radar_xmitting = true
local lock_strongest_speed_flag = false
local lock_fastest_speed_flag = false
local toggle_radar_doppler_sound_display_timer = -1

local locked_speed = 0

local function toggleRadarXmitting()
  radar_xmitting = not radar_xmitting

  audio.playSelectSound()
end

local function adjustRadarDopplerVolume()
  audio.setRadarDopplerVolume()
  
  audio.playSelectSound()
  
  toggle_radar_doppler_sound_display_timer = 0
end

local function lockStrongestSpeed()
  if not radar_xmitting then return end

  if middle_display_mode == "locked_speed" then
    middle_display_mode = "fastest_speed"
    
    locked_speed = 0
  else
    middle_display_mode = "locked_speed"
    
    lock_strongest_speed_flag = true
  end
  
  audio.playSelectSound()
end

local function lockFastestSpeed()
  if not radar_xmitting then return end

  if middle_display_mode == "locked_speed" then
    middle_display_mode = "fastest_speed"
    
    locked_speed = 0
  else
    middle_display_mode = "locked_speed"
    
    lock_fastest_speed_flag = true
  end
  
  audio.playSelectSound()
end

local function init(jbeamData)
  antenna_yaw_angle = v.data.variables["$antenna_yaw_angle"].val
  
  antenna_relative_x_pos = v.data.variables["$antenna_relative_x_pos"].val
  antenna_relative_y_pos = v.data.variables["$antenna_relative_y_pos"].val
  antenna_relative_z_pos = v.data.variables["$antenna_relative_z_pos"].val
  
  show_radar_beam = v.data.variables["$show_radar_beam"].val == 1
  
  local radar_beam_size_rads = radar_beam_size * math.pi / 180.0
  
  beam_spread = max_range * math.tan(radar_beam_size_rads / 2.0)
end

local function getBeamDimensions(radar_pos)
  local my_veh_dir = vec3(obj:getDirectionVector())
  local my_veh_dir_up = vec3(obj:getDirectionVectorUp())
  
  local radar_dir = quatFromAxisAngle(my_veh_dir_up, antenna_yaw_angle * math.pi / 180.0) * my_veh_dir
  local radar_dir_right = radar_dir:cross(my_veh_dir_up)
 
  local p1 = radar_pos + radar_dir * max_range + radar_dir_right * beam_spread
  local p2 = radar_pos + radar_dir * max_range + radar_dir_right * -beam_spread

  return p1, p2
end

local function getVehiclesInRadarBeam(radar_pos, p1, p2)
  local vehs = {}

  local vehicles = mapmgr.getObjects()
  
  for _, other_veh in pairs(vehicles) do
    --if other_veh:getJBeamFilename() ~= "unicycle" 
    --and other_veh:getID() ~= my_veh:getID() then
    if other_veh.id ~= obj:getID() then
      local hit_dist = intersectsRay_Triangle(other_veh.pos, vec3(0,0,1), radar_pos, p1, p2)
      local hit_dist2 = intersectsRay_Triangle(other_veh.pos, vec3(0,0,-1), radar_pos, p1, p2)
      
      if (hit_dist ~= math.huge and hit_dist ~= -math.huge) or (hit_dist2 ~= math.huge and hit_dist2 ~= -math.huge) then
        local raycast_dist = obj:castRayStatic(radar_pos, (other_veh.pos - radar_pos):normalized(), max_range)
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
  local dir = nil
  
  for _, veh in pairs(vehs) do
    local dist = (radar_pos - vec3(veh.pos)):length()
    
    if dist < min_dist then
      local veh_speed = vec3(veh.vel):length()
    
      local vel_dir = vec3(veh.vel):normalized() 
      local my_veh_dir = vec3(obj:getDirectionVector())
 
      --Same direction = away
      if math.acos(vel_dir:dot(my_veh_dir)) < math.pi / 2.0 then
        dir = "away"
      else
        dir = "closing"
      end
 
      min_dist = dist
      speed = veh_speed
    end
  end
  
  return speed, dir
end

local function getFastestVehicle(vehs)
  local max_speed = 0
  local dir = nil
  
  for _, veh in pairs(vehs) do
    local veh_speed = vec3(veh.vel):length()
    
    if veh_speed > max_speed then
      local vel_dir = vec3(veh.vel):normalized() 
      local my_veh_dir = vec3(obj:getDirectionVector())
 
      --Same direction = away
      if math.acos(vel_dir:dot(my_veh_dir)) < math.pi / 2.0 then
        dir = "away"
      else
        dir = "closing"
      end
    
      max_speed = veh_speed
    end
  end
  
  return max_speed, dir
end

local function getAntennaPos()
  local my_veh_dir = vec3(obj:getDirectionVector())
  local my_veh_dir_up = vec3(obj:getDirectionVectorUp())
  local my_veh_dir_right = vec3(obj:getDirectionVectorRight())

  return vec3(obj:getFrontPosition()) + my_veh_dir_up * antenna_relative_z_pos + my_veh_dir * antenna_relative_x_pos + my_veh_dir_right * antenna_relative_y_pos
end

local first_update = false
local update_timer = 0
local delta_update = 1.0 / 20.0 -- 20 Hz

local function updateGFX(dt)
  --Only run on player's vehicle
  if not playerInfo.firstPlayerSeated then
    return
  end

  if not first_update then
    audio.init()
    
    first_update = true
  end
  
  local radar_pos = getAntennaPos()  
  local p1, p2 = getBeamDimensions(radar_pos)
  
  if show_radar_beam then
		obj.debugDrawProxy:drawLine(radar_pos, p1, color(255,0,0,255)) 
    obj.debugDrawProxy:drawLine(radar_pos, p2, color(255,0,0,255))
    obj.debugDrawProxy:drawSphere(0.1, radar_pos, color(255,0,0,255))  
  end
  
  if update_timer >= delta_update then    
    update_timer = 0
    
    update_timer = update_timer + dt
  else
    update_timer = update_timer + dt  
    return
  end
  
  local strongest_speed = nil
  local fastest_speed = nil
  local patrol_speed = nil
  local strongest_dir = nil
  local fastest_dir = nil
  
  local data = {}

  data.middle_display_mode = middle_display_mode
  data.radar_xmitting = radar_xmitting
  
  if radar_xmitting then
    data.patrol_speed = vec3(obj:getVelocity()):length()
    
    local vehs = getVehiclesInRadarBeam(radar_pos, p1, p2)
  
    strongest_speed, strongest_dir = getStrongestVehicle(vehs, radar_pos)
    
    --Check if vehicle in beam first of all
    if strongest_speed then
      fastest_speed, fastest_dir = getFastestVehicle(vehs)
      data.strongest_speed = strongest_speed
    
      --Only display fastest speed if greater than strongest source speed
      if fastest_speed > strongest_speed then
        data.fastest_speed = fastest_speed
      else
        data.fastest_speed = nil
      end
      
      if lock_strongest_speed_flag then
        locked_speed = strongest_speed
        
        --audio.playLockedSpeedVoice("front", "stationary", strongest_dir)   
      end
      
      if lock_fastest_speed_flag then
        locked_speed = fastest_speed
        
        --audio.playLockedSpeedVoice("front", "stationary", fastest_dir)  
      end
    end
    
    lock_strongest_speed_flag = false
    lock_fastest_speed_flag = false

    data.locked_speed = locked_speed
    
    local noise_val = math.random() * 0.5 - 0.25
    
    local tone_speed = strongest_speed or 0
    
    audio.setDopplerSoundPitch(tone_speed + noise_val)
  else
    audio.setDopplerSoundPitch(0)
  end
  
  --Override display if adjusting volume with current volume level for 2.5 seconds
  if toggle_radar_doppler_sound_display_timer >= 0 then
    if toggle_radar_doppler_sound_display_timer >= 2.5 then
      toggle_radar_doppler_sound_display_timer = -1
    else
      data.display_doppler_sound = true;
      data.doppler_sound_on = audio.getDopplerSoundVolume()
      
      toggle_radar_doppler_sound_display_timer = toggle_radar_doppler_sound_display_timer + delta_update
    end
  else
    data.display_doppler_sound = false
  end

  guihooks.trigger('sendRadarInfo', data)

  audio.updateGFX(delta_update)
end

M.toggleRadarXmitting = toggleRadarXmitting
M.adjustRadarDopplerVolume = adjustRadarDopplerVolume
M.lockStrongestSpeed = lockStrongestSpeed
M.lockFastestSpeed = lockFastestSpeed
M.init = init
M.updateGFX = updateGFX

return M
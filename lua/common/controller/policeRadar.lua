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
  local my_veh_dir = obj:getDirectionVector()
  local my_veh_dir_up = obj:getDirectionVectorUp()

  local radar_dir = quatFromAxisAngle(my_veh_dir_up, antenna_yaw_angle * math.pi / 180.0) * my_veh_dir
  local radar_dir_right = radar_dir:cross(my_veh_dir_up)

  local p1 = radar_pos + radar_dir * max_range + radar_dir_right * beam_spread
  local p2 = radar_pos + radar_dir * max_range + radar_dir_right * -beam_spread

  return p1, p2
end

local tempVehs = {}

local function getVehiclesInRadarBeam(radar_pos, p1, p2)
  table.clear(tempVehs)

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
          local noiseScale = 0.0025
          local noise = math.random() * 0.5 - 0.25 --dist_between * noiseScale - 0.5 * dist_between * noiseScale
          table.insert(tempVehs, {
            veh = other_veh,
            dist = dist_between,
            speed = obj:getDirectionVector():dot(other_veh.vel) + noise,
          })
        end
      end
    end
  end

  return tempVehs
end

local function getStrongestVehicle(vehs, radar_pos)
  local min_dist = 999999
  local strongest_speed = nil
  local dir = nil

  for _, data in pairs(vehs) do
    if data.dist < min_dist then
      local speed = data.speed
      --Same direction = away
      dir = sign2(speed) == 1 and "away" or "closing"
      min_dist = data.dist
      strongest_speed = speed
    end
  end

  return strongest_speed, dir
end

local function getFastestVehicle(vehs)
  local max_speed = nil
  local dir = nil

  for _, data in pairs(vehs) do
    local speed = data.speed
    if not max_speed or math.abs(speed) > math.abs(max_speed) then
      --Same direction = away
      dir = sign2(speed) == 1 and "away" or "closing"
      max_speed = speed
    end
  end

  return max_speed, dir
end

local function getAntennaPos()
  local my_veh_dir = obj:getDirectionVector()
  local my_veh_dir_up = obj:getDirectionVectorUp()
  local my_veh_dir_right = obj:getDirectionVectorRight()

  return obj:getFrontPosition() + my_veh_dir_up * antenna_relative_z_pos + my_veh_dir * antenna_relative_x_pos + my_veh_dir_right * antenna_relative_y_pos
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
    data.patrol_speed = obj:getVelocity():length()

    local vehs = getVehiclesInRadarBeam(radar_pos, p1, p2)
    strongest_speed, strongest_dir = getStrongestVehicle(vehs, radar_pos)
    local strongest_speed_abs = strongest_speed and math.abs(strongest_speed)
    data.strongest_speed = strongest_speed_abs

    fastest_speed, fastest_dir = getFastestVehicle(vehs)
    local fastest_speed_abs = fastest_speed and math.abs(fastest_speed)

    --Only display fastest speed if greater than strongest source speed
    if fastest_speed_abs and strongest_speed_abs and fastest_speed_abs > strongest_speed_abs then
      data.fastest_speed = fastest_speed_abs
    else
      data.fastest_speed = nil
    end

    if lock_strongest_speed_flag then
      locked_speed = strongest_speed_abs
      --audio.playLockedSpeedVoice("front", "stationary", strongest_dir)
    end
    if lock_fastest_speed_flag then
      locked_speed = fastest_speed_abs
      --audio.playLockedSpeedVoice("front", "stationary", fastest_dir)
    end

    lock_strongest_speed_flag = false
    lock_fastest_speed_flag = false

    data.locked_speed = locked_speed
    local tone_speed = strongest_speed_abs or 0

    audio.setDopplerSoundPitch(tone_speed)
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
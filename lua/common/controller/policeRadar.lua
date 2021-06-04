-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}

--Radar beam width in degrees
local radar_beam_size = 15

local max_range = 500

local sfx_source = nil

local yaw_angle = -6

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
  local speed = 0
  
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

local function playTone(speed)
  local pitch = math.max(speed / 13.4112, 0)

  obj:setVolumePitch(sfx_source, 1, pitch)
end

local function updateGFX(dt)
  if not sfx_source then
    sfx_source = obj:createSFXSource('art/sound/550hz.wav', 'AudioDefaultLoop3D', '', 1)
  end

  local my_veh_dir = vec3(obj:getDirectionVector())
  local my_veh_dir_up = vec3(obj:getDirectionVectorUp())
  local my_veh_dir_right = vec3(obj:getDirectionVectorRight())

  local radar_pos = vec3(obj:getFrontPosition()) + my_veh_dir_up * 0.75 - my_veh_dir * 1.5 + my_veh_dir_right * 0.4

  local vehs = getVehiclesInRadarBeam(radar_pos)

  local noise_val = math.random() * 0.5 - 0.25

  local strongest_speed = getStrongestVehicle(vehs, radar_pos) + noise_val
  local fastest_speed = getFastestVehicle(vehs) + noise_val

  playTone(fastest_speed)
  
  local data = {}
  data.strongest_speed = strongest_speed
  
  --Only display fastest speed if greater than strongest source speed
  if fastest_speed > strongest_speed then
    data.fastest_speed = fastest_speed
  else
    data.fastest_speed = nil
  end
  
  data.patrol_speed = vec3(obj:getVelocity()):length()
  
  guihooks.trigger('sendRadarInfo', data)
  
  --print("Max speed: " .. (max_speed * 3.6) .. " km/h")
end

local function cleanUp()
  obj:stopSFX(sfx_source)
end

M.init = init
M.updateGFX = updateGFX
M.cleanUp = cleanUp

return M
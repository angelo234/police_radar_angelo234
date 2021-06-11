local M = {}

local radar_doppler_sfx = nil

local voice_sfx_table = {}

local voice_volume = 5

local locked_speed_voice_time = 0

local locked_speed_voice_timer = -1
local locked_speed_voice_msg = "dir"

local locked_speed_voice_dir = nil
local locked_speed_voice_mode = nil
local locked_speed_voice_vel = nil

local function init()
  radar_doppler_sfx = obj:createSFXSource('art/sound/550hz.wav', 'AudioDefaultLoop3D', '', 1)
  
  obj:createSFXSource('art/sound/select.wav', 'AudioGui', 'radar_select', 1)
  
  --Voices (credits: https://voicemaker.in/)
  voice_sfx_table["front"] = {sfx_name = "radar_voice_front", length = 0.45}
  voice_sfx_table["rear"] = {sfx_name = "radar_voice_rear", length = 0.45}
  voice_sfx_table["stationary"] = {sfx_name = "radar_voice_stationary", length = 0.68}
  voice_sfx_table["same"] = {sfx_name = "radar_voice_same", length = 0.45}
  voice_sfx_table["opposite"] = {sfx_name = "radar_voice_opposite", length = 0.7}
  voice_sfx_table["closing"] = {sfx_name = "radar_voice_closing", length = 0.5}
  voice_sfx_table["away"] = {sfx_name = "radar_voice_away", length = 0.45}
  
  for key, data in pairs(voice_sfx_table) do
    obj:createSFXSource('art/sound/speech/' .. key .. '.wav', 'AudioGui', data.sfx_name, 1)
  end
end

local function playLockedSpeedVoice(dir, mode, vel)
  locked_speed_voice_dir = dir
  locked_speed_voice_mode = mode
  locked_speed_voice_vel = vel

  locked_speed_voice_msg = "dir"
  locked_speed_voice_timer = 1
end

local function playVoice(voice)
  if voice_sfx_table[voice] then
    obj:playSFXOnce(voice_sfx_table[voice].sfx_name, 0, voice_volume, 1)

    return voice_sfx_table[voice].length
  end
  
  return nil
end

local function playSelectSound()
  obj:playSFXOnce('radar_select', 0, 2.5, 1)
end

local function setDopplerSoundOn(on)
  if on then
    obj:playSFX(radar_doppler_sfx)
  else
    obj:setVolumePitch(radar_doppler_sfx, 0, 1)
    obj:stopSFX(radar_doppler_sfx)
  end
end

local function setDopplerSoundPitch(speed)
  local pitch = math.max(speed / 13.4112, 0)

  obj:setVolumePitch(radar_doppler_sfx, 1, pitch)
end

local function updateGFX(dt)
  if locked_speed_voice_timer >= locked_speed_voice_time then
    if locked_speed_voice_msg == "dir" then
      local length = playVoice(locked_speed_voice_dir)
      
      locked_speed_voice_time = length
      locked_speed_voice_msg = "mode"
      locked_speed_voice_timer = 0
      
    elseif locked_speed_voice_msg == "mode" then
      local length = playVoice(locked_speed_voice_mode)
      
      locked_speed_voice_time = length
      locked_speed_voice_msg = "vel"    
      locked_speed_voice_timer = 0
      
    elseif locked_speed_voice_msg == "vel" then
      local length = playVoice(locked_speed_voice_vel)
      
      locked_speed_voice_time = length
      locked_speed_voice_msg = "dir"    
      locked_speed_voice_timer = -1
    end
  end
  
  if locked_speed_voice_timer >= 0 then
    locked_speed_voice_timer = locked_speed_voice_timer + dt
  end
end

M.init = init
M.playLockedSpeedVoice = playLockedSpeedVoice
M.playSelectSound = playSelectSound
M.setDopplerSoundOn = setDopplerSoundOn
M.setDopplerSoundPitch = setDopplerSoundPitch
M.updateGFX = updateGFX

return M
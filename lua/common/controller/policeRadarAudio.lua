local M = {}

local radar_doppler_sfx = nil
local select_sfx = nil

local voice_front_sfx = nil
local voice_rear_sfx = nil
local voice_stationary_sfx = nil
local voice_same_sfx = nil
local voice_opposite_sfx = nil
local voice_closing_sfx = nil
local voice_away_sfx = nil

local function init()
  radar_doppler_sfx = obj:createSFXSource(    'art/sound/550hz.wav',              'AudioDefaultLoop3D', '', 1)
  select_sfx = obj:createSFXSource(           'art/sound/select.wav',             'AudioGui', 'radar_select', 1)
  
  --Voices
  voice_front_sfx = obj:createSFXSource(      'art/sound/speech/front.wav',       'AudioGui', 'radar_voice_front', 1)
  voice_rear_sfx = obj:createSFXSource(       'art/sound/speech/rear.wav',        'AudioGui', 'radar_voice_rear', 1)
  voice_stationary_sfx = obj:createSFXSource( 'art/sound/speech/stationary.wav',  'AudioGui', 'radar_voice_stationary', 1)
  voice_same_sfx = obj:createSFXSource(       'art/sound/speech/same.wav',        'AudioGui', 'radar_voice_same', 1)
  voice_opposite_sfx = obj:createSFXSource(   'art/sound/speech/opposite.wav',    'AudioGui', 'radar_voice_opposite', 1)
  voice_closing_sfx = obj:createSFXSource(    'art/sound/speech/closing.wav',     'AudioGui', 'radar_voice_closing', 1)
  voice_away_sfx = obj:createSFXSource(       'art/sound/speech/away.wav',        'AudioGui', 'radar_voice_away', 1)
end

local function playLockedSpeedVoice(dir, mode, vel)
  if dir == "front" then
    obj:playSFXOnce('radar_voice_front', 0, 2.5, 1)
  elseif dir == "rear" then
    obj:playSFXOnce('radar_voice_rear', 0, 2.5, 1)
  end

  if mode == "stationary" then
    obj:playSFXOnce('radar_voice_stationary', 0, 2.5, 1)
  elseif mode == "same" then
    obj:playSFXOnce('radar_voice_same', 0, 2.5, 1)
  elseif mode == "opposite" then
    obj:playSFXOnce('radar_voice_opposite', 0, 2.5, 1)
  end
  
  if vel == "closing" then
    obj:playSFXOnce('radar_voice_closing', 0, 2.5, 1)
  elseif vel == "away" then
    obj:playSFXOnce('radar_voice_away', 0, 2.5, 1)
  end
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

M.init = init
M.playSelectSound = playSelectSound
M.setDopplerSoundOn = setDopplerSoundOn
M.setDopplerSoundPitch = setDopplerSoundPitch

return M
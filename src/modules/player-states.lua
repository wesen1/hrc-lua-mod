---
-- @author wesen
-- @copyright 2021 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local PlayerStates = {}

local playerStates = {}


local function initializePlayerStateIfRequired(_clientNumber)
  if (playerStates[_clientNumber] == nil) then
    playerStates[_clientNumber] = {}
  end
end

local function deletePlayerState(_clientNumber)
  playerStates[_clientNumber] = nil
end

local function setPlayerStateProperty(_clientNumber, _propertyName, _propertyValue)
  initializePlayerStateIfRequired(_clientNumber)
  playerStates[_clientNumber][_propertyName] = _propertyValue
end

local function getPlayerStateProperty(_clientNumber, _propertyName)
  initializePlayerStateIfRequired(_clientNumber)
  return playerStates[_clientNumber][_propertyName]
end


function PlayerStates.setLoggedIn(_clientNumber, _isLoggedIn)
  setPlayerStateProperty(_clientNumber, "loggedIn", _isLoggedIn)
end

function PlayerStates.isLoggedIn(_clientNumber)
  return (getPlayerStateProperty(_clientNumber, "loggedIn") == true)
end

function PlayerStates.clear(_clientNumber)
  deletePlayerState(_clientNumber)
end


return PlayerStates

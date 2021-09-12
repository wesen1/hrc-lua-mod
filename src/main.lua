---
-- @author wesen
-- @copyright 2021 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

PLUGIN_NAME = "HrC lua mod"
PLUGIN_AUTHOR = "wesen"
PLUGIN_VERSION = "0.1"

--
-- Add the path to the AC-ClientOutput src directory to the package path list
-- to be able to omit this path portion in require() calls (Needed for the AC-ClientOutput classes)
--
package.path = package.path .. ";lua/scripts/external/AC-ClientOutput-1.1.1/src/?.lua"

package.path = package.path .. ";lua/scripts/external/md5.lua-1.1.0/?.lua"

-- Configure AC-ClientOutput
local ClientOutputFactory = require "AC-ClientOutput.ClientOutputFactory"
ClientOutputFactory.getInstance():configure({
    fontConfigFileName = "FontDefault",
    maximumLineWidth = 10000
})

local Ladders = require "lua.scripts.modules.ladders"
local Commands = require "lua.scripts.modules.commands"
local Accounts = require "lua.scripts.modules.accounts"
local PlayerStates = require "lua.scripts.modules.player-states"


local ladders = {
  ["kills"] = {
    ["titleName"] = "KILL",
    ["pointsName"] = "kills"
  },

  ["headshots"] = {
    ["titleName"] = "HEADSHOT",
    ["pointsName"] = "heads"
  },

  ["gibs"] = {
    ["titleName"] = "GIB",
    ["pointsName"] = "gibs"
  },

  ["flags"] = {
    ["titleName"] = "FLAG",
    ["pointsName"] = "flags"
  }
}

local function isLoginAllowed(_playerName)

  for clientNumber in players() do
    if (getname(clientNumber) == _playerName and
        PlayerStates.isLoggedIn(clientNumber)
    ) then
      return "Error: Account is already used by Player #" .. clientNumber
    end
  end

  return true

end

local commands = {
  ["!blacklist"] = {
    ["level"] = Commands.LEVELS.ADMIN,
    ["execute"] = function(_executorClientNumber, _ip, _reason)
      clientprint(_executorClientNumber, "TODO: Blacklist " .. _ip .. " with reason " .. _reason)
    end
  },


  ["!login"] = {
    ["level"] = Commands.LEVELS.UNARMED,
    ["execute"] = function(_executorClientNumber, _password)

      if (PlayerStates.isLoggedIn(_executorClientNumber)) then
        clientprint(_executorClientNumber, "Error: Already logged in")
        return
      end

      local executorPlayerName = getname(_executorClientNumber)
      local isLoginAllowedResult = isLoginAllowed(executorPlayerName)
      if (isLoginAllowedResult ~= true) then
        clientprint(_executorClientNumber, isLoginAllowedResult)
        return
      end


      local loginResult = Accounts.tryLogin(
        executorPlayerName,
        _password
      )

      if (loginResult == true) then
        PlayerStates.setLoggedIn(_executorClientNumber, true)
        clientprint(_executorClientNumber, "Successfully logged in")
      else
        clientprint(_executorClientNumber, "Error: " .. loginResult)
      end

    end
  },

  ["!logout"] = {
    ["level"] = Commands.LEVELS.UNARMED,
    ["execute"] = function(_executorClientNumber)

      if (PlayerStates.isLoggedIn(_executorClientNumber)) then
        PlayerStates.setLoggedIn(_executorClientNumber, false)
        clientprint(_executorClientNumber, "Successfully logged out")
      else
        clientprint(_executorClientNumber, "Error: Not logged in")
      end

    end
  },

  ["!register"] = {
    ["level"] = Commands.LEVELS.UNARMED,
    ["execute"] = function(_executorClientNumber, _password)

      local result = Accounts.tryRegister(
        getip(_executorClientNumber),
        getname(_executorClientNumber),
        _password
      )

      if (result == true) then
        PlayerStates.setLoggedIn(_executorClientNumber, true)
        clientprint(_executorClientNumber, "Succesfully registered")
      else
        clientprint(_executorClientNumber, "Error: " .. result)
      end

    end
  },


  ["!ladders"] = {
    ["level"] = Commands.LEVELS.UNARMED,
    ["execute"] = function(_executorClientNumber)

      local ladderDisplayOrder = {
        "kills",
        "headshots",
        "gibs",
        "flags"
      }

      local outputRows = {
        [1] = {}
      }
      for _, ladderName in ipairs(ladderDisplayOrder) do

        local ladderConfig = ladders[ladderName]
        local ladderScores = Ladders.getSortedLadderScores(ladderName, 5)

        local ladderOutputRows = {
          [1] = {
            ladderConfig["titleName"] .. " LADDER",
            ladderConfig["pointsName"]
          }
        }

        for rank, score in ipairs(ladderScores) do
          table.insert(
            ladderOutputRows,
            {
              rank .. ") ".. score["playerName"],
              score["points"]
            }
          )
        end

        if (#ladderScores == 0) then
          table.insert(
            ladderOutputRows,
            {
              "No scores",
              " "
            }
          )
        end

        table.insert(outputRows[1], ladderOutputRows)

      end

      local clientOutputTable = ClientOutputFactory.getInstance():getClientOutputTable(outputRows)
      for _, outputRow in ipairs(clientOutputTable:getOutputRows()) do
        clientprint(_executorClientNumber, outputRow)
      end

    end
  }
}


function onInit()
  logline(ACLOG_INFO, "Initializing ladders ...")
  Ladders.initializeLadders(ladders)

  logline(ACLOG_INFO, "Initializing commands ...")
  Commands.initializeCommands(commands)
end


function onPlayerConnect(_actorClientNumber)

  local connectedPlayerName = getname(_actorClientNumber)
  local isLoginAllowedResult = isLoginAllowed(connectedPlayerName)
  if (isLoginAllowedResult ~= true) then
    return
  end

  local autoLoginResult = Accounts.tryAutoLogin(
    getip(_actorClientNumber),
    connectedPlayerName
  )

  if (autoLoginResult == true) then
    PlayerStates.setLoggedIn(_actorClientNumber, true)
    clientprint(_actorClientNumber, "Successfully logged in")
  end

end

function onPlayerDisconnect(_actorClientNumber, _disconnectReason)
  PlayerStates.clear(_actorClientNumber)
end


function onPlayerDeath(_targetClientNumber, _actorClientNumber, _isGib, _weaponId)

  if (_targetClientNumber ~= _actorClientNumber) then
    -- Not a suicide

    Ladders.addPointsToPlayerLadderScore("kills", _actorClientNumber, 1)

    if (_isGib and _weaponId == GUN_SNIPER) then
      Ladders.addPointsToPlayerLadderScore("headshots", _actorClientNumber, 1)
    end

    if (_isGib and _weaponId == GUN_GRENADE) then
      Ladders.addPointsToPlayerLadderScore("gibs", _actorClientNumber, 1)
    end

  end

end

function onFlagAction(_actorClientNumber, _flagActionId)

  if (_flagActionId == FA_SCORE and getgamemode() == GM_CTF) then
    Ladders.addPointsToPlayerLadderScore("flags", _actorClientNumber, 1)
  end

end

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

-- Configure AC-ClientOutput
local ClientOutputFactory = require "AC-ClientOutput.ClientOutputFactory"
ClientOutputFactory.getInstance():configure({
    fontConfigFileName = "FontDefault",
    maximumLineWidth = 10000
})

local Ladders = require "lua.scripts.modules.ladders"
local Commands = require "lua.scripts.modules.commands"


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

local commands = {
  ["!blacklist"] = {
    ["level"] = Commands.LEVELS.ADMIN,
    ["execute"] = function(_executorClientNumber, _ip, _reason)
      clientprint(_executorClientNumber, "TODO: Blacklist " .. _ip .. " with reason " .. _reason)
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

---
-- @author wesen
-- @copyright 2021 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Ladders = {}

local ladders = {}

local function isValidLadderName(_ladderName)
  return (ladders[_ladderName] ~= nil)
end


-- Storage

local function getConfigNameForLadder(_ladderName)
  return "ladder_" .. _ladderName
end

local function loadAllLadderScores(_ladderName)

  if (isValidLadderName(_ladderName)) then

    -- Load the scores as a list in the format { <player name> => <score data>, ... }
    local scores = cfg.totable(getConfigNameForLadder(_ladderName))
    if (scores == nil) then
      return {}
    end

    local sortedScores = {}
    for playerName, scoreData in pairs(scores) do
      table.insert(
        sortedScores,
        {
          ["playerName"] = playerName,
          ["points"] = tonumber(scoreData),
          ["rank"] = -1
        }
      )
    end

    table.sort(
      sortedScores,
      function(_scoreA, _scoreB)
        return _scoreA["points"] > _scoreB["points"]
      end
    )

    for rank, score in ipairs(sortedScores) do
      score["rank"] = rank
    end

    return sortedScores

  else
    return {}
  end

end

local function setPlayerLadderScore(_ladderName, _playerScore)

  if (isValidLadderName(_ladderName)) then
    cfg.setvalue(getConfigNameForLadder(_ladderName), _playerScore["playerName"], _playerScore["points"])
  end

end


-- Cached ladder data

function Ladders.getPlayerLadderScore(_ladderName, _playerName)

  if (isValidLadderName(_ladderName)) then
    for _, score in ipairs(ladders[_ladderName]["scores"]) do
      if (score["playerName"] == _playerName) then
        return score
      end
    end
  end

  return {
    ["playerName"] = _playerName,
    ["points"] = 0,
    ["rank"] = #ladders[_ladderName]["scores"] + 1
  }

end

local function updatePlayerLadderRanks(_ladderName, _playerScore)

  if (isValidLadderName(_ladderName)) then
    local scores = ladders[_ladderName]["scores"]

    local currentRank = _playerScore["rank"]

    -- Find the new rank
    local newRank = currentRank
    for i = currentRank - 1, 1, -1 do
      if (scores[i]["points"] < _playerScore["points"]) then
        newRank = i
      else
        break
      end
    end

    for i = currentRank - 1, newRank, -1 do
      scores[i]["rank"] = i + 1
      scores[i + 1] = scores[i]
    end

    _playerScore["rank"] = newRank
    scores[newRank] = _playerScore

  end

end

function Ladders.addPointsToPlayerLadderScore(_ladderName, _playerClientNumber, _points)

  if (isValidLadderName(_ladderName)) then
    local playerName = getname(_playerClientNumber)
    local playerScore = Ladders.getPlayerLadderScore(_ladderName, playerName)

    -- Update the cached player score
    playerScore["points"] = playerScore["points"] + _points
    updatePlayerLadderRanks(_ladderName, playerScore)

    -- Write the updated player score to the cfg file
    setPlayerLadderScore(_ladderName, playerScore)
  end

end

function Ladders.getSortedLadderScores(_ladderName, _numberOfScores)

  if (isValidLadderName(_ladderName)) then
    return { unpack(ladders[_ladderName]["scores"], 1, _numberOfScores) }
  else
    return {}
  end

end


-- Config

function Ladders.initializeLadders(_ladders)

  ladders = {}
  for ladderName, ladderConfig in pairs(_ladders) do
    logline(ACLOG_INFO, "Initializing ladder: " .. ladderName)
    ladders[ladderName] = {
      ["scores"] = loadAllLadderScores(ladderName)
    }
  end

end


return Ladders

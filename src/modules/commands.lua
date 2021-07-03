---
-- @author wesen
-- @copyright 2021 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Commands = {}

Commands.LEVELS = {
  ["UNARMED"] = 1,
  ["ADMIN"] = 2
}

local commands = {}

function Commands.initializeCommands(_commandConfigs)

  commands = {}
  for commandName, commandConfig in pairs(_commandConfigs) do
    logline(ACLOG_INFO, "Initializing command: " .. commandName)
    commands[commandName] = {
      ["level"] = commandConfig["level"] or Commands.LEVELS.UNARMED,
      ["execute"] = commandConfig["execute"]
    }
  end

end

local function isPlayerAllowedToExecuteCommand(_clientNumber, _commandConfig)

  if (_commandConfig["level"] == Commands.LEVELS.UNARMED) then
    return true
  elseif (_commandConfig["level"] == Commands.LEVELS.ADMIN) then
    return isadmin(_clientNumber)
  else
    return false
  end

end


function onPlayerSayText(_senderClientNumber, _message)

  if (_message:match("^![^!]+") ~= nil) then
    -- Message starts with "!" and is followed by something other than "!", this should be a command

    -- Parse the command message
    local commandName
    local commandParameters = { _senderClientNumber }

    local isFirstWord = true
    for word in _message:gmatch("%S+") do
      if (isFirstWord) then
        isFirstWord = false
        commandName = word:lower() -- case insensitive command names
      else
        table.insert(commandParameters, word)
      end
    end

    -- Find the matching command and execute it
    local command = commands[commandName]
    if (not command) then
      clientprint(_senderClientNumber, "Unknown command: " .. commandName)

    elseif (not isPlayerAllowedToExecuteCommand(_senderClientNumber, command)) then
      clientprint(_senderClientNumber, "No permission to execute command: " .. commandName)
    else
      command["execute"](unpack(commandParameters))
    end

    -- Prevent the command message from being sent to other players
    return PLUGIN_BLOCK

  end

end


return Commands

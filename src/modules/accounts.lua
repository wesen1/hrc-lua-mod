---
-- @author wesen
-- @copyright 2021 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local md5 = require "md5"

local Accounts = {}


-- Storage

local function setAccountPassword(_playerName, _password)
  cfg.setvalue("player_account_passwords", _playerName, md5.sumhexa(_password))
end

local function setAutologinPlayerNameForIp(_ip, _playerName)
  cfg.setvalue("player_account_autologin_ips", _ip, _playerName)
end

local function getAccountPasswordHashSum(_playerName)
  return cfg.getvalue("player_account_passwords", _playerName)
end

local function getAutologinPlayerNameForIp(_ip)
  return cfg.getvalue("player_account_autologin_ips", _ip)
end


-- Creation and login helpers

local function accountForPlayerNameExists(_playerName)
  return (getAccountPasswordHashSum(_playerName) ~= nil)
end

local function createAccount(_ip, _playerName, _password)
  setAccountPassword(_playerName, _password)
  setAutologinPlayerNameForIp(_ip, _playerName)
end

local function isPasswordCorrect(_playerName, _password)
  local md5SumOfSavedPassword = getAccountPasswordHashSum(_playerName)
  local md5SumOfEnteredPassword = md5.sumhexa(_password)

  return (md5SumOfSavedPassword == md5SumOfEnteredPassword)
end


function Accounts.tryRegister(_ip, _playerName, _password)

  if (accountForPlayerNameExists(_playerName)) then
    return "Account for player name already exists"
  else
    createAccount(_ip, _playerName, _password)
    return true
  end

end

function Accounts.tryLogin(_playerName, _password)

  if (not accountForPlayerNameExists(_playerName)) then
    return "You are not registered"
  elseif (not isPasswordCorrect(_playerName, _password)) then
    return "Incorrect password"
  else
    return true
  end

end

function Accounts.tryAutoLogin(_ip, _playerName)

  if (getAutologinPlayerNameForIp(_ip) == _playerName) then
    return true
  else
    return false
  end

end


return Accounts

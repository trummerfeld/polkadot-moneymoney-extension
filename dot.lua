-- Polkadot Network Extension for MoneyMoney
-- Gets Address Balances from Subscan API (free tier)
--
-- Copyright (c) 2022 trummerfeld
-- Feel free to buy me a coffee
-- 1xHjUKhSYxjHHR9iEXN5YBXuxZsHPkUcZV4nJ2DeGX6UV6w - DOT
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking{
  version = 2.0,
  url = "https://assethub-polkadot.api.subscan.io/api/v2/scan/account/tokens",
  description = "Include your Polkadot Holdings in MoneyMoney by providing comma separated polkadot wallet addresses as the username. Data is provided via free tier of Subscan API.",
  services = { "Polkadot" }
}

local dotAddress
local connection = Connection()
local currency = "EUR"
local SUBSCAN_API_KEY = "4d0c8ba32dde4a06bda83d52af49120f"

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Polkadot"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
  dotAddress = username:gsub("%s+", "")
end

function ListAccounts(knownAccounts)
  local account = {
    name = "Polkadot",
    accountNumber = "Polkadot",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount(account, since)
  local s = {}
  local usdToEur = getUsdToEurRate()

  for address in string.gmatch(dotAddress, '([^,]+)') do
    local tokens = getTokensForAddress(address)
    
    for _, token in ipairs(tokens) do
      processToken(token, address, s, usdToEur)
    end
  end

  return {securities = s}
end

function EndSession()
end

-- Get USD to EUR conversion rate
function getUsdToEurRate()
  local response = JSON(connection:request("GET", "https://min-api.cryptocompare.com/data/price?fsym=USD&tsyms=EUR", {}))
  return response:dictionary()['EUR']
end

-- Fetch tokens from Subscan API
function getTokensForAddress(address)
  local headers = {
    ["Content-Type"] = "application/json",
    ["x-api-key"] = SUBSCAN_API_KEY
  }
  
  local body = '{"address":"' .. address .. '"}'
  local response = JSON(connection:request("POST", "https://assethub-polkadot.api.subscan.io/api/v2/scan/account/tokens", body, headers))
  local data = response:dictionary()
  
  if data and data.data and data.data.native then
    return data.data.native
  end
  
  return {}
end

-- Convert balance using decimals from API
function convertBalance(balance, decimals)
  local divisor = 10 ^ decimals
  return balance / divisor
end

-- Convert USD price to EUR
function convertPriceToEur(usdPrice, usdToEur)
  if usdPrice and usdToEur then
    return usdPrice * usdToEur
  end
  return nil
end

-- Token handlers dispatch table
local tokenHandlers = {
  Native = function(token, address, securities, usdToEur)
    local decimals = token.decimals or 10
    local symbol = token.symbol or "DOT"
    local priceUsd = token.price
    local priceEur = convertPriceToEur(priceUsd, usdToEur)
    
    -- Free balance
    if token.balance and tonumber(token.balance) > 0 then
      local freeBalance = convertBalance(tonumber(token.balance), decimals)
      table.insert(securities, {
        name = symbol .. " Free (" .. address .. ")",
        currency = nil,
        market = "cryptocompare",
        quantity = freeBalance,
        price = priceEur,
      })
    end
    
    -- Bonded balance
    if token.bonded and tonumber(token.bonded) > 0 then
      local bondedBalance = convertBalance(tonumber(token.bonded), decimals)
      table.insert(securities, {
        name = symbol .. " Bonded (" .. address .. ")",
        currency = nil,
        market = "cryptocompare",
        quantity = bondedBalance,
        price = priceEur,
      })
    end
    
    -- Unbonding balance
    if token.unbonding and tonumber(token.unbonding) > 0 then
      local unbondingBalance = convertBalance(tonumber(token.unbonding), decimals)
      table.insert(securities, {
        name = symbol .. " Unbonding (" .. address .. ")",
        currency = nil,
        market = "cryptocompare",
        quantity = unbondingBalance,
        price = priceEur,
      })
    end
    
    -- Reserved balance
    if token.reserved and tonumber(token.reserved) > 0 then
      local reservedBalance = convertBalance(tonumber(token.reserved), decimals)
      table.insert(securities, {
        name = symbol .. " Reserved (" .. address .. ")",
        currency = nil,
        market = "cryptocompare",
        quantity = reservedBalance,
        price = priceEur,
      })
    end
  end,
  
  Assets = function(token, address, securities, usdToEur)
    local decimals = token.decimals or 10
    local symbol = token.symbol or "UNKNOWN"
    local priceUsd = token.price
    local priceEur = convertPriceToEur(priceUsd, usdToEur)
    
    if token.balance and tonumber(token.balance) > 0 then
      local balance = convertBalance(tonumber(token.balance), decimals)
      table.insert(securities, {
        name = symbol .. " (" .. address .. ")",
        currency = nil,
        market = "cryptocompare",
        quantity = balance,
        price = priceEur,
      })
    end
  end,
  
  ForeignAssets = function(token, address, securities, usdToEur)
    local decimals = token.decimals or 10
    local symbol = token.symbol or "UNKNOWN"
    local priceUsd = token.price
    local priceEur = convertPriceToEur(priceUsd, usdToEur)
    
    if token.balance and tonumber(token.balance) > 0 then
      local balance = convertBalance(tonumber(token.balance), decimals)
      table.insert(securities, {
        name = symbol .. " (Foreign) (" .. address .. ")",
        currency = nil,
        market = "cryptocompare",
        quantity = balance,
        price = priceEur,
      })
    end
  end,
  
  NFT = function(token, address, securities, usdToEur)
    -- Skip NFTs entirely
  end
}

-- Process a single token
function processToken(token, address, securities, usdToEur)
  local category = token.category or "Native"
  local handler = tokenHandlers[category]
  
  if handler then
    handler(token, address, securities, usdToEur)
  end
end
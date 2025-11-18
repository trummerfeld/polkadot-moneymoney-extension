-- Mock MoneyMoney environment for testing
local dkjson = require("dkjson")

-- Mock WebBanking function
function WebBanking(config)
  _G.WebBankingConfig = config
end

-- Mock ProtocolWebBanking constant
_G.ProtocolWebBanking = "ProtocolWebBanking"

-- Mock Connection class
local MockConnection = {}
MockConnection.__index = MockConnection

-- Singleton instance for testing
local sharedConnectionInstance = nil

function MockConnection:new()
  local instance = {
    requests = {},
    responses = {}
  }
  setmetatable(instance, MockConnection)
  return instance
end

function MockConnection:request(method, url, ...)
  local args = {...}
  local request = {
    method = method,
    url = url,
    args = args
  }
  table.insert(self.requests, request)

  -- Check if there's a mocked response
  local response = self.responses[url]
  if response then
    return response
  end

  -- Default empty response
  return "{}"
end

function MockConnection:mockResponse(url, responseData)
  self.responses[url] = responseData
end

function MockConnection:reset()
  self.requests = {}
  self.responses = {}
end

function Connection()
  -- Return singleton instance for testing
  if not sharedConnectionInstance then
    sharedConnectionInstance = MockConnection:new()
  end
  return sharedConnectionInstance
end

-- Function to reset the shared connection (useful for tests)
function ResetConnection()
  if sharedConnectionInstance then
    sharedConnectionInstance:reset()
  end
  sharedConnectionInstance = nil
end

-- Mock JSON function
local MockJSON = {}
MockJSON.__index = MockJSON

function MockJSON:new(jsonString)
  local instance = {
    data = dkjson.decode(jsonString)
  }
  setmetatable(instance, MockJSON)
  return instance
end

function MockJSON:dictionary()
  return self.data
end

function JSON(jsonString)
  return MockJSON:new(jsonString)
end

return {
  Connection = Connection,
  JSON = JSON,
  WebBanking = WebBanking
}

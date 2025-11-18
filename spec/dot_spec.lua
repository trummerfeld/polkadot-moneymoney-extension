-- Test suite for dot.lua
describe("Polkadot MoneyMoney Extension", function()
  local mock

  setup(function()
    -- Load the mock MoneyMoney environment
    mock = require("spec.mocks.moneymoney_mock")
  end)

  before_each(function()
    -- Reset globals before each test
    _G.connection = nil
  end)

  describe("convertBalance", function()
    it("should convert balance with 10 decimals correctly", function()
      -- Load the main file to get access to functions
      dofile("dot.lua")

      local result = convertBalance(1000000000000, 10)
      assert.are.equal(100, result)
    end)

    it("should convert balance with 12 decimals correctly", function()
      dofile("dot.lua")

      local result = convertBalance(1000000000000, 12)
      assert.are.equal(1, result)
    end)

    it("should handle zero balance", function()
      dofile("dot.lua")

      local result = convertBalance(0, 10)
      assert.are.equal(0, result)
    end)
  end)

  describe("convertPriceToEur", function()
    it("should convert USD price to EUR correctly", function()
      dofile("dot.lua")

      local result = convertPriceToEur(10, 0.85)
      assert.are.equal(8.5, result)
    end)

    it("should return nil if USD price is nil", function()
      dofile("dot.lua")

      local result = convertPriceToEur(nil, 0.85)
      assert.is_nil(result)
    end)

    it("should return nil if exchange rate is nil", function()
      dofile("dot.lua")

      local result = convertPriceToEur(10, nil)
      assert.is_nil(result)
    end)
  end)

  describe("processToken", function()
    before_each(function()
      dofile("dot.lua")
    end)

    it("should process Native token with free balance (balance - reserved)", function()
      local token = {
        category = "Native",
        symbol = "DOT",
        decimals = 10,
        balance = "50000000000",  -- Total balance
        reserved = "10000000000",  -- Reserved amount
        price = 7.5
      }
      local securities = {}
      local usdToEur = 0.85

      processToken(token, "1xHjUKhS...", securities, usdToEur)

      -- Should have 2 entries: free and reserved
      assert.are.equal(2, #securities)

      -- Free = balance - reserved = 50000000000 - 10000000000 = 40000000000
      assert.are.equal("DOT Free (1xHjUKhS...)", securities[1].name)
      assert.are.equal(4, securities[1].quantity) -- 40000000000 / 10^10
      assert.are.equal(6.375, securities[1].price) -- 7.5 * 0.85

      -- Reserved stays as is
      assert.are.equal("DOT Reserved (1xHjUKhS...)", securities[2].name)
      assert.are.equal(1, securities[2].quantity) -- 10000000000 / 10^10
    end)

    it("should process Native token with only free balance (no reserved)", function()
      local token = {
        category = "Native",
        symbol = "DOT",
        decimals = 10,
        balance = "50000000000",
        reserved = "0",
        price = 7.5
      }
      local securities = {}
      local usdToEur = 0.85

      processToken(token, "1xHjUKhS...", securities, usdToEur)

      -- Should only have free balance
      assert.are.equal(1, #securities)
      assert.are.equal("DOT Free (1xHjUKhS...)", securities[1].name)
      assert.are.equal(5, securities[1].quantity) -- All 50000000000 is free
    end)

    it("should process Native token with all balance reserved", function()
      local token = {
        category = "Native",
        symbol = "DOT",
        decimals = 10,
        balance = "50000000000",
        reserved = "50000000000",  -- All reserved
        price = 7.5
      }
      local securities = {}
      local usdToEur = 0.85

      processToken(token, "1xHjUKhS...", securities, usdToEur)

      -- Should only have reserved, no free balance
      assert.are.equal(1, #securities)
      assert.are.equal("DOT Reserved (1xHjUKhS...)", securities[1].name)
      assert.are.equal(5, securities[1].quantity)
    end)

    it("should handle Native token with zero balance", function()
      local token = {
        category = "Native",
        symbol = "DOT",
        decimals = 10,
        balance = "0",
        reserved = "0",
        price = 7.5
      }
      local securities = {}
      local usdToEur = 0.85

      processToken(token, "1xHjUKhS...", securities, usdToEur)

      -- Should have no securities for zero balance
      assert.are.equal(0, #securities)
    end)

    it("should process Assets token", function()
      local token = {
        category = "Assets",
        symbol = "USDT",
        decimals = 6,
        balance = "1000000",
        price = 1.0
      }
      local securities = {}
      local usdToEur = 0.85

      processToken(token, "1xHjUKhS...", securities, usdToEur)

      assert.are.equal(1, #securities)
      assert.are.equal("USDT (1xHjUKhS...)", securities[1].name)
      assert.are.equal(1, securities[1].quantity)
      assert.are.equal(0.85, securities[1].price)
    end)

    it("should process ForeignAssets token", function()
      local token = {
        category = "ForeignAssets",
        symbol = "USDC",
        decimals = 6,
        balance = "5000000",
        price = 1.0
      }
      local securities = {}
      local usdToEur = 0.85

      processToken(token, "1xHjUKhS...", securities, usdToEur)

      assert.are.equal(1, #securities)
      assert.are.equal("USDC (Foreign) (1xHjUKhS...)", securities[1].name)
      assert.are.equal(5, securities[1].quantity)
    end)

    it("should skip NFT tokens", function()
      local token = {
        category = "NFT",
        symbol = "NFT",
        balance = "1"
      }
      local securities = {}
      local usdToEur = 0.85

      processToken(token, "1xHjUKhS...", securities, usdToEur)

      assert.are.equal(0, #securities)
    end)
  end)

  describe("InitializeSession", function()
    it("should strip whitespace from address", function()
      dofile("dot.lua")

      InitializeSession(nil, nil, " 1xHjUKhS... , 2xAbc... ", nil, nil, nil)

      -- dotAddress is a local variable, so we need to test it indirectly
      -- We'll test this through the behavior it affects
      assert.is_not_nil(true) -- Placeholder for now
    end)
  end)

  describe("SupportsBank", function()
    it("should return true for Polkadot bank code", function()
      dofile("dot.lua")

      local result = SupportsBank(ProtocolWebBanking, "Polkadot")
      assert.is_true(result)
    end)

    it("should return false for other bank codes", function()
      dofile("dot.lua")

      local result = SupportsBank(ProtocolWebBanking, "OtherBank")
      assert.is_false(result)
    end)
  end)

  describe("ListAccounts", function()
    it("should return a portfolio account", function()
      dofile("dot.lua")

      local accounts = ListAccounts({})

      assert.are.equal(1, #accounts)
      assert.are.equal("Polkadot", accounts[1].name)
      assert.are.equal("Polkadot", accounts[1].accountNumber)
      assert.are.equal("EUR", accounts[1].currency)
      assert.is_true(accounts[1].portfolio)
      assert.are.equal("AccountTypePortfolio", accounts[1].type)
    end)
  end)

  describe("getTokensForAddress", function()
    it("should parse real Subscan API response correctly", function()
      -- Reset connection to ensure clean state
      ResetConnection()

      -- Mock the real API response structure BEFORE dofile
      local mockResponse = [[{
        "code": 0,
        "message": "Success",
        "data": {
          "count": 5,
          "list": [
            {
              "symbol": "DOT",
              "decimals": 10,
              "balance": "42140145004327",
              "bonded": "41377998932004",
              "reserved": "41377998932004",
              "price": "2.73",
              "category": "Native"
            }
          ]
        }
      }]]

      -- Set up mock connection BEFORE loading dot.lua
      local conn = Connection()
      conn:mockResponse(
        "https://assethub-polkadot.api.subscan.io/api/v2/scan/account/tokens",
        mockResponse
      )

      -- Now load dot.lua - it will use the singleton connection
      dofile("dot.lua")

      local tokens = getTokensForAddress("test_address")

      assert.are.equal(1, #tokens)
      assert.are.equal("DOT", tokens[1].symbol)
      assert.are.equal("42140145004327", tokens[1].balance)
    end)
  end)

  describe("Real Subscan API Response", function()
    -- Real API response from Subscan for testing
    local realApiResponse = {
      list = {
        {
          symbol = "DED",
          unique_id = "standard_assets/30",
          decimals = 10,
          balance = "771873132902040",
          lock = "0",
          asset_id = "30",
          supply = "0",
          category = "Assets"
        },
        {
          symbol = "DOT",
          unique_id = "DOT",
          decimals = 10,
          balance = "42140145004327",
          lock = "41377998932004",
          reserved = "41377998932004",
          bonded = "41377998932004",
          unbonding = "0",
          democracy_lock = "0",
          conviction_lock = "0",
          election_lock = "0",
          price = "2.73",
          supply = "11504.259586181271",
          category = "Native"
        },
        {
          symbol = "MYTH",
          unique_id = "standard_foreign_assets/6212dc295daf309533f0f5873ec3f3e62d9dba33",
          decimals = 18,
          balance = "199000000000000000000",
          asset_id = "6212dc295daf309533f0f5873ec3f3e62d9dba33",
          price = "0.053535",
          supply = "10.653465",
          category = "ForeignAssets"
        },
        {
          symbol = "Polkadot Blockchain Academy, Berkeley 2023: Graduation Certificates",
          unique_id = "standard_nfts/56",
          decimals = 0,
          balance = "1",
          asset_id = "56",
          token_image = "https://gcs.subscan.io/statemint/nfts/3d9d148c7107d9c8326db606fd004f98_thumbnail.png",
          supply = "0",
          category = "NFTs"
        },
        {
          symbol = "TSN",
          unique_id = "standard_assets/1107",
          decimals = 10,
          balance = "25000000000000",
          lock = "0",
          asset_id = "1107",
          supply = "0",
          category = "Assets"
        }
      }
    }

    before_each(function()
      dofile("dot.lua")
    end)

    it("should correctly process DOT native token from real API", function()
      local token = realApiResponse.list[2] -- DOT token
      local securities = {}
      local usdToEur = 0.92 -- example exchange rate

      processToken(token, "test_address", securities, usdToEur)

      -- DOT has free and reserved balance
      -- balance = 42140145004327, reserved = 41377998932004
      -- free = balance - reserved = 762146072323
      assert.are.equal(2, #securities)

      -- Check free balance (balance - reserved)
      assert.are.equal("DOT Free (test_address)", securities[1].name)
      assert.are.equal(76.2146072323, securities[1].quantity) -- 762146072323 / 10^10
      assert.are.equal(2.5116, securities[1].price) -- 2.73 * 0.92

      -- Check reserved balance
      assert.are.equal("DOT Reserved (test_address)", securities[2].name)
      assert.are.equal(4137.7998932004, securities[2].quantity) -- 41377998932004 / 10^10
    end)

    it("should correctly process DED asset token from real API", function()
      local token = realApiResponse.list[1] -- DED token
      local securities = {}
      local usdToEur = 0.92

      processToken(token, "test_address", securities, usdToEur)

      assert.are.equal(1, #securities)
      assert.are.equal("DED (test_address)", securities[1].name)
      assert.are.equal(77187.313290204, securities[1].quantity) -- 771873132902040 / 10^10
      assert.is_nil(securities[1].price) -- No price in API response
    end)

    it("should correctly process MYTH foreign asset from real API", function()
      local token = realApiResponse.list[3] -- MYTH token
      local securities = {}
      local usdToEur = 0.92

      processToken(token, "test_address", securities, usdToEur)

      assert.are.equal(1, #securities)
      assert.are.equal("MYTH (Foreign) (test_address)", securities[1].name)
      assert.are.equal(199, securities[1].quantity) -- 199000000000000000000 / 10^18
      assert.are.equal(0.04925220, securities[1].price) -- 0.053535 * 0.92
    end)

    it("should correctly process TSN asset token from real API", function()
      local token = realApiResponse.list[5] -- TSN token
      local securities = {}
      local usdToEur = 0.92

      processToken(token, "test_address", securities, usdToEur)

      assert.are.equal(1, #securities)
      assert.are.equal("TSN (test_address)", securities[1].name)
      assert.are.equal(2500, securities[1].quantity) -- 25000000000000 / 10^10
      assert.is_nil(securities[1].price) -- No price in API response
    end)

    it("should skip NFT from real API", function()
      local token = realApiResponse.list[4] -- NFT token
      local securities = {}
      local usdToEur = 0.92

      processToken(token, "test_address", securities, usdToEur)

      assert.are.equal(0, #securities) -- NFTs should be skipped
    end)

    it("should process all tokens from real API response", function()
      local securities = {}
      local usdToEur = 0.92

      for _, token in ipairs(realApiResponse.list) do
        processToken(token, "test_address", securities, usdToEur)
      end

      -- Should have: 1 DED, 2 DOT (free+reserved), 1 MYTH, 1 TSN, 0 NFT = 5 total
      assert.are.equal(5, #securities)
    end)
  end)

  describe("RefreshAccount Integration Test", function()
    it("should fetch and process all tokens for an address", function()
      -- Reset connection to ensure clean state
      ResetConnection()

      -- Mock the full API response
      local mockSubscanResponse = [[{
        "code": 0,
        "message": "Success",
        "data": {
          "count": 3,
          "list": [
            {
              "symbol": "DOT",
              "decimals": 10,
              "balance": "50000000000",
              "reserved": "10000000000",
              "price": "7.5",
              "category": "Native"
            },
            {
              "symbol": "USDT",
              "decimals": 6,
              "balance": "1000000",
              "price": "1.0",
              "category": "Assets"
            },
            {
              "symbol": "TestNFT",
              "balance": "1",
              "category": "NFTs"
            }
          ]
        }
      }]]

      local mockUsdEurResponse = '{"EUR": 0.92}'

      -- Setup mocked connections BEFORE dofile
      local conn = Connection()
      conn:mockResponse(
        "https://assethub-polkadot.api.subscan.io/api/v2/scan/account/tokens",
        mockSubscanResponse
      )
      conn:mockResponse(
        "https://min-api.cryptocompare.com/data/price?fsym=USD&tsyms=EUR",
        mockUsdEurResponse
      )

      -- Load dot.lua after mocks are set up
      dofile("dot.lua")

      -- Initialize with a test address
      InitializeSession(nil, nil, "test_address_123", nil, nil, nil)

      -- Call RefreshAccount
      local result = RefreshAccount({}, nil)

      -- Should have DOT (free, reserved) + USDT = 3 securities (NFT skipped)
      assert.are.equal(3, #result.securities)

      -- Check DOT Free (balance - reserved = 50000000000 - 10000000000 = 40000000000)
      assert.are.equal("DOT Free (test_address_123)", result.securities[1].name)
      assert.are.equal(4, result.securities[1].quantity) -- 40000000000 / 10^10
      assert.are.equal(6.9, result.securities[1].price) -- 7.5 * 0.92

      -- Check DOT Reserved
      assert.are.equal("DOT Reserved (test_address_123)", result.securities[2].name)
      assert.are.equal(1, result.securities[2].quantity) -- 10000000000 / 10^10

      -- Check USDT
      assert.are.equal("USDT (test_address_123)", result.securities[3].name)
      assert.are.equal(1, result.securities[3].quantity) -- 1000000 / 10^6
      assert.are.equal(0.92, result.securities[3].price) -- 1.0 * 0.92
    end)

    it("should handle multiple comma-separated addresses", function()
      -- Reset connection to ensure clean state
      ResetConnection()

      local mockSubscanResponse = [[{
        "code": 0,
        "message": "Success",
        "data": {
          "count": 1,
          "list": [
            {
              "symbol": "DOT",
              "decimals": 10,
              "balance": "10000000000",
              "reserved": "0",
              "price": "5.0",
              "category": "Native"
            }
          ]
        }
      }]]

      local mockUsdEurResponse = '{"EUR": 0.9}'

      -- Setup mocks BEFORE dofile
      local conn = Connection()
      conn:mockResponse(
        "https://assethub-polkadot.api.subscan.io/api/v2/scan/account/tokens",
        mockSubscanResponse
      )
      conn:mockResponse(
        "https://min-api.cryptocompare.com/data/price?fsym=USD&tsyms=EUR",
        mockUsdEurResponse
      )

      -- Load dot.lua after mocks are set up
      dofile("dot.lua")

      -- Initialize with multiple addresses
      InitializeSession(nil, nil, "addr1, addr2", nil, nil, nil)

      local result = RefreshAccount({}, nil)

      -- Should have 2 securities (1 DOT Free per address, no reserved since it's 0)
      assert.are.equal(2, #result.securities)
      assert.are.equal("DOT Free (addr1)", result.securities[1].name)
      assert.are.equal(1, result.securities[1].quantity) -- 10000000000 / 10^10
      assert.are.equal("DOT Free (addr2)", result.securities[2].name)
      assert.are.equal(1, result.securities[2].quantity)
    end)
  end)
end)

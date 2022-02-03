-- Polkadot Network Extension for MoneyMoney
-- Gets Address Balances from Blockchair API (free tier)
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
    version = 1.0,
    url = "https://api.blockchair.com/polkadot/raw/address/",
    description = "Include your Polkadot Holdings in MoneyMoney by providing comma separated polkadot wallet addresses as the username. Data is provided via free tier of BLockchai API.",
    services= { "Polkadot" }
  }
  
  local dotAddress
  local connection = Connection()
  local currency = "EUR"
  
  function SupportsBank (protocol, bankCode)
    return protocol == ProtocolWebBanking and bankCode == "Polkadot"
  end
  
  function InitializeSession (protocol, bankCode, username, username2, password, username3)
    dotAddress = username:gsub("%s+", "")
  end
  
  function ListAccounts (knownAccounts)
    local account = {
      name = "Polkadot",
      accountNumber = "Polkadot",
      currency = currency,
      portfolio = true,
      type = "AccountTypePortfolio"
    }
  
    return {account}
  end
  
  function RefreshAccount (account, since)
    local s = {}
    prices = requestDotPrice()
  
    for address in string.gmatch(dotAddress, '([^,]+)') do
      dotQuantity = requestDotQuantityForDotAddress(address)
  
      s[#s+1] = {
        name = "DOT (Polkadot Network) " .. address,
        currency = nil,
        market = "cryptocompare",
        quantity = convertDots(dotQuantity),
        price = prices,
      }
    end
  
    return {securities = s}
  end
  
  function EndSession ()
  end
  
  function requestDotPrice()
    response = JSON(connection:request("GET", cryptocompareRequestUrl(), {}))
    return response:dictionary()['EUR']
  end
  
  
  function requestDotQuantityForDotAddress(dotAddress)
    response = JSON(connection:request("GET",PolkadotRequestUrl(dotAddress), {}))
    return response:dictionary()["data"][dotAddress]["address"]["balance"]["free"]
  end
  
  function cryptocompareRequestUrl()
    return "https://min-api.cryptocompare.com/data/price?fsym=DOT&tsyms=EUR"
  end

  function PolkadotRequestUrl(dotAddress)
    return "https://api.blockchair.com/polkadot/raw/address/" .. dotAddress
  end

  function convertDots(dots)
    return dots / 10000000000
  end
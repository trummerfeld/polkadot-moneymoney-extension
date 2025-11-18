# Polkadot Network Extension for MoneyMoney

Fetches Polkadot address balances from the Subscan API (free tier) and displays them as securities in MoneyMoney.

![MoneyMoney screenshot with Polkadot Balance](screenshot.png)

## Installation

### Download Extension

You can get a signed version of this extension from

* my [GitHub Releases page](https://github.com/trummerfeld/polkadot-moneymoney-extension/releases), or
* the [MoneyMoney Extensions page](https://moneymoney-app.com/extensions/)

Once downloaded, move `dot.lua` to your MoneyMoney Extensions folder.

### Account Setup in MoneyMoney

* Add a new account of type “Polkadot”
* Enter one or more DOT addresses with comma separation (e.g. `1xHjUKhSYxjHHR9iEXN5YBXuxZsHPkUcZV4nJ2DeGX6UV6w`)
* Enter anything as the password (the dialog wants to have a password..)
**Note:** You can can enter anything for password, e.g. `test`

## Limitations

* EUR is the base currency for this Extension
* This Extension works with MoneyMoney >=2.4.9 (from Beta onwards)

## Development

### Testing

This project uses [busted](https://olivinelabs.com/busted/) for testing the Lua implementation.

#### Setup Testing Environment (First Time Only)

```bash
# Install Lua and LuaRocks (macOS)
brew install lua luarocks

# Install testing framework
luarocks install busted
```

#### Running Tests

```bash
# Run all tests
busted

# Run with verbose output
busted --verbose

# Watch mode (requires watchexec)
brew install watchexec
watchexec -e lua busted
```

#### Test Coverage

The test suite includes 23+ tests covering:
- Balance conversion with different decimals (10, 12, 18)
- USD to EUR price conversion
- All token types: Native (DOT), Assets, ForeignAssets, NFTs
- Multiple balance types: free, bonded, unbonding, reserved
- Real Subscan API response processing
- Edge cases (zero balances, nil prices)

See `spec/dot_spec.lua` for the full test suite.
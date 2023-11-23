# ens-market

**Me learning to test ENS with foundry**

## How It Works

The ENSMarket contract is provided with an interface of the [ENS: ETH Registrar Controller (ETHRC)](https://etherscan.io/address/0x253553366da8546fc250f225fe3d25d0c782303b), for more info on the ETHRC visit [docs.ens.domains/contract-api-reference/.eth-permanent-registrar/controller](https://docs.ens.domains/contract-api-reference/.eth-permanent-registrar/controller).

```solidity
  import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";

  ...

  IETHRC immutable i_IETHRC;

  constructor(address _IETHERC) payable {
      i_IETHRC = IETHRC(_IETHERC);
  }
```

Then within [ENSMarket.sol](https://github.com/Pryority/ens-market/blob/main/src/ENSMarket.sol), a custom function is created that interacts with the ETHRC based on the methods provided by the interface. In this example, the available() method provided by the ETHRC is called by ENSMarket.

```solidity
  function isAvailableName(string calldata name) external returns (bool) {
        return i_IETHRC.available(name);
    }
```

## Testing

Here is the stack trace of the setUp() method in ENSMarket.t.sol:

```zshrc
  [PASS] test_available() (gas: 16915)
Traces:
  [736104] ENSMarketTest::setUp()
    ├─ [399935] → new DeployENSMarket@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   └─ ← 1887 bytes of code
    ├─ [257183] DeployENSMarket::run()
    │   ├─ [87792] → new HelperConfig@0x104fBc016F4bb334D775a19E8A6510109AC63E00
    │   │   └─ ← 327 bytes of code
    │   ├─ [381] HelperConfig::activeNetworkConfig() [staticcall]
    │   │   └─ ← 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72
    │   ├─ [0] VM::startBroadcast()
    │   │   └─ ← ()
    │   ├─ [100745] → new ENSMarket@0x90193C961A926261B756D1E5bb255e67ff9498A1
    │   │   └─ ← 502 bytes of code
    │   ├─ [0] VM::stopBroadcast()
    │   │   └─ ← ()
    │   └─ ← ENSMarket: [0x90193C961A926261B756D1E5bb255e67ff9498A1]
    ├─ [0] VM::addr(70564938991660933374592024341600875602376452319261984317470407481576058979585 [7.056e76]) [staticcall]
    │   └─ ← alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6]
    ├─ [0] VM::label(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], "alice")
    │   └─ ← ()
    └─ ← ()
```

And then, here is the stack trace of the isAvailableName() method being tested. This test passes because when compiling and running the test, I specified the **--fork-url** flag that provides a RPC URL to simulate the transaction(s) in the test that are coming from [ENSMarket.t.sol](https://github.com/Pryority/ens-market/blob/main/test/ENSMarket.t.sol):

```zshrc
    [16915] ENSMarketTest::test_available()
    ├─ [11200] ENSMarket::isAvailableName("nick")
    │   ├─ [7709] 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72::available("nick")
    │   │   ├─ [2606] 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85::available(42219085255511335250589442208301538195142221433306354426240614732612795430543 [4.221e76]) [staticcall]
    │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    │   └─ ← false
    └─ ← ()
```

## Documentation

<https://book.getfoundry.sh/>

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil

```shell
anvil
```

### Deploy

```shell
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```

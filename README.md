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

Here is a stack trace of the setUp() method [ENSMarket.t.sol](https://github.com/Pryority/ens-market/blob/main/test/ENSMarket.t.sol#L25):

```zsh
[2464362] ENSMarketTest::setUp()
    ├─ [1291046] → new DeployENSMarket@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   └─ ← 6338 bytes of code
    ├─ [1093400] DeployENSMarket::run()
    │   ├─ [252978] → new HelperConfig@0x104fBc016F4bb334D775a19E8A6510109AC63E00
    │   │   └─ ← 820 bytes of code
    │   ├─ [665] HelperConfig::activeNetworkConfig() [staticcall]
    │   │   └─ ← 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72, 0x0635513f179D50A207757E05759CbD106d7dFcE8, 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
    │   ├─ [0] VM::startBroadcast()
    │   │   └─ ← ()
    │   ├─ [770408] → new ENSMarket@0x90193C961A926261B756D1E5bb255e67ff9498A1
    │   │   └─ ← 3845 bytes of code
    │   ├─ [0] VM::stopBroadcast()
    │   │   └─ ← ()
    │   └─ ← ENSMarket: [0x90193C961A926261B756D1E5bb255e67ff9498A1]
    ├─ [0] VM::addr(70564938991660933374592024341600875602376452319261984317470407481576058979585 [7.056e76]) [staticcall]
    │   └─ ← alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6]
    ├─ [0] VM::label(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], "alice")
    │   └─ ← ()
    └─ ← ()
```

To [register](https://github.com/Pryority/ens-market/blob/main/test/ENSMarket.t.sol#L25) a name:

- 1. ENS Contracts need a commited name.

  ```solidity
  Commitment memory commitment = Commitment({
    label: bytes32(keccak256(bytes(name))),
    owner: alice,
    duration: 31536000,
    secret: bytes32(keccak256(bytes("my_secret"))),
    resolver: address(0),
    data: data,
    reverseRecord: false,
    ownerControlledFuses: 0
  });

  bytes32 commitHash = market.createCommitment(
    name,
    commitment.owner,
    commitment.duration,
    commitment.secret,
    commitment.resolver,
    commitment.data,
    commitment.reverseRecord,
    commitment.ownerControlledFuses
  );

  market.commit(commitHash);
  ```

- 2. Wait for at least 60 seconds, but less than 86400 seconds (24 hr) to register the name.

  In the test we fast-forward time 60 seconds after calling `market.commit(commitHash)`.

  ```solidity
  uint registerTime = commitTime + 61;
  vm.warp(registerTime);
  ```

- 3. The market contract get's the cost of the price to rent the name from the ENS: Price Oracle.

  The value sent in the transaction to register must be greater than this cost.

  ```solidity
  IPriceOracle.Price memory price = market.getRentPrice("my_new_name");
  uint256 cost = price.base + price.premium;
  ```

  ```solidity
  function register(...) public payable {
    uint256 cost = price.base + price.premium;

    if (msg.value < cost) {
      revert InsufficientValue();
    }

    ...

  }
  ```

- 4. Having the rental cost, we can call market to register with the values we need to get the ENS token we want.

  ```soldiity
  market.register{value: cost}(
    name,
    alice,
    31536000,
    bytes32(keccak256(bytes("my_secret"))),
    address(0),
    data,
    false,
    0
  );
  ```

`test_register()` Stack Trace

```zsh
[252319] ENSMarketTest::test_register()
    ├─ [0] VM::startPrank(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6])
    │   └─ ← ()
    ├─ [0] VM::deal(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], 1000000000000000000 [1e18])
    │   └─ ← ()
    ├─ emit log_named_uint(key: "Commit Time", val: 1700855604 [1.7e9])
    ├─ [26360] ENSMarket::getRentPrice("my_new_name") [staticcall]
    │   ├─ [22569] 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72::rentPrice("my_new_name", 31536000 [3.153e7]) [staticcall]
    │   │   ├─ [2505] 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85::nameExpires(66878621533378929571864897251546994675403720721589284185685379034090347664240 [6.687e76]) [staticcall]
    │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   ├─ [12943] ExponentialPremiumPriceOracle::price("my_new_name", 0, 31536000 [3.153e7]) [staticcall]
    │   │   │   ├─ [2246] DummyOracle::latestAnswer() [staticcall]
    │   │   │   │   └─ ← 160000000000 [1.6e11]
    │   │   │   ├─ [246] DummyOracle::latestAnswer() [staticcall]
    │   │   │   │   └─ ← 160000000000 [1.6e11]
    │   │   │   └─ ← Price({ base: 3125000000003490 [3.125e15], premium: 0 })
    │   │   └─ ← 0x000000000000000000000000000000000000000000000000000b1a2bc2ec5da20000000000000000000000000000000000000000000000000000000000000000
    │   └─ ← Price({ base: 3125000000003490 [3.125e15], premium: 0 })
    ├─ [2111] ENSMarket::createCommitment("my_new_name", alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], 31536000 [3.153e7], 0xc7c416a1e7c42f101dad44002093abfa5f65a35d40e573f1a8b49bfc10ea02cf, 0x0000000000000000000000000000000000000000, [], false, 0) [staticcall]
    │   └─ ← 0x8bd90c82dc4101c2f6d33425b84312e49e49bfa3a504780e6f26c9c70f268106
    ├─ [23267] ENSMarket::commit(0x8bd90c82dc4101c2f6d33425b84312e49e49bfa3a504780e6f26c9c70f268106)
    │   ├─ [22630] 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72::commit(0x8bd90c82dc4101c2f6d33425b84312e49e49bfa3a504780e6f26c9c70f268106)
    │   │   └─ ← ()
    │   └─ ← ()
    ├─ [0] VM::warp(1700855665 [1.7e9])
    │   └─ ← ()
    ├─ emit log_named_uint(key: "Register Time", val: 1700855665 [1.7e9])
    ├─ [174556] ENSMarket::register{value: 3125000000003490}("my_new_name", alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], 31536000 [3.153e7], 0xc7c416a1e7c42f101dad44002093abfa5f65a35d40e573f1a8b49bfc10ea02cf, 0x0000000000000000000000000000000000000000, [], false, 0)
    │   ├─ [11546] 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72::rentPrice("my_new_name", 31536000 [3.153e7]) [staticcall]
    │   │   ├─ [505] 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85::nameExpires(66878621533378929571864897251546994675403720721589284185685379034090347664240 [6.687e76]) [staticcall]
    │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   ├─ [8920] ExponentialPremiumPriceOracle::price("my_new_name", 0, 31536000 [3.153e7]) [staticcall]
    │   │   │   ├─ [246] DummyOracle::latestAnswer() [staticcall]
    │   │   │   │   └─ ← 160000000000 [1.6e11]
    │   │   │   ├─ [246] DummyOracle::latestAnswer() [staticcall]
    │   │   │   │   └─ ← 160000000000 [1.6e11]
    │   │   │   └─ ← Price({ base: 3125000000003490 [3.125e15], premium: 0 })
    │   │   └─ ← 0x000000000000000000000000000000000000000000000000000b1a2bc2ec5da20000000000000000000000000000000000000000000000000000000000000000
    │   ├─ [153229] 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72::register{value: 3125000000003490}("my_new_name", alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], 31536000 [3.153e7], 0xc7c416a1e7c42f101dad44002093abfa5f65a35d40e573f1a8b49bfc10ea02cf, 0x0000000000000000000000000000000000000000, [], false, 0)
    │   │   ├─ [505] 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85::nameExpires(66878621533378929571864897251546994675403720721589284185685379034090347664240 [6.687e76]) [staticcall]
    │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   ├─ [8920] ExponentialPremiumPriceOracle::price("my_new_name", 0, 31536000 [3.153e7]) [staticcall]
    │   │   │   ├─ [246] DummyOracle::latestAnswer() [staticcall]
    │   │   │   │   └─ ← 160000000000 [1.6e11]
    │   │   │   ├─ [246] DummyOracle::latestAnswer() [staticcall]
    │   │   │   │   └─ ← 160000000000 [1.6e11]
    │   │   │   └─ ← Price({ base: 3125000000003490 [3.125e15], premium: 0 })
    │   │   ├─ [606] 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85::available(66878621533378929571864897251546994675403720721589284185685379034090347664240 [6.687e76]) [staticcall]
    │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   ├─ [147488] NameWrapper::registerAndWrapETH2LD("my_new_name", alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], 31536000 [3.153e7], 0x0000000000000000000000000000000000000000, 0)
    │   │   │   ├─ [91031] 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85::register(66878621533378929571864897251546994675403720721589284185685379034090347664240 [6.687e76], NameWrapper: [0x0635513f179D50A207757E05759CbD106d7dFcE8], 31536000 [3.153e7])
    │   │   │   │   ├─ [2797] ENSRegistryWithFallback::owner(0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae) [staticcall]
    │   │   │   │   │   └─ ← 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
    │   │   │   │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: NameWrapper: [0x0635513f179D50A207757E05759CbD106d7dFcE8], tokenId: 66878621533378929571864897251546994675403720721589284185685379034090347664240 [6.687e76])
    │   │   │   │   ├─ [25000] ENSRegistryWithFallback::setSubnodeOwner(0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae, 0x93dbf557693acd728ae3fc6f44888362b47822cc3a67b9969a508e82a5239370, NameWrapper: [0x0635513f179D50A207757E05759CbD106d7dFcE8])
    │   │   │   │   │   ├─ emit NewOwner(node: 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae, label: 0x93dbf557693acd728ae3fc6f44888362b47822cc3a67b9969a508e82a5239370, owner: NameWrapper: [0x0635513f179D50A207757E05759CbD106d7dFcE8])
    │   │   │   │   │   └─ ← 0xb06622130280008e40bfcc7f8dfe95793f98a85196abb53e42c5a16474910d3a
    │   │   │   │   ├─ emit NameRegistered(id: 66878621533378929571864897251546994675403720721589284185685379034090347664240 [6.687e76], owner: NameWrapper: [0x0635513f179D50A207757E05759CbD106d7dFcE8], expires: 1732391665 [1.732e9])
    │   │   │   │   └─ ← 0x00000000000000000000000000000000000000000000000000000000674232f1
    │   │   │   ├─ emit TransferSingle(operator: 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72, from: 0x0000000000000000000000000000000000000000, to: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], id: 79787514923140338732460962921823399702127321520420068197196330152815724924218 [7.978e76], value: 1)
    │   │   │   ├─ emit NameWrapped(node: 0xb06622130280008e40bfcc7f8dfe95793f98a85196abb53e42c5a16474910d3a, name: 0x0b6d795f6e65775f6e616d650365746800, owner: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], fuses: 196608 [1.966e5], expiry: 1740167665 [1.74e9])
    │   │   │   └─ ← 1732391665 [1.732e9]
    │   │   ├─ emit NameRegistered(param0: "my_new_name", param1: 0x000000000000000000000000000000000000000000000000000b1a2bc2ec5da2, param2: 0x0000000000000000000000000000000000000000, param3: 1732391665 [1.732e9], param4: 11, param5: 49516547632596947897790984400236102137055570870134426422048736648097895022592 [4.951e76])
    │   │   └─ ← ()
    │   └─ ← ()
    ├─ [0] VM::stopPrank()
    │   └─ ← ()
    └─ ← ()

```

```zsh
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

View a successful registration on Sepolia Testnet: [0xda783735da25e664da2a552673cef849e4fc9a0ca35981d9c70bcbebf1b7be06](https://sepolia.etherscan.io/tx/0xda783735da25e664da2a552673cef849e4fc9a0ca35981d9c70bcbebf1b7be06)

And then, here is the stack trace of the isAvailableName() method being tested. This test passes because when compiling and running the test, I specified the **--fork-url** flag that provides a RPC URL to simulate the transaction(s) in the test that are coming from [ENSMarket.t.sol](https://github.com/Pryority/ens-market/blob/main/test/ENSMarket.t.sol):

```zsh
  [PASS] test_available() (gas: 16915)
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

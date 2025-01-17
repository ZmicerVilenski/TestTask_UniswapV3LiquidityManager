Необходимо написать контракт, который взаимодействует с протоколом UniswapV3.
В контракт подается информация о интересующем пуле (адрес пула), количество первого и второго актива, который необходимо вложить в позицию, а также параметр ширины.
Необходимо вложить заданные объемы в позицию таким образом, чтобы ширина этой позиции равнялась заданному параметру.
Ширину предлагаем считать следующим образом: width = (upperPrice - lowerPrice) * 10000 / (lowerPrice + upperPrice).

Необходимо, чтобы контракт работал для любого uniswap v3 пула вне зависимости от вкладываемых токенов.


forge install OpenZeppelin/openzeppelin-contracts@8e02960 --no-commit
forge install uniswap/v3-periphery --no-commit
forge install uniswap/v3-core --no-commit


## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy
```shell
$ forge script script/DeployUniswapV3LiquidityManager.s.sol    // - local
$ forge script script/DeployUniswapV3LiquidityManager.s.sol --rpc-url $RPC_URL --legacy    // - simulate
$ forge script script/DeployUniswapV3LiquidityManager.s.sol --rpc-url $RPC_URL --broadcast --legacy -vvvv   // - real tx

$ source .env
$ forge script script/DeployUniswapV3LiquidityManager.s.sol --legacy --broadcast --rpc-url $RPC_URL --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY

```
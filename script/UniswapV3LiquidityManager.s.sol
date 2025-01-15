// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/UniswapV3LiquidityManager.sol";
import "@uniswap-v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

contract DeployUniswapV3LiquidityManager is Script {    
    INonfungiblePositionManager positionManager = INonfungiblePositionManager(0x1234567890123456789012345678901234567890);

    function run() external {
        vm.startBroadcast();
        UniswapV3LiquidityManager manager = new UniswapV3LiquidityManager(positionManager);
        console.log("UniswapV3LiquidityManager deployed at:", address(manager));
        vm.stopBroadcast();
    }
}

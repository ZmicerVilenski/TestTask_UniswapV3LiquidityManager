// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/UniswapV3LiquidityManager.sol";

contract DeployUniswapV3LiquidityManager is Script {
    address public constant POSITION_MANAGER = 0x1234567890123456789012345678901234567890; 

    function run() external {
        vm.startBroadcast();
        UniswapV3LiquidityManager manager = new UniswapV3LiquidityManager(POSITION_MANAGER);
        console.log("UniswapV3LiquidityManager deployed at:", address(manager));
        vm.stopBroadcast();
    }
}

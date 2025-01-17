// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.21;
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap-v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicksCalculator} from "./TickCalculator.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UniswapV3LiquidityManager is ReentrancyGuard {

    event LiquidityProvided(address indexed user, uint256 amount0, uint256 amount1);

    INonfungiblePositionManager public positionManager;

    constructor(INonfungiblePositionManager _positionManager) {
        positionManager = _positionManager;
    }

    function provideLiquidity(
        IUniswapV3Pool pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 width
    ) external 
      nonReentrant
      returns (uint256 tokenId, uint128 liquidity, uint256 amount0Used, uint256 amount1Used)
    {
        require(width > 0, "Width must be greater than 0");
        require(amount0Desired != 0 && amount1Desired != 0, "Input amount should not be zero");

        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);

        // Changed Tick math
        // (uint160 sqrtPriceX96, , , , , , ) = uniswapPool.slot0();
        // uint256 currentPrice = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) / (2**192);
        // uint256 lowerPrice = (currentPrice * (10000 - width)) / (10000 + width);
        // uint256 upperPrice = (currentPrice * (10000 + width)) / (10000 - width);
        // int24 tickSpacing = uniswapPool.tickSpacing();
        // int24 lowerTick = _getNearestTick(lowerPrice, tickSpacing);
        // int24 upperTick = _getNearestTick(upperPrice, tickSpacing);
        (int24 lowerTick, int24 upperTick) = TicksCalculator.calculateTickBounds(pool, width);

        IERC20(uniswapPool.token0()).transferFrom(msg.sender, address(this), amount0Desired);
        IERC20(uniswapPool.token1()).transferFrom(msg.sender, address(this), amount1Desired);

        IERC20(uniswapPool.token0()).approve(address(positionManager), amount0Desired);
        IERC20(uniswapPool.token1()).approve(address(positionManager), amount1Desired);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: uniswapPool.token0(),
            token1: uniswapPool.token1(),
            fee: uniswapPool.fee(),
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 1 hours
        });

        (tokenId, liquidity, amount0Used, amount1Used) = positionManager.mint(params);
        emit LiquidityProvided(msg.sender, amount0Used, amount1Used);

        _refundUnusedTokens(uniswapPool.token0(), uniswapPool.token1(), amount0Desired, amount1Desired, amount0Used, amount1Used);

    }

    function _refundUnusedTokens(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Used,
        uint256 amount1Used
    ) internal {
        if (amount0 > amount0Used) {
            IERC20(token0).transfer(msg.sender, amount0 - amount0Used);
        }
        if (amount1 > amount1Used) {
            IERC20(token1).transfer(msg.sender, amount1 - amount1Used);
        }
    }

    // function _getNearestTick(uint256 price, int24 tickSpacing) public pure returns (int24) {
    //     int24 tick = int24(int256(_sqrt(price * 1e18) / (2**96)));
    //     return tick - (tick % tickSpacing);
    // }

    // function _sqrt(uint256 x) internal pure returns (uint256) {
    //     if (x == 0) return 0;
    //     uint256 z = (x + 1) / 2;
    //     uint256 y = x;
    //     while (z < y) {
    //         y = z;
    //         z = (x / z + z) / 2;
    //     }
    //     return y;
    // }
}

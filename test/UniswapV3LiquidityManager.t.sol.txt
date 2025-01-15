// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/UniswapV3LiquidityManager.sol";
import "@uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3LiquidityManagerTest is Test {
    UniswapV3LiquidityManager liquidityManager;
    address positionManager = 0x1234567890123456789012345678901234567890; // Mock address
    address pool =   0x3333333333333333333333333333333333333333; // Mock pool address
    address token0 = 0x1111111111111111111111111111111111111111; // Mock token0 address
    address token1 = 0x2222222222222222222222222222222222222222; // Mock token1 address

    function setUp() public {
        liquidityManager = new UniswapV3LiquidityManager(positionManager);
    }

    function testProvideLiquidity() public {
        uint256 amount0Desired = 1000 ether;
        uint256 amount1Desired = 500 ether;
        uint256 width = 500; // Mock width

        // Mock token balances
        vm.prank(address(this));
        IERC20(token0).approve(address(liquidityManager), amount0Desired);
        vm.prank(address(this));
        IERC20(token1).approve(address(liquidityManager), amount1Desired);

        // Call provideLiquidity
        vm.prank(address(this));
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, width);

        // Assertions
        // Assert that the function executes without reverting and tokens are approved
        assertGt(IERC20(token0).allowance(address(this), address(liquidityManager)), 0);
        assertGt(IERC20(token1).allowance(address(this), address(liquidityManager)), 0);
    }

    function testInvalidWidth() public {
        uint256 amount0Desired = 1000 ether;
        uint256 amount1Desired = 500 ether;
        uint256 invalidWidth = 0;

        vm.expectRevert("Width must be greater than 0");
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, invalidWidth);
    }

    function testInsufficientBalanceToken0() public {
        uint256 amount0Desired = 1000 ether;
        uint256 amount1Desired = 500 ether;
        uint256 width = 500;

        // Mock insufficient balance for token0
        vm.prank(address(this));
        IERC20(token0).approve(address(liquidityManager), amount0Desired);

        vm.expectRevert(); // Expect transaction to revert due to insufficient balance
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, width);
    }

    function testInsufficientBalanceToken1() public {
        uint256 amount0Desired = 1000 ether;
        uint256 amount1Desired = 500 ether;
        uint256 width = 500;

        // Mock insufficient balance for token1
        vm.prank(address(this));
        IERC20(token1).approve(address(liquidityManager), amount1Desired);

        vm.expectRevert(); // Expect transaction to revert due to insufficient balance
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, width);
    }

    function testZeroAmountLiquidity() public {
        uint256 amount0Desired = 0;
        uint256 amount1Desired = 0;
        uint256 width = 500;

        vm.expectRevert(); // Expect revert due to zero amounts
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, width);
    }

    function testWidthCalculations() public {
        uint256 amount0Desired = 1000 ether;
        uint256 amount1Desired = 500 ether;
        uint256 width = 500;

        // Mock the pool's slot0 response
        vm.mockCall(
            pool,
            abi.encodeWithSignature("slot0()"),
            abi.encode(uint160(1 << 96), 0, 0, 0, 0, 0, 0)
        );

        // Call provideLiquidity to ensure proper tick calculation
        vm.prank(address(this));
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, width);

        // No assertions here as we focus on not reverting and mocking behavior
    }

    function testTickCalculation() public view{
        uint256 price = 1 ether;
        int24 tickSpacing = 60;

        int24 calculatedTick = liquidityManager._getNearestTick(price, tickSpacing);
        assertEq(calculatedTick % tickSpacing, 0, "Tick should align with spacing");
    }
}

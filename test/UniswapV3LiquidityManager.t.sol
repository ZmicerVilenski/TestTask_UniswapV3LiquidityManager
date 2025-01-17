// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.21;
pragma solidity =0.7.6;
pragma abicoder v2;

import "../src/UniswapV3LiquidityManager.sol";
import "forge-std/Test.sol";
import "@uniswap-v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap-v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract UniswapV3LiquidityManagerTest is Test {
    uint256 private constant BLOCK_NUM = 21000000;
    string private constant RPC_URL = "https://eth.llamarpc.com";
    address private constant USER = address(1);
    uint256 private constant USDC_AMOUNT = 100000 ether;
    uint256 private constant WETH_AMOUNT = 10 ether;
    uint256 private constant USDC_BALANCE_SLOT = 2;
    address private constant USDC_ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH_MAINNET_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant POSITION_MANAGER_ADDR = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address private constant UNISWAP_V3_POOL_ADDR = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;

    UniswapV3LiquidityManager liquidityManager;
    INonfungiblePositionManager positionManager;
    IUniswapV3Pool pool;

    IERC20 USDC = IERC20(USDC_ADDR);
    IWETH WETH9 = IWETH(WETH_MAINNET_ADDR);

    function setUSDCBalance(address account, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encode(account, uint256(USDC_BALANCE_SLOT)));
        vm.store(address(USDC), slot, bytes32(amount));

        // bytes32 slot1 = vm.load(address(USDC), keccak256(abi.encode(account, uint256(USDC_BALANCE_SLOT))));
        // console.logBytes32(slot1);
        // console.log("USDC_AMOUNT:", USDC_AMOUNT);
        // console.log("amount:", amount);
        // console.log("USDC balace:", USDC.balanceOf(USER));
    }

    function setWETHBalance(address account, uint256 amount) internal {
        vm.deal(account, amount);
        vm.startPrank(account);
        WETH9.deposit{value: amount}();
        vm.stopPrank();
    }

    function approveTokens(address account, uint256 usdtAmount, uint256 wethAmount) internal {
        vm.startPrank(account);
        USDC.approve(address(liquidityManager), usdtAmount);
        WETH9.approve(address(liquidityManager), wethAmount);
        vm.stopPrank();
    }

    function setUp() public {

        vm.createSelectFork(RPC_URL, BLOCK_NUM);

        positionManager = INonfungiblePositionManager(POSITION_MANAGER_ADDR);
        pool = IUniswapV3Pool(UNISWAP_V3_POOL_ADDR);
        liquidityManager = new UniswapV3LiquidityManager(positionManager);

        setUSDCBalance(USER, USDC_AMOUNT);
        setWETHBalance(USER, WETH_AMOUNT);
        approveTokens(USER, USDC_AMOUNT, WETH_AMOUNT);

    }

    function testProvideLiquidity() public {
        uint256 width = 500; 

        vm.prank(USER);
        (uint256 tokenId, uint128 liquidity, uint256 amount0Used, uint256 amount1Used) =
            liquidityManager.provideLiquidity(pool, USDC_AMOUNT, WETH_AMOUNT, width);

        assertGt(uint256(liquidity), 0, "Liquidity should be greater than 0");
        assertGt(tokenId, 0, "Token ID should be greater than 0");
        assertLe(amount0Used, USDC_AMOUNT, "Used more amount0 than provided");
        assertLe(amount1Used, WETH_AMOUNT, "Used more amount1 than provided");
    }

    function testProvideLiquidityWithDifferentWidths() public {
        uint256[] memory widths = new uint256[](3);
        widths[0] = 10;
        widths[1] = 50;
        widths[2] = 100;

        uint256 usdcAmount = USDC_AMOUNT / 10;
        uint256 wethAmount = WETH_AMOUNT / 10;

        for (uint256 i = 0; i < widths.length; i++) {
            vm.prank(USER);
            liquidityManager.provideLiquidity(pool, usdcAmount, wethAmount, widths[i]);
        }
    }

    function testInsufficientBalanceToken1() public {
        uint256 amount0Desired = 1000 ether;
        uint256 amount1Desired = 500 ether;
        uint256 width = 500;

        vm.prank(USER);
        USDC.approve(address(liquidityManager), amount1Desired);

        vm.expectRevert(); 
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, width);
    }

    function testInvalidWidth() public {
        uint256 amount0Desired = 1000 ether;
        uint256 amount1Desired = 500 ether;
        uint256 invalidWidth = 0;

        vm.expectRevert("Width must be greater than 0");
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, invalidWidth);
    }

    function testZeroAmountLiquidity() public {
        uint256 amount0Desired = 0;
        uint256 amount1Desired = 0;
        uint256 width = 500;

        vm.expectRevert(); 
        liquidityManager.provideLiquidity(pool, amount0Desired, amount1Desired, width);
    }

    function testProvideLiquidityWithInvalidAmounts() public {
        uint256 width = 1;

        vm.prank(USER);
        vm.expectRevert("Input amount should not be zero");
        liquidityManager.provideLiquidity(pool, 0, 0, width);
    }

    function testProvideLiquidityWithInsufficientBalance() public {
        uint256 width = 1;
        setUSDCBalance(USER, USDC_AMOUNT / 2);

        vm.prank(USER);
        vm.expectRevert();
        liquidityManager.provideLiquidity(pool, USDC_AMOUNT, WETH_AMOUNT, width);
    }

    function testPartialFills() public {
        uint256 width = 1;
        uint256 largeUSDCAmount = USDC_AMOUNT * 10; 
        vm.prank(USER);
        vm.expectRevert();
        liquidityManager.provideLiquidity(pool, largeUSDCAmount, WETH_AMOUNT, width);
    }

    function testprovideLiquidityWithoutApproval() public {

        uint256 width = 1;
        vm.startPrank(USER);
        USDC.approve(address(liquidityManager), 0);
        WETH9.approve(address(liquidityManager), 0);
        vm.stopPrank();

        vm.prank(USER);
        vm.expectRevert();
        liquidityManager.provideLiquidity(pool, USDC_AMOUNT, WETH_AMOUNT, width);

    }
}

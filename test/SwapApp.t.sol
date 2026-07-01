// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import "forge-std/Test.sol";
import "../src/SwapApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SwappAppTest is Test {
    SwapApp app;
    address uniswapV2SwappRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address user = 0xB45323118e29e3C33c4a906dD8ce9d9CF443D380; 
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; 
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; 

    function setUp() public {
        app = new SwapApp(uniswapV2SwappRouterAddress);
    }

    function testHasBeenDeployedCorrectly() public view {
        assertEq(app.V2Router02Address(), uniswapV2SwappRouterAddress);
    }

    function testSwapTokensCorrectly() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6;
        uint256 amountOutMin = 1; 
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;

        IERC20(USDT).approve(address(app), amountIn);
        
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);
        
        app.swapTokens(amountIn, amountOutMin, path, block.timestamp + 1000);
        
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(user);
        assertGt(daiBalanceAfter, daiBalanceBefore);
        vm.stopPrank();
    }

    function testSwapTokensRevertsOnExpiredDeadline() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;

        IERC20(USDT).approve(address(app), amountIn);
        
       
        vm.expectRevert(); 
        app.swapTokens(amountIn, 1, path, block.timestamp - 1);
        vm.stopPrank();
    }

    function testSwapTokensRevertsOnSlippage() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6;
        
        uint256 amountOutMin = type(uint256).max; 
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;

        IERC20(USDT).approve(address(app), amountIn);
        
        vm.expectRevert();
        app.swapTokens(amountIn, amountOutMin, path, block.timestamp + 1000);
        vm.stopPrank();
    }

    function testSwapTokensRevertsOnInsufficientAllowance() public {
        vm.startPrank(user);
        uint256 amountIn = 5 * 1e6;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;


        vm.expectRevert();
        app.swapTokens(amountIn, 1, path, block.timestamp + 1000);
        vm.stopPrank();
    }

    function testFuzzSwapTokens(uint256 amountIn) public {

    vm.assume(amountIn > 0 && amountIn < 1000 * 1e6); 

    vm.startPrank(user);
    
   
    uint256 userBalance = IERC20(USDT).balanceOf(user);
    vm.assume(amountIn <= userBalance);

    IERC20(USDT).approve(address(app), amountIn);
    
    address[] memory path = new address[](2);
    path[0] = USDT;
    path[1] = DAI;


    app.swapTokens(amountIn, 0, path, block.timestamp + 1000);
    
    vm.stopPrank();
}
}
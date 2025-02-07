// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MiniFactory.sol";
import "../src/MiniRouter.sol";
import "../src/MiniPair.sol";
import "../src/mock/MockToken.sol";

contract MiniDexTest is Test {
    MiniFactory public factory;
    MiniRouter public router;
    MockToken public tokenA;
    MockToken public tokenB;
    address public pair;

    address public user1 = address(1);
    address public user2 = address(2);

    function setUp() public {
        // Deploy contracts
        factory = new MiniFactory();
        router = new MiniRouter(address(factory));

        // Create tokens ensuring tokenA has a smaller address than tokenB
        tokenA = new MockToken("Token A", "TKNA");
        vm.etch(address(0x1000), address(tokenA).code);
        tokenA = MockToken(address(0x1000));

        tokenB = new MockToken("Token B", "TKNB");
        vm.etch(address(0x2000), address(tokenB).code);
        tokenB = MockToken(address(0x2000));

        // Create pair with 0.3% fee
        pair = factory.createPair(address(tokenA), address(tokenB), 30);

        // Setup initial balances
        tokenA.mint(user1, 1000 ether);
        tokenB.mint(user1, 1000 ether);
        tokenA.mint(user2, 1000 ether);
        tokenB.mint(user2, 1000 ether);

        // Approve tokens for router
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);

        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, user1, block.timestamp);

        assertEq(tokenA.balanceOf(pair), 100 ether);
        assertEq(tokenB.balanceOf(pair), 100 ether);
        assertEq(tokenA.balanceOf(user1), 900 ether);
        assertEq(tokenB.balanceOf(user1), 900 ether);

        vm.stopPrank();
    }

    function testSwap() public {
        // First add liquidity
        vm.startPrank(user1);
        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, user1, block.timestamp);
        vm.stopPrank();

        // Verify initial state
        assertEq(MiniPair(pair).reserve0(), 100 ether);
        assertEq(MiniPair(pair).reserve1(), 100 ether);
        assertEq(tokenA.balanceOf(user2), 1000 ether);
        assertEq(tokenB.balanceOf(user2), 1000 ether);

        // Calculate expected amount out
        uint256 amountIn = 1 ether;
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * 100 ether;
        uint256 denominator = (100 ether * 1000) + amountInWithFee;
        uint256 expectedAmountOut = numerator / denominator;

        // Prepare path for swap
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Perform swap
        vm.startPrank(user2);
        router.swapExactTokensForTokens(amountIn, expectedAmountOut, path, user2, block.timestamp);
        vm.stopPrank();

        // Verify final state
        assertEq(tokenA.balanceOf(user2), 1000 ether - amountIn);
        assertTrue(tokenB.balanceOf(user2) > 1000 ether);
        assertTrue(tokenB.balanceOf(user2) == 1000 ether + expectedAmountOut);
    }

    function testRemoveLiquidity() public {
        // First add liquidity
        vm.startPrank(user1);
        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, user1, block.timestamp);

        // Record balances before removal
        uint256 lpBalance = MiniPair(pair).balanceOf(user1);
        uint256 tokenABefore = tokenA.balanceOf(user1);
        uint256 tokenBBefore = tokenB.balanceOf(user1);

        // Approve LP tokens for pair contract
        MiniPair(pair).approve(pair, lpBalance);

        // Remove half of liquidity
        uint256 halfLiquidity = lpBalance / 2;
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            halfLiquidity,
            0, // min amount A
            0, // min amount B
            user1,
            block.timestamp
        );

        // Verify amounts received
        assertEq(tokenA.balanceOf(user1), tokenABefore + amountA);
        assertEq(tokenB.balanceOf(user1), tokenBBefore + amountB);
        assertEq(MiniPair(pair).balanceOf(user1), lpBalance - halfLiquidity);
        assertEq(MiniPair(pair).totalSupply(), lpBalance - halfLiquidity);

        // Verify reserves are updated
        assertEq(MiniPair(pair).reserve0(), 50 ether);
        assertEq(MiniPair(pair).reserve1(), 50 ether);

        vm.stopPrank();
    }
}

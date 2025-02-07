// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MiniFactory.sol";
import "../src/MiniRouter.sol";
import "../src/MiniPair.sol";
import "../src/mock/MockToken.sol";

contract MiniSwapTest is Test {
    MiniFactory public factory;
    MiniRouter public router;
    MockToken public tokenA;
    MockToken public tokenB;
    MockToken public tokenC;
    address public pair;
    address public pair1;

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

        tokenC = new MockToken("Token C", "TKNC");
        vm.etch(address(0x3000), address(tokenC).code);
        tokenC = MockToken(address(0x3000));

        // Create pair with 0.3% fee
        pair = factory.createPair(address(tokenA), address(tokenB), 30);
        pair1 = factory.createPair(address(tokenC), address(tokenA), 30);
        assertEq(factory.allPairsLength(), 2);

        // Setup initial balances
        tokenA.mint(user1, 1000 ether);
        tokenB.mint(user1, 1000 ether);
        tokenC.mint(user1, 1000 ether);
        tokenA.mint(user2, 1000 ether);
        tokenB.mint(user2, 1000 ether);

        // Approve tokens for router
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        tokenC.approve(address(router), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function testEdgeCases() public {
        vm.startPrank(user1);

        // Add Liquidity
        vm.expectRevert("MiniRouter: EXPIRED");
        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 100 ether, 0, 0, user1, block.timestamp - 1);

        router.addLiquidity(address(tokenC), address(tokenA), 100 ether, 200 ether, 0, 0, user1, block.timestamp);
        router.addLiquidity(address(tokenA), address(tokenB), 100 ether, 200 ether, 0, 0, user1, block.timestamp);

        assertEq(tokenA.balanceOf(pair), 100 ether);
        assertEq(tokenB.balanceOf(pair), 200 ether);
        assertEq(tokenA.balanceOf(user1), 700 ether);
        assertEq(tokenB.balanceOf(user1), 800 ether);
        assertEq(tokenC.balanceOf(pair1), 100 ether);
        assertEq(tokenA.balanceOf(pair1), 200 ether);
        assertEq(tokenC.balanceOf(user1), 900 ether);



        vm.expectRevert("MiniRouter: INSUFFICIENT_B_AMOUNT");
        router.addLiquidity(address(tokenA), address(tokenC), 100, 50, 100, 100, user1, block.timestamp);

        vm.expectRevert("MiniRouter: INSUFFICIENT_A_AMOUNT");
        router.addLiquidity(address(tokenA), address(tokenC), 100, 40, 200, 40, user1, block.timestamp);

        router.addLiquidity(address(tokenC), address(tokenA), 200, 100, 0, 0, user1, block.timestamp);

        // Swap Tokens
        address[] memory invalid_path = new address[](1);
        invalid_path[0] = address(tokenA);
        vm.expectRevert("MiniRouter: INVALID_PATH");
        router.swapExactTokensForTokens(100, 0, invalid_path, user1, block.timestamp);

        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenC);

        vm.expectRevert("MiniRouter: INSUFFICIENT_LIQUIDITY");
        router.swapExactTokensForTokens(100, 0, path, user1, block.timestamp);

        path[0] = address(tokenA);
        vm.expectRevert("MiniRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        router.swapExactTokensForTokens(100, 200, path, user1, block.timestamp);

        vm.expectRevert("MiniRouter: EXPIRED");
        router.swapExactTokensForTokens(100, 200, path, user1, block.timestamp-1);

        router.swapExactTokensForTokens(50 ether, 0, path, user1, block.timestamp);

        // Remove Liquidity
        vm.expectRevert("MiniRouter: EXPIRED");
        router.removeLiquidity(address(tokenA), address(tokenC), 10 ether, 0, 0, user1, block.timestamp-1);

        vm.expectRevert("MiniRouter: PAIR_NOT_FOUND");
        router.removeLiquidity(address(tokenC), address(tokenB), 200 ether, 0, 0, user1, block.timestamp);

        vm.expectRevert("MiniPair: INSUFFICIENT_LIQUIDITY");
        router.removeLiquidity(address(tokenA), address(tokenB), 200 ether, 0, 0, user1, block.timestamp);

        vm.expectRevert("MiniRouter: INSUFFICIENT_A_AMOUNT");
        router.removeLiquidity(address(tokenA), address(tokenB), 50, 100, 100, user1, block.timestamp);

        vm.expectRevert("MiniRouter: INSUFFICIENT_B_AMOUNT");
        router.removeLiquidity(address(tokenA), address(tokenB), 50, 0, 100, user1, block.timestamp);

        router.removeLiquidity(address(tokenA), address(tokenB), 50, 0, 0, user1, block.timestamp);

        uint256[] memory amounts = router.getAmountsOut(100, path);
        assertEq(amounts[0], 100);

        // Create Pair
        vm.expectRevert("MiniFactory: PAIR_EXISTS");
        factory.createPair(address(tokenA), address(tokenC), 30);

        tokenC.mint(user1, 1000 ether);
        factory.createPair(address(tokenB), address(tokenC), 30);

        MiniRouter router1 = new MiniRouter(address(factory));
        assertEq(router1.factory(), address(factory));

        vm.stopPrank();
    }
}
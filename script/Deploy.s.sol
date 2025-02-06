// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MiniFactory.sol";
import "../src/MiniRouter.sol";
import "../src/mock/MockToken.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Factory
        MiniFactory factory = new MiniFactory();

        // Deploy Router
        MiniRouter router = new MiniRouter(address(factory));

        // For testing on Sepolia, deploy two mock tokens
        MockToken tokenA = new MockToken("Token A", "TKNA");
        MockToken tokenB = new MockToken("Token B", "TKNB");

        // Create a pair with 0.3% fee (30 basis points)
        factory.createPair(address(tokenA), address(tokenB), 30);

        vm.stopBroadcast();

        console.log("Deployed contracts:");
        console.log("Factory:", address(factory));
        console.log("Router:", address(router));
        console.log("Token A:", address(tokenA));
        console.log("Token B:", address(tokenB));
    }
}

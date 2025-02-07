// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MiniPair.sol";

contract MiniFactory {
    // Mapping to store the address of a pair for two tokens
    mapping(address => mapping(address => address)) public getPair;

    // Array to store all created pairs
    address[] public allPairs;

    // Event emitted when a new pair is created
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 fee);

    /// @notice Creates a new pair of tokens
    /// @param tokenA Address of the first token
    /// @param tokenB Address of the second token
    /// @param fee Fee applied to swaps (in basis points)
    /// @return pair Address of the newly created pair
    function createPair(address tokenA, address tokenB, uint256 fee) external returns (address pair) {
        require(tokenA != tokenB, "MiniFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "MiniFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "MiniFactory: PAIR_EXISTS");

        // Create a new pair
        pair = address(new MiniPair(token0, token1, fee));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // Populate mapping in both directions
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, fee);
    }

    /// @notice Returns the total number of pairs created
    /// @return Total number of pairs
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}
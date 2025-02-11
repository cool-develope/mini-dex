// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MiniFactory.sol";
import "./MiniPair.sol";

contract MiniRouter {
    using SafeERC20 for IERC20;

    // Address of the factory contract
    address public immutable factory;

    /// @notice Constructor to initialize the router
    /// @param _factory Address of the factory contract
    constructor(address _factory) {
        factory = _factory;
    }

    /// @notice Adds liquidity to a pair
    /// @param tokenA Address of the first token
    /// @param tokenB Address of the second token
    /// @param amountADesired Desired amount of tokenA to add
    /// @param amountBDesired Desired amount of tokenB to add
    /// @param amountAMin Minimum amount of tokenA to add
    /// @param amountBMin Minimum amount of tokenB to add
    /// @param to Address to receive the LP tokens
    /// @param deadline Deadline for the transaction
    /// @return amountA Actual amount of tokenA added
    /// @return amountB Actual amount of tokenB added
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(deadline >= block.timestamp, "MiniRouter: EXPIRED");

        address pair = MiniFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "MiniRouter: PAIR_NOT_FOUND");

        (amountA, amountB) = _calculateLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        IERC20(tokenA).transferFrom(msg.sender, address(pair), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(pair), amountB);

        MiniPair(pair).addLiquidity(to);
    }

    /// @notice Removes liquidity from a pair
    /// @param tokenA Address of the first token
    /// @param tokenB Address of the second token
    /// @param liquidity Amount of LP tokens to burn
    /// @param amountAMin Minimum amount of tokenA to receive
    /// @param amountBMin Minimum amount of tokenB to receive
    /// @param to Address to receive the underlying tokens
    /// @param deadline Deadline for the transaction
    /// @return amountA Actual amount of tokenA received
    /// @return amountB Actual amount of tokenB received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(deadline >= block.timestamp, "MiniRouter: EXPIRED");

        address pair = MiniFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "MiniRouter: PAIR_NOT_FOUND");

        (amountA, amountB) = MiniPair(pair).removeLiquidity(liquidity, to);

        require(amountA >= amountAMin, "MiniRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "MiniRouter: INSUFFICIENT_B_AMOUNT");
    }

    /// @notice Swaps tokens in a pair
    /// @param amountIn Amount of input tokens to swap
    /// @param amountOutMin Minimum amount of output tokens to receive
    /// @param path Array of token addresses representing the swap path
    /// @param to Address to receive the output tokens
    /// @param deadline Deadline for the transaction
    /// @return amounts Array of amounts received at each step of the swap
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline >= block.timestamp, "MiniRouter: EXPIRED");
        require(path.length >= 2, "MiniRouter: INVALID_PATH");

        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "MiniRouter: INSUFFICIENT_OUTPUT_AMOUNT");

        IERC20(path[0]).safeTransferFrom(msg.sender, MiniFactory(factory).getPair(path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    /// @notice Calculates the optimal amounts of tokens to add to a pair
    /// @param tokenA Address of the first token
    /// @param tokenB Address of the second token
    /// @param amountADesired Desired amount of tokenA to add
    /// @param amountBDesired Desired amount of tokenB to add
    /// @param amountAMin Minimum amount of tokenA to add
    /// @param amountBMin Minimum amount of tokenB to add
    /// @return amountA Actual amount of tokenA to add
    /// @return amountB Actual amount of tokenB to add
    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        address pair = MiniFactory(factory).getPair(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = _getReserves(pair);

        if (reserve0 == 0 && reserve1 == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserve0, reserve1);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "MiniRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(amountBDesired, reserve1, reserve0);
                require(amountAOptimal <= amountADesired, "MiniRouter: EXCESSIVE_INPUT_AMOUNT");
                require(amountAOptimal >= amountAMin, "MiniRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        for (uint256 i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = _sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];

            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

            // For intermediary swaps, the recipient is the next pair
            address recipient = i < path.length - 2 ? MiniFactory(factory).getPair(path[i + 1], path[i + 2]) : _to;

            MiniPair(MiniFactory(factory).getPair(input, output)).swap(amount0Out, amount1Out, recipient);
        }
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _getReserves(address pair) internal view returns (uint256 reserve0, uint256 reserve1) {
        if (pair == address(0)) return (0, 0);
        reserve0 = MiniPair(pair).reserve0();
        reserve1 = MiniPair(pair).reserve1();
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "MiniRouter: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "MiniRouter: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Calculates the optimal amounts of tokens to receive in a swap
    /// @param amountIn Amount of input tokens
    /// @param path Array of token addresses representing the swap path
    /// @return amounts Array of amounts received at each step of the swap
    function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256[] memory amounts) {
        require(path.length >= 2, "MiniRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 reserve0, uint256 reserve1) = _getReserves(MiniFactory(factory).getPair(path[i], path[i + 1]));
            if (path[i] < path[i+1]) {
                amounts[i + 1] = getAmountOut(amounts[i], reserve0, reserve1);
            } else {
                amounts[i + 1] = getAmountOut(amounts[i], reserve1, reserve0);
            }
        }
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "MiniRouter: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "MiniRouter: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
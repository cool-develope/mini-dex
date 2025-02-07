// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MiniPair is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Address of the factory that created this pair
    address public immutable factory;

    // Addresses of the tokens in the pair
    address public immutable token0;
    address public immutable token1;

    // Fee applied to swaps (in basis points)
    uint256 public immutable fee;

    // Reserves of the tokens in the pool
    uint256 public reserve0;
    uint256 public reserve1;

    // Lock to prevent reentrancy
    uint256 private unlocked = 1;

    /// @notice Constructor to initialize the pair
    /// @param _token0 Address of the first token
    /// @param _token1 Address of the second token
    /// @param _fee Fee applied to swaps (in basis points)
    constructor(address _token0, address _token1, uint256 _fee) ERC20("Mini LP Token", "MINI-LP") {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
    }

    // Modifier to prevent reentrancy
    modifier lock() {
        require(unlocked == 1, "MiniPair: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /// @notice Adds liquidity to the pool
    /// @param to Address to receive the LP tokens
    /// @return liquidity Amount of LP tokens minted
    function addLiquidity(address to) external nonReentrant returns (uint256 liquidity) {
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        require(amount0 > 0 && amount1 > 0, "MiniPair: INSUFFICIENT_INPUT_AMOUNT");

        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0 * amount1);
            _mint(to, liquidity);
        } else {
            uint256 _liquidity0 = amount0 * _totalSupply / _reserve0;
            uint256 _liquidity1 = amount1 * _totalSupply / _reserve1;
            liquidity = _liquidity0 < _liquidity1 ? _liquidity0 : _liquidity1;
            require(liquidity > 0, "MiniPair: INSUFFICIENT_LIQUIDITY_MINTED");
            _mint(to, liquidity);
        }
        _update();
    }

    /// @notice Removes liquidity from the pool
    /// @param liquidity Amount of LP tokens to burn
    /// @param to Address to receive the underlying tokens
    /// @return amount0 Amount of token0 received
    /// @return amount1 Amount of token1 received
    function removeLiquidity(uint256 liquidity, address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        uint256 _totalSupply = totalSupply();
        require (_totalSupply > liquidity, "MiniPair: INSUFFICIENT_LIQUIDITY");
        
        amount0 = (liquidity * reserve0) / _totalSupply;
        amount1 = (liquidity * reserve1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "MiniPair: INSUFFICIENT_LIQUIDITY_BURNED");

        _burn(to, liquidity);
        IERC20(token0).safeTransfer(to, amount0);
        IERC20(token1).safeTransfer(to, amount1);

        _update();
    }

    /// @notice Swaps tokens in the pool
    /// @param amount0Out Amount of token0 to send out
    /// @param amount1Out Amount of token1 to send out
    /// @param to Address to receive the output tokens
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external lock nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "MiniPair: INSUFFICIENT_OUTPUT_AMOUNT");
        require(amount0Out < reserve0 && amount1Out < reserve1, "MiniPair: INSUFFICIENT_LIQUIDITY");

        uint256 balance0Before = reserve0;
        uint256 balance1Before = reserve1;

        if (amount0Out > 0) IERC20(token0).safeTransfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).safeTransfer(to, amount1Out);

        uint256 balance0After = IERC20(token0).balanceOf(address(this));
        uint256 balance1After = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0After - (balance0Before - amount0Out);
        uint256 amount1In = balance1After - (balance1Before - amount1Out);

        require(amount0In > 0 || amount1In > 0, "MiniPair: INSUFFICIENT_INPUT_AMOUNT");

        {
            uint256 balance0Adjusted = (balance0After * 10000) - (amount0In * fee);
            uint256 balance1Adjusted = (balance1After * 10000) - (amount1In * fee);
            require(balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * (10000 ** 2), "MiniPair: K");
        }

        _update();
    }

    /// @notice Updates the reserves of the pool
    function _update() private {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        reserve0 = balance0;
        reserve1 = balance1;
    }

    // Helper function to calculate the square root of a number
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
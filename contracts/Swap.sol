// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

// import "hardhat/console.sol";

contract Swap {
    ISwapRouter public immutable swapRouter;
    address public owner;

    // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    uint256 public ownerFee = 100000; // 10%

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "UA");
        require(_owner != address(0), "ZA");
        owner = _owner;
    }

    function setOwnerFee(uint256 _ownerFee) external {
        require(msg.sender == owner, "UA");
        ownerFee = _ownerFee;
    }

    function swapExactInputSingle(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 amountOutMinimum,
        uint24 poolFee
    ) external returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
        uint256 ownerAmount = (amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
    }

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenIn,
        address tokenOut,
        uint24 poolFee
    ) external returns (uint256 amountIn) {
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountInMaximum
        );

        TransferHelper.safeApprove(
            tokenIn,
            address(swapRouter),
            amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        uint256 ownerAmount = (amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransfer(
                tokenIn,
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }

    function swapExactInputMultihop(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bytes memory path
    ) external returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp + 20000,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        amountOut = swapRouter.exactInput(params);
        uint256 ownerAmount = (amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
    }

    function swapExactOutputMultihop(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenIn,
        address tokenOut,
        bytes memory path
    ) external returns (uint256 amountIn) {
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountInMaximum
        );
        TransferHelper.safeApprove(
            tokenIn,
            address(swapRouter),
            amountInMaximum
        );

        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path: path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        amountIn = swapRouter.exactOutput(params);

        uint256 ownerAmount = (amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(
                tokenIn,
                address(this),
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Swap {
    ISwapRouter public immutable swapRouter;
    address public owner;

    struct ExactInputSingleParams {
        uint256 amountIn;
        address tokenIn;
        address tokenOut;
        uint256 amountOutMinimum;
        uint24 fee;
    }

    struct ExactOutputSingleParams {
        uint256 amountOut;
        uint256 amountInMaximum;
        address tokenIn;
        address tokenOut;
        uint24 fee;
    }

    struct ExactInputMultiParams {
        uint256 amountIn;
        address tokenIn;
        address tokenOut;
        uint256 amountOutMinimum;
        bytes path;
    }

    struct ExactOutputMultiParams {
        uint256 amountOut;
        uint256 amountInMaximum;
        address tokenIn;
        address tokenOut;
        bytes path;
    }

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
        ExactInputSingleParams calldata args
    ) external returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            args.tokenIn,
            msg.sender,
            address(this),
            args.amountIn
        );

        TransferHelper.safeApprove(
            args.tokenIn,
            address(swapRouter),
            args.amountIn
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: args.tokenIn,
                tokenOut: args.tokenOut,
                fee: args.fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: args.amountIn,
                amountOutMinimum: args.amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
        uint256 ownerAmount = (amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(args.tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            args.tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
    }

    function swapExactOutputSingle(
        ExactOutputSingleParams calldata args
    ) external returns (uint256 amountIn) {
        TransferHelper.safeTransferFrom(
            args.tokenIn,
            msg.sender,
            address(this),
            args.amountInMaximum
        );

        TransferHelper.safeApprove(
            args.tokenIn,
            address(swapRouter),
            args.amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: args.tokenIn,
                tokenOut: args.tokenOut,
                fee: args.fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: args.amountOut,
                amountInMaximum: args.amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        uint256 ownerAmount = (args.amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(args.tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            args.tokenOut,
            msg.sender,
            args.amountOut - ownerAmount
        );
        if (amountIn < args.amountInMaximum) {
            TransferHelper.safeApprove(args.tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransfer(
                args.tokenIn,
                msg.sender,
                args.amountInMaximum - amountIn
            );
        }
    }

    function swapExactInputMultihop(
        ExactInputMultiParams calldata args
    ) external returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            args.tokenIn,
            msg.sender,
            address(this),
            args.amountIn
        );

        TransferHelper.safeApprove(
            args.tokenIn,
            address(swapRouter),
            args.amountIn
        );

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: args.path,
                recipient: address(this),
                deadline: block.timestamp + 20000,
                amountIn: args.amountIn,
                amountOutMinimum: args.amountOutMinimum
            });

        amountOut = swapRouter.exactInput(params);
        uint256 ownerAmount = (amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(args.tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            args.tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
    }

    function swapExactOutputMultihop(
        ExactOutputMultiParams calldata args
    ) external returns (uint256 amountIn) {
        TransferHelper.safeTransferFrom(
            args.tokenIn,
            msg.sender,
            address(this),
            args.amountInMaximum
        );
        TransferHelper.safeApprove(
            args.tokenIn,
            address(swapRouter),
            args.amountInMaximum
        );

        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path: args.path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: args.amountOut,
                amountInMaximum: args.amountInMaximum
            });

        amountIn = swapRouter.exactOutput(params);

        uint256 ownerAmount = (args.amountOut * ownerFee) / 1e6;
        TransferHelper.safeTransfer(args.tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
            args.tokenOut,
            msg.sender,
            args.amountOut - ownerAmount
        );
        if (amountIn < args.amountInMaximum) {
            TransferHelper.safeApprove(args.tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(
                args.tokenIn,
                address(this),
                msg.sender,
                args.amountInMaximum - amountIn
            );
        }
    }
}

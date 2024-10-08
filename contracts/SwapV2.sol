// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract SwapV2 {
    IUniswapV2Router02 public swapRouterV2;

    uint256 public constant FEE_DENOMINATOR = 1e6;

    struct SwapExactTokensForTokensV2Params {
        uint amountIn;
        uint amountOutMin;
        address[] path;
        uint deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct SwapTokensForExactTokensV2Params {
        uint amountOut;
        uint amountInMax;
        address[] path;
        uint deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct SwapExactETHForTokensV2Params {
        uint amountOutMin;
        address[] path;
        uint deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct SwapTokensForExactETHV2Params {
        uint amountOut;
        uint amountInMax;
        address[] path;
        uint deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct SwapExactTokensForETHV2Params {
        uint amountIn;
        uint amountOutMin;
        address[] path;
        uint deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct SwapETHForExactTokensV2Params {
        uint amountOut;
        address[] path;
        uint deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    constructor(address _swapRouterV2) {
        swapRouterV2 = IUniswapV2Router02(_swapRouterV2);
    }

    function sweepToken(address tokenAddress, address reciepient) internal {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance > 0) {
            TransferHelper.safeTransfer(tokenAddress, reciepient, balance);
        }
    }

    function sweepNative(address recipient) internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            TransferHelper.safeTransferETH(recipient, balance);
        }
    }

    function swapExactTokensForTokensV2(
        SwapExactTokensForTokensV2Params calldata args
    ) external returns (uint[] memory amounts) {
        address tokenIn = args.path[0];
        address tokenOut = args.path[args.path.length - 1];
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            args.amountIn
        );
        TransferHelper.safeApprove(
            tokenIn,
            address(swapRouterV2),
            args.amountIn
        );
        amounts = swapRouterV2.swapExactTokensForTokens(
            args.amountIn,
            args.amountOutMin,
            args.path,
            address(this),
            args.deadline
        );
        require(amounts.length == args.path.length, "IS");
        uint256 amountOut = amounts[amounts.length - 1];
        uint256 ownerAmount = (amountOut * args.ownerFee) / FEE_DENOMINATOR;

        TransferHelper.safeTransfer(tokenOut, args.owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
        sweepToken(tokenIn, msg.sender);
        sweepToken(tokenOut, msg.sender);
    }

    function swapTokensForExactTokensV2(
        SwapTokensForExactTokensV2Params calldata args
    ) external returns (uint[] memory amounts) {
        address tokenIn = args.path[0];
        address tokenOut = args.path[args.path.length - 1];
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            args.amountInMax
        );
        TransferHelper.safeApprove(
            tokenIn,
            address(swapRouterV2),
            args.amountInMax
        );

        amounts = swapRouterV2.swapTokensForExactTokens(
            args.amountOut,
            args.amountInMax,
            args.path,
            address(this),
            args.deadline
        );
        require(amounts.length == args.path.length, "IS");
        uint256 amountIn = amounts[amounts.length - 1];
        uint256 ownerAmount = (args.amountOut * args.ownerFee) /
            FEE_DENOMINATOR;
        TransferHelper.safeTransfer(tokenOut, args.owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            args.amountOut - ownerAmount
        );
        if (amountIn < args.amountInMax) {
            uint256 returnAmount = args.amountInMax - amountIn;
            TransferHelper.safeApprove(tokenIn, address(swapRouterV2), 0);
            TransferHelper.safeTransfer(tokenIn, msg.sender, returnAmount);
        }
        sweepToken(tokenIn, msg.sender);
        sweepToken(tokenOut, msg.sender);
    }

    function swapExactETHForTokensV2(
        SwapExactETHForTokensV2Params calldata args
    ) external payable returns (uint[] memory amounts) {
        address tokenOut = args.path[args.path.length - 1];
        amounts = swapRouterV2.swapExactETHForTokens{value: msg.value}(
            args.amountOutMin,
            args.path,
            address(this),
            args.deadline
        );
        require(amounts.length == args.path.length, "IS");
        uint256 amountOut = amounts[amounts.length - 1];
        uint256 ownerAmount = (amountOut * args.ownerFee) / FEE_DENOMINATOR;

        TransferHelper.safeTransfer(tokenOut, args.owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            amountOut - ownerAmount
        );
        sweepToken(tokenOut, msg.sender);
        sweepNative(msg.sender);
    }

    function swapTokensForExactETHV2(
        SwapTokensForExactETHV2Params calldata args
    ) external returns (uint[] memory amounts) {
        address tokenIn = args.path[0];
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            args.amountInMax
        );
        TransferHelper.safeApprove(
            tokenIn,
            address(swapRouterV2),
            args.amountInMax
        );
        amounts = swapRouterV2.swapTokensForExactETH(
            args.amountOut,
            args.amountInMax,
            args.path,
            address(this),
            args.deadline
        );
        require(amounts.length == args.path.length, "IS");
        uint256 amountIn = amounts[amounts.length - 1];
        uint256 ownerAmount = (args.amountOut * args.ownerFee) /
            FEE_DENOMINATOR;
        TransferHelper.safeTransferETH(args.owner, ownerAmount);
        TransferHelper.safeTransferETH(
            msg.sender,
            args.amountOut - ownerAmount
        );
        if (amountIn < args.amountInMax) {
            uint256 returnAmount = args.amountInMax - amountIn;
            TransferHelper.safeApprove(tokenIn, address(swapRouterV2), 0);
            TransferHelper.safeTransfer(tokenIn, msg.sender, returnAmount);
        }
        sweepToken(tokenIn, msg.sender);
        sweepNative(msg.sender);
    }

    function swapExactTokensForETHV2(
        SwapExactTokensForETHV2Params calldata args
    ) external returns (uint[] memory amounts) {
        address tokenIn = args.path[0];
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            args.amountIn
        );
        TransferHelper.safeApprove(
            tokenIn,
            address(swapRouterV2),
            args.amountIn
        );

        amounts = swapRouterV2.swapExactTokensForETH(
            args.amountIn,
            args.amountOutMin,
            args.path,
            address(this),
            args.deadline
        );
        require(amounts.length == args.path.length, "IS");
        uint256 amountOut = amounts[amounts.length - 1];
        uint256 ownerAmount = (amountOut * args.ownerFee) / FEE_DENOMINATOR;

        TransferHelper.safeTransferETH(args.owner, ownerAmount);
        TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
        sweepToken(tokenIn, msg.sender);
        sweepNative(msg.sender);
    }

    function swapETHForExactTokensV2(
        SwapETHForExactTokensV2Params calldata args
    ) external payable returns (uint[] memory amounts) {
        address tokenOut = args.path[args.path.length - 1];
        amounts = swapRouterV2.swapETHForExactTokens{value: msg.value}(
            args.amountOut,
            args.path,
            address(this),
            args.deadline
        );
        require(amounts.length == args.path.length, "IS");
        uint256 amountIn = amounts[amounts.length - 1];
        uint256 ownerAmount = (args.amountOut * args.ownerFee) /
            FEE_DENOMINATOR;
        TransferHelper.safeTransfer(tokenOut, args.owner, ownerAmount);
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            args.amountOut - ownerAmount
        );
        if (amountIn < msg.value)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
        sweepToken(tokenOut, msg.sender);
        sweepNative(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Swap is Ownable, ReentrancyGuard {
    ISwapRouter public immutable swapRouter;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        uint256 deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMaximum;
        uint256 amountOut;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        uint256 deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct ExactInputMultiParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMinimum;
        bytes path;
        uint256 deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    struct ExactOutputMultiParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMaximum;
        uint256 amountOut;
        bytes path;
        uint256 deadline;
        address owner;
        uint256 ownerFee; // 10000 = 1%, 100000 = 10%, 1000000 = 100%
    }

    address public immutable wethAddress;

    constructor(ISwapRouter _swapRouter, address _wethAddress) {
        swapRouter = _swapRouter;
        wethAddress = _wethAddress;
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

    function swapExactInputSingle(
        ExactInputSingleParams calldata args
    ) external payable nonReentrant returns (uint256 amountOut) {
        if (args.tokenIn == wethAddress) {
            require(msg.value == args.amountIn, "IV");
            IWETH9(wethAddress).deposit{value: args.amountIn}();
        } else
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
                deadline: args.deadline,
                amountIn: args.amountIn,
                amountOutMinimum: args.amountOutMinimum,
                sqrtPriceLimitX96: args.sqrtPriceLimitX96
            });

        amountOut = swapRouter.exactInputSingle(params);
        uint256 ownerAmount = (amountOut * args.ownerFee) / 1e6;
        if (args.tokenOut == wethAddress) {
            IWETH9(wethAddress).withdraw(amountOut);
            TransferHelper.safeTransferETH(args.owner, ownerAmount);
            TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
        } else {
            TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
            TransferHelper.safeTransfer(
                args.tokenOut,
                msg.sender,
                amountOut - ownerAmount
            );
        }

        sweepToken(args.tokenIn, msg.sender);
        sweepToken(args.tokenOut, msg.sender);
        sweepNative(msg.sender);
    }

    function swapExactOutputSingle(
        ExactOutputSingleParams calldata args
    ) external payable nonReentrant returns (uint256 amountIn) {
        if (args.tokenIn == wethAddress) {
            require(msg.value == args.amountInMaximum, "IV");
            IWETH9(wethAddress).deposit{value: args.amountInMaximum}();
        } else
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
                deadline: args.deadline,
                amountOut: args.amountOut,
                amountInMaximum: args.amountInMaximum,
                sqrtPriceLimitX96: args.sqrtPriceLimitX96
            });

        amountIn = swapRouter.exactOutputSingle(params);

        uint256 ownerAmount = (args.amountOut * args.ownerFee) / 1e6;
        if (args.tokenOut == wethAddress) {
            IWETH9(wethAddress).withdraw(args.amountOut);
            TransferHelper.safeTransferETH(args.owner, ownerAmount);
            TransferHelper.safeTransferETH(
                msg.sender,
                args.amountOut - ownerAmount
            );
        } else {
            TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
            TransferHelper.safeTransfer(
                args.tokenOut,
                msg.sender,
                args.amountOut - ownerAmount
            );
        }

        if (amountIn < args.amountInMaximum) {
            uint256 returnAmount = args.amountInMaximum - amountIn;
            if (args.tokenIn == wethAddress) {
                IWETH9(wethAddress).withdraw(returnAmount);
                TransferHelper.safeTransferETH(msg.sender, returnAmount);
            } else {
                TransferHelper.safeApprove(
                    args.tokenIn,
                    address(swapRouter),
                    0
                );
                TransferHelper.safeTransfer(
                    args.tokenIn,
                    msg.sender,
                    returnAmount
                );
            }
        }

        sweepToken(args.tokenIn, msg.sender);
        sweepToken(args.tokenOut, msg.sender);
        sweepNative(msg.sender);
    }

    function swapExactInputMultihop(
        ExactInputMultiParams calldata args
    ) external payable nonReentrant returns (uint256 amountOut) {
        if (args.tokenIn == wethAddress) {
            require(msg.value == args.amountIn, "IV");
            IWETH9(wethAddress).deposit{value: args.amountIn}();
        } else
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
                deadline: args.deadline,
                amountIn: args.amountIn,
                amountOutMinimum: args.amountOutMinimum
            });

        amountOut = swapRouter.exactInput(params);
        uint256 ownerAmount = (amountOut * args.ownerFee) / 1e6;
        if (args.tokenOut == wethAddress) {
            IWETH9(wethAddress).withdraw(amountOut);
            TransferHelper.safeTransferETH(args.owner, ownerAmount);
            TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
        } else {
            TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
            TransferHelper.safeTransfer(
                args.tokenOut,
                msg.sender,
                amountOut - ownerAmount
            );
        }
        sweepToken(args.tokenIn, msg.sender);
        sweepToken(args.tokenOut, msg.sender);
        sweepNative(msg.sender);
    }

    function swapExactOutputMultihop(
        ExactOutputMultiParams calldata args
    ) external payable nonReentrant returns (uint256 amountIn) {
        if (args.tokenIn == wethAddress) {
            require(msg.value == args.amountInMaximum, "IV");
            IWETH9(wethAddress).deposit{value: args.amountInMaximum}();
        } else
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
                recipient: address(this),
                deadline: args.deadline,
                amountOut: args.amountOut,
                amountInMaximum: args.amountInMaximum
            });

        amountIn = swapRouter.exactOutput(params);

        uint256 ownerAmount = (args.amountOut * args.ownerFee) / 1e6;
        if (args.tokenOut == wethAddress) {
            IWETH9(wethAddress).withdraw(args.amountOut);
            TransferHelper.safeTransferETH(args.owner, ownerAmount);
            TransferHelper.safeTransferETH(
                msg.sender,
                args.amountOut - ownerAmount
            );
        } else {
            TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
            TransferHelper.safeTransfer(
                args.tokenOut,
                msg.sender,
                args.amountOut - ownerAmount
            );
        }
        if (amountIn < args.amountInMaximum) {
            uint256 returnAmount = args.amountInMaximum - amountIn;
            if (args.tokenIn == wethAddress) {
                IWETH9(wethAddress).withdraw(returnAmount);
                TransferHelper.safeTransferETH(msg.sender, returnAmount);
            } else {
                TransferHelper.safeApprove(
                    args.tokenIn,
                    address(swapRouter),
                    0
                );
                TransferHelper.safeTransfer(
                    args.tokenIn,
                    msg.sender,
                    returnAmount
                );
            }
        }
        sweepToken(args.tokenIn, msg.sender);
        sweepToken(args.tokenOut, msg.sender);
        sweepNative(msg.sender);
    }

    function collectTokens(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            sweepToken(addrs[i], msg.sender);
        }
    }

    function collectNative() external onlyOwner {
        sweepNative(msg.sender);
    }

    receive() external payable {}
}

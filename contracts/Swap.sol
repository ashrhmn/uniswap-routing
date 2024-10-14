// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Swap is Ownable, ReentrancyGuard {
  ISwapRouter public swapRouterV3;

  IUniswapV2Router02 public swapRouterV2;

  uint256 public constant FEE_DENOMINATOR = 1e6; // 10000 = 1%, 100000 = 10%, 1000000 = 100%

  address public wethAddress;
  //////////////// V3 Structs Start//////////////////////
  struct ExactInputSingleV3Params {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint24 fee;
    uint160 sqrtPriceLimitX96;
    uint256 deadline;
    address owner;
    uint256 ownerFee;
  }

  struct ExactOutputSingleV3Params {
    address tokenIn;
    address tokenOut;
    uint256 amountInMaximum;
    uint256 amountOut;
    uint24 fee;
    uint160 sqrtPriceLimitX96;
    uint256 deadline;
    address owner;
    uint256 ownerFee;
  }

  struct ExactInputMultiV3Params {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOutMinimum;
    bytes path;
    uint256 deadline;
    address owner;
    uint256 ownerFee;
  }

  struct ExactOutputMultiV3Params {
    address tokenIn;
    address tokenOut;
    uint256 amountInMaximum;
    uint256 amountOut;
    bytes path;
    uint256 deadline;
    address owner;
    uint256 ownerFee;
  }

  ////////// V3 Structs End ///////////////////////////////

  ////////////// V2 Structs Start ////////////////////////
  struct SwapExactTokensForTokensV2Params {
    uint amountIn;
    uint amountOutMin;
    address[] path;
    uint deadline;
    address owner;
    uint256 ownerFee;
  }

  struct SwapTokensForExactTokensV2Params {
    uint amountOut;
    uint amountInMax;
    address[] path;
    uint deadline;
    address owner;
    uint256 ownerFee;
  }

  struct SwapExactETHForTokensV2Params {
    uint amountOutMin;
    address[] path;
    uint deadline;
    address owner;
    uint256 ownerFee;
  }

  struct SwapTokensForExactETHV2Params {
    uint amountOut;
    uint amountInMax;
    address[] path;
    uint deadline;
    address owner;
    uint256 ownerFee;
  }

  struct SwapExactTokensForETHV2Params {
    uint amountIn;
    uint amountOutMin;
    address[] path;
    uint deadline;
    address owner;
    uint256 ownerFee;
  }

  struct SwapETHForExactTokensV2Params {
    uint amountOut;
    address[] path;
    uint deadline;
    address owner;
    uint256 ownerFee;
  }

  ///////////// v2 Structs End/////////////////////////////////////

  constructor(
    address _swapRouterV3,
    address _swapRouterV2,
    address _wethAddress
  ) {
    swapRouterV3 = ISwapRouter(_swapRouterV3);
    swapRouterV2 = IUniswapV2Router02(_swapRouterV2);
    wethAddress = _wethAddress;
  }

  function setAddresses(
    address _swapRouterV3,
    address _swapRouterV2,
    address _wethAddress
  ) external onlyOwner {
    swapRouterV3 = ISwapRouter(_swapRouterV3);
    swapRouterV2 = IUniswapV2Router02(_swapRouterV2);
    wethAddress = _wethAddress;
  }

  ///////////// Internal Functions ////////////////////////////////
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

  /////////////////////////////////////////////////////////////////

  ///////////////// V3 Swap Functions ///////////////////////////
  function handleInputOfExactInputV3(
    address tokenIn,
    uint256 amountIn,
    address owner,
    uint256 ownerFee
  ) internal {
    if (tokenIn == wethAddress) {
      uint256 ownerAmount = (amountIn * FEE_DENOMINATOR) / ownerFee;
      require(msg.value == amountIn + ownerAmount, "IV");
      TransferHelper.safeTransferETH(owner, ownerAmount);
      IWETH9(wethAddress).deposit{value: amountIn}();
    } else
      TransferHelper.safeTransferFrom(
        tokenIn,
        msg.sender,
        address(this),
        amountIn
      );

    TransferHelper.safeApprove(tokenIn, address(swapRouterV3), amountIn);
  }

  function handleOutputOfExactInputV3(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    address owner,
    uint256 ownerFee
  ) internal {
    if (tokenIn != wethAddress) {
      uint256 ownerAmount = (amountOut * ownerFee) / FEE_DENOMINATOR;
      if (tokenOut == wethAddress) {
        IWETH9(wethAddress).withdraw(amountOut);
        TransferHelper.safeTransferETH(owner, ownerAmount);
        TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
      } else {
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
          tokenOut,
          msg.sender,
          amountOut - ownerAmount
        );
      }
    } else {
      if (tokenOut == wethAddress) {
        IWETH9(wethAddress).withdraw(amountOut);
        TransferHelper.safeTransferETH(msg.sender, amountOut);
      } else {
        TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut);
      }
    }
  }

  function handleInputOfExactOutputV3(
    address tokenIn,
    uint256 amountInMaximum,
    address owner,
    uint256 ownerFee
  ) internal {
    if (tokenIn == wethAddress) {
      uint256 ownerAmount = (amountInMaximum * FEE_DENOMINATOR) / ownerFee;
      require(msg.value == amountInMaximum + ownerAmount, "IV");
      TransferHelper.safeTransferETH(owner, ownerAmount);
      IWETH9(wethAddress).deposit{value: amountInMaximum}();
    } else
      TransferHelper.safeTransferFrom(
        tokenIn,
        msg.sender,
        address(this),
        amountInMaximum
      );

    TransferHelper.safeApprove(tokenIn, address(swapRouterV3), amountInMaximum);
  }

  function handleOutputOfExactOutputV3(
    address tokenIn,
    address tokenOut,
    uint256 amountInMaximum,
    uint256 amountIn,
    uint256 amountOut,
    address owner,
    uint256 ownerFee
  ) internal {
    if (tokenIn != wethAddress) {
      uint256 ownerAmount = (amountOut * ownerFee) / FEE_DENOMINATOR;
      if (tokenOut == wethAddress) {
        IWETH9(wethAddress).withdraw(amountOut);
        TransferHelper.safeTransferETH(owner, ownerAmount);
        TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
      } else {
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount);
        TransferHelper.safeTransfer(
          tokenOut,
          msg.sender,
          amountOut - ownerAmount
        );
      }
    } else {
      if (tokenOut == wethAddress) {
        IWETH9(wethAddress).withdraw(amountOut);
        TransferHelper.safeTransferETH(msg.sender, amountOut);
      } else {
        TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut);
      }
    }

    if (amountIn < amountInMaximum) {
      uint256 returnAmount = amountInMaximum - amountIn;
      if (tokenIn == wethAddress) {
        IWETH9(wethAddress).withdraw(returnAmount);
        TransferHelper.safeTransferETH(msg.sender, returnAmount);
      } else {
        TransferHelper.safeApprove(tokenIn, address(swapRouterV3), 0);
        TransferHelper.safeTransfer(tokenIn, msg.sender, returnAmount);
      }
    }
  }

  function swapExactInputSingle(
    ExactInputSingleV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountOut) {
    handleInputOfExactInputV3(
      args.tokenIn,
      args.amountIn,
      args.owner,
      args.ownerFee
    );
    // if (args.tokenIn == wethAddress) {
    //   uint256 ownerAmount = (args.amountIn * FEE_DENOMINATOR) / args.ownerFee;
    //   require(msg.value == args.amountIn + ownerAmount, "IV");
    //   TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //   IWETH9(wethAddress).deposit{value: args.amountIn}();
    // } else
    //   TransferHelper.safeTransferFrom(
    //     args.tokenIn,
    //     msg.sender,
    //     address(this),
    //     args.amountIn
    //   );

    // TransferHelper.safeApprove(
    //   args.tokenIn,
    //   address(swapRouterV3),
    //   args.amountIn
    // );

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

    amountOut = swapRouterV3.exactInputSingle(params);

    handleOutputOfExactInputV3(
      args.tokenIn,
      args.tokenOut,
      amountOut,
      args.owner,
      args.ownerFee
    );
    // if (args.tokenIn != wethAddress) {
    //   uint256 ownerAmount = (amountOut * args.ownerFee) / FEE_DENOMINATOR;
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(amountOut);
    //     TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //     TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
    //     TransferHelper.safeTransfer(
    //       args.tokenOut,
    //       msg.sender,
    //       amountOut - ownerAmount
    //     );
    //   }
    // } else {
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(amountOut);
    //     TransferHelper.safeTransferETH(msg.sender, amountOut);
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, msg.sender, amountOut);
    //   }
    // }

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  function swapExactOutputSingle(
    ExactOutputSingleV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountIn) {
    handleInputOfExactOutputV3(
      args.tokenIn,
      args.amountInMaximum,
      args.owner,
      args.ownerFee
    );
    // if (args.tokenIn == wethAddress) {
    //   uint256 ownerAmount = (args.amountInMaximum * FEE_DENOMINATOR) /
    //     args.ownerFee;
    //   require(msg.value == args.amountInMaximum + ownerAmount, "IV");
    //   TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //   IWETH9(wethAddress).deposit{value: args.amountInMaximum}();
    // } else
    //   TransferHelper.safeTransferFrom(
    //     args.tokenIn,
    //     msg.sender,
    //     address(this),
    //     args.amountInMaximum
    //   );
    // TransferHelper.safeApprove(
    //   args.tokenIn,
    //   address(swapRouterV3),
    //   args.amountInMaximum
    // );

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

    amountIn = swapRouterV3.exactOutputSingle(params);

    handleOutputOfExactOutputV3(
      args.tokenIn,
      args.tokenOut,
      args.amountInMaximum,
      amountIn,
      args.amountOut,
      args.owner,
      args.ownerFee
    );

    // if (args.tokenIn != wethAddress) {
    //   uint256 ownerAmount = (args.amountOut * args.ownerFee) / FEE_DENOMINATOR;
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(args.amountOut);
    //     TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //     TransferHelper.safeTransferETH(
    //       msg.sender,
    //       args.amountOut - ownerAmount
    //     );
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
    //     TransferHelper.safeTransfer(
    //       args.tokenOut,
    //       msg.sender,
    //       args.amountOut - ownerAmount
    //     );
    //   }
    // } else {
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(args.amountOut);
    //     TransferHelper.safeTransferETH(msg.sender, args.amountOut);
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, msg.sender, args.amountOut);
    //   }
    // }

    // if (amountIn < args.amountInMaximum) {
    //   uint256 returnAmount = args.amountInMaximum - amountIn;
    //   if (args.tokenIn == wethAddress) {
    //     IWETH9(wethAddress).withdraw(returnAmount);
    //     TransferHelper.safeTransferETH(msg.sender, returnAmount);
    //   } else {
    //     TransferHelper.safeApprove(args.tokenIn, address(swapRouterV3), 0);
    //     TransferHelper.safeTransfer(args.tokenIn, msg.sender, returnAmount);
    //   }
    // }

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  function swapExactInputMultihop(
    ExactInputMultiV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountOut) {
    handleInputOfExactInputV3(
      args.tokenIn,
      args.amountIn,
      args.owner,
      args.ownerFee
    );
    // if (args.tokenIn == wethAddress) {
    //   uint256 ownerAmount = (args.amountIn * FEE_DENOMINATOR) / args.ownerFee;
    //   require(msg.value == args.amountIn + ownerAmount, "IV");
    //   TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //   IWETH9(wethAddress).deposit{value: args.amountIn}();
    // } else
    //   TransferHelper.safeTransferFrom(
    //     args.tokenIn,
    //     msg.sender,
    //     address(this),
    //     args.amountIn
    //   );

    // TransferHelper.safeApprove(
    //   args.tokenIn,
    //   address(swapRouterV3),
    //   args.amountIn
    // );

    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: args.path,
      recipient: address(this),
      deadline: args.deadline,
      amountIn: args.amountIn,
      amountOutMinimum: args.amountOutMinimum
    });

    amountOut = swapRouterV3.exactInput(params);

    handleOutputOfExactInputV3(
      args.tokenIn,
      args.tokenOut,
      amountOut,
      args.owner,
      args.ownerFee
    );
    // if (args.tokenIn != wethAddress) {
    //   uint256 ownerAmount = (amountOut * args.ownerFee) / FEE_DENOMINATOR;
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(amountOut);
    //     TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //     TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
    //     TransferHelper.safeTransfer(
    //       args.tokenOut,
    //       msg.sender,
    //       amountOut - ownerAmount
    //     );
    //   }
    // } else {
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(amountOut);
    //     TransferHelper.safeTransferETH(msg.sender, amountOut);
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, msg.sender, amountOut);
    //   }
    // }

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  function swapExactOutputMultihop(
    ExactOutputMultiV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountIn) {
    handleInputOfExactOutputV3(
      args.tokenIn,
      args.amountInMaximum,
      args.owner,
      args.ownerFee
    );
    // if (args.tokenIn == wethAddress) {
    //   uint256 ownerAmount = (args.amountInMaximum * FEE_DENOMINATOR) /
    //     args.ownerFee;
    //   require(msg.value == args.amountInMaximum + ownerAmount, "IV");
    //   TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //   IWETH9(wethAddress).deposit{value: args.amountInMaximum}();
    // } else
    //   TransferHelper.safeTransferFrom(
    //     args.tokenIn,
    //     msg.sender,
    //     address(this),
    //     args.amountInMaximum
    //   );
    // TransferHelper.safeApprove(
    //   args.tokenIn,
    //   address(swapRouterV3),
    //   args.amountInMaximum
    // );

    ISwapRouter.ExactOutputParams memory params = ISwapRouter
      .ExactOutputParams({
        path: args.path,
        recipient: address(this),
        deadline: args.deadline,
        amountOut: args.amountOut,
        amountInMaximum: args.amountInMaximum
      });

    amountIn = swapRouterV3.exactOutput(params);

    handleOutputOfExactOutputV3(
      args.tokenIn,
      args.tokenOut,
      args.amountInMaximum,
      amountIn,
      args.amountOut,
      args.owner,
      args.ownerFee
    );

    // if (args.tokenIn != wethAddress) {
    //   uint256 ownerAmount = (args.amountOut * args.ownerFee) / FEE_DENOMINATOR;
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(args.amountOut);
    //     TransferHelper.safeTransferETH(args.owner, ownerAmount);
    //     TransferHelper.safeTransferETH(
    //       msg.sender,
    //       args.amountOut - ownerAmount
    //     );
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, args.owner, ownerAmount);
    //     TransferHelper.safeTransfer(
    //       args.tokenOut,
    //       msg.sender,
    //       args.amountOut - ownerAmount
    //     );
    //   }
    // } else {
    //   if (args.tokenOut == wethAddress) {
    //     IWETH9(wethAddress).withdraw(args.amountOut);
    //     TransferHelper.safeTransferETH(msg.sender, args.amountOut);
    //   } else {
    //     TransferHelper.safeTransfer(args.tokenOut, msg.sender, args.amountOut);
    //   }
    // }

    // if (amountIn < args.amountInMaximum) {
    //   uint256 returnAmount = args.amountInMaximum - amountIn;
    //   if (args.tokenIn == wethAddress) {
    //     IWETH9(wethAddress).withdraw(returnAmount);
    //     TransferHelper.safeTransferETH(msg.sender, returnAmount);
    //   } else {
    //     TransferHelper.safeApprove(args.tokenIn, address(swapRouterV3), 0);
    //     TransferHelper.safeTransfer(args.tokenIn, msg.sender, returnAmount);
    //   }
    // }

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  ///////////////// V3 Swap Functions End //////////////////////////////////////

  //////////////// V2 Swap Functions Start ////////////////////////////////////
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
    TransferHelper.safeApprove(tokenIn, address(swapRouterV2), args.amountIn);
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
    TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut - ownerAmount);
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
    uint256 ownerAmount = (args.amountOut * args.ownerFee) / FEE_DENOMINATOR;
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
    uint256 ownerAmount = (msg.value * args.ownerFee) / FEE_DENOMINATOR;
    TransferHelper.safeTransferETH(args.owner, ownerAmount);
    amounts = swapRouterV2.swapExactETHForTokens{
      value: msg.value - ownerAmount
    }(args.amountOutMin, args.path, address(this), args.deadline);
    require(amounts.length == args.path.length, "IS");
    uint256 amountOut = amounts[amounts.length - 1];

    TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut);

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
    uint256 ownerAmount = (args.amountOut * args.ownerFee) / FEE_DENOMINATOR;
    TransferHelper.safeTransferETH(args.owner, ownerAmount);
    TransferHelper.safeTransferETH(msg.sender, args.amountOut - ownerAmount);
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
    TransferHelper.safeApprove(tokenIn, address(swapRouterV2), args.amountIn);

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
    uint256 ownerAmount = (msg.value * args.ownerFee) / FEE_DENOMINATOR;
    TransferHelper.safeTransferETH(args.owner, ownerAmount);
    amounts = swapRouterV2.swapETHForExactTokens{
      value: msg.value - ownerAmount
    }(args.amountOut, args.path, address(this), args.deadline);
    require(amounts.length == args.path.length, "IS");
    uint256 amountIn = amounts[amounts.length - 1];
    TransferHelper.safeTransfer(tokenOut, msg.sender, args.amountOut);
    if (amountIn < msg.value - ownerAmount)
      TransferHelper.safeTransferETH(
        msg.sender,
        msg.value - ownerAmount - amountIn
      );
    sweepToken(tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  ///////////////  V2 Swap Functions End //////////////////////////////////////
  ///////// Function for collecting accidentally sent tokens to the contract///////
  function collectTokens(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      sweepToken(_addresses[i], msg.sender);
    }
  }

  function collectNative() external onlyOwner {
    sweepNative(msg.sender);
  }

  receive() external payable {}
}

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

  function ownerAmountFromSwapInAmount(
    uint256 userAmount, // 99%
    uint256 ownerFee // 1%
  ) internal pure returns (uint256 ownerAmount) {
    uint256 totalAmount = ((userAmount * FEE_DENOMINATOR) /
      (FEE_DENOMINATOR - ownerFee));
    ownerAmount = totalAmount - userAmount;
  }

  function ownerAmountFromTotalAmount(
    uint256 totalAmount, // 100%
    uint256 ownerFee // 1%
  ) internal pure returns (uint256 ownerAmount) {
    ownerAmount = (totalAmount * ownerFee) / FEE_DENOMINATOR;
  }

  function handleInputOfExactInputV3(
    address tokenIn,
    uint256 amountIn,
    address owner,
    uint256 ownerFee
  ) internal {
    if (tokenIn == wethAddress) {
      // if from token is eth
      uint256 ownerAmount = ownerAmountFromSwapInAmount(amountIn, ownerFee); // calculate owner amount from amountIn
      require(msg.value == amountIn + ownerAmount, "IV"); // owner amount+swapAmount must be already sent as native
      TransferHelper.safeTransferETH(owner, ownerAmount); // transfer owner portion to owner
      IWETH9(wethAddress).deposit{value: amountIn}(); // convert swap amount eth to weth
    }
    // if from token is erc20
    else
      TransferHelper.safeTransferFrom( // transfer swap amount to this contract, assuming user already approved the token
        tokenIn,
        msg.sender,
        address(this),
        amountIn
      );

    TransferHelper.safeApprove(tokenIn, address(swapRouterV3), amountIn); // approve swap router to take the from token from this contract
  }

  function handleOutputOfExactInputV3(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    address owner,
    uint256 ownerFee
  ) internal {
    if (tokenIn != wethAddress) {
      // if from token is erc20
      uint256 ownerAmount = ownerAmountFromTotalAmount(amountOut, ownerFee); // calculate owner amount
      if (tokenOut == wethAddress) {
        // if to token is eth
        IWETH9(wethAddress).withdraw(amountOut); // convert all weth to eth
        TransferHelper.safeTransferETH(owner, ownerAmount); // transfer owner portion eth to owner
        TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount); // transfer rest of the eth to user
      } else {
        // if to token is erc20
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount); // transfer owner portion erc20 to owner
        TransferHelper.safeTransfer( // transfer rest of the erc20 to user
          tokenOut,
          msg.sender,
          amountOut - ownerAmount
        );
      }
    } else {
      // if from token is eth (considering owner ammount was taken before swap, so no dividents)
      if (tokenOut == wethAddress) {
        // if to token is eth, possibly will never be true but still
        IWETH9(wethAddress).withdraw(amountOut); // convert all weth to eth
        TransferHelper.safeTransferETH(msg.sender, amountOut); // transfer full eth to user
      } else {
        // if to token is erc20
        TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut); // transfer total amount of erc20 to user
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
      // if from token is eth
      uint256 ownerAmount = ownerAmountFromSwapInAmount( // calculate owner amount from swapIn amount
        amountInMaximum,
        ownerFee
      );
      require(msg.value == amountInMaximum + ownerAmount, "IV"); // swapIn + ownerAmount must be already sent as native value
      TransferHelper.safeTransferETH(owner, ownerAmount); // transfer owner portion eth to owner
      IWETH9(wethAddress).deposit{value: amountInMaximum}(); // convert rest of the eth to weth
    }
    // if from token is erc20
    else
      TransferHelper.safeTransferFrom( // transfer swapIn amount to this contract, assuming user already approved the token
        tokenIn,
        msg.sender,
        address(this),
        amountInMaximum
      );

    TransferHelper.safeApprove(tokenIn, address(swapRouterV3), amountInMaximum); // approve swap router to take the from token from this contract
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
      // from is erc20, dividing output amount to owner and user
      uint256 ownerAmount = ownerAmountFromTotalAmount(amountOut, ownerFee); // owner amount 1 % of total swap output
      if (tokenOut == wethAddress) {
        // to is eth
        IWETH9(wethAddress).withdraw(amountOut); // convert weth to eth
        TransferHelper.safeTransferETH(owner, ownerAmount); // transfer owner amount to owner
        TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount); // transfer left amount to user
      } else {
        // to is erc20
        TransferHelper.safeTransfer(tokenOut, owner, ownerAmount); // transfer owner amount to owner
        TransferHelper.safeTransfer( // transfer left amount to user
          tokenOut,
          msg.sender,
          amountOut - ownerAmount
        );
      }
    } else {
      // from eth, not dividing amount as already divided from eth
      if (tokenOut == wethAddress) {
        // to eth, possibly will never be true but still
        IWETH9(wethAddress).withdraw(amountOut); // convert weth to eth
        TransferHelper.safeTransferETH(msg.sender, amountOut); // send full amount eth to user
      } else {
        // to erc20
        TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut); // transfer full amount erc20 to user
      }
    }

    if (amountIn < amountInMaximum) {
      // swap was done using less amount than maximum allowed/taken from the user, so returning back unused amount
      uint256 returnAmount = amountInMaximum - amountIn;
      if (tokenIn == wethAddress) {
        // from is eth, converting weth to eth and returning back
        IWETH9(wethAddress).withdraw(returnAmount);
        TransferHelper.safeTransferETH(msg.sender, returnAmount);
      } else {
        // from is erc20
        TransferHelper.safeApprove(tokenIn, address(swapRouterV3), 0); // removing allownace from swap router
        TransferHelper.safeTransfer(tokenIn, msg.sender, returnAmount); // returning back unused amount to user
      }
    }
  }

  function swapExactInputSingleV3(
    ExactInputSingleV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountOut) {
    require(args.tokenIn != args.tokenOut, "IT");
    handleInputOfExactInputV3(
      args.tokenIn,
      args.amountIn,
      args.owner,
      args.ownerFee
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

    amountOut = swapRouterV3.exactInputSingle(params);

    handleOutputOfExactInputV3(
      args.tokenIn,
      args.tokenOut,
      amountOut,
      args.owner,
      args.ownerFee
    );

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  function swapExactOutputSingleV3(
    ExactOutputSingleV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountIn) {
    require(args.tokenIn != args.tokenOut, "IT");
    handleInputOfExactOutputV3(
      args.tokenIn,
      args.amountInMaximum,
      args.owner,
      args.ownerFee
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

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  function swapExactInputV3(
    ExactInputMultiV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountOut) {
    require(args.tokenIn != args.tokenOut, "IT");
    handleInputOfExactInputV3(
      args.tokenIn,
      args.amountIn,
      args.owner,
      args.ownerFee
    );

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

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  function swapExactOutputV3(
    ExactOutputMultiV3Params calldata args
  ) external payable nonReentrant returns (uint256 amountIn) {
    require(args.tokenIn != args.tokenOut, "IT");
    handleInputOfExactOutputV3(
      args.tokenIn,
      args.amountInMaximum,
      args.owner,
      args.ownerFee
    );

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

    sweepToken(args.tokenIn, msg.sender);
    sweepToken(args.tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  ///////////////// V3 Swap Functions End //////////////////////////////////////

  //////////////// V2 Swap Functions Start ////////////////////////////////////
  function swapExactTokensForTokensV2(
    SwapExactTokensForTokensV2Params calldata args
  ) external nonReentrant returns (uint[] memory amounts) {
    address tokenIn = args.path[0];
    address tokenOut = args.path[args.path.length - 1];
    require(tokenIn != tokenOut, "IT");
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
    uint256 ownerAmount = ownerAmountFromTotalAmount(amountOut, args.ownerFee);

    TransferHelper.safeTransfer(tokenOut, args.owner, ownerAmount);
    TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut - ownerAmount);
    sweepToken(tokenIn, msg.sender);
    sweepToken(tokenOut, msg.sender);
  }

  function swapTokensForExactTokensV2(
    SwapTokensForExactTokensV2Params calldata args
  ) external nonReentrant returns (uint[] memory amounts) {
    address tokenIn = args.path[0];
    address tokenOut = args.path[args.path.length - 1];
    require(tokenIn != tokenOut, "IT");
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
    uint256 ownerAmount = ownerAmountFromTotalAmount(
      args.amountOut,
      args.ownerFee
    );
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
  ) external payable nonReentrant returns (uint[] memory amounts) {
    address tokenOut = args.path[args.path.length - 1];
    uint256 ownerAmount = ownerAmountFromTotalAmount(msg.value, args.ownerFee);
    TransferHelper.safeTransferETH(args.owner, ownerAmount);
    amounts = swapRouterV2.swapExactETHForTokens{
      value: msg.value - ownerAmount
    }(args.amountOutMin, args.path, msg.sender, args.deadline);

    sweepToken(tokenOut, msg.sender);
    sweepNative(msg.sender);
  }

  function swapTokensForExactETHV2(
    SwapTokensForExactETHV2Params calldata args
  ) external nonReentrant returns (uint[] memory amounts) {
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
    uint256 ownerAmount = ownerAmountFromTotalAmount(
      args.amountOut,
      args.ownerFee
    );
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
  ) external nonReentrant returns (uint[] memory amounts) {
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
    uint256 ownerAmount = ownerAmountFromTotalAmount(amountOut, args.ownerFee);

    TransferHelper.safeTransferETH(args.owner, ownerAmount);
    TransferHelper.safeTransferETH(msg.sender, amountOut - ownerAmount);
    sweepToken(tokenIn, msg.sender);
    sweepNative(msg.sender);
  }

  function swapETHForExactTokensV2(
    SwapETHForExactTokensV2Params calldata args
  ) external payable nonReentrant returns (uint[] memory amounts) {
    address tokenOut = args.path[args.path.length - 1];
    uint256 ownerAmount = ownerAmountFromTotalAmount(msg.value, args.ownerFee);
    TransferHelper.safeTransferETH(args.owner, ownerAmount);
    uint256 swapinAmount = msg.value - ownerAmount;
    amounts = swapRouterV2.swapETHForExactTokens{value: swapinAmount}(
      args.amountOut,
      args.path,
      msg.sender,
      args.deadline
    );
    require(amounts.length == args.path.length, "IS");
    uint256 amountIn = amounts[amounts.length - 1];
    if (amountIn < swapinAmount)
      TransferHelper.safeTransferETH(msg.sender, swapinAmount - amountIn);
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

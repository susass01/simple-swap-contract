// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;
/**
 * @title SimpleSwap
 * @author Susana Carolina Sanchez
 * @notice Smart contract replicating basic Uniswap functionality: add/remove liquidity, swap tokens, get price, get amount out
 */

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract SimpleSwap {
    //Liquidity token pair
    struct Pair {
        uint reserveA;
        uint reserveB;
        mapping(address => uint) liquidity; //Liquidity of each address
        uint totalLiquidity; //Total liquidity sum of the token pair
    }

    mapping(bytes32 => Pair) public pairs; //Unique pair identifier

    //Temporary state variable
    uint[] public tempAmounts;

    //Triggered when a user adds liquidity
    event LiquidityAdded(address indexed user, //Tracks which user added liquidity
                         address tokenA, 
                         address tokenB, 
                         uint amountA, 
                         uint amountB, 
                         uint liquidity);

    //Triggered when a user removes liquidity
    event LiquidityRemoved(address indexed user, 
                           address tokenA, 
                           address tokenB, 
                           uint amountA, 
                           uint amountB);

    //Triggered when someone performs a token swap                      
    event TokensSwapped(address indexed user, 
                        address tokenIn, 
                        address tokenOut, 
                        uint amountIn, 
                        uint amountOut);

    //Generates the unique key to identify the pair of tokens
    function _getPairKey(address tokenA, address tokenB) internal pure returns (bytes32) {
        return keccak256( //Generates the unique hash
            abi.encodePacked( //Converts addresses into binary block
                            tokenA < tokenB ? tokenA : tokenB, //Comparing tokens to ensure the lowest value goes first
                            tokenA < tokenB ? tokenB : tokenA
            )
        );
    }

    //Function that returns the effective amounts used and the liquidity
    function addLiquidity(
        address tokenA, //Token addresses
        address tokenB,
        uint amountADesired, //Token contribution
        uint amountBDesired, 
        uint amountAMin, //Minimum acceptable Token
        uint amountBMin,
        address to, //Address of the user who will receive the tokens
        uint deadline //Time limit for the transaction to be valid
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(block.timestamp <= deadline, "Transaction expired"); //Protects the user from the transaction being carried out out of time

        bytes32 pairKey = _getPairKey(tokenA, tokenB); //The unique key of the token pair is generated
        Pair storage pair = pairs[pairKey]; //The token pair record is accessed or created

        if (pair.totalLiquidity == 0) { //If it is empty, what the user sends is accepted.
            amountA = amountADesired;
            amountB = amountBDesired;
        } else { //If you do not calculate how much you should contribute
            uint ratioA = (amountADesired * pair.reserveB) / pair.reserveA;
            if (ratioA <= amountBDesired) {
                amountA = amountADesired;
                amountB = ratioA;
            } else {
                uint ratioB = (amountBDesired * pair.reserveA) / pair.reserveB;
                amountA = ratioB;
                amountB = amountBDesired;
            }
        }

        require(amountA >= amountAMin && amountB >= amountBMin, "Insufficient amounts"); //Prevents the operation from executing if it falls below

        //Tokens are transferred from the user's account to the contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        liquidity = amountA + amountB; //Calculation of aggregate liquidity
        pair.reserveA += amountA; //Reservations are updated
        pair.reserveB += amountB;
        pair.liquidity[to] += liquidity; //It is recorded that the user to has liquidity
        pair.totalLiquidity += liquidity;

        //An aggregate liquidity event is issued
        emit LiquidityAdded(to, tokenA, tokenB, amountA, amountB, liquidity);
    }
    
    //Function that allows the user to withdraw their token
    function removeLiquidity(
        address tokenA, //Token Address
        address tokenB,
        uint liquidity, //Liquidity to withdraw
        uint amountAMin, //Minimum acceptable quantity
        uint amountBMin,
        address to, //Address to which the withdrawn tokens will be sent
        uint deadline //Deadline for the transaction to be valid
    ) external returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "Transaction expired"); //Protects the user from the transaction being executed out of time

        bytes32 pairKey = _getPairKey(tokenA, tokenB);
        Pair storage pair = pairs[pairKey]; //Locate the Pair to which the user belongs

        require(pair.liquidity[msg.sender] >= liquidity, "Insufficient liquidity"); //Prevents the user from trying to withdraw more than what they contributed
        //Calculate how much belongs to the user according to their liquidity
        amountA = (pair.reserveA * liquidity) / pair.totalLiquidity;
        amountB = (pair.reserveB * liquidity) / pair.totalLiquidity;

        require(amountA >= amountAMin && amountB >= amountBMin, "Amounts below minimums"); //Evita que el usuario reciba menos de lo que espera

        //Variables are updated
        pair.reserveA -= amountA;
        pair.reserveB -= amountB;
        pair.liquidity[msg.sender] -= liquidity;
        pair.totalLiquidity -= liquidity;

        //Return of tokens
        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        //Event is issued notifying the withdrawal
        emit LiquidityRemoved(to, tokenA, tokenB, amountA, amountB);
    }

    //Exchange function between two tokens
    function swapExactTokensForTokens(
        uint amountIn, //Amount of token the user wants to exchange
        uint amountOutMin, //Minimum acceptable output token amount
        address[] calldata path, //Array for the input and output tokens
        address to, //Address that will receive the output tokens
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(block.timestamp <= deadline, "Transaction expired"); //Verifies that the transaction is not executed if the time expires
        require(path.length == 2, "Only single pair swaps supported"); //It will only allow a swap from one token to another.

        address tokenIn = path[0];
        address tokenOut = path[1];
        bytes32 pairKey = _getPairKey(tokenIn, tokenOut); //Calculating the unique key of the token pair
        Pair storage pair = pairs[pairKey];

        //Transfer input tokens from the user to the contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn); //The transfer is made

        //Get output token quantity calculated based on reserves
        uint amountOut = getAmountOut(
            amountIn,
            tokenIn < tokenOut ? pair.reserveA : pair.reserveB,
            tokenIn < tokenOut ? pair.reserveB : pair.reserveA
        );

        //Validate that the output quantity is not less than the minimum accepted (slippage)
        require(amountOut >= amountOutMin, "Insufficient output amount");
        
        //Reservations are updated
        if (tokenIn < tokenOut ) {
            pair.reserveA += amountIn;
            pair.reserveB -= amountOut;
        } else {
            pair.reserveB += amountIn;
            pair.reserveA -= amountOut;
        }

        
        IERC20(tokenOut).transfer(to, amountOut); //Exit tokens are transferred to the user

        /**
            * @dev Clears the tempAmounts storage array and then adds the swap input and output values
            * using push(). It then copies those values
            * to a new in-memory array so they can be returned.
            *
            * @notice tempAmounts is used to comply with the requirement to use `push()`
            * since `push()` is not available for `memory` arrays.
        */
        delete tempAmounts;
        tempAmounts.push(amountIn);
        tempAmounts.push(amountOut);

        amounts = new uint[](tempAmounts.length);
        for (uint i = 0; i < tempAmounts.length; i++) {
            amounts[i] = tempAmounts[i];
        }

          //An event is emitted to display the swap
        emit TokensSwapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        return amounts;
        
    }

    //Function to obtain the price of a token
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        bytes32 pairKey = _getPairKey(tokenA, tokenB); //Unique key of the token pair
        Pair storage pair = pairs[pairKey];

        //Determines the reserve that corresponds to each token
        (uint reserveA, uint reserveB) = tokenA < tokenB 
        ? (pair.reserveA, pair.reserveB) 
        : (pair.reserveB, pair.reserveA);

        require(reserveA > 0 && reserveB > 0, "No liquidity"); //Check if there are no tokens added
        price = (reserveB * 1e18) / reserveA; //Calculation to return the price of 1 token unit
    }

    //Function to calculate the amount of output token to receive
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, "Amount must be > 0"); //Validates that the exchange is greater than 0
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves"); //Validate that there is sufficient liquidity
        uint amountInWithFee = amountIn * 997; //Commission calculation
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator; //Calculation of the value of the token to be received by the user
    }

    /**
     * @notice Public function to expose the internal _getPairKey for external use
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return pairKey The unique identifier of the token pair
     */
    function getPairKey(address tokenA, address tokenB) external pure returns (bytes32 pairKey) {
        return _getPairKey(tokenA, tokenB);
    }
}
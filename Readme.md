SimpleSwap - Smart Contract

Overview

SimpleSwap is a Solidity smart contract that replicates basic functionalities of Uniswap: adding/removing liquidity, swapping tokens, getting price, and calculating output amounts. The contract operates with ERC-20 tokens and does not rely on Uniswap's protocol.
Contract address on Sepolia: 0xfd1FAB6DCA1A2164c9C3C3BE7EbBd2e9d3ef4af2

🛠️ Technologies

- Solidity `^0.8.0`
- OpenZeppelin ERC20
- Remix IDE for testing and deployment
- Sepolia testnet
Functionalities
1. Add Liquidity - addLiquidity()
Description: Allows users to add liquidity to a token pair pool.
Tasks:
Transfer tokens from user to contract.
Calculate optimal contribution amounts.
Update reserves and liquidity shares.
Returns: Actual token amounts used and liquidity added.
2. Remove Liquidity - removeLiquidity()
Description: Allows users to withdraw their share of tokens from a pool.
Tasks:
Burn liquidity.
Calculate and return token amounts.
Returns: Token amounts received after withdrawal.


3. Swap Tokens - swapExactTokensForTokens()
Description: Swap an exact amount of one token for another.
Tasks:
Transfer input tokens.
Calculate output amount.
Transfer output tokens to recipient.
Returns: Array containing input and output amounts.
4. Get Price - getPrice()
Description: Returns the price of tokenA in terms of tokenB based on current reserves.
Returns: Price as a fixed-point number (18 decimals)

5. Get Output Amount - getAmountOut()
Description: Calculates how many tokens will be received in a swap.
Returns: Output token amount, factoring in a 0.3% fee.

Deployment & Testing Notes
Deployer Address: 0x24dF8324b227742482d4b4FA08506Cf84a276bd7
Test Tokens: ERC-20 tokens deployed on Sepolia with sufficient supply.
Test Functions Used: addLiquidity, removeLiquidity, swapExactTokensForTokens, getAmountOut, getPrice
Gas optimized and validated with realistic parameters.



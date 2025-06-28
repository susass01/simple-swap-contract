**SimpleSwap \- Smart Contract**

This repository contains the \`SimpleSwap\` smart contract, which replicates basic functionalities of decentralized exchanges like Uniswap. The contract allows users to:

\- Add and remove liquidity to token pairs.  
\- Swap one ERC20 token for another.  
\- Query the price of a token.  
\- Calculate expected output amounts.

✅ Features

\- Liquidity management with reserve tracking.  
\- Token swapping with slippage protection.  
\- Event emission for external monitoring.  
\- Price and output estimation.

🛠️ Technologies

\- Solidity \`^0.8.0\`  
\- OpenZeppelin ERC20  
\- Remix IDE for testing and deployment  
\- Sepolia testnet

📄 Contract Address (Sepolia) 0x79102cd202BB93575F079a64213f5ddBCf725Cfd


📦 Contracts Deployed

\- \*\*TokenA\*\*: \`0xA73025d7F27A2B3c298eC776890ddf36801EfAc0\`  
\- \*\*TokenB\*\*: \`0xd008F7Cccc30fc317934BbC0c4B1EE7DcD108D1C\`  
\- \*\*SimpleSwap\*\*: \`0x79102cd202BB93575F079a64213f5ddBCf725Cfd\`

🚀 How to Use

**1\. Deploy Contracts**

Deploy the following contracts:

\- \`TokenA.sol\` and \`TokenB.sol\` with an initial supply.  
\- \`SimpleSwap.sol\` after deploying tokens.

**2\. Add Liquidity**

Call \`approve()\` on both tokens to allow SimpleSwap to move them.

**\`\`\`solidity**  
TokenA.approve(simpleSwapAddress, amountA);  
TokenB.approve(simpleSwapAddress, amountB);

**Then call:**

addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);

**3\. Swap Token**

swapExactTokensForTokens(amountIn, amountOutMin, \[tokenA, tokenB\], to, deadline);

**4\. Remove Liquidity**

removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

**Verification**  
The contract was deployed and verified on the Sepolia network


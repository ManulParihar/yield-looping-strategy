## yield-looping-strategy
The yield looping strategy is a looping strategy built on ERC-4626 vault and uses Aave to borrow and lend wstETH/wETH token-pair to maximise profit.  
The YieldLooping.sol smart contract inherits BaseStrategy from Yearn's tokenized-strategy. BaseStrategy is an abstract ERC-4626 compliant vault which requires 3 main functions to be defined - `_deployFunds`, `_freeFunds`, `_harvestAndReport`.  

## Functions
* *_deployFunds* - Deploys funds present in the vault to Aave. The DAO can decide when to push funds to this strategy and when to use the funds. The function implements the looping strategy with max loop length set to 3. The maximum length of loop can be calculated off-chain to save some computational cost.  
* *_freeFunds* - Withdraws wstETH from Aave. This again cann be decided by the DAO.  
* *_harvestAndReport* - This function calculates and returns the total rewards accrued. Currently it returns total rewards calculated by `_totalValue` function, but more functionalities can be added.  
* *getVaultRate* - Returns the rate for vault token ("ynLoopWstETH").  

## Enhancements
If given more time to enhance the functionalities, following enhancements could be made:
1. Use WrappedTokenGateway to convert ETH to wETH before sending to Aave.  
2. Use Aave's SwapRouter to swap between assets: wETH <> wstETH
3. Instead of using hardcoded LTV, we could fetch LTV from Aave.  
4. Dynamically calculate number of profitable loops. The MAX_LOOP length would still exist but with higher threshold.  
5. `_harvestAndReport` function could re-deploy any idle funds apart from just calculating rewards. 

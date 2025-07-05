# Meta-Vault proof of concept (in lack of a better name)

This project aims to be presented at EthGlobal 2025.


A manager pushes commands to the meta vaults as well as addresses of ERC4626 middlewares.  


- The main contract works with the Meta-Vault Token (MVT)
- No on-chain rebalancing.
- When receiving liquidity, the liquidity is distributed to the middlewares using the weight of current liquidity.


At any time, the vault has the following assets and liabilities:

| Liability               | Assets                        |
|-------------------------|-------------------------------|
| Meta-Vault Shares (MVS) | Underlying Asset Shares (UAS) |
| Count:     $L$          | Count: $S_i$      |


The manager commands the weights of the share count per underlying asset as follows:  
$$w_i=\frac{|S_i|}{|Assets|}$$

When the user sends liquidity onto the MV, the later dispaches the liquidity respecting these weights.

When the prices changes, the weight of UAS stay the same, and the manager can rebalance the underlying assets by changing the weights accordingly.



## Example

The manager adds two vaults as underlying assets.
They target a 50%/50% weighting. Their tokens to share ratios are respectively 1 and 2.
He can there for command the following set of weights: 
$$W = (1/4, 3/4)$$









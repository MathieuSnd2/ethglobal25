# Meta-Vault proof of concept (in lack of a better name)

This project aims to be presented at EthGlobal 2025.



### Motivation 

Decentralized finance yield opportunities are countless in the ethereum eco-system.
They are split accross different numerous lending platforms, liquidity providing pools, staking protocols, automated market makers, and others.


A lot of these are wrappable in ERC-4626 complient vaults. Vaults aims at gathering opportunities on a given platform.
It can become hard to follow investments and track positions accross all of these platforms,
Our solution is to aggregate these yield opportunities into higher-level aggregator vaults: we called Meta-Vaults.



### Technical details


A manager has a high level strategy, e.g. 30% staking on Vault A, 20% lending on Vault B and 50% liquidity providing on vault C.
Meta-Vaults enable them to use a factory to deploy a decentralized vault and leverage their own strategy, in
  to the meta vaults as well as addresses of ERC4626 middlewares.  


- The main contract works with the Meta-Vault Token (MVT)
- No on-chain rebalancing.
- When receiving liquidity, the liquidity is distributed to the middlewares using the weight of current liquidity.


At any time, the meta-vault has the following assets and liabilities:

| Liability               | Assets                        |
|-------------------------|-------------------------------|
| Meta-Vault Shares (MVS) | Underlying Asset Shares (UAS) |
| Count:     $L$          | Count: $S_i$      |


The manager commands the weights of the valuation of the underlying tokens in the sub-vaults using a subsequent withdraw/redeem call.

When the user sends liquidity onto the meta-vault (MV), the later dispaches the liquidity respecting these weights.

When the user withdraws however, the MV 
When the prices changes, the weight of UAS stay the same, and the manager can rebalance the underlying assets by changing the weights accordingly.


## Going further

Although this project is really promissing, we couldn't get all the features done during this hackathon.
This section presents the main features we would thrive implement.

### Rebalancing

The contract should contain the currator address to 


### Fees


### Factory


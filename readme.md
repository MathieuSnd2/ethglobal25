# Meta-Vault proof of concept (in lack of a better name)

This project aims to be presented at EthGlobal 2025.



### Motivation 

Decentralized finance yield opportunities are countless in the ethereum eco-system.
They are split accross different numerous lending platforms, liquidity providing pools, staking protocols, automated market makers, and others.


A lot of these are wrappable in ERC-4626 complient vaults. Vaults aims at gathering opportunities on a given platform.
It can become hard to follow investments and track positions accross all of these platforms,
Our solution is to aggregate these yield opportunities into higher-level aggregator vaults: we called Meta-Vaults.


A currator has a high level strategy, e.g. 30% staking on Vault A, 20% lending on Vault B and 50% liquidity providing on vault C.
Meta-Vaults enable them to use a Factory to deploy a decentralized vault and leverage their own strategy, in exchange for a fee.
These vaults could be used for arbitraging or even market making.


If used broadly, it would benefit the entire eco-system to bring more liquidity and forward it to all sides of DeFi.



### Technical details


At any time, the meta-vault has the following assets and liabilities:

| Liability               | Assets                        |
|-------------------------|-------------------------------|
| Meta-Vault Shares (MVS) | Underlying Asset Shares (UAS) |

When receiving liquidity, the liquidity is distributed to the middlewares following the weights. 
When total assets of underlying vaults change, the currator updates the weights through a dedicated funciton, which would make a rebalancing.
The rebalancing and weight update system is not yet implemented by our team.


## Going further

Although this project is really promissing, we couldn't get all the features done during this hackathon.
This section presents the main features we would thrive implement.

### Rebalancing

The contract should contain the currator address to 


### Fees


### Factory


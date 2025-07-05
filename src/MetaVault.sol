// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Implementation of the MetaVault aggregator PoC for ethglobal 2025 edition.
 * 
 * This vault dispatches liquidity to middle wares following weights given by the Manager.
 *  
 */
contract MetaVault is ERC4626 {
    IERC4626[] internal middleWares;
    /**
     * Fixed point weights:
     * 2^256 = 1
     */ 
    uint256[] internal shareWeights; 

    address internal Manager;


    
    constructor(IERC20 asset_, IERC4626[] memory middleWares_, uint256[] memory shareWeights_)
        ERC20("MetaVault Share Token", "MVS")
        ERC4626(asset_)
    {
        middleWares = middleWares_;
        shareWeights = shareWeights_;
    }


    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() public view override(ERC4626) returns (uint256 totalManagedAssets) {
        uint256 sum;
        for(uint32 i = 0; i < middleWares.length; i++) {
            sum += middleWares[i].totalAssets();
        }
        return sum;
    }

    function fixedPointMul(uint256 a, uint256 b, uint8 shift) private pure returns (uint256) {
        return a * b >> shift;
    }

    function tokenWeights() private view returns (uint256[] memory) {
        uint256[] memory tokenWeights = new uint256[](middleWareCnt);
        uint32 sum = 0;
        for (uint32 i = 0; i < middleWareCnt; i++) {
            tokenWeights[i] = middleWares[i].previewWithdraw(uint256(1) << 128);
            sum += tokenWeights[i];
        }

        // normalize weights
        for (uint32 i = 0; i < middleWareCnt; i++) {
            tokenWeights[i] /= sum;
        }
        return tokenWeights;
    }
    
    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) public override(ERC4626) returns (uint256 shares) {
        require(shareWeights.length == middleWares.length, "ShareWeights and middleWares length mismatch");
        uint32 middleWareCnt = middleWares.length;

        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256[] memory weights = tokenWeights();

        uint256 totalAllocated;
        for (uint32 i = 0; i < middleWareCnt; i++) {
            // might save gas by using mint rather than deposit?
            (, uint256 allocated) = fullMul(assets, weights[i]);

            middleWares[i].deposit(allocated, receiver);
            totalAllocated += allocated;
        }

        // Handle any dust due to truncation
        uint256 dust = assets - totalAllocated;
        if (dust > 0) {
            // give it to the first middleware
            middleWares[0].deposit(dust, receiver);
        }

        // Optionally mint shares
        shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        return shares;
    }

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}
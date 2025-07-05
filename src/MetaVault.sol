// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ERC4626, IERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Implementation of the MetaVault aggregator PoC for ethglobal 2025 edition.
 *
 * This vault dispatches liquidity to middle wares following weights given by the Manager.
 *
 */
contract MetaVault is ERC4626 {
    using Math for uint256;

    uint256 private constant WAD = 1e18;
    uint8 private constant fpShift = 128;

    IERC4626[] internal middleWares;
    /**
     * Fixed point weights:
     * 2^256 => 100%
     */
    uint256[] internal weights;

    address internal Manager;

    constructor(IERC20 asset_, IERC4626[] memory middleWares_, uint256[] memory weights_)
        ERC20("MetaVault Share Token", "MVS")
        ERC4626(asset_)
    {
        if (middleWares_.length != weights_.length) revert InvalidLength();
        middleWares = middleWares_;
        weights = weights_;
    }

    function totalAssets() public view override(ERC4626) returns (uint256) {
        uint256 sum;
        for (uint32 i = 0; i < middleWares.length; i++) {
            sum += middleWares[i].convertToAssets(middleWares[i].balanceOf(address(this)));
        }
        return sum;
    }

    function fixedPointMul(uint256 a, uint256 b, uint8 shift) private pure returns (uint256) {
        return a * b >> shift;
    }

    function dispatch(uint256 assets) private {
        for (uint32 i = 0; i < middleWares.length; i++) {
            uint256 allocated = fixedPointMul(assets, weights[i], fpShift);
            middleWares[i].deposit(allocated, address(this));
        }
    }

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
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override(ERC4626)
        returns (uint256 shares)
    {
        shares = super.withdraw(assets, receiver, owner);
        uint256 proportion = shares.mulDiv(WAD, totalSupply());

        for (uint32 i; i < middleWares.length; i++) {
            uint256 sharesToRedeem = middleWares[i].totalSupply().mulDiv(proportion, WAD);
            middleWares[i].redeem(sharesToRedeem, address(this), address(this));
        }
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
        shares = super.deposit(assets, receiver);
        dispatch(assets);
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
    function mint(uint256 shares, address receiver) public override(ERC4626) returns (uint256 assets) {
        assets = super.mint(shares, receiver);
        dispatch(assets);
        return assets;
    }

    error InvalidLength();
}

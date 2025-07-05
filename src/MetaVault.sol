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

    /// @dev Fixed point weights: 2^128 => 100%
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

    /// @inheritdoc IERC4626
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

    /// @inheritdoc IERC4626
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override(ERC4626)
        returns (uint256 shares)
    {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }
        shares = previewWithdraw(assets);
        uint256 proportion = shares.mulDiv(WAD, totalSupply());

        for (uint32 i; i < middleWares.length; i++) {
            uint256 sharesToRedeem = middleWares[i].totalSupply().mulDiv(proportion, WAD);
            middleWares[i].redeem(sharesToRedeem, address(this), address(this));
        }

        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 shares, address receiver, address owner)
        public
        override(ERC4626)
        returns (uint256 assets)
    {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }
        assets = previewRedeem(shares);
        uint256 proportion = shares.mulDiv(WAD, totalSupply());

        for (uint32 i; i < middleWares.length; i++) {
            uint256 sharesToRedeem = middleWares[i].totalSupply().mulDiv(proportion, WAD);
            middleWares[i].redeem(sharesToRedeem, address(this), address(this));
        }

        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver) public override(ERC4626) returns (uint256 shares) {
        shares = super.deposit(assets, receiver);
        dispatch(assets);
        return shares;
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver) public override(ERC4626) returns (uint256 assets) {
        assets = super.mint(shares, receiver);
        dispatch(assets);
        return assets;
    }

    error InvalidLength();
}

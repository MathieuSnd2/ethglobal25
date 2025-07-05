// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MetaVault.sol";
import "../src/SimpleMiddleware.sol";
import "./MockERC20.sol";

contract MyVaultScenarioTest is Test {
    MetaVault vault;
    MockERC20 asset;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        asset = new MockERC20("MockToken", "MTK", address(this), 0);
        IERC4626[] memory middleWares = new IERC4626[](2);
        middleWares[0] = new SimpleVault(asset);
        middleWares[1] = new SimpleVault(asset);
        uint256[] memory weights = new uint256[](2);
        weights[0] = (50 << 128) / 100; // 50%
        weights[1] = (50 << 128) / 100; // 50%

        vault = new MetaVault(ERC20(address(asset)), middleWares, weights);

        // Mint tokens to users
        asset.mint(alice, 10 ether);
        asset.mint(bob, 10 ether);

        vm.prank(alice);
        asset.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        asset.approve(address(vault), type(uint256).max);
    }

    function testScenario() public {
        // 1. Alice deposits 1 ETH
        vm.startPrank(alice);
        vault.deposit(1 ether, alice);
        vm.stopPrank();

        assertEq(vault.totalAssets(), 1 ether, "Step 1");
        assertEq(vault.balanceOf(alice), 1 ether, "Step 1 LP");

        // 2. Alice withdraws 0.5 ETH
        vm.prank(alice);
        vault.withdraw(0.5 ether, alice, alice);

        assertEq(vault.totalAssets(), 0.5 ether, "Step 2");
        assertApproxEqAbs(vault.balanceOf(alice), 0.5 ether, 1, "Step 2 LP");

        // 3. Bob deposits 0.5 ETH
        vm.startPrank(bob);
        vault.deposit(0.5 ether, bob);
        vm.stopPrank();

        assertEq(vault.totalAssets(), 1 ether, "Step 3");
        assertApproxEqAbs(vault.balanceOf(bob), 0.5 ether, 1, "Step 3 LP");

        // 4. Alice deposits 0.5 ETH
        vm.prank(alice);
        vault.deposit(0.5 ether, alice);

        assertEq(vault.totalAssets(), 1.5 ether, "Step 4");
        assertApproxEqAbs(vault.balanceOf(alice), 1 ether, 1, "Step 4 LP");

        // 5. Bob deposits 1 ETH
        vm.prank(bob);
        vault.deposit(1 ether, bob);

        assertEq(vault.totalAssets(), 2.5 ether, "Step 5");
        assertApproxEqAbs(vault.balanceOf(bob), 1.5 ether, 1, "Step 5 LP");

        // 6. Alice withdraws 0.5 ETH
        vm.prank(alice);
        vault.withdraw(0.5 ether, alice, alice);

        assertApproxEqAbs(vault.totalAssets(), 2 ether, 1, "Step 6");
        assertApproxEqAbs(vault.balanceOf(alice), 0.75 ether, 1, "Step 6 LP");

        // 7. Bob withdraws 1 ETH
        vm.prank(bob);
        vault.withdraw(1 ether, bob, bob);

        assertApproxEqAbs(vault.totalAssets(), 1 ether, 1, "Step 7");
        assertApproxEqAbs(vault.balanceOf(bob), 0.5 ether, 1, "Step 7 LP");

        // 8. Everyone withdraws everything
        vm.prank(alice);
        vault.redeem(vault.balanceOf(alice), alice, alice);

        vm.prank(bob);
        vault.redeem(vault.balanceOf(bob), bob, bob);

        assertEq(vault.totalAssets(), 0, "Step 8");
        assertEq(vault.totalSupply(), 0, "Step 8");
    }
}

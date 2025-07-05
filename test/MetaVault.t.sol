// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MetaVault.sol";
import "../src/SimpleMiddleware.sol";
import "./MockERC20.sol";

contract MyVaultScenarioTest is Test {
    MetaVault metaVault;
    MockERC20 asset;
    IERC4626[] middleWares;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        asset = new MockERC20("MockToken", "MTK", address(this), 0);
        middleWares = new IERC4626[](2);
        middleWares[0] = new SimpleMiddleware(asset);
        middleWares[1] = new SimpleMiddleware(asset);
        uint256[] memory weights = new uint256[](2);
        weights[0] = (50 << 128) / 100; // 50%
        weights[1] = (50 << 128) / 100; // 50%

        metaVault = new MetaVault(asset, middleWares, weights);

        // Mint tokens to users
        asset.mint(alice, 10 ether);
        vm.startPrank(alice);
        asset.approve(address(metaVault), 100 ether);
        vm.stopPrank();
        asset.mint(bob, 10 ether);

        vm.startPrank(bob);
        asset.approve(address(metaVault), 100 ether);
        vm.stopPrank();
    }

    function testScenario() public {
        // 1. Alice deposits 1 ETH
        vm.startPrank(alice);
        asset.approve(address(metaVault), 1 ether);
        metaVault.deposit(1 ether, alice);
        vm.stopPrank();

        assertEq(metaVault.totalAssets(), 1 ether, "Step 1");
        assertEq(metaVault.balanceOf(alice), 1 ether, "Step 1 LP");

        assertEq(metaVault.totalAssets(), 1 ether, "Step 1");
        assertEq(metaVault.balanceOf(alice), 1 ether, "Step 1 LP");

        assertEq(middleWares[0].totalAssets(), 0.5 ether, "Step 1");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 0.5 ether, "Step 1 LP");
        assertEq(middleWares[1].totalAssets(), 0.5 ether, "Step 1");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 0.5 ether, "Step 1 LP");

        // 2. Alice withdraws 0.5 ETH
        vm.startPrank(alice);
        metaVault.withdraw(0.5 ether, alice, alice);

        assertEq(metaVault.totalAssets(), 0.5 ether, "Step 2");
        assertApproxEqAbs(metaVault.balanceOf(alice), 0.5 ether, 1, "Step 2 LP");

        assertEq(middleWares[0].totalAssets(), 0.25 ether, "Step 2");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 0.25 ether, "Step 2 LP");
        assertEq(middleWares[1].totalAssets(), 0.25 ether, "Step 2");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 0.25 ether, "Step 2 LP");

        // 3. Bob deposits 0.5 ETH
        vm.startPrank(bob);
        asset.approve(address(metaVault), 1 ether);
        metaVault.deposit(0.5 ether, bob);
        vm.stopPrank();

        assertEq(metaVault.totalAssets(), 1 ether, "Step 3");
        assertApproxEqAbs(metaVault.balanceOf(bob), 0.5 ether, 1, "Step 3 LP");

        assertEq(middleWares[0].totalAssets(), 0.5 ether, "Step 3");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 0.5 ether, "Step 3 LP");
        assertEq(middleWares[1].totalAssets(), 0.5 ether, "Step 3");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 0.5 ether, "Step 3 LP");

        // 4. Alice deposits 0.5 ETH

        vm.startPrank(alice);
        asset.approve(address(metaVault), 1 ether);
        metaVault.deposit(0.5 ether, alice);
        vm.stopPrank();

        assertEq(metaVault.totalAssets(), 1.5 ether, "Step 4");
        assertApproxEqAbs(metaVault.balanceOf(alice), 1 ether, 1, "Step 4 LP");
        assertEq(middleWares[0].totalAssets(), 0.75 ether, "Step 4");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 0.75 ether, "Step 4 LP");
        assertEq(middleWares[1].totalAssets(), 0.75 ether, "Step 4");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 0.75 ether, "Step 4 LP");


        // 5. Bob deposits 1 ETH
        vm.startPrank(bob);
        asset.approve(address(metaVault), 1 ether);
        metaVault.deposit(1 ether, bob);

        assertEq(metaVault.totalAssets(), 2.5 ether, "Step 5");
        assertApproxEqAbs(metaVault.balanceOf(bob), 1.5 ether, 1, "Step 5 LP");

        assertEq(middleWares[0].totalAssets(), 1.25 ether, "Step 5");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 1.25 ether, "Step 5 LP");
        assertEq(middleWares[1].totalAssets(), 1.25 ether, "Step 5");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 1.25 ether, "Step 5 LP");

        // 6. Alice withdraws 0.5 ETH
        vm.startPrank(alice);
        metaVault.withdraw(0.5 ether, alice, alice);

        assertApproxEqAbs(metaVault.totalAssets(), 2 ether, 1, "Step 6");
        assertApproxEqAbs(metaVault.balanceOf(alice), 0.5 ether, 1, "Step 6 LP");

        assertEq(middleWares[0].totalAssets(), 1 ether, "Step 6");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 1 ether, "Step 6");
        assertEq(middleWares[1].totalAssets(), 1 ether, "Step 6");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 1 ether, "Step 6");

        // 7. Bob withdraws 1 ETH
        vm.startPrank(bob);
        metaVault.withdraw(1 ether, bob, bob);

        assertApproxEqAbs(metaVault.totalAssets(), 1 ether, 1, "Step 7");
        assertApproxEqAbs(metaVault.balanceOf(bob), 0.5 ether, 1, "Step 7 LP");

        assertEq(middleWares[0].totalAssets(), 0.5 ether, "Step 7");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 0.5 ether, "Step 7");
        assertEq(middleWares[1].totalAssets(), 0.5 ether, "Step 7");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 0.5 ether, "Step 7");

        // 8. Everyone withdraws everything
        vm.startPrank(alice);
        metaVault.redeem(metaVault.balanceOf(alice), alice, alice);

        vm.startPrank(bob);
        metaVault.redeem(metaVault.balanceOf(bob), bob, bob);

        assertEq(metaVault.totalAssets(), 0, "Step 8");
        assertEq(metaVault.totalSupply(), 0, "Step 8");

        assertEq(middleWares[0].totalAssets(), 0 ether, "Step 8");
        assertEq(middleWares[0].balanceOf(address(metaVault)), 0 ether, "Step 8");
        assertEq(middleWares[1].totalAssets(), 0 ether, "Step 8");
        assertEq(middleWares[1].balanceOf(address(metaVault)), 0 ether, "Step 8");

    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Router} from "../src/Router.sol";
import {XNET} from "../test/mocks/token.sol";

contract RouterTest is Test {
    Router public router;
    XNET private token;
    address private owner;

    function setUp() public {
        router = new Router(200);
        token = new XNET();
    }

    function testInitialArrayLimit() public {
        assertEq(router.getArrayLimit(), 200);
        assertEq(router.getBaseFee(), 0);
        assertEq(router.getFee(), 0);
        assertEq(router.getDiscountStep(), 0);
        assertEq(router.getDiscountRate(address(0x123)), 0);
        assertEq(router.getCurrentFee(address(0x123)), 0);
        router.setFeeManager(address(0x123));
        assertEq(router.feeManager(), address(0x123));
        vm.expectRevert("Zero batch");
        router.setArrayLimit(0);
    }

    function testSetFee() public {
        router.setFee(1 ether);
        assertEq(router.getFee(), 1 ether);
    }

    function testSetBaseFee() public {
        router.setBaseFee(0.1 ether);
        assertEq(router.getBaseFee(), 0.1 ether);
    }

    function testSetDiscountStep() public {
        router.setDiscountStep(0.01 ether);
        assertEq(router.getDiscountStep(), 0.01 ether);
    }

    function testSendToken() public {
        vm.expectRevert();
        router.setArrayLimit(0);
        uint256 amount = 100e18; // 100 tokens
        address recipient = address(0x1);

        token.approve(address(router), amount);

        router.setArrayLimit(1);
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        recipients[0] = recipient;
        amounts[0] = amount / 2;

        recipients[1] = address(0x123);
        amounts[1] = amount / 2;

        vm.expectRevert("Above batch limit");
        router.sendToken(address(token), recipients, amounts);

        router.setArrayLimit(200);
        router.sendToken(address(token), recipients, amounts);
        assertEq(token.balanceOf(recipients[0]), amounts[0]);
        assertEq(token.balanceOf(recipients[1]), amounts[1]);

        recipients = new address[](1);
        amounts = new uint256[](2);
        amounts[0] = amount / 2;
        amounts[1] = amount / 2;
        vm.expectRevert("Not equal length");
        router.sendToken(address(token), recipients, amounts);
    }

    function testSendTokenFailsWithoutFee() public {
        router.setFee(1 ether);
        address recipient = address(0x1);

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = recipient;
        amounts[0] = 100e18; // 100 tokens

        vm.expectRevert("Not enough fee");
        router.sendToken(address(token), recipients, amounts);
    }

    function testSendNative() public payable {
        router.setBaseFee(0.03 ether);
        router.setFee(0);
        router.setDiscountStep(0);

        address recipient = address(0x1);

        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        recipients[0] = recipient;
        recipients[1] = recipient;
        amounts[0] = 0.1 ether;
        amounts[1] = 0.2 ether;

        // This simulates sending 0.11 ether to cover the fee + amount
        vm.deal(address(this), 0.33 ether);
        router.sendNative{value: 0.33 ether}(recipients, amounts);
    }

    function testRecoverNativeAndToken() public payable {
        router.setBaseFee(0.03 ether);
        router.setFee(0);
        router.setDiscountStep(0);

        address recipient = address(0x1);

        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        recipients[0] = recipient;
        recipients[1] = recipient;
        amounts[0] = 0.1 ether;
        amounts[1] = 0.2 ether;

        // This simulates sending 0.11 ether to cover the fee + amount
        vm.deal(address(this), 0.33 ether);
        router.sendNative{value: 0.33 ether}(recipients, amounts);
        router.recoverTokens(router.feeReciever());
        vm.assertEq(router.feeReciever().balance, router.getBaseFee());

        uint256 balance = token.balanceOf(router.feeReciever());
        token.approve(address(this), 333e18);
        token.transferFrom(address(this), address(router), 333e18);
        router.setFeeReceiver(address(0x1));
        router.recoverTokens(address(token));
        vm.assertEq(token.balanceOf(router.feeReciever()), balance + 333e18);
        assertEq(router.getCurrentFee(address(0x123)), router.getBaseFee());
    }

    function testSendTokenExcludedFromFee() public {
        router.setFee(1 ether);
        address recipient = address(0x1);

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = recipient;
        amounts[0] = 100e18; // 100 tokens

        token.approve(address(router), amounts[0]);

        router.excludeFromFee(address(this));
        vm.prank(address(0x123));
        vm.expectRevert();
        router.excludeFromFee(address(this));
        vm.stopPrank();
        router.sendToken(address(token), recipients, amounts);
        vm.assertEq(token.balanceOf(recipients[0]), amounts[0]);
        assertEq(router.getCurrentFee(address(0x123)), router.getFee());
    }

    function testFallbackEther() public {
        vm.deal(address(this), 0.1 ether);
        vm.expectRevert("Fallback not allowed");
        (bool success, ) = address(router).call{value: 0.1 ether}("");
        assertFalse(!success, "Fallback was incorrectly allowed.");
    }

    function testFallbackToken() public {
        vm.deal(address(this), 0.1 ether);
        vm.expectRevert("Fallback not allowed");
        (bool success, ) = address(router).call{value: 0.1 ether}("Kek");
        assertFalse(!success, "Fallback was incorrectly allowed.");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Router} from "../src/Router.sol";
import {XNET} from "../test/mocks/token.sol";

contract RouterFuzzTest is Test {
    Router public router;
    XNET private token;
    address private owner;

    function setUp() public {
        router = new Router(200);
        token = new XNET();
    }

    function testFuzzInitialArrayLimit(uint256 array) public {
        vm.assume(array > 0);
        router.setArrayLimit(array);
        assertEq(router.getArrayLimit(), array);
    }

    function testFuzzSetFee(uint256 value) public {
        router.setFee(value);
        assertEq(router.getFee(), value);
    }

    function testFuzzSetBaseFee(uint256 value) public {
        router.setBaseFee(value);
        assertEq(router.getBaseFee(), value);
    }

    function testFuzzSetDiscountStep(uint256 value) public {
        router.setDiscountStep(value);
        assertEq(router.getDiscountStep(), value);
    }

    function testFuzzSendToken(uint256 _amount) public {
        vm.assume(_amount <= 24000000000 ether);
        uint256 amount = _amount;
        address recipient = address(0x1);

        token.approve(address(router), amount);

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = recipient;
        amounts[0] = amount;

        router.sendToken(address(token), recipients, amounts);
        assertEq(token.balanceOf(recipients[0]), amounts[0]);
    }

    function testFuzzSendTokenFailsWithoutFee(
        uint256 _amount,
        uint256 fee
    ) public {
        vm.assume(fee > 0);
        router.setFee(fee);
        address recipient = address(0x1);

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = recipient;
        amounts[0] = _amount;

        vm.expectRevert("Not enough fee");
        router.sendToken(address(token), recipients, amounts);
    }

    function testFuzzSendNative(
        uint256 baseFee,
        uint256 fee,
        uint256 discountStep,
        uint256 _amount
    ) public payable {
        vm.assume(discountStep < 100 ether);
        vm.assume(fee < 10 ether);
        vm.assume(baseFee < 10 ether);
        vm.assume(_amount <= 24000000000 ether);

        router.setBaseFee(baseFee);
        router.setFee(fee);
        router.setDiscountStep(discountStep);

        address recipient = address(0x1);

        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        recipients[0] = recipient;
        recipients[1] = recipient;
        amounts[0] = _amount;
        amounts[1] = _amount * 2;

        uint256 tVal = amounts[0] + amounts[1] + baseFee + fee;

        vm.deal(address(this), tVal);
        router.sendNative{value: tVal}(recipients, amounts);
    }

    function testFuzzRecoverNativeAndToken(
        uint256 baseFee,
        uint256 fee,
        uint256 discountStep,
        uint256 _amount
    ) public payable {
        vm.assume(discountStep < 100 ether);
        vm.assume(fee < 10 ether);
        vm.assume(baseFee < 10 ether);
        vm.assume(_amount > 0 && _amount < (24000000000 ether) / 3);

        router.setBaseFee(baseFee);
        router.setFee(fee);
        router.setDiscountStep(discountStep);

        address recipient = address(0x1);

        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        recipients[0] = recipient;
        recipients[1] = recipient;
        amounts[0] = _amount;
        amounts[1] = _amount * 2;

        uint256 tVal = amounts[0] + amounts[1] + baseFee + fee;

        vm.deal(address(this), tVal);
        router.sendNative{value: tVal}(recipients, amounts);
        router.recoverTokens(router.feeReciever());
        vm.assertEq(
            router.feeReciever().balance,
            router.getBaseFee() + router.getFee()
        );

        uint256 balance = token.balanceOf(router.feeReciever());
        token.approve(address(this), _amount * 3);
        token.transferFrom(address(this), address(router), _amount * 3);
        router.setFeeReceiver(address(0x1));
        router.recoverTokens(address(token));
        vm.assertEq(
            token.balanceOf(router.feeReciever()),
            balance + _amount * 3
        );
    }

    function testFuzzSendTokenExcludedFromFee(
        uint256 fee,
        uint256 _amount
    ) public {
        vm.assume(_amount > 0 && _amount < (24000000000 ether) / 3);
        router.setFee(fee);
        address recipient = address(0x1);

        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = recipient;
        amounts[0] = _amount;

        token.approve(address(router), amounts[0]);

        router.excludeFromFee(address(this));
        router.sendToken(address(token), recipients, amounts);
        vm.assertEq(token.balanceOf(recipients[0]), amounts[0]);
    }
}

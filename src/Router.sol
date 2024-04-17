//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Router is Ownable {
    event Sent(uint256 total, address tokenAddress);
    event SentNative(uint256 total);
    event RecoveredToken(uint256 total, address token);
    event RecoveredNative(uint256 total);
    event SentFee(uint256 total, address tokenAddress);

    modifier hasFee() {
        if (
            calculateCurrentFee(msg.sender) > 0 && !excludedFromFee[msg.sender]
        ) {
            uint256 currentFee = calculateCurrentFee(msg.sender);
            require(msg.value >= currentFee, "Not enough fee");
            (bool transferTx /*memory data */, ) = feeReciever.call{
                value: currentFee
            }("");
            require(transferTx, "Fee txn failed");
            emit SentFee(currentFee, feeReciever);
        }
        _;
    }

    mapping(address => uint256) txnCount;
    mapping(address => bool) excludedFromFee;

    uint256 private fee;
    uint256 private baseFee;
    uint256 private discountStep;
    uint256 private arrayLimit;
    address public feeManager;
    address payable public feeReciever;

    constructor(uint256 _arrayLimit) Ownable(msg.sender) {
        arrayLimit = _arrayLimit;
        feeManager = msg.sender;
    }

    fallback() external payable {
        revert("Fallback not allowed");
    }

    receive() external payable {
        revert("Fallback not allowed");
    }

    function setArrayLimit(uint256 _arrayLimit) external onlyOwner {
        require(_arrayLimit != 0, "Zero batch");
        arrayLimit = _arrayLimit;
    }

    function setDiscountStep(uint256 _discountStep) external onlyOwner {
        discountStep = _discountStep;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    function setFeeReceiver(address _feeReciever) external onlyOwner {
        feeReciever = payable(_feeReciever);
    }

    function excludeFromFee(address _address) external {
        require(msg.sender == feeManager, "Not fee manager");
        excludedFromFee[_address] = !excludedFromFee[_address];
    }

    function sendToken(
        address _token,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external payable hasFee {
        uint256 total = 0;
        require(_recipients.length == _amounts.length, "Not equal length");
        require(_recipients.length <= arrayLimit, "Above batch limit");
        IERC20 token = IERC20(_token);
        for (uint256 i = 0; i < _recipients.length; i++) {
            token.transferFrom(msg.sender, _recipients[i], _amounts[i]);
            total += _amounts[i];
        }
        txnCount[msg.sender] += _recipients.length;
        emit Sent(total, _token);
    }

    function sendNative(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external payable hasFee {
        uint256 total = 0;
        require(_recipients.length == _amounts.length, "Not equal length");
        require(_recipients.length <= arrayLimit, "Above batch limit");
        for (uint256 i = 0; i < _recipients.length; i++) {
            (bool transferTx /*memory data */, ) = _recipients[i].call{
                value: _amounts[i]
            }("");
            require(transferTx, "Not enough funds provided");
            total += _amounts[i];
        }
        txnCount[msg.sender] += _recipients.length;
        emit SentNative(total);
    }

    function recoverTokens(address _token) external {
        if (_token == feeReciever) {
            uint256 amount = address(this).balance;
            (bool transferTx /*memory data */, ) = feeReciever.call{
                value: amount
            }("");
            require(transferTx, "Recovery failed");
            emit RecoveredNative(amount);
            return;
        }
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(feeReciever, balance);
        emit RecoveredToken(balance, _token);
    }

    function getDiscountRate(address _user) public view returns (uint256) {
        return txnCount[_user] * discountStep;
    }

    function getCurrentFee(address _user) public view returns (uint256) {
        if (fee > discountRate(msg.sender)) {
            return fee - discountRate(_user);
        } else {
            return baseFee;
        }
    }

    function getFee() public view returns (uint256) {
        return fee;
    }

    function getBaseFee() public view returns (uint256) {
        return baseFee;
    }

    function getDiscountStep() public view returns (uint256) {
        return discountStep;
    }

    function getArrayLimit() public view returns (uint256) {
        return arrayLimit;
    }

    function discountRate(address _user) internal view returns (uint256) {
        return txnCount[_user] * discountStep;
    }

    function calculateCurrentFee(
        address _user
    ) internal view returns (uint256) {
        if (fee > discountRate(msg.sender)) {
            return fee - discountRate(_user);
        } else {
            return baseFee;
        }
    }
}

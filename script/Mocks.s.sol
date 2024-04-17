// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {XNET} from "../test/mocks/token.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        vm.startBroadcast(deployerPrivateKey);

        new XNET();

        vm.stopBroadcast();
    }
}

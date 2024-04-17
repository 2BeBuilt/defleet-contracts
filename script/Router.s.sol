// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Router} from "../src/Router.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        vm.startBroadcast(deployerPrivateKey);

        new Router(200);

        vm.stopBroadcast();
    }
}

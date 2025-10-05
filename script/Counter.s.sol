// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1EvmManager} from "../src/L1EvmManager.sol";

contract CounterScript is Script {
    L1EvmManager public l1EvmManager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        l1EvmManager = new L1EvmManager();

        vm.stopBroadcast();
    }
}

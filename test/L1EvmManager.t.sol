// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { L1EvmManager } from "../src/L1EvmManager.sol";
import { L1Write } from "../src/L1Write.sol";

import { MockPrecompile801 } from "./mock/MockPrecompile801.sol";

contract L1EvmManagerTest is Test {

    L1EvmManager public l1EvmManager;
    L1Write public l1Write;
    MockPrecompile801 public mockPrecompile801;
    address public user = address(0x123);
    uint256 public ethAmount = 1 ether;
    address public constant L1_WRITE_ADDRESS = 0x3333333333333333333333333333333333333333;
    uint64 public constant L1_HYPE_TOKEN_NUMBER = 1105;
    address public PRECOMPILE_801_ADDRESS = 0x0000000000000000000000000000000000000801;

    address public constant VALIDATOR = 0x9Cd47ac47E6E9cc1441E21ff23d3B3f70AB55A33;

    event TokenDelegate(
        address indexed user,
        address indexed validator,
        uint64 _wei,
        bool isUndelegate
    );
    event CDeposit(address indexed user, uint64 _wei);
    event SpotSend(address indexed user, address indexed destination, uint64 token, uint64 _wei);

    event EvmToStaking(address indexed user, address indexed validator, uint64 _wei);
    event EvmToSpot(address indexed user, uint64 _wei);
    event EvmToContractSpot(address indexed user, uint64 _wei);
    event SendSpotOnL1(address indexed user, address indexed destination, uint64 token, uint64 _wei);

    function setUp() public {
        l1Write = new L1Write();
        
        // Deploy the mock precompile to the precompile address
        MockPrecompile801 mock = new MockPrecompile801();
        vm.etch(PRECOMPILE_801_ADDRESS, address(mock).code);
        
        // Deploy the L1Write contract to its address
        vm.etch(address(L1_WRITE_ADDRESS), address(l1Write).code);
        
        // Deploy the L1EvmManager contract
        l1EvmManager = new L1EvmManager();
        
        // Fund the test user with ETH
        vm.deal(user, 10 ether);
    }

    function test_fromEvmToStaking() public {
        vm.startPrank(user);
        
        uint64 l1Amount = uint64(ethAmount / 1e10); // Account for the division in the contract
        
        // Expect the CDeposit event with the divided amount
        vm.expectEmit(true, false, false, true);
        emit CDeposit(address(l1EvmManager), l1Amount);

        // Expect the TokenDelegate event with the divided amount
        vm.expectEmit(true, true, false, true);
        emit TokenDelegate(address(l1EvmManager), VALIDATOR, l1Amount, false);

        // Expect the EvmToStaking event with the original amount
        vm.expectEmit(true, true, false, true);
        emit EvmToStaking(user, VALIDATOR, uint64(ethAmount));
        
        // Trigger the test transaction
        l1EvmManager.fromEvmToStaking{value: ethAmount}(VALIDATOR);
        
        vm.stopPrank();
    }

    function test_fromEvmToSpot() public {
        vm.startPrank(user);

        vm.expectEmit(true, false, false, true);
        emit EvmToSpot(user, uint64(ethAmount));
        
        // 觸發測試交易
        l1EvmManager.fromEvmToSpot{value: ethAmount}();
        
        vm.stopPrank();
    }

    function test_fromEvmToContractSpot() public {
        vm.startPrank(user);

        vm.expectEmit(true, false, false, true);
        emit EvmToContractSpot(user, uint64(ethAmount));
        
        // 觸發測試交易
        l1EvmManager.fromEvmToContractSpot{value: ethAmount}();
        
        vm.stopPrank();
    }

    function test_sendHypeOnL1() public {
        address destination = address(0x456);
        uint64 _wei = 10000;
        
        // The mock precompile always returns (1000000, 500000, 200)
        // So we know the user has enough balance for this test
        
        // Start the test as the user
        vm.startPrank(user);
        
        // Expect the SpotSend event to be emitted by the precompile
        vm.expectEmit(true, true, false, true);
        emit SpotSend(user, destination, L1_HYPE_TOKEN_NUMBER, _wei);
        
        // Expect the SendSpotOnL1 event to be emitted by the L1EvmManager
        vm.expectEmit(true, true, false, true);
        emit SendSpotOnL1(user, destination, L1_HYPE_TOKEN_NUMBER, _wei);
        
        // Execute the function - this should pass since the mock returns enough balance
        l1EvmManager.sendHypeOnL1(destination, _wei);
        
        vm.stopPrank();
    }
    
    // Fuzz test for sendHypeOnL1 with random destinations and amounts
    function testFuzz_sendHypeOnL1(address destination, uint64 amount) public {
        // Ensure the amount is non-zero and doesn't cause overflows
        vm.assume(amount > 0 && amount <= 1000000);
        
        // Start the test as the user
        vm.startPrank(user);
        
        // Expect the events to be emitted
        vm.expectEmit(true, true, false, true);
        emit SpotSend(user, destination, L1_HYPE_TOKEN_NUMBER, amount);
        
        vm.expectEmit(true, true, false, true);
        emit SendSpotOnL1(user, destination, L1_HYPE_TOKEN_NUMBER, amount);
        
        // Execute the function with fuzzed inputs
        l1EvmManager.sendHypeOnL1(destination, amount);
        
        vm.stopPrank();
    }
    
    // Test gas usage of sendHypeOnL1 function
    function testGas_sendHypeOnL1() public {
        address destination = address(0x456);
        uint64 _wei = 10000;
        
        vm.startPrank(user);
        
        uint256 gasBefore = gasleft();
        l1EvmManager.sendHypeOnL1(destination, _wei);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for sendHypeOnL1:", gasUsed);
        
        // Optional: Add gas limit assertion to catch regressions
        uint256 gasLimit = 40000; // Adjust based on your requirements
        assertLt(gasUsed, gasLimit, "Gas usage exceeds limit");
        
        vm.stopPrank();
    }
    
    // Test gas usage for fromEvmToStaking
    function testGas_fromEvmToStaking() public {
        vm.startPrank(user);
        
        uint256 gasBefore = gasleft();
        l1EvmManager.fromEvmToStaking{value: ethAmount}(VALIDATOR);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for fromEvmToStaking:", gasUsed);
        
        uint256 gasLimit = 100000; // Adjust based on your requirements
        assertLt(gasUsed, gasLimit, "Gas usage exceeds limit");
        
        vm.stopPrank();
    }
}

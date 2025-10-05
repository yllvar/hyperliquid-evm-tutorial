// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { L1Read } from "../src/L1Read.sol";

import { MockPrecompile801 } from "./mock/MockPrecompile801.sol";

contract L1ReadTest is Test {
    L1Read public l1Read;
    
    // Precompile address that L1Read will call
    address public constant SPOT_BALANCE_PRECOMPILE_ADDRESS = 0x0000000000000000000000000000000000000801;

    function setUp() public {
        // Deploy the mock precompile to the precompile address
        MockPrecompile801 mock = new MockPrecompile801();
        vm.etch(SPOT_BALANCE_PRECOMPILE_ADDRESS, address(mock).code);
        
        // Deploy the L1Read contract
        l1Read = new L1Read();
    }
    
    function test_spotBalance() public view {
        // Get the balance through the L1Read contract
        L1Read.SpotBalance memory l1Balance = l1Read.spotBalance(address(0), 0);
        
        // The mock always returns (1000000, 500000, 200)
        assertEq(uint256(l1Balance.total), 1000000, "Total balance mismatch");
        assertEq(uint256(l1Balance.hold), 500000, "Hold balance mismatch");
        assertEq(uint256(l1Balance.entryNtl), 200, "EntryNtl mismatch");
    }
    
    function test_spotBalance_returnsValuesForAnyInput() public view {
        // The mock returns the same values for any input
        L1Read.SpotBalance memory l1Balance = l1Read.spotBalance(address(0x123), 1105);
        
        // The mock always returns (1000000, 500000, 200)
        assertEq(uint256(l1Balance.total), 1000000, "Total balance mismatch");
        assertEq(uint256(l1Balance.hold), 500000, "Hold balance mismatch");
        assertEq(uint256(l1Balance.entryNtl), 200, "EntryNtl mismatch");
    }
    
    // Fuzz test for spotBalance with random addresses and token IDs
    function testFuzz_spotBalance_returnsValidValues(address user, uint64 tokenId) public view {
        // This will test with a wide range of addresses and token IDs
        L1Read.SpotBalance memory l1Balance = l1Read.spotBalance(user, tokenId);
        
        // The mock should always return the same values regardless of input
        assertEq(uint256(l1Balance.total), 1000000, "Total balance mismatch");
        assertEq(uint256(l1Balance.hold), 500000, "Hold balance mismatch");
        assertEq(uint256(l1Balance.entryNtl), 200, "EntryNtl mismatch");
    }
    
    // Test gas usage of spotBalance function
    function testGas_spotBalance() public view returns (uint256) {
        uint256 gasBefore = gasleft();
        l1Read.spotBalance(address(0x123), 1105);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Log the gas usage (can be seen with -vvv flag)
        console.log("Gas used for spotBalance:", gasUsed);
        
        // Return gas used for potential assertions in the future
        return gasUsed;
    }
}
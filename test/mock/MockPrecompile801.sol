// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MockPrecompile801 {
    // This mock will return hardcoded values when called
    
    // The values we want to return
    uint64 public constant TOTAL = 1000000;
    uint64 public constant HOLD = 500000;
    uint64 public constant ENTRY_NTL = 200;

    // This is the function that will be called by the L1Read contract
    fallback(bytes calldata) external returns (bytes memory) {
        // Return the hardcoded balance values
        return abi.encode(TOTAL, HOLD, ENTRY_NTL);
    }
    
    // This function is called by the L1EvmManager contract
    function sendHypeOnL1(address, uint64) external pure returns (bool) {
        // Always return true to simulate a successful transfer
        return true;
    }
    
    // Helper function for tests to verify the mock is working
    function getSpotBalance() public pure returns (uint64, uint64, uint64) {
        return (TOTAL, HOLD, ENTRY_NTL);
    }
}

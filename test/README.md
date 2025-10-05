# Hyperliquid EVM Test Documentation

This document provides an overview of the testing strategy, test structure, and implementation details for the Hyperliquid EVM project.

## Test Structure

The test directory is organized as follows:

```
test/
├── L1EvmManager.t.sol     # Tests for L1EvmManager contract
├── L1Read.t.sol          # Tests for L1Read contract
└── mock/
    └── MockPrecompile801.sol  # Mock implementation of the Hyperliquid precompile
```

## Testing Strategy

### Unit Testing

We use Foundry's testing framework to write unit tests for our smart contracts. Each contract has its own test file with test cases covering:

- Core functionality
- Edge cases
- Access control
- Event emissions
- State changes

### Fuzz Testing

We employ property-based fuzz testing to ensure robustness:

- **Input Validation**: Tests with random inputs to catch edge cases
- **Property Verification**: Ensures invariants hold across all inputs
- **Boundary Testing**: Automatically tests edge cases in number ranges

### Gas Optimization

Gas usage is tracked and tested to ensure efficient smart contracts:

- Gas benchmarks for critical functions
- Performance regression detection
- Optimization validation

### Mocking

We use mock contracts to simulate external dependencies, particularly for:

1. **Precompiled Contracts**: The `MockPrecompile801` simulates the Hyperliquid precompile at address `0x0000000000000000000000000000000000000801`.
2. **External Dependencies**: Any external contract interactions are mocked to ensure isolated and predictable test environments.

## Test Implementation Details

### L1Read Tests

Tests for the `L1Read` contract focus on:

- Reading spot balances from the precompile
- Handling different input scenarios
- Verifying correct data decoding
- Fuzz testing with random addresses and token IDs
- Gas usage benchmarking

### L1EvmManager Tests

Tests for the `L1EvmManager` contract cover:

- Depositing to staking
- Transferring to spot
- Sending HYPE on L1
- Event emissions
- Access control
- Fuzz testing with random inputs
- Gas usage optimization

### MockPrecompile801

The mock precompile provides deterministic responses for testing:

- Returns fixed spot balance (`total=1000000`, `hold=500000`, `entryNtl=200`)
- Simulates successful HYPE transfers
- Implements the same interface as the real precompile
- Supports fuzz testing with consistent behavior

## Running Tests

### Basic Test Commands

Run all tests:
```bash
forge test -vvv
```

Run specific test contract:
```bash
forge test --match-contract L1ReadTest -vvv
```

Run specific test function:
```bash
forge test --match-test test_spotBalance -vvv
```

### Fuzz Testing

Run all fuzz tests:
```bash
forge test --match-test testFuzz -vvv
```

Run specific fuzz test with more iterations (default is 256):
```bash
FOUNDRY_FUZZ_RUNS=10000 forge test --match-test testFuzz -vvv
```

### Gas Testing

Run gas tests and see gas usage:
```bash
forge test --match-test testGas -vvv
```

Generate gas report:
```bash
forge test --gas-report
```

### Coverage

Generate test coverage report:
```bash
forge coverage --report lcov
```

## Best Practices

1. **Isolation**: Each test is independent and doesn't rely on state from other tests
2. **Descriptive Names**: Test names clearly describe the scenario being tested
3. **Fuzzing**: All public/external functions should have fuzz tests
4. **Gas Tracking**: Critical functions include gas usage tests
5. **Events**: Verify correct events are emitted with proper parameters
6. **Edge Cases**: Explicitly test boundary conditions and edge cases

## Test Types

### Unit Tests
- Test individual functions in isolation
- Verify business logic
- Check access control and permissions

### Fuzz Tests
- Test with random inputs to find edge cases
- Verify invariants hold across all inputs
- Use `vm.assume` to filter invalid inputs

### Gas Tests
- Track gas usage of critical functions
- Set gas limits to catch performance regressions
- Help identify optimization opportunities

## Troubleshooting

### Common Issues

1. **Test Failing**
   - Check error messages in test output
   - Run with `-vvvv` for maximum verbosity
   - Verify mock behavior matches real contracts

2. **Fuzz Test Failures**
   - Look for the specific input that caused the failure
   - Add `vm.assume` to filter invalid inputs
   - Check boundary conditions

3. **Gas Test Failures**
   - Review recent changes that might affect gas usage
   - Consider optimizing hot paths
   - Check for unnecessary storage operations

## Performance Metrics

### L1Read
- `spotBalance`: ~9,919 gas

### L1EvmManager
- `sendHypeOnL1`: ~25,443 gas
- `fromEvmToStaking`: ~60,459 gas

## Future Improvements

- Add more fuzz test cases for complex scenarios
- Implement invariant testing
- Add fork testing against mainnet state
- Set up continuous benchmarking
- Add formal verification for critical functions
- Implement test coverage thresholds

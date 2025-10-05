// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { L1Read } from "./L1Read.sol";


interface IL1Write {
    function sendIocOrder(uint32 asset, bool isBuy, uint64 limitPx, uint64 sz) external;
    function sendVaultTransfer(address vault, bool isDeposit, uint64 usd) external;
    function sendTokenDelegate(address validator, uint64 _wei, bool isUndelegate) external;
    function sendCDeposit(uint64 _wei) external;
    function sendCWithdrawal(uint64 _wei) external;
    function sendSpot(address destination, uint64 token, uint64 _wei) external;
    function sendUsdClassTransfer(uint64 ntl, bool toPerp) external;
}

contract L1EvmManager {
    address public constant NATIVE_TRANSFER_ADDRESS = 0x2222222222222222222222222222222222222222;
    address public constant L1_WRITE_ADDRESS = 0x3333333333333333333333333333333333333333;
    uint64 public constant L1_HYPE_TOKEN_NUMBER = 1105;
    IL1Write private l1Write;
    L1Read public l1Read;

    event EvmToStaking(address indexed user, address indexed validator, uint64 _wei);
    event EvmToSpot(address indexed user, uint64 _wei);
    event EvmToContractSpot(address indexed user, uint64 _wei);
    event SendSpotOnL1(address indexed user, address indexed destination, uint64 token, uint64 _wei);
    event SpotToEvm(address indexed user, uint64 _wei);
    event ContractSpotToEvm(address indexed user, uint64 _wei);
    event ContractCDeposit(uint64 _wei);
    event ContractCWithdrawal(uint64 _wei);

    constructor() {
        l1Write = IL1Write(L1_WRITE_ADDRESS);
        l1Read = new L1Read();
    }

    function fromEvmToStaking(address validator) public payable {
        // check did user send enough HYPE token
        require(msg.value > 0, "Must send HYPE token");
        uint64 value = uint64(msg.value);
        (bool success, ) = NATIVE_TRANSFER_ADDRESS.call{value: value}("");
        require(success, "Native Transfer Failed");
        uint64 l1Amount = uint64(value / 1e10);
        l1Write.sendCDeposit(l1Amount);
        l1Write.sendTokenDelegate(validator, l1Amount, false);
        // (bool success1, ) = address(l1Write).call{value: value}(abi.encodeWithSignature("sendCDeposit(uint64)", value));
        // require(success1, "Deposit failed");
        // (bool success2, ) = address(l1Write).call(abi.encodeWithSignature("sendTokenDelegate(address,uint64,bool)", validator, value, false));
        // require(success2, "Token Delegate failed");
        emit EvmToStaking(msg.sender, validator, value);
    }

    function fromEvmToSpot() public payable {
        require(msg.value > 0, "Must send HYPE token");
        uint64 value = uint64(msg.value);
        (bool success, ) = NATIVE_TRANSFER_ADDRESS.delegatecall("");
        require(success, "Native Transfer Failed");
        emit EvmToSpot(msg.sender, value);
    }

    function fromEvmToContractSpot() public payable {
        require(msg.value > 0, "Must send HYPE token");
        uint64 value = uint64(msg.value);
        (bool success, ) = NATIVE_TRANSFER_ADDRESS.call{value: value}("");
        require(success, "Native Transfer Failed");
        emit EvmToContractSpot(msg.sender, value);
    }

    function fromSpotToEvm(uint64 _wei) public {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(msg.sender, L1_HYPE_TOKEN_NUMBER);
        require(hype_balance.total > _wei, "Not enough HYPE on L1");
        (bool success, ) = address(l1Write).delegatecall(abi.encodeWithSignature("sendSpot(address,uint64,uint64)", NATIVE_TRANSFER_ADDRESS, L1_HYPE_TOKEN_NUMBER, _wei));
        require(success, "Send Spot on L1 Failed");
        emit SpotToEvm(msg.sender, _wei);

    }

    function fromContractSpotToEvm(uint64 _wei) public {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(address(this), L1_HYPE_TOKEN_NUMBER);
        require(hype_balance.total > _wei, "Not enough HYPE on L1");
        (bool success, ) = address(l1Write).call(abi.encodeWithSignature("sendSpot(address,uint64,uint64)", NATIVE_TRANSFER_ADDRESS, L1_HYPE_TOKEN_NUMBER, _wei));
        require(success, "Send Spot on L1 Failed");
        emit ContractSpotToEvm(msg.sender, _wei);
    }

    function sendHypeOnL1(address destination, uint64 _wei) public {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(msg.sender, L1_HYPE_TOKEN_NUMBER);
        require(hype_balance.total > _wei, "Not enough HYPE on L1");
        // l1Write.sendSpot(destination, L1_HYPE_TOKEN_NUMBER, _wei);
        (bool success, ) = address(l1Write).delegatecall(abi.encodeWithSignature("sendSpot(address,uint64,uint64)", destination, L1_HYPE_TOKEN_NUMBER, _wei));
        require(success, "Send Spot on L1 Failed");
        emit SendSpotOnL1(msg.sender, destination, L1_HYPE_TOKEN_NUMBER, _wei);
    }

    function sendContractHypeOnL1(address destination, uint64 _wei) public {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(address(this), L1_HYPE_TOKEN_NUMBER);
        require(hype_balance.total > _wei, "Not enough HYPE on L1");
        // l1Write.sendSpot(destination, L1_HYPE_TOKEN_NUMBER, _wei);
        (bool success, ) = address(l1Write).call(abi.encodeWithSignature("sendSpot(address,uint64,uint64)", destination, L1_HYPE_TOKEN_NUMBER, _wei));
        require(success, "Send Spot on L1 Failed");
        emit SendSpotOnL1(msg.sender, destination, L1_HYPE_TOKEN_NUMBER, _wei);
    }

    function sendContractCDeposit(uint64 _wei) public {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(address(this), L1_HYPE_TOKEN_NUMBER);
        require(hype_balance.total > _wei, "Not enough HYPE on L1");
        (bool success, ) = address(l1Write).call(abi.encodeWithSignature("sendCDeposit(uint64)", _wei));
        require(success, "Send Spot on L1 Failed");
        emit ContractCDeposit(_wei);
    }

    function sendContractCWithdrawal(uint64 _wei) public {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(address(this), L1_HYPE_TOKEN_NUMBER);
        require(hype_balance.total > _wei, "Not enough HYPE on L1");
        (bool success, ) = address(l1Write).call(abi.encodeWithSignature("sendCWithdrawal(uint64)", _wei));
        require(success, "Send Spot on L1 Failed");
        emit ContractCWithdrawal(_wei);
    }

    function getContractSpotBalance() public view returns (L1Read.SpotBalance memory) {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(address(this), L1_HYPE_TOKEN_NUMBER);
        return hype_balance;
    }

    function getSpotBalance(address user) public view returns (L1Read.SpotBalance memory) {
        L1Read.SpotBalance memory hype_balance = l1Read.spotBalance(user, L1_HYPE_TOKEN_NUMBER);
        return hype_balance;
    }

    function getContractStakeBalance() public view returns (uint64) {
        L1Read.Withdrawable memory withdrawable = l1Read.withdrawable(address(this));
        return withdrawable.withdrawable;
    }
}

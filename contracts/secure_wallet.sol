// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract SecureWallet {

    address payable public walletOwner;

    mapping(address => uint) public allowedTransferAmount;
    mapping(address => bool) public isAuthorizedSender;

    mapping(address => bool) public guardianList;
    address payable proposedNewOwner;
    uint guardianApprovalCount;
    uint public constant REQUIRED_GUARDIAN_CONFIRMATIONS = 3;

    constructor() {
        walletOwner = payable(msg.sender);
    }

    function proposeOwnershipTransfer(address payable newOwnerCandidate) public {
        require(guardianList[msg.sender], "Only a guardian can propose new owner.");
        if (proposedNewOwner != newOwnerCandidate) {
            proposedNewOwner = newOwnerCandidate;
            guardianApprovalCount = 0;
        }

        guardianApprovalCount++;

        if (guardianApprovalCount >= REQUIRED_GUARDIAN_CONFIRMATIONS) {
            walletOwner = proposedNewOwner;
            proposedNewOwner = payable(address(0));
        }
    }

    function setTransferAllowance(address _authorizedSender, uint _allowedAmount) public {
        require(msg.sender == walletOwner, "Only the wallet owner can set allowances.");
        allowedTransferAmount[_authorizedSender] = _allowedAmount;
        isAuthorizedSender[_authorizedSender] = true;
    }

    function revokeSenderAuthorization(address _sender) public {
        require(msg.sender == walletOwner, "Only the wallet owner can revoke authorization.");
        isAuthorizedSender[_sender] = false;
    }

    function transferFunds(address payable _recipient, uint _amount, bytes memory transactionData) public returns (bytes memory) {
        require(_amount <= address(this).balance, "Insufficient funds in the contract.");
        
        if (msg.sender != walletOwner) {
            require(isAuthorizedSender[msg.sender], "Sender not authorized to transfer funds.");
            require(allowedTransferAmount[msg.sender] >= _amount, "Transfer amount exceeds allowed limit.");
            allowedTransferAmount[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _recipient.call{value: _amount}(transactionData);
        require(success, "Transaction failed.");
        return returnData;
    }

    receive() external payable {}
}

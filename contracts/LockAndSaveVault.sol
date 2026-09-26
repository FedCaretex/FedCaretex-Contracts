// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LockAndSaveVault is Ownable {
    IERC20 public stablecoin;
    
    struct Vault {
        uint256 balance;
        uint256 maturityDate;
        bool isLocked;
    }
    
    mapping(address => Vault) public vaults;
    
    event Deposited(address indexed user, uint256 amount, uint256 maturityDate);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyUnlocked(address indexed user);

    constructor(address _stablecoinAddress) Ownable(msg.sender) {
        stablecoin = IERC20(_stablecoinAddress);
    }
    
    /**
     * @dev Deposits funds and locks them for a specified duration in days.
     */
    function deposit(uint256 _amount, uint256 _lockDurationInDays) external {
        require(_amount > 0, "Amount must be > 0");
        require(stablecoin.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        Vault storage userVault = vaults[msg.sender];
        userVault.balance += _amount;
        
        // Extend maturity date if it's already locked, or set a new one
        if (!userVault.isLocked || block.timestamp > userVault.maturityDate) {
            userVault.maturityDate = block.timestamp + (_lockDurationInDays * 1 days);
        } else {
             userVault.maturityDate += (_lockDurationInDays * 1 days);
        }
        
        userVault.isLocked = true;
        
        emit Deposited(msg.sender, _amount, userVault.maturityDate);
    }
    
    /**
     * @dev Withdraws funds if the maturity date has passed.
     */
    function withdraw() external {
        Vault storage userVault = vaults[msg.sender];
        require(userVault.balance > 0, "No funds available");
        require(!userVault.isLocked || block.timestamp >= userVault.maturityDate, "Funds are still locked");
        
        uint256 amount = userVault.balance;
        userVault.balance = 0;
        userVault.isLocked = false;
        
        require(stablecoin.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Emergency unlock mechanism for verified absolute emergencies.
     * In a production environment, this should ideally be governed by a Multi-Sig wallet.
     */
    function emergencyUnlock(address _user) external onlyOwner {
        Vault storage userVault = vaults[_user];
        require(userVault.balance > 0, "No funds in vault");
        
        userVault.isLocked = false;
        userVault.maturityDate = block.timestamp;
        
        emit EmergencyUnlocked(_user);
    }
}

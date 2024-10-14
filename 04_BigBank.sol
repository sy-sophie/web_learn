// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
interface IBank {
    function deposite() external payable;
    function bankWithdraw() external returns (uint);
}

contract Bank is IBank {
    address public owner;
    mapping(address => uint) public balances;
    struct TopUser {
        address user;
        uint balances;
    }
    TopUser[3] public topUsers;

    constructor () {
        owner = msg.sender;
    }

    function deposite() external payable virtual override {
        require(msg.value > 0, "You need to deposit some ether.");
        balances[msg.sender] += msg.value;
        updateTopThreeBalances(msg.sender);
    }
    function updateTopThreeBalances(address _user) internal {
        uint currentUserBalance = balances[_user];

        for(uint i = 0; i < 3; i++){
            if (currentUserBalance > topUsers[i].balances){
                for (uint j = 2; j > i; j--){
                    topUsers[j] = topUsers[j - 1];
                }
                topUsers[i] = TopUser(_user, currentUserBalance);
                break;
            }
        }
    }
    function bankWithdraw() public virtual override returns (uint) {
        uint totalBalance = address(this).balance;
        (bool success, ) = payable(owner).call{value: totalBalance}("");
        require(success, "Transfer faild.");
        return totalBalance;
    }
}

contract BigBank is Bank {
    error EtherInsufficient();

    modifier depositAmount() { // 要求存款金额 > 0.001 ether
        if (msg.value < 0.001 ether) { // 1 ether = 10 ^ 18
            revert EtherInsufficient();
        }
        _;
    }

    function deposite() external payable override depositAmount() {
        require(msg.value > 0, "You need to deposit some ether.");
        balances[msg.sender] += msg.value;
        updateTopThreeBalances(msg.sender);
    }

    function transferAdmin(address newAdmin) external {
        require(msg.sender == owner, "Only the current admin can transfer admin rights.");
        require(newAdmin != address(0), "New admin cannot be the zero address.");
        owner = newAdmin; // 更新管理员地址
    }

}

contract Admin {
    address public immutable adminOwner;
    uint public totalWithdrawn; // 记录余额

    constructor () {
        adminOwner = msg.sender;
    }

    receive() external payable { } // 接收ETH

    function adminWithdraw(IBank bankAddress) public{
        require(msg.sender == adminOwner, "Only the owner can withdraw.");
        try IBank(bankAddress).bankWithdraw() returns (uint bankBalance){
            // 使用call方法，将提取的余额转入到Admin合约地址
            (bool success, ) = payable(address(this)).call{value: bankBalance}("");
            require(success, "Transfer to Admin contract failed.");
            totalWithdrawn += bankBalance;
        } catch {
            revert("Withdraw failed");
        }
    }
}

// 测试流程

// 1. 部署 Bank 合约。
//   - Deploy -> Bank：合约地址：0x2F8895b08D8F226b19895d46154faB7096fB2593
//   owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// 2. 部署 BigBank 合约。
//   - Deploy -> BigBank：合约地址：0x8207D032322052AfB9Bf1463aF87fd0c0097EDDE
//   owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// 3. 部署 Admin 合约。
//   - Deploy -> Admin：合约地址：0x047b37Ef4d76C2366F795Fb557e3c15E0607b7d8
//   adminOwner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// 4. 在 BigBank 合约中调用 transferAdmin 方法。
//   - 选择 BigBank 合约实例 -> transferAdmin(address Admin：0x047b37Ef4d76C2366F795Fb557e3c15E0607b7d8) -> 输入 Admin 合约地址
//   admin: 0x047b37Ef4d76C2366F795Fb557e3c15E0607b7d8

// 5. 模拟用户存款。
//   - 使用用户地址 -> 调用 BigBank 合约的 deposite 方法，存入 0.01 ether -> Transact
//   - 重复以上步骤以模拟多个用户存款。
//   用户1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2，value: 1 ether
//   用户2: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db，value: 2 ether
//   用户3: 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB，value: 3 ether

// 6. 管理员提取资金。
//   - 在 Admin 合约中调用 adminWithdraw(address BigBank: 0x26b989b9525Bb775C8DEDf70FeE40C36B397CE67)，输入 BigBank 合约地址
//   totalWithdrawn: 6 ether

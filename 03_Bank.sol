// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;
// 1. 现有一个管理员，address owner
// 2. 所有的人address 都可以 存到 owner 中
//     2.1 存的过程要记录到balances，用于计算前3名用户的余额accounts
// 3. 管理员可以取出所有的钱

contract Bank {
    address public immutable owner;

    mapping(address => uint) public balances; // 用户地址 => 金额

    struct TopUser {
        address user;
        uint balance;
    }
    TopUser[3] public topUsers; // 存储 前3名 用户地址

    constructor() {
        owner = msg.sender; // 将部署者设为管理员
    }

    receive() external payable {
        require(msg.value > 0, "You need to deposit some ether.");
        balances[msg.sender] += msg.value;
        updateTopThreeBalances(msg.sender);
    }


    function updateTopThreeBalances(address _user) internal  {
        uint currentUserBalance = balances[_user];

        for (uint i =0; i< 3; i++) {
            if (currentUserBalance > topUsers[i].balance){
                // 将当前用户的余额插入到前三名，并将其他余额后移
                for(uint j = 2; j > i; j--){
                    topUsers[j] = topUsers[j - 1];
                }
                topUsers[i] = TopUser(_user, currentUserBalance);
                break;
            }
        }
    }

    function withdraw() external returns (uint) {
        require(msg.sender == owner, 'not owner');
        uint totalBalance = address(this).balance;
        (bool success,) = payable(owner).call{value: totalBalance}("");
        require(success, "Transfer failed.");
        return totalBalance;
    }
}

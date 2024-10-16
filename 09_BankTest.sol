// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { Bank } from "../src/Bank.sol";
// 为银行合约的 DepositETH 方法编写测试 Case
// 断言检查 Deposit 事件输出是否符合预期。
// 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
contract BankTest is Test {
    event Deposit(address indexed user, uint amount);

    function test_Bank() public {
        Bank bank = new Bank();

        // 开始模拟当前调用者为测试合约的地址
        vm.startPrank(address(this));

        uint initialBalance = bank.balanceOf(address(this));
        assertEq(initialBalance, 0); // 确保初始余额为0

        uint depositAmount = 123;

        vm.expectEmit(true, false, false, true);
        emit Deposit(address(this), depositAmount);

        // 存入ETH并发送相应的值
        bank.depositETH{value: depositAmount}();

        // 存款后的余额
        uint finalBalance = bank.balanceOf(address(this));
        assertEq(finalBalance, depositAmount); // 确保余额更新为存款金额

        // 停止模拟
        vm.stopPrank();
    }
}

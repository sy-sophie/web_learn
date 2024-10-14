// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract BaseERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * 10 ** uint256(decimals);

        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];

    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance"); // 不要忘记 =
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance"); // 不要忘记 =
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance"); // 不要忘记 =

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // write your code here
        return allowances[_owner][_spender];

    }
}

interface ITokenBank {
    function deposite(uint256 amount) external payable;
    function withdraw() external returns (uint);

}
contract TokenBank is ITokenBank {
    mapping (address => uint) public balances;
    address public admin; // 管理员
    BaseERC20 public token; // ERC20 Token 合约地址


    constructor(BaseERC20 _token) {
        admin = msg.sender;
        token = _token; // 初始化 Token 合约地址
    }

    function deposite(uint256 amount) public payable  override {
        require(amount > 0, "Deposit amount must be greater than zero");
        token.transferFrom(msg.sender, address(this), amount); // 从用户转移 Token 到合约
        balances[msg.sender] += amount; // 更新用户的存入数量
    }
    function withdraw() public returns (uint){
        require(msg.sender == admin, "Only admin can withdraw all tokens");
        uint totalBalance = token.balanceOf(address(this)); // 获取合约的总余额

        require(totalBalance > 0, "No tokens available for withdrawal");

        token.transfer(admin, totalBalance); // 提取所有 Token 到管理员地址
        return totalBalance;
    }
}

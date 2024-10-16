// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * 10 ** uint256(decimals);

        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];

    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance"); // 不要忘记 =
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance"); // 不要忘记 =
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance"); // 不要忘记 =

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    // isContract函数，判断地址是否为合约地址
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly { // 使用内联汇编检查地址的代码大小
            size := extcodesize(account) // 获取地址关联的代码大小，extcodesize可区分 合约地址>0 和 EOA=0
        }
        return  size > 0; // 如果代码大小大于0，则为合约地址
    }
    function transferWithCallback(address recipient, uint amount) external returns (bool)  {
        transferFrom(msg.sender, recipient, amount);
        // 检查接收者是否为合约
        if(isContract(recipient)) {
            IERC777Recipient(recipient).tokensReceived(msg.sender, msg.sender, recipient, amount, "", "");
        }
        return true;
    }
}


interface IERC777Recipient {
    function tokensReceived( // 允许 接收者 在接收代币时执行自定义逻辑 这个函数在 ERC777 代币合约调用 send 或 transfer 后自动触发，确保代币接收者可以处理接收到的代币
        address operator, // 代币持有者地址 || 操作的代理方
        address from,
        address to,
        uint256 amount,
        bytes calldata userData, // 用户提供的附加数据
        bytes calldata operatorData // 操作员提供的附加数据
    ) external;
}


contract NFTMarket is IERC777Recipient {
    // NFT contract
    IERC721 public nftContract;

    struct Listing {
        address seller;
        uint256 price;
    }

    constructor(IERC721 _nftContract) {
        nftContract = _nftContract;
    }

    mapping(uint256 => Listing) public listings;
    // @param nftContract  NFT 合约的地址
    // @param tokenId      要出售的 NFT 的 ID
    // @param price        NFT 上架的价格，单位是 ERC20 代币
    function listNFT(address nftContract, uint256 tokenId, uint256 price) public {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing(msg.sender, price);
    }

    // @param nftContract   NFT 合约的地址
    // @param tokenId       要购买的 NFT 的 ID
    // @param amount        买家支付的代币数量
    // @param erc20Token    用于支付的 ERC20 代币的合约地址
    function buyNFT(address nftContract, uint256 tokenId, uint256 amount, address erc20Token) public {
        Listing memory listing = listings[tokenId];
        require(amount >= listing.price, "Insufficient funds");

        BaseERC20(erc20Token).transferFrom(msg.sender, listing.seller, listing.price);

        // @param  address(this) 当前合约的地址，表示要转移的NFT所在地址
        // @param  msg.sender,   NFT被转移到哪个地址
        // @param  tokenId       哪一个NFT
        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenId);

        delete listings[tokenId]; // Remove the listing after purchase
    }

    function tokensReceived( // 允许 接收者 在接收代币时执行自定义逻辑 这个函数在 ERC777 代币合约调用 send 或 transfer 后自动触发，确保代币接收者可以处理接收到的代币
        address operator, // 代币持有者地址 || 操作的代理方
        address from,
        address to,
        uint256 amount,
        bytes calldata userData, // 用户提供的附加数据
        bytes calldata operatorData // 操作员提供的附加数据
    ) external {
        uint256 tokenId = abi.decode(userData, (uint256));  // The tokenId of the NFT to buy
        Listing memory listing = listings[tokenId];

        require(listing.price > 0, "NFT is not listed for sale");
        require(amount == listing.price, "Incorrect payment amount");

        nftContract.safeTransferFrom(address(this), from, tokenId);
        BaseERC20(to).transfer(from, amount);

        delete listings[tokenId];

    }
}

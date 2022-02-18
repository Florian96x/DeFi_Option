pragma solidity ^0.7.6;

contract Owned {
    constructor() { owner = msg.sender; }
    address payable owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }
}

contract Token is Owned {
    mapping(address => uint) public balanceOf;
    constructor() Owned() {}
    function issue(address recipient, uint amount) public onlyOwner {
        balanceOf[recipient] += amount;
    }
    function transfer(address recipient, uint amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
    }
}

contract CallOptionSeller is Owned {
    address buyer;
    uint quantity;
    uint strikePrice;
    uint purchasePrice;
    uint expiry;
    bool wasPurchased;
    Token token;

    constructor(uint _quantity, uint _strikePrice, uint _purchasePrice, uint _expiry, address _tokenAddress) Owned() {
        quantity = _quantity;
        strikePrice = _strikePrice;
        purchasePrice = _purchasePrice;
        expiry = _expiry;
        token = Token(_tokenAddress);
        wasPurchased = false;
    }

    function purchase() public payable {
        require(!wasPurchased, "Option already purchased");
        require(msg.value == purchasePrice, "Incorrect purchase price");
        buyer = msg.sender;
        wasPurchased = true;
    }

    function execute() public payable {
        require(wasPurchased, "Option unpurchased");
        require(msg.sender == buyer, "Unauthorized");   
        require(token.balanceOf(address(this)) == quantity, "Funding error");
        require(msg.value == strikePrice, "Payment error");
        require(block.timestamp < expiry, "Expired");
        
        token.transfer(buyer, quantity);
        selfdestruct(owner);
    }
    
    function refund() public {
        if(wasPurchased) {
            require(block.timestamp > expiry, "Not expired");
        }
        token.transfer(owner, quantity);
        selfdestruct(owner);
    }
    
    receive()
        external
        payable {
    }
}

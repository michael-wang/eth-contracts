contract owned {
  address public owner;

  function owner() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _to) onlyOwner {
    owner = _to;
  }
}

contract MyAdvancedToken is owned {
  string public name;
  string public symbol;
  uint8 public decimals;
  mapping (address => uint256) public balanceOf;
  uint256 public totalSupply;

  mapping (address => bool) public frozenAccount;

  uint256 public sellPrice;
  uint256 public buyPrice;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event FrozenFunds(address target, bool frozen);

  function MyAdvancedToken(uint256 _supply, string _name, string _symbol, 
    uint8 _decimals, address centralMinter) {
    if (_supply == 0) _supply = 1000000;

    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    balanceOf[msg.sender] = _supply;

    if (centralMinter != 0) owner = centralMinter;

    totalSupply = _supply;
  }

  function transfer(address _to, uint256 _value) public {
    require (!frozenAccount[msg.sender]);
    _transfer(msg.sender, _to, _value);
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require (_to != 0x0);
    require (balanceOf[_from] >= _value);
    require (balanceOf[_to] + _value >= balanceOf[_to]);
    require (!frozenAccount[_from]);
    require (!frozenAccount[_to]);

    balanceOf[_from] -= value;
    balanceOf[_to]   += value;
    
    Transfer(_from, _to, _value);
  }

  function mintToken(address _target, uint256 _amount) onlyOwner {
    /* Issue token to owner, this step cannot reuse _transfer because it checks
       the balance of the sender, which in this case there is none. */
    require (balanceOf[owner] + _amount >= balanceOf[owner]);
    balanceOf[owner] += _amount;

    // If transfer fails, token remains on owner.
    _transfer(owner, _target, _amount);

    totalSupply += _amount;
  }

  function frozenAccount(address _target, bool _freeze) onlyOwner {
    frozenAccount[_target] = _freeze;

    FrozenFunds(_target, _freeze);
  }

  function setPrice(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
    sellPrice = newSellPrice;
    buyPrice  = newBuyPrice;
  }

  function buy() payable returns (uint amount) {
    amount = msg.value / buyPrice;
    require (balanceOf[this] >= amount);
    balanceOf[msg.sender] += amount;
    balanceOf[this] -= amount;
    Transfer(this, msg.sender, amount);
    return amount;
  }
}

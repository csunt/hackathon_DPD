pragma solidity ^0.4.17;

/**
 * @title Infrastructure Ontario's DSWA
 * @author Marcelo Paniza <marcelo.paniza@infrastructureontario.ca>
 * @dev Smart Contract for Distributed Smart Work Assignment
 * @workflow Client Mint contract amount plus some,
 *           IO approves, 
 *           CBRE Approves and assign Consultant (not mandatory) and Vendor,
 *           Vendor returns to indicate that work is completed,
 *           CBRE returns to confirm work status,
 *           IO returns to confirm work status,
 *           Client returns to confirm work status and automaticall pay vendor
 *           End of contract
 */

import './ERC20.sol';
import '../utils/SafeMath.sol';
import '../utils/LoggingErrors.sol';

/**
 * @title Standard ERC20 Token
 */
contract SWA is ERC20, LoggingErrors {

  using SafeMath for uint256;

   /**
   * Storage
   *
   */
  string public constant symbol = "DPD";
  string public constant name = "Distributed Project Delivery";
  uint public constant decimals = 18;

  // Amount of tokens current in circulation
  uint256 public totalSupply_;

  address owner_;

  struct Participant {
    address id; //account number that will send and/or receive tokens
    uint receivable; // how much will this participant receive when the contract is done
    // bool isTheClient; // if true, no receiable and must have enought balance
    bool approved;
    bool paid;
    bool CanAddParticpant; // once it is all approved, we will pay the participants from contract balance and will mark as paid here
  }

  // create a contract without participants
  // add participants later
  // TODO: decide... hash a contract number or use real life... privacy concerns

  struct Contract {
    uint contractId; 
    uint balance; //contract balance
    uint numParticipants;
    uint status; 
    uint OverBudgetPercentage;// todo, decide the statuses
    mapping (uint => Participant) participants;
  }
  
  mapping (uint => Contract) contracts;

  uint numContracts=0;

  /**
   * Events
   */
  event LogTokensMinted(address indexed _to, address to, uint256 value, uint256 totalSupply);

  /**
   * @dev CONSTRUCTOR - set token owner account
   */
  function SWA() {
    owner_ = msg.sender;
  }

  /**
   * External
   */

//create new contract and return new contract id
function createContract() external returns (uint) {
  numContracts ++;
  contracts[numContracts] = Contract(numContracts, 0, 0, 0);

  return numContracts;
}

/*
* Add a participant to the contract
*/
function addParticipant(uint _contractId, address _id, uint _receivable, bool _isTheClient) external returns (uint) {
  
  uint lastParticipant = Contract[_contractId].numParticipants++;
  
  Contract[_contractId].participants[lastParticipant] = Participant(_id, _receivable, _isTheClient, false, false);
  Contract[_contractId].numParticipants = lastParticipant;

  return lastParticipant;
}

/*
*Add funds for the contract... that is the Client (Participant)
*/

function addContractFunds(uint _contractId, address _clientId) external returns (bool) {

// get a reference of the contract
//  add funds to the contract 

}

function setParticipantResponse(uint _contractId, address _participantId, bool approve) external returns (bool) {

  // get a reference of the contract and participantId
  // set approve... if approved, set to true

  //checkContractStatus();

  return true;
}

function closeContract (uint _contractId) external returns (bool) {

  return true;
}

/*********************************************************************** 

stopped here


************************************************************************/

  /**
   * @dev Approve a user to spend your tokens.
   * @param _spender The user to spend your tokens.
   * @param _amount The amount to increase the spender's allowance by. Totaling
   * the amount of tokens they may spend on the senders behalf.
   * @return The success of this method.
   */
  function approve(address _spender, uint256 _amount)
    external
    returns (bool)
  {
    if (_amount <= 0)
      return error("Can not approve an amount <= 0, Token.approve()");

    // if (_amount > balances_[msg.sender])
    //   return error("Amount is greater than senders balance, Token.approve()");

//todo fix below
    //allowed_[msg.sender][_spender] = allowed_[msg.sender][_spender].add(_amount);

    return true;
  }

  /**
   * @dev Mint tokens and allocate them to the specified user.
   * @param _to The address of the recipient.
   * @param _value The amount of tokens to be minted and transferred.
   * @return Success of the transaction.
   */
  function mint(address _to, uint _value)
    external
    returns (bool)
  {
    if (msg.sender != owner_)
      return error("msg.sender != owner, Token.mint()");

    if (_value <= 0)
      return error("Cannot mint a value of <= 0, Token.mint()");

    if (_to == address(0))
      return error("Cannot mint tokens to address(0), Token.mint()");

    totalSupply_ = totalSupply_.add(_value);
    //balances_[_to] = balances_[_to].add(_value);

    LogTokensMinted(_to, _to, _value, totalSupply_);
    Transfer(address(0), _to, _value);

    return true;
  }

  /**
   * @dev send `_value` token to `_to` from `msg.sender`
   * @param _to The address of the recipient, sent from msg.sender.
   * @param _value The amount of token to be transferred
   * @return Whether the transfer was successful or not
   */
  function transfer(
    address _to,
    uint256 _value
  ) external
    returns (bool)
  {
    // if (balances_[msg.sender] < _value)
    //   return error("Sender balance is insufficient, Token.transfer()");

    // balances_[msg.sender] = balances_[msg.sender].sub(_value);
    // balances_[_to] = balances_[_to].add(_value);

    Transfer(msg.sender, _to, _value);

    return true;
  }

  /**
   * @param _from The address transferring from.
   * @param _to The address transferring to.
   * @param _amount The amount to transfer.
   * @return The success of this method.
   */
  function transferFrom(address _from, address _to, uint256 _amount)
    external
    returns (bool)
  {
    if (_amount <= 0)
      return error("Cannot transfer amount <= 0, Token.transferFrom()");

    // if (_amount > balances_[_from])
    //   return error("From account has an insufficient balance, Token.transferFrom()");

// todo fix below
    // if (_amount > allowed_[_from][msg.sender])
    //   return error("msg.sender has insufficient allowance, Token.transferFrom()");

    // balances_[_from] = balances_[_from].sub(_amount);
    // balances_[_to] = balances_[_to].add(_amount);

// todo fix below
    // allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_amount);

    Transfer(_from, _to, _amount);

    return true;
  }

  // Constants

  /**
   * @return the allowance the owner gave the spender
   */
  function allowance(address _owner, address _spender)
    external
    constant
    returns(uint256)
  {
    return 0; //allowed_[_owner][_spender];
  }

  /**
   * @param _owner The address from which the balance will be retrieved.
   * @return The balance
   */
  function balanceOf(
    address _owner
  ) external
    constant
    returns (uint256)
  {
    return 0; // balances_[_owner];
  }

  /**
   * @return total amount of tokens.
   */
  function totalSupply()
    external
    constant
    returns (uint256)
  {
    return totalSupply_;
  }
}

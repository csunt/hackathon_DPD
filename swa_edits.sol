pragma solidity ^0.4.15;

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
import './SafeMath.sol';
import './LoggingErrors.sol';
import './Token.sol';

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

  // Amount of tokens currentl in circulation
  uint256 public totalSupply_;

  enum participantType {IO, CLIENT, CBRE, CONSULTANT, VENDOR }

  // planning when consultant is on board.
  // initiated is client and cbre is set.
  // EXECUTION is when the vendor is on board and budget check is good.
  // CLOSEOUT when everyone is approved.
  // PARTIAL PAYOUT when money is partially pay.
  enum contractStatus { CREATED, INITIATED, PLANNING, EXECUTION, INSUFFICENTFUND , CLOSEOUT, PARTIAL_PAYOUT, PAYOUT, COMPLETE}
  
  address owner_;

  struct Participant {
    address id; //account number that will send and/or receive tokens
    uint receivable; // how much will this participant receive when the contract is done
    bool approved;
    uint apprvoedTime;
    bool paid; // once it is all approved, we will pay the participants from contract balance and will mark as paid here
  participantType role;
  
  }


  

  // create a contract without participants
  // add participants later
  // TODO: decide... hash a contract number or use real life... privacy concerns

  struct Contract {
    uint contractId; 
    uint balance; //contract balance
    uint numParticipants;
    contractStatus status; // todo, decide the statuses
    uint overBudgetPercentage;
    //mapping (uint => address) participantIndex;
    mapping (uint => Participant) participantIndex;
  mapping (address => Participant) participants;
  }
  
  mapping (uint => Contract) contracts;

  uint numContracts=0;

  /**
   * Events
   */
  event LogTokensMinted(address indexed _to, address to, uint256 value, uint256 totalSupply);
  event logContractStatusChangeEvent( uint contractId, contractStatus value);

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
  contracts[numContracts] = Contract(numContracts, 0, 0, contractStatus.CREATED, 0);
  contracts[numContracts].contractId = numContracts;
  contracts[numContracts].status = contractStatus.CREATED;
  return numContracts;
}

/*
* Add a participant to the contract
*/
function addParticipant(uint _contractId, address _id, participantType role) external returns (uint) {
  // Owner allows to set IO, Client and CBRE Role and address.
   uint lastParticipant = 0;
   Participant participant;
  if ( msg.sender == owner_) {
        /* Allow to set only role for IO and client and CBRE role */
        if ( (role == participantType.IO || role == participantType.CLIENT) || (role == participantType.CBRE) ) {
          lastParticipant = contracts[_contractId].numParticipants++;
         
          participant.id = _id;
          participant.role = role;
          participant.approved=false;
          contracts[_contractId].participants[_id] = participant;
          contracts[_contractId].participantIndex[lastParticipant] = participant;
         
           changeContractStatus(_contractId, contractStatus.INITIATED);
        }
        
        // Only CBRE is allowed to add Consultant and Vendor Role
       if ( contracts[_contractId].participants[msg.sender].role == participantType.CBRE ) {
          if ( role == participantType.CONSULTANT || role == participantType.VENDOR) {
    
           
            lastParticipant= contracts[_contractId].numParticipants++;
         
            participant.id = _id;
            participant.role = role;
            participant.approved=false;
            contracts[_contractId].participants[_id] = participant;    
            contracts[_contractId].participantIndex[lastParticipant] = participant;  
            if (contracts[_contractId].numParticipants == 5 ) {
            
            
            }
          } 
       }
   }
   
  
 
  return lastParticipant;
}


/*
*Add funds for the contract... that is the Client (Participant)
*/
function findParticipantByRole( uint _contractId, participantType role) private returns (Participant) {

  for (uint i=0; i < contracts[_contractId].numParticipants; i++ ) {
    if ( contracts[_contractId].participantIndex[i].role == role ) {
      return contracts[_contractId].participantIndex[i];
      }
   
   } 
   
}

function clientAddContractBalance(uint _contractId, uint amt) external returns (bool) {
  // only client is allowed to set contract balance.
  if ( contracts[_contractId].participants[msg.sender].role == participantType.CLIENT )  {
      contracts[_contractId].balance += amt;
      return true;

    }
}

function budgetCheckFail(uint _contractId) returns (bool) {
       // Ensure all the particpants are there before we check.
       if ( contracts[_contractId].numParticipants == 5 ) {
          // Find vendor and consultant participants.
          uint vendorAmt=findParticipantByRole( _contractId, participantType.VENDOR).receivable;
          uint consultantAmt=findParticipantByRole( _contractId, participantType.CONSULTANT).receivable;
    
              // check if the contract balance < consultant fee + vendorCost.
              if ( contracts[_contractId].balance < (vendorAmt + consultantAmt) ) {
                  changeContractStatus(_contractId, contractStatus.INSUFFICENTFUND);
        
                  return true;

              } 
        }
        return false;

}


// CBRE as administrator set initial participant balance or receivable.
function admininstratorSetContractFunds(uint _contractId, address participantId, participantType role , uint amt) external returns (bool) {
  
    // only CBRE can set the particpants consultant and Vendor initial receivable .
    if ( contracts[_contractId].participants[msg.sender].role == participantType.CLIENT ) {
         if ( contracts[_contractId].participants[participantId].role == participantType.CONSULTANT  || contracts[_contractId].participants[participantId].role == participantType.VENDOR )  {

              contracts[_contractId].participants[participantId].receivable = amt;

              if ( contracts[_contractId].participants[participantId].role ==   participantType.CONSULTANT ) {
                changeContractStatus(_contractId, contractStatus.PLANNING);
                 
              }
              budgetCheckFail(_contractId);

             
        return true;
         }
  }
  
  return false;
}


function setParticipantResponse(uint _contractId,  bool approve) external returns (bool) {

     
     // sender set their own approval status.
     contracts[_contractId].participants[msg.sender].approved = approve;
     contracts[_contractId].participants[msg.sender].apprvoedTime=block.timestamp;
     // do a payout check
     partialPayout(_contractId);
        


  return true;
}

function   changeContractStatus(uint _contractId, contractStatus statusToBe) private returns (bool) {
  
    if ( checkValidTransistionState( _contractId, statusToBe) ) {
         contracts[_contractId].status = statusToBe;
         logContractStatusChangeEvent(_contractId, statusToBe);
         return true;
    }
    return false;
} 

function ceil(uint a, uint m) constant returns (uint ) {
        return ((a + m - 1) / m) * m;
}
    
function partialPayout(uint _contractId) private returns (bool) {
  // Only CBRE do the payout.
 
    // Ensure all the particpants are there before we check.
      if ( contracts[_contractId].numParticipants == 5 ) {
          uint numApprovedParty = 0;      
          // check if all party approved the contract.
          for (uint i=0; i < contracts[_contractId].numParticipants; i++ )
              if ( contracts[_contractId].participantIndex[i].approved == true ) {
                numApprovedParty++;
                  if ( numApprovedParty == contracts[_contractId].numParticipants) {

                      // Change contract status to CLOSEOUT
                      changeContractStatus(_contractId, contractStatus.CLOSEOUT); 

                      // payout to Vendor and consultant from CBRE wallet.
                      Participant memory cbre=findParticipantByRole( _contractId, participantType.CBRE);
                      Participant memory vendor=findParticipantByRole( _contractId, participantType.VENDOR);
               //     

                      // 90% of num, 2 decimals
                      uint vendorAmt = vendor.receivable * 90/100;

                      Token token=Token(cbre.id);
                      token.mint( cbre.id,cbre.receivable);

                      token.transfer(vendor.id, vendorAmt ); 
                      vendor.paid = true;
        
                      Participant memory consultant=findParticipantByRole( _contractId, participantType.CONSULTANT);
                      token.transfer(consultant.id, consultant.receivable); 
                      changeContractStatus(_contractId, contractStatus.PARTIAL_PAYOUT); 

                      return true;
                  }      
             }
   
           } 
   
    return false;

}


  
function checkValidTransistionState(uint _contractId, contractStatus statusToBe) private returns (bool) {

    // In order to be closed, the contract need to be fully payout.
    if ( contractStatus.COMPLETE == statusToBe &&
       contracts[_contractId].status == contractStatus.PAYOUT ) {
       return true;
    } else 
    if ( contractStatus.PAYOUT == statusToBe &&
     contracts[_contractId].status == contractStatus.PARTIAL_PAYOUT ) {
       return true;
    } else
     if ( contractStatus.PARTIAL_PAYOUT == statusToBe &&
     contracts[_contractId].status == contractStatus.CLOSEOUT ) {
       return true;
    } else
     if ( contractStatus.CLOSEOUT == statusToBe &&
     contracts[_contractId].status == contractStatus.EXECUTION ) {
       return true;
    } else
    if ( contractStatus.EXECUTION == statusToBe &&
     contracts[_contractId].status == contractStatus.INSUFFICENTFUND ) {
       return true;
    } else
    if ( contractStatus.INSUFFICENTFUND == statusToBe &&
     contracts[_contractId].status == contractStatus.EXECUTION ) {
       return true;
    } else
    if ( contractStatus.EXECUTION == statusToBe &&
     contracts[_contractId].status == contractStatus.PLANNING ) {
       return true;
    } else
   if ( contractStatus.PLANNING == statusToBe &&
     contracts[_contractId].status == contractStatus.INITIATED ) {
       return true;
    } else
   if ( contractStatus.INITIATED == statusToBe &&
     contracts[_contractId].status == contractStatus.CREATED ) {
       return true;
    } else
      return false;
}

function closeContract (uint _contractId) external returns (bool) {

  if ( checkValidTransistionState( _contractId, contractStatus.COMPLETE ) ) {
     contracts[_contractId].status =contractStatus.COMPLETE;
      return true;
  } else
      return false;
}

}
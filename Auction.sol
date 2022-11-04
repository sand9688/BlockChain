// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <=0.6.0;

contract BlindAuction {

    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    enum Phase {
        Init, Bidding, Reveal, Done
    }
    Phase public state = Phase.Init;

    address payable beneficiary;
    mapping(address=>Bid) bids;

    address public highestBidder;
    uint public highestBid = 0;

    mapping(address=>uint) depositReturns;

    modifier validPhase(Phase reqPhase) {
        require(state == reqPhase);
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary);
        _;
    }

    constructor() public {    //AOP
        beneficiary = msg.sender;
        state = Phase.Bidding;
    }

    function changeState(Phase x) public onlyBeneficiary {
        if(x < state) revert();
        state = x;
    }
    
    function bid(bytes32 blindBid) public payable validPhase(Phase.Bidding) {  
        bids[msg.sender] = Bid({
            blindedBid: blindBid,
            deposit: msg.value
        });
    }
    
    function reveal(uint value, bytes32 secret) public validPhase(Phase.Reveal) {
        uint refund = 0;
            Bid storage bidToCheck = bids[msg.sender];
            if (bidToCheck.blindedBid == keccak256(abi.encodePacked(value, secret))) {
                refund += bidToCheck.deposit;
                if (bidToCheck.deposit >= value) {
                    if (placeBid(msg.sender, value))
                        refund -= value;
                }
            }
            
        msg.sender.transfer(refund);
    }

    function placeBid(address bidder, uint value) internal returns (bool success) {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            depositReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    function withdraw() public {   
        uint amount = depositReturns[msg.sender];
        require (amount > 0);
        depositReturns[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function auctionEnd() public validPhase(Phase.Done) {
        beneficiary.transfer(highestBid);
    }
}
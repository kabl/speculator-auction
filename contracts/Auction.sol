//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./IERC20Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    IERC20Mintable public token;

    enum PayOutCurrency { ETH, RAND };
    struct BidderInfo {
        uint256 bidInWei;
        PayOutCurrency payOutCurrency; 
    }

    struct BidData {
        uint256 podTokens;
        uint256 startDate;
        mapping(address => uint256) bidderMap; //uint256 represents the Wei the user commited
        mapping(address => bool) payedOutMap;
        address[] bidderArray;
        uint256 podWeis;
        address highestBidder;
        uint256 highestBid;
        bool roundEnded;
    }

    uint256 round = 0;
    mapping(uint256 => BidData) private bidDataMap;
    mapping(uint256 => BidderInfo) private bidderInfoMap;


    event HighestBidIncreased(address bidder, uint256 amount);

    constructor(address tokenAddress) public {
        token = IERC20Mintable(tokenAddress);
    }

    function bid() public payable returns (bool) {
        BidData storage bidData = bidRounds[round];

        require(msg.value >= 100 szabo, "Minimum value required"); // 0.1 Ether
        require(
            bidData.bidderMap[msg.sender] == 0,
            "Only one Bid per address allowed"
        );

        bidData.bidderMap[msg.sender] = msg.value;
        bidData.bidderArray.push(msg.sender);

        //todo use SafeMath
        bidData.podWeis = bidData.podWeis + msg.value;

        if (msg.value > bidData.highestBid) {
            bidData.highestBid = msg.value;
            bidData.highestBidder = msg.sender;
            emit HighestBidIncreased(msg.sender, msg.value);
        }
    }

    function payOut(uint256 payOutRound, address payable bidder)
        public
        payable
        returns (bool)
    {
        BidData storage bidData = bidRounds[payOutRound];
        require(bidData.roundEnded == true, "Round not ended");
        require(bidData.bidderMap[bidder] > 0, "Unknown bidder");
        require(bidData.payedOutMap[bidder] == false, "Already payed out");
        // todo: require 30 days wait time

        uint256 amountWei = bidData.bidderMap[bidder];

        if (bidder == bidData.highestBidder) {
            token.transfer(bidder, bidData.podTokens);
        }

        bidder.transfer(amountWei);
    }

    function startAuction() public onlyOwner returns (bool) {
        BidData memory bidData;
        bidData.podTokens = pseudoRandom();
        bidData.startDate = block.timestamp;

        uint256 ownTokens1 = token.balanceOf(address(this));
        token.mint(address(this), bidData.podTokens);

        // Security check
        uint256 ownTokens2 = token.balanceOf(address(this));
        uint256 diff = ownTokens2 - ownTokens1;
        require(diff == bidData.podTokens, "Minting bug!");

        bidRounds[round] = bidData;

        return true;
    }

    function endAuction() public returns (bool) {
        BidData storage bidData = bidRounds[round];
        require(bidData.roundEnded == false, "Already ended");
        // todo: check 24 hours

        bidData.roundEnded = true;
        round = round + 1;
    }

    function pseudoRandom() private view returns (uint8) {
        // Do not use this in production!!!
        return
            uint8(
                uint256(
                    keccak256(abi.encode(block.timestamp, block.difficulty))
                ) % 101
            );
    }

    function auctionData(uint256 auctionRound)
        public
        view
        returns (
            uint256 podTokens,
            uint256 startDate,
            uint256 podWeis,
            address highestBidder,
            uint256 highestBid,
            bool roundEnded,
            uint256 numberOfBidders
        )
    {
        BidData memory bidData = bidRounds[auctionRound];

        podTokens = bidData.podTokens;
        startDate = bidData.startDate;
        podWeis = bidData.podWeis;
        highestBidder = bidData.highestBidder;
        highestBid = bidData.highestBid;
        roundEnded = bidData.roundEnded;
        numberOfBidders = bidData.bidderArray.length;
    }
}

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./IERC20Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    IERC20Mintable public token;

    enum PayOutCurrency {ETH, RAND}

    struct BidderInfo {
        uint256 bidInWei;
        uint256 payedOutAmount;
        PayOutCurrency payOutCurrency;
        bool payedOut;
         
    }

    struct BidData {
        uint256 podTokens;
        uint256 startDate;
        uint256 numberOfBidders;
        uint256 podWeis;
        address highestBidder;
        uint256 highestBid;
        bool roundEnded;
    }

    uint256 round = 0;
    mapping(uint256 => BidData) private bidDataMap;
    mapping(uint256 => mapping(address => BidderInfo)) private bidderInfoMapMap;

    event NewBid(address bidder, uint256 amount);
    event HighestBidIncreased(address bidder, uint256 amount);

    constructor(address tokenAddress) public {
        token = IERC20Mintable(tokenAddress);
    }

    function bid(PayOutCurrency payOutCurrency) public payable returns (bool) {
        BidData storage bidData = bidDataMap[round];
        BidderInfo storage bidderInfo = bidderInfoMapMap[round][msg.sender];

        require(bidData.numberOfBidders < 1000, "Too many bidders");
        require(msg.value >= 100 szabo, "Minimum value required"); // 0.1 Ether
        require(bidderInfo.bidInWei == 0, "Only one Bid per address allowed");

        bidderInfo.bidInWei = msg.value;
        bidderInfo.payOutCurrency = payOutCurrency;
        bidderInfo.payedOut = false;

        bidData.podWeis = bidData.podWeis + msg.value; //todo: use SafeMath
        bidData.numberOfBidders = bidData.numberOfBidders + 1;

        emit NewBid(msg.sender, msg.value);

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
        BidData storage bidData = bidDataMap[payOutRound];
        BidderInfo storage bidderInfo = bidderInfoMapMap[payOutRound][bidder];

        require(bidData.roundEnded == true, "Round not ended");
        require(bidderInfo.bidInWei > 0, "Unknown bidder");
        require(bidderInfo.payedOut == false, "Already payed out");
        // todo: impl. require check: 30 days wait time

        bidderInfo.payedOut = true;

        if (bidder == bidData.highestBidder) {
            token.transfer(bidder, bidData.podTokens);
            bidderInfo.payedOutAmount = bidData.podTokens;
        } else {
            bidder.transfer(bidderInfo.bidInWei);
            bidderInfo.payedOutAmount = bidderInfo.bidInWei;
        }
    }

    function startAuction() public onlyOwner returns (bool) {
        //todo: Require check start is only allowed when current bid ended
        //todo: Require check start is only allowed after 24hours after last bid

        BidData memory bidData;
        bidData.podTokens = pseudoRandom();
        bidData.startDate = block.timestamp;

        uint256 ownTokens1 = token.balanceOf(address(this));
        token.mint(address(this), bidData.podTokens);

        // Security check. Make sure the right amount of tokens is minted
        uint256 ownTokens2 = token.balanceOf(address(this));
        uint256 diff = ownTokens2 - ownTokens1;
        require(diff == bidData.podTokens, "Minting bug!");

        bidDataMap[round] = bidData;

        return true;
    }

    function endAuction() public returns (bool) {
        BidData storage bidData = bidDataMap[round];
        require(bidData.roundEnded == false, "Already ended");
        // todo: Require check end auction allowed after 24 hours.

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

    function getAuctionData(uint256 auctionRound)
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
        require(auctionRound <= round, "Invalid round");

        BidData memory bidData = bidDataMap[auctionRound];

        podTokens = bidData.podTokens;
        startDate = bidData.startDate;
        podWeis = bidData.podWeis;
        highestBidder = bidData.highestBidder;
        highestBid = bidData.highestBid;
        roundEnded = bidData.roundEnded;
        numberOfBidders = bidData.numberOfBidders;
    }

    function getBidderInfo(uint256 auctionRound, address bidder)
        public
        view
        returns (
            uint256 bidInWei,
            uint256 payedOutAmount,
            PayOutCurrency payOutCurrency,
            bool payedOut
        )
    {
        require(auctionRound <= round, "Invalid round");

        BidderInfo memory bidderInfo = bidderInfoMapMap[round][bidder];
        require(bidderInfo.bidInWei > 0, "Invalid Bidder");

        bidInWei = bidderInfo.bidInWei;
        payedOutAmount = bidderInfo.payedOutAmount;
        payOutCurrency = bidderInfo.payOutCurrency;
        payedOut = bidderInfo.payedOut;
    }
}

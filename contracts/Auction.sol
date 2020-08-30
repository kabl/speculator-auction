//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./IERC20Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    IERC20Mintable public _token;

    enum PayOutCurrency {ETH, ERC20}

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

    uint256 private _currentRound = 0;

    // round->BidData
    mapping(uint256 => BidData) private _bidDataMap;

    // round->bidder->BidderInfo
    mapping(uint256 => mapping(address => BidderInfo))
        private _bidderInfoMapMap;

    event AuctionStarted(uint256 round);
    event AuctionEnded(uint256 round);
    event NewBidPlaced(address bidder, uint256 amount);
    event HighestBidIncreased(address bidder, uint256 amount);
    event PayedOut(address bidder, uint256 amount, PayOutCurrency currency);

    constructor(address tokenAddress) public {
        _token = IERC20Mintable(tokenAddress);
    }

    function startAuction() public onlyOwner returns (bool) {
        //todo: Require check start is only allowed when current bid ended
        //todo: Require check start is only allowed after 24hours after last bid

        BidData memory bidData;
        bidData.podTokens = pseudoRandom();
        bidData.startDate = block.timestamp;

        uint256 ownTokens1 = _token.balanceOf(address(this));
        _token.mint(address(this), bidData.podTokens);

        // Security check. Make sure the right amount of tokens is minted
        uint256 ownTokens2 = _token.balanceOf(address(this));
        uint256 diff = ownTokens2 - ownTokens1;
        require(diff == bidData.podTokens, "Minting bug!");

        _bidDataMap[_currentRound] = bidData;

        emit AuctionStarted(_currentRound);
        return true;
    }

    function endAuction() public returns (bool) {
        BidData storage bidData = _bidDataMap[_currentRound];
        require(bidData.roundEnded == false, "Already ended");
        // todo: Require check end auction allowed after 24 hours.

        bidData.roundEnded = true;
        emit AuctionEnded(_currentRound);
        _currentRound = _currentRound + 1;
    }

    function bid(PayOutCurrency payOutCurrency) public payable returns (bool) {
        BidData storage bidData = _bidDataMap[_currentRound];

        require(bidData.numberOfBidders < 1000, "Too many bidders");
        require(msg.value >= 100 szabo, "Minimum value required"); // 0.1 Ether
        require(
            _bidderInfoMapMap[_currentRound][msg.sender].bidInWei == 0,
            "Only one Bid per address allowed"
        );

        BidderInfo memory bidderInfo;
        bidderInfo.bidInWei = msg.value;
        bidderInfo.payOutCurrency = payOutCurrency;
        bidderInfo.payedOut = false;
        _bidderInfoMapMap[_currentRound][msg.sender] = bidderInfo;

        bidData.podWeis = bidData.podWeis + msg.value; //todo: use SafeMath
        bidData.numberOfBidders = bidData.numberOfBidders + 1;

        emit NewBidPlaced(msg.sender, msg.value);

        if (msg.value > bidData.highestBid) {
            bidData.highestBid = msg.value;
            bidData.highestBidder = msg.sender;
            emit HighestBidIncreased(msg.sender, msg.value);
        }
    }

    function payOut(uint256 round, address payable bidder)
        public
        payable
        returns (bool)
    {
        BidData storage bidData = _bidDataMap[round];
        BidderInfo storage bidderInfo = _bidderInfoMapMap[round][bidder];

        require(bidData.roundEnded == true, "Round not ended");
        require(bidderInfo.bidInWei > 0, "Unknown bidder");
        require(bidderInfo.payedOut == false, "Already payed out");
        // todo: impl. require check: 30 days wait time

        bidderInfo.payedOut = true;

        if (bidder == bidData.highestBidder) {
            _token.transfer(bidder, bidData.podTokens); //
            address(0x0).transfer(bidderInfo.bidInWei); // burn the ETH
            bidderInfo.payedOutAmount = bidData.podTokens;
            emit PayedOut(bidder, bidData.podTokens, PayOutCurrency.ERC20);
        } else {
            bidder.transfer(bidderInfo.bidInWei); // Refund
            bidderInfo.payedOutAmount = bidderInfo.bidInWei;
            emit PayedOut(bidder, bidderInfo.bidInWei, PayOutCurrency.ETH);
        }
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

    function getAuctionData(uint256 round)
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
        require(round <= _currentRound, "Invalid round");

        BidData memory bidData = _bidDataMap[round];

        podTokens = bidData.podTokens;
        startDate = bidData.startDate;
        podWeis = bidData.podWeis;
        highestBidder = bidData.highestBidder;
        highestBid = bidData.highestBid;
        roundEnded = bidData.roundEnded;
        numberOfBidders = bidData.numberOfBidders;
    }

    function getBidderInfo(uint256 round, address bidder)
        public
        view
        returns (
            uint256 bidInWei,
            uint256 payedOutAmount,
            PayOutCurrency payOutCurrency,
            bool payedOut
        )
    {
        require(round <= _currentRound, "Invalid round");

        BidderInfo memory bidderInfo = _bidderInfoMapMap[round][bidder];
        require(bidderInfo.bidInWei > 0, "Invalid Bidder");

        bidInWei = bidderInfo.bidInWei;
        payedOutAmount = bidderInfo.payedOutAmount;
        payOutCurrency = bidderInfo.payOutCurrency;
        payedOut = bidderInfo.payedOut;
    }
}

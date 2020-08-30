var Web3 = require("web3");
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const RND = artifacts.require("./RANDToken");
const Auction = artifacts.require("./Auction");


contract("AuctionTest", accounts => {
  var owner = accounts[0];
  var minter = accounts[1];
  var user1 = accounts[2];
  var user2 = accounts[3];
  var user3 = accounts[4];


  it("Auction happy path", async function () {

    var user1Bid = web3.utils.toWei("2", "ether");
    var user2Bid = web3.utils.toWei("2.2", "ether");
    var user3Bid = web3.utils.toWei("1", "ether");

    var token = await RND.new();
    var auction = await Auction.new(token.address);

    var burnAddr = "0x000000000000000000000000000000000000dEaD";
    var balance0x0beginning = await web3.eth.getBalance(burnAddr);

    token.addMinter(auction.address, { from: owner });

    await auction.startAuction({ from: owner });
    var data = await auction.getAuctionData(0);
    var totalSupply = await token.totalSupply();

    assert.equal(data.podTokens.toString(), totalSupply.toString());
    //  assert.equal(data.payedOut, false);
    assert.equal(data.roundEnded, false);
    assert.equal(data.numberOfBidders.toString(), "0");

    var result = await auction.bid(0, { from: user1, value: user1Bid });
    var bidderInfo = await auction.getBidderInfo(0, user1);
    assert.equal(bidderInfo.bidInWei.toString(), user1Bid.toString());

    result = await auction.bid(0, { from: user2, value: user2Bid });
    result = await auction.bid(1, { from: user3, value: user3Bid });

    data = await auction.getAuctionData(0);
    assert.equal(data.numberOfBidders.toString(), "3");
    assert.equal(data.podWeis.toString(), web3.utils.toWei("5.2", "ether").toString());
    assert.equal(data.highestBidder, user2);

    await auction.endAuction();

    var user1BalanceBefore = await web3.eth.getBalance(user1);
    result = await auction.payOut(0, user1);
    var user1BalanceAfter = await web3.eth.getBalance(user1);
    var BN = web3.utils.BN;
    var user1BalanceExpected = new BN(user1BalanceBefore.toString()).add(new BN(user1Bid.toString()));
    assert.equal(user1BalanceAfter.toString(), user1BalanceExpected.toString());

    result = await auction.payOut(0, user2);

    bidderInfo = await auction.getBidderInfo(0, user1);
    assert.equal(bidderInfo.bidInWei.toString(), user1Bid.toString());

    data = await auction.getAuctionData(0);
    assert.equal(data.highestBidder, user2);

    var randBalancerUser2 = await token.balanceOf(user2);
    assert.equal(randBalancerUser2.toString(), data.podTokens.toString());

    await auction.payOut(0, user3);
    var randBalancerUser3 = await token.balanceOf(user3);
    assert.equal(randBalancerUser3.toString(), "10000000000000000000"); // 10 RND

    // check that the contract has no more assets after the Auction
    var contractEtherBalance = await web3.eth.getBalance(auction.address);
    assert.equal(contractEtherBalance.toString(), "0");

    var contractTokenBalance = await token.balanceOf(auction.address);
    assert.equal(contractTokenBalance.toString(), "0");

    // 3.2 Eth should be burned
    var balance0x0End = await web3.eth.getBalance(burnAddr);
    var balance0x0Diff = new BN(balance0x0End.toString()).sub(new BN(balance0x0beginning.toString()));
    console.log(web3.utils.fromWei(balance0x0beginning, "ether"));
    console.log(web3.utils.fromWei(balance0x0End, "ether"));

    assert.equal(balance0x0Diff.toString(), web3.utils.toWei("3.2", "ether").toString());
  });
});

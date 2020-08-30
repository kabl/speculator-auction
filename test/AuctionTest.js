var Web3 = require("web3");
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const RND = artifacts.require("./RANDToken");
const Auction = artifacts.require("./Auction");


contract("AuctionTest", accounts => {
  var owner = accounts[0];
  var minter = accounts[1];
  var user1 = accounts[2];
  var user2 = accounts[3];
  var user3 = accounts[3];


  it("Auction happy path", async function () {
    var token = await RND.new();
    var auction = await Auction.new(token.address);
    token.addMinter(auction.address, { from: owner });


    await auction.startAuction({ from: owner });
    var data = await auction.getAuctionData(0);
    var totalSupply = await token.totalSupply();

    assert.equal(data.podTokens.toString(), totalSupply.toString());
  //  assert.equal(data.payedOut, false);
    assert.equal(data.roundEnded, false);
    assert.equal(data.numberOfBidders.toString(), "0");

    var weis = web3.utils.toWei("2","ether");
    var result = await auction.bid(0, {from: user1, value: weis});

    weis = web3.utils.toWei("2.2","ether");
    var result = await auction.bid(0, {from: user2, value: weis});    

    data = await auction.getAuctionData(0);
    assert.equal(data.numberOfBidders.toString(), "2");
    assert.equal(data.podWeis.toString(), web3.utils.toWei("4.2","ether").toString());
    assert.equal(data.highestBidder, user2);
    

    await auction.endAuction();

    result = await auction.payOut(0, user1);
    console.dir(result);
    result = await auction.payOut(0, user2);
    console.dir(result);
  });
});

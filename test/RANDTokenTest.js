var Web3 = require("web3");
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const RND = artifacts.require("./RANDToken");

contract("RANDTokenTest", accounts => {
  var owner = accounts[0];
  var minter = accounts[1];
  var user1 = accounts[2];
  var user2 = accounts[3];

  it("Mint", async function() {
    var token = await RND.new();

    var totalSupply = (await token.totalSupply()).toString();
    assert.equal(totalSupply, "0");

    const amount = "10000000000000000000"
    await token.mint(user1, amount, {from: owner}); // 18 decimals..

    var user1Balance = (await token.balanceOf(user1)).toString();

    assert.equal(user1Balance, amount);
  });
});

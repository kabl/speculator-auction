const RANDToken = artifacts.require("./RANDToken.sol");
const Auction = artifacts.require("./Auction.sol");


module.exports = function (deployer, network) {
    deployer.then(async () => {
        if (network === "development") {
            const instance = await deployer.deploy(RANDToken);
            console.log("RANDToken Contract: " + instance.address);

            const instance2 = await deployer.deploy(Auction, instance.address);
            console.log("Auction Contract: " + instance2.address);
        } else if (network === "rinkeby") {
            console.error('Not yet implemented');
        } else {
            console.log("Network is not yet configured. Network:", network);
        }
    });
};

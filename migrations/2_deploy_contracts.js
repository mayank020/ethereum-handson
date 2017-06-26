var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var Hotel = artifacts.require("./Hotel.sol");

module.exports = function(deployer) {
  deployer.deploy(Hotel, "Ethereum Hotel", "Book rooms with ease", "12.9716", "77.5946");
};

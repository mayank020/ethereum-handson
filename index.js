Web3 = require('web3');
web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
hotelCode = fs.readFileSync('Hotel.sol').toString();
hotelCodeCompiled =  web3.eth.compile.solidity(hotelCode);
hotelContractDefinition = web3.eth.contract(hotelCodeCompiled.info.abiDefinition);
DeployedHotelContract = hotelContractDefinition.new('Blockchain Hotel', 'Book your rooms with ease', '12.972442', '77.580643', 19800, {data: hotelCodeCompiled.code, from: web3.eth.accounts[0], gas: 4700000});
hotelContractInstance = hotelContractDefinition.at(DeployedHotelContract.address);


"Ethereum Hotel", "ABC", "12.9716", "77.5946"
1, "Single AC Room", 2, 100, true
19800, true
1, 18500, 18502, 1

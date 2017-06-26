var Hotel = artifacts.require("./Hotel.sol");

contract('Hotel', function(accounts){
    it("should assign the hotel details correctly", function(){
        return Hotel.deployed().then(function(instance){
            console.log(instance);
            return instance.name();
        }).then(function(description){
            assert.equal(description, "Book rooms with ease", "Description is correct");
        });
    });
});

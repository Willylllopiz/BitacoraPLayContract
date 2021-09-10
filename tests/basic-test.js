var Test = artifacts.require("./Test.sol");
contract('Test', function(accounts) {
    it("call method g", function() {
        Test.deployed().then(function(instance) {
            return instance.call('g');
        }).then(function(result) {
            assert.equal("method g()", result, "is not call method g");
        });
    });
    it("call method f", function() {
        Test.deployed().then(function(instance) {
            return instance.call('f');
        }).then(function(result) {
            assert.equal("method f()", result, "is not call method f");
        });
    });
});
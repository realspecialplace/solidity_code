// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Anything {
    // custom type
    struct User {
        string name;
        string occupation;
        uint256 age;
    }
    // state variable
    User public user;

    // events
    event UserUpdated(string indexed name, string indexed job, uint256 age);

    /**
     * @notice This function updates user state
     */
    function updateUserDetails(string memory _name, string memory _occu, uint256 _age)
        public
        returns (string memory, User memory)
    {
        user = User({name: _name, occupation: _occu, age: _age});
        emit UserUpdated(_name, _occu, _age);

        return ("user info updated", user);
    }
}

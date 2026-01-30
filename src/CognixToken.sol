// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CognixToken is Ownable {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _supply, address _owner) Ownable(_owner) {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply;
        balanceOf[_owner] = _supply;
    }
}

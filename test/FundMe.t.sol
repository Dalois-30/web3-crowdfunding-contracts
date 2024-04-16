// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract CounterTest is Test {
    FundMe fundme;

    function setUp() external {
        fundme = new FundMe(
            address(
                bytes20(bytes("0x694AA1769357215DE4FAC081bf1f309aDC325306"))
            )
        );
    }

    function testMIN_USDT() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwner() public view {
        console.log(fundme.i_owner());
        console.log(msg.sender);
        assertEq(fundme.i_owner(), address(this));
    }

    function testVersion() public view {
        console.log(fundme.getVersion());
        assertEq(fundme.getVersion(), 4);
    }
}

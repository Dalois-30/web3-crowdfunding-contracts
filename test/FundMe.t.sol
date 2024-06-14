// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMeScript} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;

    address USER = makeAddr("user"); // Create a new address based on the string provided
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMeScript deployFundMe = new DeployFundMeScript();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMIN_USDT() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwner() public view {
        assertEq(fundme.i_owner(), msg.sender);
    }

    function testVersion() public view {
        console.log(fundme.getVersion());
        assertEq(fundme.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // hey, the next line, should revert !
        // assert(this tx fails/reverts)
        fundme.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next transaction will be sent by USER
        fundme.fund{value: SEND_VALUE}();
        
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }
}

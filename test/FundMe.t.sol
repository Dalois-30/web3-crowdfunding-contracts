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
        DeployFundMeScript deployFundMe = new DeployFundMeScript();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // set the initial balance of the address USER
    }

    function testMIN_USDT() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwner() public view {
        assertEq(fundme.getOwner(), msg.sender);
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

    modifier funded() {
        vm.prank(USER); // the next transaction will be sent by USER
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded() {
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundme.getFunder(0);
        assertEq(funder, USER); // Check if the first funder is the correct sender
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // Instead of add these tho line every time, we can just add the modifier funded
        // vm.prank(USER); // the next transaction will be sent by USER
        // fundme.fund{value: SEND_VALUE}();

        vm.prank(USER); // the next transaction will be sent by USER
        vm.expectRevert(); // the errer that should be get
        fundme.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
}

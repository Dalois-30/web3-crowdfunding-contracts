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
    uint256 constant GAS_PRICE = 1;

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

    function testWithdrawFromMultipleFunder() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we start from 1 because sometimes address(0) revert
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), SEND_VALUE); // create new address and send the amount SEND_VALUE to that address
            // because of the hoax function, we don't need to prank the new address, the next transaction is automatically send
            fundme.fund{value: SEND_VALUE}();
            // fund the fundme
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        // uint256 gasStart = gasleft(); // Built in fonction on solidity to get how much gas remains for the tx
        // vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundme.getOwner());
        fundme.withdraw(); // By default anvil gas price is zero, o to simulate real gas price, xe need to add some new cheatCode from foundry
        vm.stopPrank(); // startPrank and stopPrank are the same as startBroadcast and stopBroadcast
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // tx.gasprice tell the current gasprice
        // console.log('gasUsed', gasUsed);

        // Assert
        assert(address(fundme).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }

    function testWithdrawFromMultipleFunderCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we start from 1 because sometimes address(0) revert
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), SEND_VALUE); // create new address and send the amount SEND_VALUE to that address
            // because of the hoax function, we don't need to prank the new address, the next transaction is automatically send
            fundme.fund{value: SEND_VALUE}();
            // fund the fundme
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        // uint256 gasStart = gasleft(); // Built in fonction on solidity to get how much gas remains for the tx
        // vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw(); // By default anvil gas price is zero, o to simulate real gas price, xe need to add some new cheatCode from foundry
        vm.stopPrank(); // startPrank and stopPrank are the same as startBroadcast and stopBroadcast
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // tx.gasprice tell the current gasprice
        // console.log('gasUsed', gasUsed);

        // Assert
        assert(address(fundme).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }
}

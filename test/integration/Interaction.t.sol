// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMeScript} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interaction.s.sol";

contract InteractionsTest is Test {
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

    function testUserCanFundInteraction() public {
        FundFundMe fundFundMe = new FundFundMe();
        // vm.prank(USER);
        // vm.deal(USER, 1e18);
        fundFundMe.fundFundMe(address(fundme));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        // vm.prank(USER);
        // vm.deal(USER, 1e18);
        withdrawFundMe.withdrawFundMe(address(fundme));
        assertEq(address(fundme).balance, 0);

        // address funder = fundme.getFunder(0);
        // assertEq(funder, USER); // Check if the first funder is the correct sender
    }
}

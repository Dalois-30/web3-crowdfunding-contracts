// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {CrowdfundingManager} from "../../src/crowdfunding/CrowdfundingManager.sol";
import {Project} from "../../src/crowdfunding/Project.sol";
import {DeployManagerScript} from "../../script/DeployManager.s.sol";

contract ManagerTest is Test {
    CrowdfundingManager manager;
    Project project;
    address USER = makeAddr("user");
    address USER1 = makeAddr("user1");

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    uint256 cost = 15 ether;
    uint256 expireAt = 1719716276;
    string title = "Farm collect";
    string description = "Creation of a farm";
    string imageURL = "https://aws.cm/images/farm.jpeg";

    function setUp() external {
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER1, STARTING_BALANCE);
        DeployManagerScript deployManager = new DeployManagerScript();
        manager = deployManager.run();
    }

    function testCreateProject() public {
        address projectAddress;
        vm.prank(manager.getOwner());
        projectAddress = manager.createProject(title, description, imageURL, cost, expireAt);
        console.log("Project created ", projectAddress);
        project = Project(projectAddress);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {CrowdfundingManager} from "../../src/crowdfunding/CrowdfundingManager.sol";
import {Project} from "../../src/crowdfunding/Project.sol";
import {DeployCoinScript} from "../../script/crowdfunding/DeployCoin.s.sol";
import {DeployManagerScript} from "../../script/crowdfunding/DeployManager.s.sol";

contract ManagerTest is Test {
    CrowdfundingManager manager;
    Project project;
    address USER = makeAddr("user");
    address USER1 = makeAddr("user1");

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    address projectAddress;
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
        vm.prank(manager.getOwner());
        projectAddress = manager.createProject(
            title,
            description,
            imageURL,
            cost,
            expireAt
        );
        project = Project(projectAddress);
        // console.log("====================================Project Firsts Informations====================================");
        // console.log("Title:", project.getTitle());
        // console.log("Description:", project.getDescription());
        // console.log("Image:", project.getImageURL());
        // console.log("Cost:", project.getCost());
        // console.log("Expire At:", project.getExpiresAt());
    }

    function testCreateProject() public {
        string memory titleTest = "Project Farm City";
        string memory descriptionTest = "Project Description";
        string memory imageURLTest = "Image URL";
        uint256 costTest = 1 ether;
        uint256 expireAtTest = 1719719276;
        vm.prank(manager.getOwner());
        projectAddress = manager.createProject(
            titleTest,
            descriptionTest,
            imageURLTest,
            costTest,
            expireAtTest
        );
        project = Project(projectAddress);
        // console.log("Project created at:", projectAddress);
        // console.log("====================================Project Informations====================================");
        // console.log("Title:", project.getTitle());
        // console.log("Description:", project.getDescription());
        // console.log("Image:", project.getImageURL());
        // console.log("Cost:", project.getCost());
        // console.log("Expire At:", project.getExpiresAt());

        assertEq(titleTest, project.getTitle());
        assertEq(descriptionTest, project.getDescription());
        assertEq(imageURLTest, project.getImageURL());
        assertEq(costTest, project.getCost());
        assertEq(expireAtTest, project.getExpiresAt());
    }

    function testUpdateProject() public {
        string memory titleTest = "Project Farm City";
        string memory descriptionTest = "Project Description";
        string memory imageURLTest = "Image URL";
        vm.prank(manager.getOwner());
        manager.updateProject(
            projectAddress,
            titleTest,
            descriptionTest,
            imageURLTest
        );
        // console.log("====================================Project Updated Informations====================================");
        // console.log("Title:", project.getTitle());
        // console.log("Description:", project.getDescription());
        // console.log("Image:", project.getImageURL());
        // console.log("Cost:", project.getCost());
        // console.log("Expire At:", project.getExpiresAt());

        assertEq(titleTest, project.getTitle());
        assertEq(descriptionTest, project.getDescription());
        assertEq(imageURLTest, project.getImageURL());
    }

    function testBackProject() public {
        vm.prank(USER);
        manager.backProject{value: SEND_VALUE}(projectAddress);
        assertEq(address(projectAddress).balance, SEND_VALUE);
    }

    function testRequestRefund() public {
        vm.prank(USER);
        vm.expectRevert();
        manager.requestRefund(projectAddress);
    }

    function testPayOut() public {
        vm.prank(USER);
        manager.backProject{value: SEND_VALUE}(projectAddress);
        
        // Arrange
        uint160 numberOfFunders = 150;
        uint160 startingFunderIndex = 1; // we start from 1 because sometimes address(0) revert
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), SEND_VALUE); // create new address and send the amount SEND_VALUE to that address
            // because of the hoax function, we don't need to prank the new address, the next transaction is automatically send
            manager.backProject{value: SEND_VALUE}(projectAddress);
            // console.log("Address:", project.getAllBackers()[i]);
        }
        console.log("Collected:", address(projectAddress).balance);
        vm.deal(address(manager), cost);
        console.log("Manager Address:", address(manager).balance);
        vm.prank(manager.getOwner());
        manager.payOutProject(projectAddress);
        console.log("Collected:", address(projectAddress).balance);
    }
}

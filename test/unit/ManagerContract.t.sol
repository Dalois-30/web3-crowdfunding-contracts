// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {CrowdfundingManager} from "../../src/crowdfunding/CrowdfundingManager.sol";
import {DecentralizedStableCoin} from "../../src/crowdfunding/DecentralizedStableCoin.sol";
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

        // Project status enumeration
    enum Status {
        OPEN,
        APPROVED,
        REVERTED,
        DELETED,
        PAIDOUT
    }

    address projectAddress;
    uint256 cost = 31500;
    uint256 expireAt = 1719716276;
    string title = "Farm collect";
    string description = "Creation of a farm";
    string imageURL = "https://aws.cm/images/farm.jpeg";

    function setUp() external {
        vm.deal(USER, STARTING_BALANCE);
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
        console.log("Manager owner", manager.getOwner());
        console.log("Project owner", project.getOwner());
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
        (string memory s_title, 
        string memory s_description, 
        string memory s_imageURL, 
        uint256 s_cost, 
        uint256 s_raised, 
        uint256 s_timestamp, 
        uint256 s_expiresAt, 
        bool s_isActive, 
        uint256 s_projectTax, 
         ) = project.getProjectDetails();
        // console.log("Project created at:", projectAddress);
        console.log("====================================Project Informations====================================");
        console.log("Title:", s_title);
        console.log("Description:", s_description);
        console.log("Image:", s_imageURL);
        console.log("Cost:", s_cost);
        console.log("s_raised:", s_raised);
        console.log("s_projectTax:", s_projectTax);
        console.log("Expire At:", s_expiresAt);
        // console.log("s_status:", s_status);

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
        (uint256 contribution, uint256 timestamp, bool refunded) = Project(projectAddress).getBacker(USER);
        console.log("contribution:", contribution);
        console.log("timestamp:", timestamp);
        console.log("refunded:", refunded);
        assertEq(address(projectAddress).balance, SEND_VALUE);

    }

    function testRequestRefund() public {
        vm.prank(USER);
        vm.expectRevert();
        manager.requestRefund(projectAddress);
    }

    function testPayOut() public {
        // vm.prank(USER);
        // manager.backProject{value: SEND_VALUE}(projectAddress);

        
        // Arrange
        uint160 numberOfFunders = 151;
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
        // console.log("USDT Collected:", DecentralizedStableCoin(project.getStablecoinAddress()).balanceOf(projectAddress));
        // console.log("USDT Collected by admin:", DecentralizedStableCoin(project.getStablecoinAddress()).balanceOf(manager.getOwner()));
        // console.log("Manager Address:", address(manager).balance);
        // vm.prank(manager.getOwner());
        // manager.payOutProject(projectAddress);
        // console.log("USDT Collected 2:", DecentralizedStableCoin(project.getStablecoinAddress()).balanceOf(projectAddress));
        // console.log("USDT Collected by contract 2:", DecentralizedStableCoin(project.getStablecoinAddress()).balanceOf(project.getOwner()));
        // console.log("USDT Collected by admin 2:", DecentralizedStableCoin(project.getStablecoinAddress()).balanceOf(manager.getOwner()));
        // console.log("Manager Address:", address(manager).balance);
    }
    // TODO: finalize the tests
}

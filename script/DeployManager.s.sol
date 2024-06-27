// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {CrowdfundingManager} from "../src/crowdfunding/CrowdfundingManager.sol";
import {Project} from "../src/crowdfunding/Project.sol";
import {console2} from "forge-std/console2.sol";

contract DeployManagerScript is Script {


    uint8 constant PROJECT_TAX = 1;

    function setUp() public {}

    function run() external returns (CrowdfundingManager) {
        // Before startBroadcast -> Not a "real" transaction
        // After startBroadcast -> real transaction
        vm.startBroadcast();

        CrowdfundingManager crowdfundingManager = new CrowdfundingManager(PROJECT_TAX);
        vm.stopBroadcast();
        console2.log("Manager deployed at:", address(crowdfundingManager));
        return crowdfundingManager;
    }
}

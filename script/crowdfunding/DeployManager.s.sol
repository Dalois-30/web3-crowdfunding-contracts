// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {CrowdfundingManager} from "../../src/crowdfunding/CrowdfundingManager.sol";
import {DecentralizedStableCoin} from "../../src/crowdfunding/DecentralizedStableCoin.sol";
import {Project} from "../../src/crowdfunding/Project.sol";
import {console2} from "forge-std/console2.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {DeployCoinScript} from "./DeployCoin.s.sol";

contract DeployManagerScript is Script {


    uint8 constant PROJECT_TAX = 1;

    function setUp() public {}

    function run() external returns (CrowdfundingManager) {
        // Before startBroadcast -> Not a "real" transaction
        // After startBroadcast -> real transaction
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        
        vm.startBroadcast();
        CrowdfundingManager crowdfundingManager = new CrowdfundingManager(PROJECT_TAX, ethUsdPriceFeed);
        vm.stopBroadcast();
        console2.log("Manager deployed at:", address(crowdfundingManager));
        return crowdfundingManager;
    }
}

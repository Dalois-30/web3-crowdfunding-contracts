// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMeScript is Script {
    function setUp() public {}

    // function run() public {
    //     vm.broadcast();
    // // }

    function run() external returns (FundMe) {

        // Before startBroadcast -> Not a "real" transaction
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();  

        // After startBroadcast -> real transaction      
        vm.startBroadcast();

        FundMe fundMe = new FundMe(ethUsdPriceFeed);

        vm.stopBroadcast();
        return fundMe;
    }
}

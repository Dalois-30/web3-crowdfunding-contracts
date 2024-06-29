// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../../src/crowdfunding/DecentralizedStableCoin.sol";
import {Project} from "../../src/crowdfunding/Project.sol";
import {console2} from "forge-std/console2.sol";

contract DeployCoinScript is Script {

    function setUp() public {}

    function run() external returns (DecentralizedStableCoin) {
        // Before startBroadcast -> Not a "real" transaction
        // After startBroadcast -> real transaction
        vm.startBroadcast();

        DecentralizedStableCoin stablecoin = new DecentralizedStableCoin();
        vm.stopBroadcast();
        console2.log("Stablecoin deployed at:", address(stablecoin));
        return stablecoin;
    }
}

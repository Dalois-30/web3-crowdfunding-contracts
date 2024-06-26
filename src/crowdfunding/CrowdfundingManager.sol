// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./Project.sol";
import "./DecentralizedStableCoin.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * @title CrowdfundingManager
 * @dev Manager contract for creating, managing, and interacting with crowdfunding projects.
 * Author: Nguenang Dalois
 */
contract CrowdfundingManager is ConfirmedOwner {
    // error Manager__messages
    error Manager__TitleCannotBeEmpty();
    error Manager__DescriptionCannotBeEmpty();
    error Manager__CostCannotBeZero();
    error Manager__DeadlineMustBeInTheFuture();

    // Struct to store statistics
    struct Stats {
        uint256 totalProjects;
        uint256 totalBacking;
        uint256 totalContributors;
        uint256 totalDonations;
    }

    // Mapping from project addresses to Project instances
    mapping(address => Project) private s_projectByAddress;

    address private immutable i_owner;
    address private immutable i_stablecoinAddress;
    address private immutable i_ethPriceFeed;

    // Array to store all projects
    Project[] private s_projects;

    DecentralizedStableCoin private i_stableCoin;

    // State variables
    uint8 private s_projectTax;
    uint256 private s_projectCount;
    Stats private s_stats;

    // Event emitted when a new project is created
    event ProjectCreated(address projectAddress, address owner, uint256 timestamp);

    /**
     * @dev Constructor of the CrowdfundingManager contract.
     * @param _projectTax The percentage tax levied on projects.
     */
    constructor(
        uint8 _projectTax,
        address _ethPriceFeed
    ) ConfirmedOwner(msg.sender) {
        i_owner = msg.sender;
        s_projectTax = _projectTax;
        i_ethPriceFeed = _ethPriceFeed;
        i_stableCoin = new DecentralizedStableCoin();
        i_stablecoinAddress = address(i_stableCoin);
    }

    /**
     * @dev Creates a new project.
     * @param title The title of the project.
     * @param description The description of the project.
     * @param imageURL The URL of the project image.
     * @param cost The total cost of the project.
     * @param expiresAt The expiration date of the project.
     * @return address The address of the newly created project.
     */
    function createProject(
        string memory title,
        string memory description,
        string memory imageURL,
        uint256 cost,
        uint256 expiresAt
    ) external onlyOwner returns (address) {
        if (bytes(title).length == 0) revert Manager__TitleCannotBeEmpty();
        if (bytes(description).length == 0) revert Manager__DescriptionCannotBeEmpty();
        if (cost == 0) revert Manager__CostCannotBeZero();
        if (expiresAt <= block.timestamp) revert Manager__DeadlineMustBeInTheFuture();

        Project newProject = new Project(title, description, imageURL, msg.sender, i_stablecoinAddress, i_ethPriceFeed, cost, expiresAt, s_projectTax);
        s_projects.push(newProject);
        s_projectByAddress[address(newProject)] = newProject;
        s_stats.totalProjects += 1;
        s_projectCount++;

        emit ProjectCreated(address(newProject), msg.sender, block.timestamp);
        return address(newProject);
    }

    /**
     * @dev Updates the details of a project.
     * @param projectAddress The address of the project to update.
     * @param title The new title of the project.
     * @param description The new description of the project.
     * @param imageURL The new URL of the project image.
     */
    function updateProject(
        address projectAddress,
        string memory title,
        string memory description,
        string memory imageURL
    ) external onlyOwner {
        Project project = s_projectByAddress[projectAddress];
        project.updateProject(title, description, imageURL);
    }

    /**
     * @dev Deletes a project.
     * @param projectAddress The address of the project to delete.
     */
    function deleteProject(address projectAddress) external onlyOwner {
        Project project = s_projectByAddress[projectAddress];
        project.deleteProject();
    }

    /**
     * @dev Allows contribution to a project.
     * @param projectAddress The address of the project to contribute to.
     */
    function backProject(address projectAddress) external payable {
        Project project = s_projectByAddress[projectAddress];
        project.backProject{value: msg.value}(msg.sender);
        s_stats.totalBacking += 1;
        s_stats.totalContributors += 1;
        s_stats.totalDonations += msg.value;
    }

    /**
     * @dev Allows a contributor to request a refund.
     * @param projectAddress The address of the project to request a refund from.
     */
    function requestRefund(address projectAddress) external onlyOwner {
        Project project = s_projectByAddress[projectAddress];
        project.requestRefund();
    }

    /**
     * @dev Performs payout of a project to the owner.
     * @param projectAddress The address of the project to pay out.
     */
    function payOutProject(address projectAddress) external onlyOwner {
        Project project = s_projectByAddress[projectAddress];
        project.payOutProject();
    }

    /**
     * @dev Changes the percentage tax levied on projects.
     * @param _taxPct The new tax percentage.
     */
    function changeTax(uint8 _taxPct) external onlyOwner {
        s_projectTax = _taxPct;
    }

    /**
     * @dev Retrieves the details of a project.
     * @param projectAddress The address of the project.
     * @return Project The project corresponding to the address.
     */
    function getProject(address projectAddress) external view returns (Project) {
        return s_projectByAddress[projectAddress];
    }

    /**
     * @dev Retrieves the statistics of a project.
     * @param projectAddress The address of the project.
     * @return uint[6] An array containing the project's statistics:
     * [cost, raised, backers, timestamp, expiresAt, status].
     */
    function getProjectStats(address projectAddress) external view returns (uint256[6] memory) {
        Project project = s_projectByAddress[projectAddress];
        return [
            project.getCost(),
            project.getRaised(),
            project.getBackers(),
            project.getTimestamp(),
            project.getExpiresAt(),
            uint256(project.getStatus())
        ];
    }

    /**
     * @dev Function to get all projects.
     * @return An array of Project instances.
     */
    function getAllProjects() external view returns (Project[] memory) {
        return s_projects;
    }

    /**
     * @dev Function to update the title of a project.
     * @param projectAddress The address of the project to update.
     * @param title The new title for the project.
     */
    function updateProjectTitle(address projectAddress, string memory title) external onlyOwner {
        Project(s_projectByAddress[projectAddress]).setTitle(title);
    }

    /**
     * @dev Function to update the description of a project.
     * @param projectAddress The address of the project to update.
     * @param description The new description for the project.
     */
    function updateProjectDescription(address projectAddress, string memory description) external onlyOwner {
        Project(s_projectByAddress[projectAddress]).setDescription(description);
    }

    /**
     * @dev Function to update the image URL of a project.
     * @param projectAddress The address of the project to update.
     * @param imageURL The new image URL for the project.
     */
    function updateProjectImageURL(address projectAddress, string memory imageURL) external onlyOwner {
        Project(s_projectByAddress[projectAddress]).setImageURL(imageURL);
    }

    /**
     * @dev Function to update the expiration timestamp of a project.
     * @param projectAddress The address of the project to update.
     * @param expiresAt The new expiration timestamp for the project.
     */
    function updateProjectExpiration(address projectAddress, uint256 expiresAt) external onlyOwner {
        Project(s_projectByAddress[projectAddress]).setExpiresAt(expiresAt);
    }

    /**
     * @dev Function to update the project tax of a project.
     * @param projectAddress The address of the project to update.
     * @param projectTax The new project tax percentage for the project.
     */
    function updateProjectTax(address projectAddress, uint256 projectTax) external onlyOwner {
        Project(s_projectByAddress[projectAddress]).setProjectTax(projectTax);
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

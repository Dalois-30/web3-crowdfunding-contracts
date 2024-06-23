// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./Project.sol";

/**
 * @title CrowdfundingManager
 * @dev This contract manages the crowdfunding platform as a whole.
 */
contract CrowdfundingManager {
    address public s_owner;
    uint8 public s_projectTax;
    uint256 public projectCount;
    uint256 public balance;
    Project[] public projects;

    // Mapping to retrieve a project by its address
    mapping(address => Project) public projectByAddress;

    struct Stats {
        uint256 totalProjects;
        uint256 totalBacking;
        uint256 totalDonations;
    }

    Stats public stats;

    modifier ownerOnly() {
        require(msg.sender == s_owner, "Owner reserved only");
        _;
    }

    event ProjectCreated(address indexed projectAddress, address indexed creator, uint256 timestamp);

    /**
     * @dev Constructor of the CrowdfundingManager contract.
     * @param _projectTax The percentage tax levied on projects.
     */
    constructor(uint8 _projectTax) {
        s_owner = msg.sender;
        s_projectTax = _projectTax;
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
    ) public returns (address) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(cost > 0 ether, "Cost cannot be zero");
        require(expiresAt > block.timestamp, "The deadline should be a date in the future.");

        Project newProject = new Project(title, description, imageURL, cost, expiresAt, s_projectTax);
        projects.push(newProject);
        projectByAddress[address(newProject)] = newProject;
        stats.totalProjects += 1;
        projectCount++;

        emit ProjectCreated(address(newProject), msg.sender, block.timestamp);
        return address(newProject);
    }

    /**
     * @dev Updates the details of a project.
     * @param projectAddress The address of the project to update.
     * @param title The new title of the project.
     * @param description The new description of the project.
     * @param imageURL The new URL of the project image.
     * @param expiresAt The new expiration date of the project.
     */
    function updateProject(
        address projectAddress,
        string memory title,
        string memory description,
        string memory imageURL,
        uint256 expiresAt
    ) public {
        Project project = projectByAddress[projectAddress];
        project.updateProject(title, description, imageURL, expiresAt);
    }

    /**
     * @dev Deletes a project.
     * @param projectAddress The address of the project to delete.
     */
    function deleteProject(address projectAddress) public {
        Project project = projectByAddress[projectAddress];
        project.deleteProject();
    }

    /**
     * @dev Allows contribution to a project.
     * @param projectAddress The address of the project to contribute to.
     */
    function backProject(address projectAddress) public payable {
        Project project = projectByAddress[projectAddress];
        project.backProject{value: msg.value}();
        stats.totalBacking += 1;
        stats.totalDonations += msg.value;
    }

    /**
     * @dev Allows a contributor to request a refund.
     * @param projectAddress The address of the project to request a refund from.
     */
    function requestRefund(address projectAddress) public {
        Project project = projectByAddress[projectAddress];
        project.requestRefund();
    }

    /**
     * @dev Performs payout of a project to the owner.
     * @param projectAddress The address of the project to pay out.
     */
    function payOutProject(address projectAddress) public {
        Project project = projectByAddress[projectAddress];
        project.payOutProject();
    }

    /**
     * @dev Changes the percentage tax levied on projects.
     * @param _taxPct The new tax percentage.
     */
    function changeTax(uint8 _taxPct) public ownerOnly {
        s_projectTax = _taxPct;
    }

    /**
     * @dev Retrieves the details of a project.
     * @param projectAddress The address of the project.
     * @return Project The project corresponding to the address.
     */
    function getProject(address projectAddress) public view returns (Project) {
        return projectByAddress[projectAddress];
    }

    /**
     * @dev Retrieves the statistics of a project.
     * @param projectAddress The address of the project.
     * @return uint[6] An array containing the project's statistics:
     * [cost, raised, backers, timestamp, expiresAt, status].
     */
    function getProjectStats(address projectAddress) public view returns (uint256[6] memory) {
        Project project = projectByAddress[projectAddress];
        return [
            project.cost(),
            project.raised(),
            project.backers(),
            project.timestamp(),
            project.expiresAt(),
            uint256(project.status())
        ];
    }

    /**
     * @dev Performs payment to a specified address.
     * @param to The recipient address.
     * @param amount The amount to pay.
     */
    function payTo(address to, uint256 amount) internal {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
    }
}

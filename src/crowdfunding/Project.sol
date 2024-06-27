// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * @title Project
 * @dev A crowdfunding project contract that allows users to contribute funds and track the progress of the project.
 * Author: Nguenang Dalois
 */
contract Project is ConfirmedOwner {
    // Error messages
    error TitleCannotBeEmpty();
    error DescriptionCannotBeEmpty();
    error ImageURLCannotBeEmpty();
    error ContributionMustBeGreaterThanZero();
    error ProjectNotOpen();
    error ProjectNotActive();
    error ProjectNotMarkedForRefund();
    error PaymentFailed();

    // Project details
    string private s_title;
    string private s_description;
    string private s_imageURL;
    uint256 private s_cost;
    uint256 private s_raised;
    uint256 private s_timestamp;
    uint256 private s_expiresAt;
    bool private s_isActive;
    uint256 private s_projectTax;

    address private immutable i_adminOwner;

    // Project status enumeration
    enum Status {
        OPEN,
        APPROVED,
        REVERTED,
        DELETED,
        PAIDOUT
    }

    // Current project status
    Status private s_status;

    // Backer struct to store contribution details
    struct Backer {
        uint256 contribution;
        uint256 timestamp;
        bool refunded;
    }

    // Mapping to store backers and their contributions
    mapping(address => Backer) private s_backersOf;
    address[] private s_backerAddresses;

    // Event emitted for various actions
    event Action(string actionType, address indexed executor, uint256 timestamp);

    /**
     * @dev Constructor to initialize the Project contract.
     * @param _title The title of the project.
     * @param _description The description of the project.
     * @param _imageURL The URL of the project image.
     * @param _adminOwner The admin owner address.
     * @param _cost The total cost required for the project.
     * @param _expiresAt The expiration timestamp for the project.
     * @param _projectTax The tax percentage applied to the raised amount upon payout.
     */
    constructor(
        string memory _title,
        string memory _description,
        string memory _imageURL,
        address _adminOwner,
        uint256 _cost,
        uint256 _expiresAt,
        uint256 _projectTax
    ) ConfirmedOwner(msg.sender) {
        i_adminOwner = _adminOwner;
        s_title = _title;
        s_description = _description;
        s_imageURL = _imageURL;
        s_cost = _cost;
        s_expiresAt = _expiresAt;
        s_timestamp = block.timestamp;
        s_isActive = true;
        s_projectTax = _projectTax;
        s_status = Status.OPEN;
    }

    /**
     * @dev Getter for the title.
     */
    function getTitle() external view returns (string memory) {
        return s_title;
    }

    /**
     * @dev Getter for the admin owner.
     */
    function getAdminOwner() external view returns (address) {
        return i_adminOwner;
    }

    /**
     * @dev Setter for the title. Only callable by the owner.
     * @param _title The new title.
     */
    function setTitle(string memory _title) external onlyOwner {
        if (bytes(_title).length == 0) revert TitleCannotBeEmpty();
        s_title = _title;
        emit Action("TITLE UPDATED", msg.sender, block.timestamp);
    }

    /**
     * @dev Getter for the description.
     */
    function getDescription() external view returns (string memory) {
        return s_description;
    }

    /**
     * @dev Getter for the Backers.
     */
    function getAllBackers() external view returns (address[] memory) {
        return s_backerAddresses;
    }

    /**
     * @dev Setter for the description. Only callable by the owner.
     * @param _description The new description.
     */
    function setDescription(string memory _description) external onlyOwner {
        if (bytes(_description).length == 0) revert DescriptionCannotBeEmpty();
        s_description = _description;
        emit Action("DESCRIPTION UPDATED", msg.sender, block.timestamp);
    }

    /**
     * @dev Getter for the imageURL.
     */
    function getImageURL() external view returns (string memory) {
        return s_imageURL;
    }

    /**
     * @dev Setter for the imageURL. Only callable by the owner.
     * @param _imageURL The new imageURL.
     */
    function setImageURL(string memory _imageURL) external onlyOwner {
        if (bytes(_imageURL).length == 0) revert ImageURLCannotBeEmpty();
        s_imageURL = _imageURL;
        emit Action("IMAGE URL UPDATED", msg.sender, block.timestamp);
    }

    /**
     * @dev Getter for the cost.
     */
    function getCost() external view returns (uint256) {
        return s_cost;
    }

    /**
     * @dev Getter for the raised amount.
     */
    function getRaised() external view returns (uint256) {
        return s_raised;
    }

    /**
     * @dev Getter for the timestamp.
     */
    function getTimestamp() external view returns (uint256) {
        return s_timestamp;
    }

    /**
     * @dev Getter for the expiration timestamp.
     */
    function getExpiresAt() external view returns (uint256) {
        return s_expiresAt;
    }

    /**
     * @dev Setter for the expiration timestamp. Only callable by the owner.
     * @param _expiresAt The new expiration timestamp.
     */
    function setExpiresAt(uint256 _expiresAt) external onlyOwner {
        s_expiresAt = _expiresAt;
        emit Action("EXPIRATION TIMESTAMP UPDATED", msg.sender, block.timestamp);
    }

    /**
     * @dev Getter for the number of backers.
     */
    function getBackers() external view returns (uint256) {
        return s_backerAddresses.length;
    }

    /**
     * @dev Getter for the active status.
     */
    function getIsActive() external view returns (bool) {
        return s_isActive;
    }

    /**
     * @dev Getter for the project tax.
     */
    function getProjectTax() external view returns (uint256) {
        return s_projectTax;
    }

    /**
     * @dev Setter for the project tax. Only callable by the owner.
     * @param _projectTax The new project tax.
     */
    function setProjectTax(uint256 _projectTax) external onlyOwner {
        s_projectTax = _projectTax;
        emit Action("PROJECT TAX UPDATED", msg.sender, block.timestamp);
    }

    /**
     * @dev Getter for the project status.
     */
    function getStatus() external view returns (Status) {
        return s_status;
    }

    /**
     * @dev Getter for the backer information.
     * @param _backer The address of the backer.
     */
    function getBacker(address _backer) external view returns (Backer memory) {
        return s_backersOf[_backer];
    }

    /**
     * @dev Allows contributors to back the project with Ether.
     * Contributions are only allowed while the project is active and open.
     */
    function backProject(address _backer) external payable onlyOwner {
        if (msg.value == 0) revert ContributionMustBeGreaterThanZero();
        if (s_status != Status.OPEN) revert ProjectNotOpen();
        if (!s_isActive) revert ProjectNotActive();

        if (s_backersOf[_backer].contribution == 0) {
            s_backerAddresses.push(_backer);
        }

        s_backersOf[_backer].contribution += msg.value;
        s_backersOf[_backer].timestamp = block.timestamp;
        s_backersOf[_backer].refunded = false;

        s_raised += msg.value;

        emit Action("PROJECT BACKED", _backer, block.timestamp);

        if (s_raised >= s_cost) {
            s_status = Status.APPROVED;
            emit Action("STATUS UPDATED TO APPROVED", _backer, block.timestamp);
        }

        if (block.timestamp >= s_expiresAt) {
            s_status = Status.REVERTED;
            emit Action("STATUS UPDATED TO REVERTED", _backer, block.timestamp);
            performRefund();
        }
    }

    /**
     * @dev Updates the project details. Only callable by the owner.
     * @param _title The new title of the project.
     * @param _description The new description of the project.
     * @param _imageURL The new URL of the project image.
     * @param _expiresAt The new expiration timestamp of the project.
     */
    function updateProject(
        string memory _title,
        string memory _description,
        string memory _imageURL,
        uint256 _expiresAt
    ) external onlyOwner {
        if (!s_isActive) revert ProjectNotActive();
        if (bytes(_title).length == 0) revert TitleCannotBeEmpty();
        if (bytes(_description).length == 0) revert DescriptionCannotBeEmpty();
        if (bytes(_imageURL).length == 0) revert ImageURLCannotBeEmpty();

        s_title = _title;
        s_description = _description;
        s_imageURL = _imageURL;
        s_expiresAt = _expiresAt;

        emit Action("PROJECT UPDATED", msg.sender, block.timestamp);
    }

    /**
     * @dev Deletes the project. Only callable by the owner.
     */
    function deleteProject() external onlyOwner {
        if (s_status != Status.OPEN) revert ProjectNotOpen();
        if (!s_isActive) revert ProjectNotActive();

        s_status = Status.DELETED;
        s_isActive = false;
        performRefund();

        emit Action("PROJECT DELETED", msg.sender, block.timestamp);
    }

    /**
     * @dev Internal function to perform refunds to all backers.
     * This function iterates over all backers and refunds their contributions.
     */
    function performRefund() internal {
        uint256 backerLength = s_backerAddresses.length;
        for (uint256 i = 0; i < backerLength; i++) {
            address backer = s_backerAddresses[i];
            if (!s_backersOf[backer].refunded) {
                uint256 contribution = s_backersOf[backer].contribution;

                s_backersOf[backer].refunded = true;
                s_backersOf[backer].timestamp = block.timestamp;
                payTo(backer, contribution);

                // emit Action("BACKER REFUNDED", backer, block.timestamp);
            }
        }
    }

    /**
     * @dev Allows a backer to request a refund.
     * Refunds are only processed if the project is marked as reverted or deleted.
     */
    function requestRefund() external {
        if (s_status != Status.REVERTED && s_status != Status.DELETED) revert ProjectNotMarkedForRefund();
        if (!s_isActive) revert ProjectNotActive();

        s_status = Status.REVERTED;
        emit Action("STATUS UPDATED TO REVERTED", msg.sender, block.timestamp);
        performRefund();
    }

    /**
     * @dev Allows the owner to payout the project funds.
     * The project must be approved and active to perform a payout.
     * A tax is deducted from the raised amount before payout.
     */
    function payOutProject() external onlyOwner {
        if (s_status != Status.APPROVED) revert ProjectNotOpen();
        if (!s_isActive) revert ProjectNotActive();

        s_status = Status.PAIDOUT;
        s_isActive = false;

        uint256 tax = (s_raised * s_projectTax) / 100;
        uint256 amountAfterTax = s_raised - tax;

        payTo(msg.sender, tax);
        payTo(i_adminOwner, amountAfterTax);

        emit Action("PROJECT PAID OUT", msg.sender, block.timestamp);
    }

    /**
     * @dev Internal function to send Ether to a specified address.
     * @param to The address to send Ether to.
     * @param amount The amount of Ether to send.
     */
    function payTo(address to, uint256 amount) internal {
        (bool success,) = payable(to).call{value: amount}("");
        if (!success) revert PaymentFailed();
    }
}
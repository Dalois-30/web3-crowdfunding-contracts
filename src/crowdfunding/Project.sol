// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {OracleLib, AggregatorV3Interface} from "../libraries/OracleLib.sol";
import "./DecentralizedStableCoin.sol";

/**
 * @title Project
 * @dev A crowdfunding project contract that allows users to contribute funds and track the progress of the project.
 * Author: Nguenang Dalois
 */
contract Project is ConfirmedOwner {
    using OracleLib for AggregatorV3Interface;

    // Error messages
    error TitleCannotBeEmpty();
    error DescriptionCannotBeEmpty();
    error ImageURLCannotBeEmpty();
    error ContributionMustBeGreaterThanZero();
    error ProjectNotOpen();
    error ProjectNotActive();
    error ProjectNotMarkedForRefund();
    error StablecoinTransferFailed();
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
    address private immutable i_stablecoinAddress;
    DecentralizedStableCoin private immutable i_stablecoin;
    address private immutable i_ethPriceFeed;

    uint256 public constant PRECISION = 1e18;

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
    event Action(
        string actionType,
        address indexed executor,
        uint256 timestamp
    );

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
        address _coinAddress,
        address _ethPriceFeed,
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
        i_stablecoinAddress = _coinAddress;
        i_ethPriceFeed = _ethPriceFeed;
        i_stablecoin = DecentralizedStableCoin(i_stablecoinAddress);
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
        emit Action(
            "EXPIRATION TIMESTAMP UPDATED",
            msg.sender,
            block.timestamp
        );
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
     * @notice Allows a backer to contribute to the project
     * @dev Contributions can be made in ETH or stablecoin
     * @param _backer The address of the backer
     */
    function backProject(address _backer) external payable {
        if (s_status != Status.OPEN) revert ProjectNotOpen();
        if (!s_isActive) revert ProjectNotActive();

        uint256 usdContribution;
        if (msg.value > 0) {
            // Payment in ETH
            if (msg.value < getEthValueOfUsd(1)) revert ContributionMustBeGreaterThanZero();
            usdContribution = (msg.value * PRECISION) / getEthPrice();
            
            // Mint equivalent stablecoins and send to this contract
            DecentralizedStableCoin(i_stablecoinAddress).mint(address(this), usdContribution);
        } else {
            // Payment in stablecoin
            usdContribution = i_stablecoin.allowance(_backer, address(this));
            if (usdContribution == 0) revert ContributionMustBeGreaterThanZero();
            
            // Transfer stablecoins from backer to this contract
            bool success = i_stablecoin.transferFrom(_backer, address(this), usdContribution);
            if (!success) revert StablecoinTransferFailed();
        }

        // Update backer information
        if (s_backersOf[_backer].contribution == 0) {
            s_backerAddresses.push(_backer);
        }

        s_backersOf[_backer].contribution += usdContribution;
        s_backersOf[_backer].timestamp = block.timestamp;
        s_backersOf[_backer].refunded = false;

        s_raised += usdContribution;

        emit Action("PROJECT BACKED", _backer, block.timestamp);

        // Check if project is fully funded
        if (s_raised >= s_cost) {
            s_status = Status.APPROVED;
            emit Action("STATUS UPDATED TO APPROVED", _backer, block.timestamp);
        }

        // Check if project has expired
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
     * @notice Performs refunds to all backers
     * @dev This function is called internally when the project is reverted
     * @dev All refunds are made in stablecoin
     */
    function performRefund() internal {
        for (uint256 i = 0; i < s_backerAddresses.length; i++) {
            address backer = s_backerAddresses[i];
            uint256 contribution = s_backersOf[backer].contribution;
            if (contribution > 0 && !s_backersOf[backer].refunded) {
                s_backersOf[backer].refunded = true;
                bool success = i_stablecoin.transfer(backer, contribution);
                if (!success) revert StablecoinTransferFailed();
            }
        }
    }

    /**
     * @dev Allows a backer to request a refund.
     * Refunds are only processed if the project is marked as reverted or deleted.
     */
    function requestRefund() external {
        if (s_status != Status.REVERTED && s_status != Status.DELETED)
            revert ProjectNotMarkedForRefund();
        if (!s_isActive) revert ProjectNotActive();

        s_status = Status.REVERTED;
        emit Action("STATUS UPDATED TO REVERTED", msg.sender, block.timestamp);
        performRefund();
    }

    /**
     * @notice Allows the owner to payout the project funds
     * @dev The project must be approved and active to perform a payout
     * @dev A tax is deducted from the raised amount before payout
     * @dev All payouts are made in stablecoin
     */
    function payOutProject() external onlyOwner {
        if (s_status != Status.APPROVED) revert ProjectNotOpen();
        if (!s_isActive) revert ProjectNotActive();

        s_status = Status.PAIDOUT;
        s_isActive = false;

        uint256 tax = (s_raised * s_projectTax) / 100;
        uint256 amountAfterTax = s_raised - tax;

        // Transfer tax to the contract owner
        bool successTax = i_stablecoin.transfer(msg.sender, tax);
        // Transfer remaining amount to the project admin
        bool successPayout = i_stablecoin.transfer(i_adminOwner, amountAfterTax);

        if (!successTax || !successPayout) revert StablecoinTransferFailed();

        emit Action("PROJECT PAID OUT", msg.sender, block.timestamp);
    }

    /// @notice Gets the current USDC price from the oracle
    /// @return The USDC price scaled by ADDITIONAL_FEED_PRECISION
    function getEthPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_ethPriceFeed);
        (, int256 price, , , ) = priceFeed.staleCheckLatestRoundData();
        return uint256(price);
    }

    /// @notice Converts a USD amount to its USDC value
    /// @param usdAmount The amount of USD
    /// @return The ETH value of the given USD amount
    function getEthValueOfUsd(uint256 usdAmount) public view returns (uint256) {
        return (usdAmount * getEthPrice()) / PRECISION;
    }

}

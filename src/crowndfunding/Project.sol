// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title Project
 * @dev This contract manages an individual crowdfunding project.
 */
contract Project {
    address public owner;
    string public title;
    string public description;
    string public imageURL;
    uint public cost;
    uint public raised;
    uint public timestamp;
    uint public expiresAt;
    uint public backers;
    bool public isActive;
    uint public projectTax;

    enum Status {
        OPEN,
        APPROVED,
        REVERTED,
        DELETED,
        PAIDOUT
    }
    Status public status;

    struct Backer {
        address owner;
        uint contribution;
        uint timestamp;
        bool refunded;
    }
    Backer[] public backersOf;

    modifier onlyManager() {
        require(msg.sender == owner, "Manager reserved only");
        _;
    }

    event Action(
        string actionType,
        address indexed executor,
        uint256 timestamp
    );

    /**
     * @dev Constructor of the Project contract.
     * @param _title The title of the project.
     * @param _description The description of the project.
     * @param _imageURL The URL of the project image.
     * @param _cost The total cost of the project.
     * @param _expiresAt The expiration date of the project.
     */
    constructor(
        string memory _title,
        string memory _description,
        string memory _imageURL,
        uint _cost,
        uint _expiresAt,
        uint _projectTax
    ) {
        owner = msg.sender;
        title = _title;
        description = _description;
        imageURL = _imageURL;
        cost = _cost;
        expiresAt = _expiresAt;
        timestamp = block.timestamp;
        isActive = true;
        projectTax = _projectTax;
    }

    /**
     * @dev Updates the project details.
     * @param _title The new title of the project.
     * @param _description The new description of the project.
     * @param _imageURL The new URL of the project image.
     * @param _expiresAt The new expiration date of the project.
     */
    function updateProject(
        string memory _title,
        string memory _description,
        string memory _imageURL,
        uint _expiresAt
    ) public onlyManager {
        require(isActive, "Project is not active");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_imageURL).length > 0, "ImageURL cannot be empty");

        title = _title;
        description = _description;
        imageURL = _imageURL;
        expiresAt = _expiresAt;

        emit Action("PROJECT UPDATED", msg.sender, block.timestamp);
    }

    /**
     * @dev Deletes the project.
     */
    function deleteProject() public onlyManager {
        require(status == Status.OPEN, "Project no longer opened");
        require(isActive, "Project is not active");

        status = Status.DELETED;
        isActive = false;
        performRefund();

        emit Action("PROJECT DELETED", msg.sender, block.timestamp);
    }

    /**
     * @dev Allows contribution to the project.
     */
    function backProject() public payable {
        require(msg.value > 0 ether, "Ether must be greater than zero");
        require(status == Status.OPEN, "Project no longer opened");
        require(isActive, "Project is not active");

        raised += msg.value;
        backers += 1;

        backersOf.push(Backer(msg.sender, msg.value, block.timestamp, false));

        emit Action("PROJECT BACKED", msg.sender, block.timestamp);

        if (raised >= cost) {
            status = Status.APPROVED;
        }

        if (block.timestamp >= expiresAt) {
            status = Status.REVERTED;
            performRefund();
        }
    }

    /**
     * @dev Performs refund to the contributors.
     */
    function performRefund() internal {
        for (uint i = 0; i < backersOf.length; i++) {
            if (!backersOf[i].refunded) {
                address _owner = backersOf[i].owner;
                uint _contribution = backersOf[i].contribution;

                backersOf[i].refunded = true;
                backersOf[i].timestamp = block.timestamp;
                payTo(_owner, _contribution);
            }
        }
    }

    /**
     * @dev Allows a contributor to request a refund.
     */
    function requestRefund() public {
        require(
            status == Status.REVERTED || status == Status.DELETED,
            "Project not marked as revert or delete"
        );
        require(isActive, "Project is not active");

        status = Status.REVERTED;
        performRefund();
    }

    /**
     * @dev Performs payout of the project to the owner.
     */
    function payOutProject() public onlyManager {
        require(status == Status.APPROVED, "Project not APPROVED");
        require(isActive, "Project is not active");

        status = Status.PAIDOUT;
        isActive = false;

        uint tax = (raised * projectTax) / 100;
        uint amountAfterTax = raised - tax;

        payTo(owner, tax);
        payTo(msg.sender, amountAfterTax);

        emit Action("PROJECT PAID OUT", msg.sender, block.timestamp);
    }

    /**
     * @dev Performs payment to a specified address.
     * @param to The recipient address.
     * @param amount The amount to pay.
     */
    function payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
    }
}

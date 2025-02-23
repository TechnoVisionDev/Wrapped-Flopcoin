// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Explicitly import OpenZeppelin Contracts v4.5.0 from GitHub.
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/AccessControlEnumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/security/Pausable.sol";

contract WrappedFlopcoin is ERC20, AccessControlEnumerable, Pausable {
    // Define roles for the bridge and pauser.
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // The designated bridge address for minting/burning operations.
    address public bridge;

    // Events for off-chain tracking.
    event BridgeUpdated(address indexed newBridge);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor() ERC20("Wrapped Flopcoin", "WFLOP") {
        // _setupRole is available in OpenZeppelin v4.5.0.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @notice Sets or updates the designated bridge address.
     * @dev Only callable by an account with DEFAULT_ADMIN_ROLE.
     *      Revokes BRIDGE_ROLE from any previous bridge.
     * @param _bridge The new bridge address.
     */
    function setBridge(address _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bridge != address(0), "Invalid address");
        // If a previous bridge exists, revoke its role.
        if (bridge != address(0)) {
            revokeRole(BRIDGE_ROLE, bridge);
        }
        bridge = _bridge;
        // Use _setupRole to grant the BRIDGE_ROLE (it calls _grantRole internally).
        _setupRole(BRIDGE_ROLE, _bridge);
        emit BridgeUpdated(_bridge);
    }

    /**
     * @notice Mints new tokens.
     * @dev Callable only by an account with BRIDGE_ROLE and when not paused.
     * @param to The address receiving the tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyRole(BRIDGE_ROLE) whenNotPaused {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @notice Burns tokens from a specified address.
     * @dev Callable only by an account with BRIDGE_ROLE and when not paused.
     * @param from The address whose tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external onlyRole(BRIDGE_ROLE) whenNotPaused {
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    /**
     * @notice Pauses all token transfers, minting, and burning.
     * @dev Callable only by an account with PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Callable only by an account with PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Overrides the ERC20 hook to block transfers when paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        require(!paused(), "Token transfer while paused");
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IExperiPie is IERC20 {
    // function initialize(address[] memory _tokens, uint256 _maxCap) external;
    function joinPool(uint256 _amount) external;

    function exitPool(uint256 _amount) external;

    function getLock() external view returns (bool);

    function getLockBlock() external view returns (uint256);

    function setLock(uint256 _lock) external;

    function getMaxCap() external view returns (uint256);

    function setMaxCap(uint256 _maxCap) external returns (uint256);

    function balance(address _token) external view returns (uint256);

    function getTokens() external view returns (address[] memory);

    function addToken(address _token) external;

    function removeToken(address _token) external;

    function getTokenInPool(address _token) external view returns (bool);

    function mint(address _receiver, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;

    // CallFacet
    function call(
        address[] memory _targets,
        bytes[] memory _calldata,
        uint256[] memory _values
    ) external;

    // Ownership

    function transferOwnership(address _newOwner) external;
    function owner() external view returns(address);

    // ERC20
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    // ERC20 facet
    function initialize(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;
}
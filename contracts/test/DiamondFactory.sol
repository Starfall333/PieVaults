// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../diamond-3/contracts/Diamond.sol";

contract DiamondFactory {
    event DiamondCreated(address tokenAddress);

    function deployNewDiamond(address _owner, IDiamondCut.FacetCut[] memory diamondCut)
    public returns (address) {
        Diamond d = new Diamond(_owner, diamondCut);
        emit DiamondCreated(address(d));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ERC20/LibERC20Storage.sol";
import "../ERC20/LibERC20.sol";
import "./LibBasketStorage.sol";
import "../shared/Reentry/ReentryProtection.sol";
import "../shared/Access/CallProtection.sol";

contract BasketFacet is ReentryProtection, CallProtection {
    using SafeMath for uint256;

    uint256 constant MIN_AMOUNT = 10**6;

    // // Before calling the first joinPool, the pools needs to be initialized with token balances
    // function initialize(address[] memory _tokens, uint256 _maxCap) external noReentry protectedCall {
    //     LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
    //     LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

    //     require(es.totalSupply >= MIN_AMOUNT, "POOL_TOKEN_BALANCE_TOO_LOW");
    //     require(es.totalSupply <= _maxCap, "MAX_POOL_CAP_REACHED");

    //     for (uint256 i = 0; i < bs.tokens.length; i ++){
    //         bs.inPool[address(bs.tokens[i])] = false;
    //     }
    //     delete bs.tokens;

    //     for (uint256 i = 0; i < _tokens.length; i ++) {
    //         bs.tokens.push(IERC20(_tokens[i]));
    //         bs.inPool[_tokens[i]] = true;
    //         // requires some initial supply, could be less than 1 gwei, but yea.
    //         require(balance(_tokens[i]) >= MIN_AMOUNT, "TOKEN_BALANCE_TOO_LOW");
    //     }

    //     // unlock the contract
    //     this.setMaxCap(_maxCap);
    //     this.setLock(block.number.sub(1));
    // }

    function addToken(address _token) external protectedCall {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        require(!bs.inPool[_token], "TOKEN_ALREADY_IN_POOL");
        // Enforce minimum to avoid rounding errors; (Minimum value is the same as in Balancer)
        require(balance(_token) >= 10**6, "BALANCE_TOO_SMALL");

        bs.inPool[_token] = true;
        bs.tokens.push(IERC20(_token));
    }

    function removeToken(address _token) external protectedCall {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();

        require(bs.inPool[_token], "TOKEN_NOT_IN_POOL");

        bs.inPool[_token] = false;

        // remove token from array
        // TODO consider limiting max amount of tokens to mitigate running out of gas.
        for(uint256 i; i < bs.tokens.length; i ++) {
            if(address(bs.tokens[i]) == _token) {
                bs.tokens[i] = bs.tokens[bs.tokens.length - 1];
                bs.tokens.pop();

                break;
            }
        }
    }

    function joinPool(uint256 _amount) external noReentry {
        require(!this.getLock(), "POOL_LOCKED");
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;
        require(totalSupply.add(_amount) < this.getMaxCap(), "MAX_POOL_CAP_REACHED");

        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenAmount = balance(address(token)).mul(_amount).div(totalSupply);
            require(token.transferFrom(msg.sender, address(this), tokenAmount), "Transfer Failed");
        }

        LibERC20.mint(msg.sender, _amount);
    }


    // Must be overwritten to withdraw from strategies
    function exitPool(uint256 _amount) external virtual noReentry {
        require(!this.getLock(), "POOL_LOCKED");
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;

        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 balance = balance(address(token));
            uint256 tokenAmount = balance.mul(_amount).div(totalSupply);
            require(balance.sub(tokenAmount) >= MIN_AMOUNT, "TOKEN_BALANCE_TOO_LOW");
            require(token.transfer(msg.sender, tokenAmount), "Transfer Failed");
        }

        require(totalSupply.sub(_amount) >= MIN_AMOUNT, "POOL_TOKEN_BALANCE_TOO_LOW");
        LibERC20.burn(msg.sender, _amount);
    }

    // returns true when locked
    function getLock() external view returns(bool){
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        return bs.lockBlock == 0 || bs.lockBlock >= block.number;
    }

    function getLockBlock() external view returns(uint256) {
        return LibBasketStorage.basketStorage().lockBlock;
    }

    // lock up to and including _lock blocknumber
    function setLock(uint256 _lock) external protectedCall {
        LibBasketStorage.basketStorage().lockBlock = _lock;
    }

    function getMaxCap() external view returns(uint256){
        return LibBasketStorage.basketStorage().maxCap;
    }

    function setMaxCap(uint256 _maxCap) external protectedCall returns(uint256){
        LibBasketStorage.basketStorage().maxCap = _maxCap;
    }

    // Seperated balance function to allow yearn like strategies to be hooked up by inheriting from this contract and overriding
    function balance(address _token) public view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getTokens() external view returns (IERC20[] memory) {
        return(LibBasketStorage.basketStorage().tokens);
    }

}
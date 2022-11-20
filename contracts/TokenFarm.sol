// SPDX License Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    address[] public allowedTokens;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    address[] public stakers;
    mapping(address => uint256) public uniqueTokensStaked;
    IERC20 public dappToken;
    mapping(address => address) public tokenToPricefeedMapping;

    // Getting the total value of the user's balance//
    //Stake tokens//
    //Unstake tokens//
    //Allowed Tokens//
    //Get Token Values//
    //Issue tokens//

    constructor(_dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function unStakeTokens(address _token) public {
        uint256 balance = stakingBalance[token][msg.sender];
        require(balance > 0, "Nothing to unstake.");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked(msg.sender) = uniqueTokensStaked(msg.sender) - 1;
    }

    function issueTokens() public onlyOwner {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient, (userTotalValue / 50));
        }
    }

    function setPriceFeed(address _token, address _pricefeed) public onlyOwner {
        tokenToPricefeedMapping[_token] = _pricefeed;
    }

    function getUserTotalValue(address _recipient)
        public
        view
        returns (uint256)
    {
        uint256 TotalValue = 0;
        require(uniqueTokensStaked > 0, "There are no tokens staked");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            TotalValue =
                TotalValue +
                getUserSingleTokenValue(
                    _recipient,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return TotalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // price of the token * stakingBalance[_token][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return // 10000000000000000000 ETH
        // ETH/USD -> 10000000000
        // 10 * 100 = 1,000
        ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address PriceFeedaddress = tokenToPricefeedMapping[_token];
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            PriceFeedaddress
        );
        (, , int256 price, , ) = pricefeed.latestRoundData();
        uint256 decimals = uint256(pricefeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(tokenIsAllowed(_token), "Token is not allowed currently");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][_msg.sender] =
            stakingBalance[_token][_msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }
}

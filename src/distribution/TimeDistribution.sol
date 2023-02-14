// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@oc/access/Ownable.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/utils/math/SafeMath.sol";
import "@oc/utils/math/Math.sol";

/**
 * @notice Linear release of SEED
 */
contract TimeDistribution is Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    IERC20 public token;
    address public distributor;

    struct DistributionInfo {
        uint256 amount;
        uint256 claimedAmount;
        uint256 beginTs;
        uint256 endTs;
        uint256 duration;
    }

    mapping(address => DistributionInfo) public infos;

    constructor(IERC20 _token, address _distributor) {
        token = _token;
        distributor = _distributor;
    }

    function userTotalToken() public view returns (uint256) {
        return infos[msg.sender].amount;
    }

    function claimed() public view returns (uint256) {
        return infos[msg.sender].claimedAmount;
    }

    function setDistributor(address _distributor) public onlyOwner {
        distributor = _distributor;
    }

    function addInfo(address account, uint256 amount, uint256 beginTs, uint256 endTs) public onlyOwner {
        require(infos[account].amount == 0, "account is not a new user");
        require(amount != 0, "addInfo: amount should not 0");
        require(beginTs >= block.timestamp, "addInfo: begin too early");
        require(endTs >= block.timestamp, "addInfo: end too early");
        infos[account] = DistributionInfo(amount, 0, beginTs, endTs, endTs.sub(beginTs));
        emit AddInfo(account, amount, beginTs, endTs);
    }

    // careful gas
    function addMultiInfo(address[] memory accounts, uint256[] memory amounts, uint256[] memory beginTsArray, uint256[] memory endTsArray)
        public
        onlyOwner
    {
        require(accounts.length == amounts.length, "addMultiInfo:function params length not equal");
        require(accounts.length == beginTsArray.length, "addMultiInfo:function params length not equal");
        require(accounts.length == endTsArray.length, "addMultiInfo:function params length not equal");
        for (uint256 i = 0; i < accounts.length; i++) {
            addInfo(accounts[i], amounts[i], beginTsArray[i], endTsArray[i]);
        }
    }

    function pendingClaim() public view returns (uint256) {
        if (infos[msg.sender].amount == 0) {
            return 0;
        }
        DistributionInfo storage info = infos[msg.sender];
        uint256 nowtime = Math.min(block.timestamp, info.endTs);
        return (nowtime.sub(info.beginTs)).mul(info.amount).div(info.duration).sub(info.claimedAmount);
    }

    function claim() public {
        uint256 claimAmount = pendingClaim();
        DistributionInfo storage info = infos[msg.sender];
        info.claimedAmount = info.claimedAmount.add(claimAmount);
        token.transferFrom(distributor, msg.sender, claimAmount);
        emit ClaimToken(msg.sender, claimAmount);
    }

    function changeUserAdmin(address oldUser, address newUser) public onlyOwner {
        require(infos[newUser].amount == 0, "newUser is not a new user");
        infos[newUser] = infos[oldUser];
        delete infos[oldUser];
        emit UserChanged(oldUser, newUser);
    }

    event AddInfo(address account, uint256 amount, uint256 beginTs, uint256 endTs);
    event ClaimToken(address account, uint256 amount);
    event UserChanged(address oldUser, address newUser);
}

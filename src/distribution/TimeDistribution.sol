// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
        uint256 claimedAmount; // already claimed
        uint256 beginTs;
        uint256 endTs;
        uint256 duration;
        bool isReward;
        bool isLocked; // true if the account is 12 mouths' locked
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

    function addInfo(address account, uint256 amount, uint256 beginTs, uint256 endTs, bool isReward, bool isLocked) public onlyOwner {
        require(infos[account].amount == 0, "account is not a new user");
        require(amount != 0, "addInfo: amount should not 0");
        require(beginTs >= block.timestamp, "addInfo: begin too early");
        require(endTs >= block.timestamp, "addInfo: end too early");
        infos[account] = DistributionInfo(amount, 0, beginTs, endTs, endTs.sub(beginTs), isReward, isLocked);
        emit AddInfo(account, amount, beginTs, endTs);
    }

    // careful gas
    function addMultiInfo(
        address[] memory accounts,
        uint256[] memory amounts,
        uint256[] memory beginTsArray,
        uint256[] memory endTsArray,
        bool[] memory isRewardArray,
        bool[] memory isLockedArray
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            addInfo(accounts[i], amounts[i], beginTsArray[i], endTsArray[i], isRewardArray[i], isLockedArray[i]);
        }
    }

    function pendingClaim() public view returns (uint256) {
        if (infos[msg.sender].amount == 0) {
            return 0;
        }
        DistributionInfo storage info = infos[msg.sender];
        uint256 nowtime = Math.min(block.timestamp, info.endTs);
        if (info.isReward) {
            uint256 coreReward = uint256(3).mul(info.amount).div(10); // 30% amount for core reward
            if (info.claimedAmount == 0) {
                return coreReward;
            }
            return (nowtime.sub(info.beginTs)).mul(info.amount - coreReward).div(info.duration).add(coreReward).sub(info.claimedAmount);
        }
        return (nowtime.sub(info.beginTs)).mul(info.amount).div(info.duration).sub(info.claimedAmount);
    }

    function claim() public {
        DistributionInfo storage info = infos[msg.sender];
        if (!info.isLocked) {
            _claim(info);
        } else {
            if (info.isReward && info.claimedAmount == 0) {
                _claim(info);
            } else {
                require(unlockTime(info.beginTs) < block.timestamp, "not allow to claim");
                _claim(info);
            }
        }
    }

    function _claim(DistributionInfo storage info) internal {
        uint256 claimAmount = pendingClaim();
        info.claimedAmount = info.claimedAmount.add(claimAmount);
        require(info.claimedAmount <= info.amount, "overflow claim");
        token.transferFrom(distributor, msg.sender, claimAmount);
        emit ClaimToken(msg.sender, claimAmount);
    }

    function unlockTime(uint256 beginTs) public pure returns (uint256) {
        return beginTs + 365 days;
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

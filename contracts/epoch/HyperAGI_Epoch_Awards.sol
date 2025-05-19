/**
 * @title Hyperdust_Render_Awards
 * @dev This contract is responsible for distributing rewards to active nodes in the Hyperdust Protocol.
 * It uses a random selection process to choose a node and distributes an epoch award to it.
 * The epoch award is calculated based on the total supply of the protocol and the number of active nodes.
 * A portion of the epoch award is kept as security deposit and the rest is released as base reward to the node.
 * The contract also keeps track of the total award and residue total award available for distribution.
 * Only the admin role can trigger the rewards distribution.
 */
pragma solidity ^0.8.7;

import {DateTime} from "@quant-finance/solidity-datetime/contracts/DateTime.sol";
import {StrUtil} from "../utils/StrUtil.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./../HyperAGI_Roles_Cfg.sol";
import "./HyperAGI_BaseReward_Release.sol";
import "./HyperAGI_Security_Deposit.sol";
import "./../finance/HyperAGI_GPUMining.sol";
import "./../node/HyperAGI_Node_Mgr.sol";

import "./../HyperAGI_Wallet_Account.sol";

import "hardhat/console.sol";

contract HyperAGI_Epoch_Awards is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _rolesCfgAddress;

    address public _nodeMgrAddress;

    address public _securityDepositAddress;

    address public _baseRewardReleaseAddress;

    address public _GPUMiningAddress;

    address public _walletAccountAddress;

    uint256 private _rand;

    receive() external payable {}

    event eveRewards(uint256 nodeId, uint256 epochAward, uint256 rand, uint256 nonce, uint256 gasFee);

    event eveDifficulty(uint256 totalNum, uint256 activeNum, uint256 securityDeposit, uint256 baseRewardReleaseAward);

    event eveActiveNodes(uint256[] nodeIds);

    function initialize(address onlyOwner) public initializer {
        _rand = 1;
        __Ownable_init(onlyOwner);
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setNodeMgrAddress(address nodeMgrAddress) public onlyOwner {
        _nodeMgrAddress = nodeMgrAddress;
    }

    function setSecurityDepositAddress(address securityDepositAddress) public onlyOwner {
        _securityDepositAddress = securityDepositAddress;
    }

    function setBaseRewardReleaseAddress(address baseRewardReleaseAddress) public onlyOwner {
        _baseRewardReleaseAddress = baseRewardReleaseAddress;
    }

    function setGPUMiningAddress(address GPUMiningAddress) public onlyOwner {
        _GPUMiningAddress = GPUMiningAddress;
    }

    function setWalletAccountAddress(address walletAccountAddress) public onlyOwner {
        _walletAccountAddress = walletAccountAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _nodeMgrAddress = contractaddressArray[1];
        _securityDepositAddress = contractaddressArray[2];
        _baseRewardReleaseAddress = contractaddressArray[3];
        _GPUMiningAddress = contractaddressArray[4];
        _walletAccountAddress = contractaddressArray[5];
    }

    function rewards(bytes32[] memory nodeStatus, uint256 nonce, uint256 gasFee) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        (uint256[] memory activeNodes, , uint256 _totalNum, uint256 _activeNum) = countActiveNode(nodeStatus);

        HyperAGI_Node_Mgr nodeMgrAddress = HyperAGI_Node_Mgr(_nodeMgrAddress);
        HyperAGI_GPUMining GPUMiningAddress = HyperAGI_GPUMining(payable(_GPUMiningAddress));
        HyperAGI_Security_Deposit securityDepositAddress = HyperAGI_Security_Deposit(payable(_securityDepositAddress));
        HyperAGI_BaseReward_Release baseRewardReleaseAddress = HyperAGI_BaseReward_Release(payable(_baseRewardReleaseAddress));
        HyperAGI_Wallet_Account walletAccountAddress = HyperAGI_Wallet_Account(_walletAccountAddress);

        address _GasFeeCollectionWallet = walletAccountAddress._GasFeeCollectionWallet();

        uint256 epochAward = GPUMiningAddress.getEpochAward();

        if (_totalNum < 10) {
            _totalNum = 20;
        }

        if (epochAward == 0) {
            return;
        }

        uint256 nodeId = 1;
        uint256 index;

        if (_activeNum == 0) {
            return;
        }

        index = _getRandom(0, _activeNum);
        nodeId = activeNodes[index];

        if (nodeId == 0) {
            revert(string(abi.encodePacked("Error: nodeId is 0 at index ", index.toString())));
        }

        uint32 accuracy = 1000000;

        uint256 difficulty = (_totalNum * accuracy) / _activeNum;

        uint256 actualEpochAward = (epochAward * accuracy) / difficulty;

        require(epochAward >= actualEpochAward, string(abi.encodePacked("epochAward (", epochAward.toString(), ") is not enough for mintNum (", actualEpochAward.toString(), "), totalNum: ", _totalNum.toString(), ", activeNum: ", _activeNum.toString())));

        uint256 securityDeposit = actualEpochAward / 10;
        uint256 baseRewardReleaseAward = actualEpochAward - securityDeposit - gasFee;

        GPUMiningAddress.mint(payable(address(this)), actualEpochAward);

        securityDepositAddress.addSecurityDeposit{value: securityDeposit}(nodeId, securityDeposit);

        (, address incomeAddress, , ) = nodeMgrAddress.getNode(nodeId);

        emit eveDifficulty(_totalNum, _activeNum, securityDeposit, baseRewardReleaseAward);

        emit eveActiveNodes(activeNodes);

        baseRewardReleaseAddress.addBaseRewardReleaseRecord{value: baseRewardReleaseAward}(baseRewardReleaseAward, incomeAddress);

        transferETH(payable(_GasFeeCollectionWallet), gasFee);

        walletAccountAddress.addAmount(gasFee);

        emit eveRewards(nodeId, actualEpochAward, index, nonce, gasFee);
    }

    function countActiveNode(bytes32[] memory nodeStatus) private returns (uint256[] memory, uint256[] memory, uint256, uint256) {
        HyperAGI_Node_Mgr nodeMgrAddress = HyperAGI_Node_Mgr(_nodeMgrAddress);

        uint256 activeNum = 0;
        uint256 totalNum = 0;

        uint256[] memory ids = nodeMgrAddress.getAllNodeList();
        uint256 totalSize = ids.length;

        uint256[] memory activeNodes = new uint256[](totalSize);
        uint256[] memory onlineNodes = new uint256[](totalSize);

        uint256 index = 0;
        uint256 activeIndex = 0;

        for (uint i = 0; i < nodeStatus.length; i++) {
            for (uint j = 0; j < 32; j++) {
                if (index > totalSize) {
                    break;
                }

                bytes1 status = bytes1(nodeStatus[i][j]);

                if (status != 0x00) {
                    uint256 nodeId = ids[index];

                    onlineNodes[totalNum] = nodeId;
                    totalNum++;

                    if (status == 0x11) {
                        activeNum++;
                        activeNodes[activeIndex] = nodeId;
                        activeIndex++;
                    }
                }
                index++;
            }
        }

        nodeMgrAddress.setStatisticalIndex(totalNum, activeNum == 0 ? 1 : activeNum);

        return (activeNodes, onlineNodes, totalNum, activeNum);
    }

    function _getRandom(uint256 _start, uint256 _end) private returns (uint256) {
        if (_start == _end) {
            return _start;
        }
        uint256 _length = _end - _start;
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _rand)));
        random = (random % _length) + _start;
        _rand++;
        return random;
    }

    function transferETH(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        recipient.transfer(amount);
    }
}

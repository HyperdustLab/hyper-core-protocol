import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../utils/StrUtil.sol";

contract HyperAGI_AgentMining is OwnableUpgradeable, AccessControlUpgradeable {
    using Strings for *;
    using StrUtil for *;

    using Math for uint256;
    uint256 public _AgentMiningTotalAward;

    uint256 private _AgentMiningCurrMiningRatio;

    uint256 constant FACTOR = 10 ** 18 * 100;

    uint256 private _AgentMiningCurrYearTotalSupply;

    uint256 public _epochAward;

    uint256 private _AgentMiningCurrYearTotalAward;

    uint256 private _AgentMiningReleaseInterval;

    uint256 private _AgentMiningRateInterval;

    uint256 private _AgentMiningAllowReleaseTime;

    uint256 private _lastAgentMiningRateTime;

    uint256 public _lastAgentMiningMintTime;

    uint256 public _AgentMiningCurrAward;

    uint256 public _TGE_timestamp;

    receive() external payable {}

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize(address onlyOwner, uint256 AgentMiningReleaseInterval) public initializer {
        __Ownable_init(onlyOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, onlyOwner);

        _AgentMiningTotalAward = (210000000 ether * 40) / 100;
        _AgentMiningCurrMiningRatio = 10 * 10 ** 18;
        _AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward, _AgentMiningCurrMiningRatio, FACTOR);

        _epochAward = _AgentMiningCurrYearTotalSupply / 365 / 225;

        _AgentMiningReleaseInterval = AgentMiningReleaseInterval;
        _AgentMiningRateInterval = 4 * AgentMiningReleaseInterval;
    }

    function getAgentMiningCurrAllowMintTotalNum() public view returns (uint256, uint256, uint256) {
        require(_AgentMiningAllowReleaseTime > 0, "The commencement of the release of Agent mining has not yet commenced");

        uint256 AgentMiningCurrMiningRatio = _AgentMiningCurrMiningRatio;
        uint256 AgentMiningCurrYearTotalAward = _AgentMiningCurrYearTotalAward;

        uint256 AgentMiningCurrYearTotalSupply = _AgentMiningCurrYearTotalSupply;

        uint256 epochAward = _epochAward;

        if (block.timestamp >= _lastAgentMiningRateTime + _AgentMiningRateInterval) {
            AgentMiningCurrMiningRatio = Math.mulDiv(AgentMiningCurrMiningRatio, FACTOR, 2 * FACTOR);

            require(AgentMiningCurrMiningRatio > 0, "currMiningRatio is 0");
        }

        if (block.timestamp >= _AgentMiningAllowReleaseTime + _AgentMiningReleaseInterval) {
            AgentMiningCurrYearTotalAward = 0;

            AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward - _AgentMiningCurrAward, AgentMiningCurrMiningRatio, FACTOR);

            epochAward = AgentMiningCurrYearTotalSupply / 365 / 225;
        }

        if (block.timestamp >= _AgentMiningAllowReleaseTime) {
            if (block.timestamp - _lastAgentMiningMintTime >= 384) {
                return (AgentMiningCurrYearTotalSupply - AgentMiningCurrYearTotalAward, AgentMiningCurrYearTotalSupply, epochAward);
            } else {
                return (0, AgentMiningCurrYearTotalSupply, epochAward);
            }
        } else {
            return (0, 0, epochAward);
        }
    }

    function mint(address payable account, uint256 mintNum) public onlyRole(MINTER_ROLE) {
        require(_TGE_timestamp > 0, "TGE_timestamp is not started");

        if (block.timestamp >= _lastAgentMiningRateTime + _AgentMiningRateInterval) {
            _AgentMiningCurrMiningRatio = _AgentMiningCurrMiningRatio / 2;
            require(_AgentMiningCurrMiningRatio > 0, "currMiningRatio is 0");

            _lastAgentMiningRateTime += _AgentMiningRateInterval;
        }

        if (block.timestamp >= _AgentMiningAllowReleaseTime + _AgentMiningReleaseInterval) {
            _AgentMiningCurrYearTotalAward = 0;

            _AgentMiningAllowReleaseTime += _AgentMiningReleaseInterval;

            _AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward - _AgentMiningCurrAward, _AgentMiningCurrMiningRatio, FACTOR);

            _epochAward = _AgentMiningCurrYearTotalSupply / 365 / 225;
        }
        require(_AgentMiningCurrYearTotalSupply - _AgentMiningCurrYearTotalAward - mintNum >= 0, "currYearTotalSupply is not enough");

        require(_AgentMiningTotalAward - _AgentMiningCurrAward - mintNum >= 0, "AgentMiningTotalAward is not enough");

        require(_epochAward >= mintNum, string(abi.encodePacked("epochAward (", _epochAward.toString(), ") is not enough for mintNum (", mintNum.toString(), ")")));

        _AgentMiningCurrYearTotalAward += mintNum;
        _AgentMiningCurrAward += mintNum;

        _lastAgentMiningMintTime = block.timestamp;

        transferETH(account, mintNum);
    }

    function startTGE(uint256 TGE_timestamp) public onlyOwner {
        require(_TGE_timestamp == 0, "TGE_timestamp is started");

        _TGE_timestamp = TGE_timestamp;

        _AgentMiningAllowReleaseTime = TGE_timestamp;
        _lastAgentMiningMintTime = TGE_timestamp;
    }

    function transferETH(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        recipient.transfer(amount);
    }

    function recalculateAgentMiningTotalAward() public onlyOwner {
        _AgentMiningTotalAward = (210000000 ether * 20) / 100;
        _AgentMiningCurrMiningRatio = 10 * 10 ** 18;
        _AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward, _AgentMiningCurrMiningRatio, FACTOR);

        _epochAward = _AgentMiningCurrYearTotalSupply / 365 / 225;

        _AgentMiningRateInterval = 4 * _AgentMiningReleaseInterval;
    }
}

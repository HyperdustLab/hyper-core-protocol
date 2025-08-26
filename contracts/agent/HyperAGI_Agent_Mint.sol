// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../utils/StrUtil.sol";
import "../HyperAGI_mNFT_Mint.sol";
import "./HyperAGI_Agent.sol" as Agent;

contract HyperAGI_Agent_Mint is OwnableUpgradeable {
    using Strings for string;
    using StrUtil for string;

    address public _mNFTMintAddress;
    address public _agentAddress;
    address public _tokenAddress;

    event eveAgentCreated(uint256 tokenId, bytes32 sid);

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
    }

    function setMintAddress(address mNFTMintAddress) public onlyOwner {
        _mNFTMintAddress = mNFTMintAddress;
    }

    function setAgentAddress(address agentAddress) public onlyOwner {
        _agentAddress = agentAddress;
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        _tokenAddress = tokenAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _mNFTMintAddress = contractaddressArray[0];
        _agentAddress = contractaddressArray[1];
        _tokenAddress = contractaddressArray[2];
    }

    // Add receive function to accept ETH
    receive() external payable {}

    function mintAndCreateAgent(uint256 id, string[] memory agentParams) public payable {
        // Check if tokenAddress is set
        require(_tokenAddress != address(0), "Token address not set");

        // Get mint info
        (, , uint256 price, address contractAddress, uint256 tokenId, bytes1 contractType, , uint256 allowNum, uint256 allowBuyNum) = HyperAGI_mNFT_Mint(_mNFTMintAddress).getMintInfo(id);

        // Ensure the contract address matches the token address
        require(contractAddress == _tokenAddress, "Contract address must match token address");

        uint256 payAmount = price * 1;

        // Verify exact ETH amount
        require(msg.value == payAmount, "ETH amount must match exactly");

        // Call mint function from mNFTMint contract with the ETH value
        uint256[] memory tokenIds = HyperAGI_mNFT_Mint(_mNFTMintAddress).mintWithReturnTokenIdV2{value: payAmount}(id, 1, msg.sender);

        // Create agent with the minted token
        Agent.HyperAGI_Agent(_agentAddress).mintV3(tokenIds[0], agentParams);

        emit eveAgentCreated(tokenIds[0], keccak256(abi.encodePacked(block.timestamp, block.difficulty, id)));
    }

    function transferETH(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        recipient.transfer(amount);
    }
}

/**
 * @title MOSSAI_mNFT_Mint
 * @dev Contract for minting mNFTs with HYDT tokens.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./utils/StrUtil.sol";
import "./HyperAGI_Roles_Cfg.sol";
import "./HyperAGI_Storage.sol";
import "./HyperAGI_Wallet_Account.sol";
import "./HyperAGI_Transaction_Cfg.sol";

abstract contract ERC721 {
    function safeMint(address to, string memory uri) public returns (uint256) {}
}

abstract contract ERC1155 {
    function mint(address to, uint256 id, uint256 amount, string memory tokenURI, bytes calldata data) public virtual {}
}

contract HyperAGI_mNFT_Mint is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _storageAddress;
    address public _rolesCfgAddress;
    address public _walletAccountAddress;
    address public _transactionCfgAddress;

    event eveSave(uint256 id);

    event eveMint(uint256 id, address account, uint256 mintNum, uint256 price, uint256 amount, uint256 gasFee);

    event eveDelete(uint256 id);

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setWalletAccountAddress(address walletAccountAddress) public onlyOwner {
        _walletAccountAddress = walletAccountAddress;
    }

    function setTransactionCfgAddress(address transactionCfgAddress) public onlyOwner {
        _transactionCfgAddress = transactionCfgAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _walletAccountAddress = contractaddressArray[1];
        _storageAddress = contractaddressArray[2];
        _transactionCfgAddress = contractaddressArray[3];
    }

    function addMintInfo(string memory tokenURI, uint256 price, address contractAddress, uint256 tokenId, bytes1 contractType, uint256 allowNum, uint256 allowBuyNum) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getNextId();

        storageAddress.setString(storageAddress.genKey("tokenURI", id), tokenURI);
        storageAddress.setUint(storageAddress.genKey("price", id), price);
        storageAddress.setAddress(storageAddress.genKey("contractAddress", id), contractAddress);

        storageAddress.setUint(storageAddress.genKey("tokenId", id), tokenId);
        storageAddress.setBytes1(storageAddress.genKey("contractType", id), contractType);

        storageAddress.setUint(storageAddress.genKey("allowNum", id), allowNum);
        storageAddress.setUint(storageAddress.genKey("allowBuyNum", id), allowBuyNum);

        storageAddress.setUint(storageAddress.genKey("del", id), 0);

        emit eveSave(id);
    }

    function deleteMintInfo(uint256 id) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        uint256 del = storageAddress.getUint(storageAddress.genKey("del", id));
        require(del == 0, "not found");
        storageAddress.setUint(storageAddress.genKey("del", id), 1);
        emit eveDelete(id);
    }

    function mint(uint256 id, uint256 num) public payable {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        HyperAGI_Wallet_Account walletAccountAddress = HyperAGI_Wallet_Account(_walletAccountAddress);
        address _GasFeeCollectionWallet = walletAccountAddress._GasFeeCollectionWallet();
        require(_GasFeeCollectionWallet != address(0), "not set GasFeeCollectionWallet");
        uint256 del = storageAddress.getUint(storageAddress.genKey("del", id));
        require(del == 0, "not found");
        uint256 price = storageAddress.getUint(storageAddress.genKey("price", id));
        uint256 gasFee = HyperAGI_Transaction_Cfg(_transactionCfgAddress).getGasFee("mint_mNFT");
        uint256 allowNum = storageAddress.getUint(storageAddress.genKey("allowNum", id));
        uint256 payAmount = price * num + gasFee;
        require(msg.value == payAmount, "Wrong payment amount");
        uint256 mintNum = storageAddress.getUint(storageAddress.genKey("mintNum", id));
        require(allowNum >= mintNum + num, "Insufficient inventory");
        uint256 allowBuyNum = storageAddress.getUint(storageAddress.genKey("allowBuyNum", id));
        if (allowBuyNum > 0) {
            string memory buyNumKey = string(abi.encode(id.toString(), msg.sender.toHexString()));
            uint256 buyNum = storageAddress.getUint(buyNumKey);
            require(buyNum + num <= allowBuyNum, "exceeds the purchase limit");
            storageAddress.setUint(buyNumKey, buyNum + num);
        }
        transferETH(payable(_GasFeeCollectionWallet), payAmount);
        walletAccountAddress.addAmount(payAmount);
        bytes1 contractType = storageAddress.getBytes1(storageAddress.genKey("contractType", id));
        address contractAddress = storageAddress.getAddress(storageAddress.genKey("contractAddress", id));
        uint256 tokenId = storageAddress.getUint(storageAddress.genKey("tokenId", id));
        string memory tokenURI = storageAddress.getString(storageAddress.genKey("tokenURI", id));
        if (contractType == 0x11) {
            for (uint i = 0; i < num; i++) {
                uint256 newTokenId = ERC721(contractAddress).safeMint(msg.sender, tokenURI);
                require(newTokenId > 0, "Failed to mint NFT");
            }
        } else if (contractType == 0x22) {
            ERC1155(contractAddress).mint(msg.sender, tokenId, num, tokenURI, "");
        } else {
            revert("invalid contract type");
        }
        storageAddress.setUint(storageAddress.genKey("mintNum", id), mintNum + num);
        emit eveSave(id);
        emit eveMint(id, msg.sender, num, price, payAmount, gasFee);
    }

    function mintWithReturnTokenId(uint256 id, uint256 num) public payable returns (uint256[] memory) {}

    function mintWithReturnTokenIdV2(uint256 id, uint256 num, address to) public payable returns (uint256[] memory) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        HyperAGI_Wallet_Account walletAccountAddress = HyperAGI_Wallet_Account(_walletAccountAddress);
        address _GasFeeCollectionWallet = walletAccountAddress._GasFeeCollectionWallet();
        require(_GasFeeCollectionWallet != address(0), "not set GasFeeCollectionWallet");
        uint256 del = storageAddress.getUint(storageAddress.genKey("del", id));
        require(del == 0, "not found");
        uint256 price = storageAddress.getUint(storageAddress.genKey("price", id));
        uint256 gasFee = HyperAGI_Transaction_Cfg(_transactionCfgAddress).getGasFee("mint_mNFT");
        uint256 allowNum = storageAddress.getUint(storageAddress.genKey("allowNum", id));
        uint256 payAmount = price * num + gasFee;
        require(msg.value == payAmount, "Wrong payment amount");
        uint256 mintNum = storageAddress.getUint(storageAddress.genKey("mintNum", id));
        require(allowNum >= mintNum + num, "Insufficient inventory");
        uint256 allowBuyNum = storageAddress.getUint(storageAddress.genKey("allowBuyNum", id));
        if (allowBuyNum > 0) {
            string memory buyNumKey = string(abi.encode(id.toString(), msg.sender.toHexString()));
            uint256 buyNum = storageAddress.getUint(buyNumKey);
            require(buyNum + num <= allowBuyNum, "exceeds the purchase limit");
            storageAddress.setUint(buyNumKey, buyNum + num);
        }

        transferETH(payable(_GasFeeCollectionWallet), payAmount);
        walletAccountAddress.addAmount(payAmount);
        bytes1 contractType = storageAddress.getBytes1(storageAddress.genKey("contractType", id));
        address contractAddress = storageAddress.getAddress(storageAddress.genKey("contractAddress", id));
        uint256 tokenId = storageAddress.getUint(storageAddress.genKey("tokenId", id));
        string memory tokenURI = storageAddress.getString(storageAddress.genKey("tokenURI", id));

        uint256[] memory mintedTokenIds = new uint256[](num);

        if (contractType == 0x11) {
            for (uint i = 0; i < num; i++) {
                uint256 newTokenId = ERC721(contractAddress).safeMint(to, tokenURI);

                require(newTokenId > 0, "Failed to mint NFT");

                mintedTokenIds[i] = newTokenId;
            }
        } else if (contractType == 0x22) {
            ERC1155(contractAddress).mint(to, tokenId, num, tokenURI, "");

            for (uint i = 0; i < num; i++) {
                mintedTokenIds[i] = tokenId;
            }
        } else {
            revert("invalid contract type");
        }

        storageAddress.setUint(storageAddress.genKey("mintNum", id), mintNum + num);
        emit eveSave(id);
        emit eveMint(id, to, num, price, payAmount, gasFee);

        return mintedTokenIds;
    }

    function updateNFT(uint256 id, string memory tokenURI, uint256 price, address contractAddress, uint256 tokenId, bytes1 contractType, uint256 allowNum, uint256 allowBuyNum) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 del = storageAddress.getUint(storageAddress.genKey("del", id));

        require(del == 0, "not found");

        storageAddress.setString(storageAddress.genKey("tokenURI", id), tokenURI);
        storageAddress.setUint(storageAddress.genKey("price", id), price);
        storageAddress.setAddress(storageAddress.genKey("contractAddress", id), contractAddress);

        storageAddress.setUint(storageAddress.genKey("tokenId", id), tokenId);
        storageAddress.setBytes1(storageAddress.genKey("contractType", id), contractType);

        storageAddress.setUint(storageAddress.genKey("allowNum", id), allowNum);

        storageAddress.setUint(storageAddress.genKey("allowBuyNum", id), allowNum);

        emit eveSave(id);
    }

    function getMintInfo(uint256 id) public view returns (uint256, string memory, uint256, address, uint256, bytes1, uint256, uint256, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 del = storageAddress.getUint(storageAddress.genKey("del", id));

        require(del == 0, "not found");
        return (
            id,
            storageAddress.getString(storageAddress.genKey("tokenURI", id)),
            storageAddress.getUint(storageAddress.genKey("price", id)),
            storageAddress.getAddress(storageAddress.genKey("contractAddress", id)),
            storageAddress.getUint(storageAddress.genKey("tokenId", id)),
            storageAddress.getBytes1(storageAddress.genKey("contractType", id)),
            storageAddress.getUint(storageAddress.genKey("mintNum", id)),
            storageAddress.getUint(storageAddress.genKey("allowNum", id)),
            storageAddress.getUint(storageAddress.genKey("allowBuyNum", id))
        );
    }

    function transferETH(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        recipient.transfer(amount);
    }
}

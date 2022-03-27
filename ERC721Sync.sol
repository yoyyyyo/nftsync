pragma solidity >=0.8.13;
// SPDX-License-Identifier: CC0-1.0

interface LightIERC721 {
    function balanceOf(address) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
}

abstract contract ERC721Sync {
    string public name;
    string public symbol;
    LightIERC721 public originalToken;

    mapping (uint => address) _ownerCache;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    constructor(string memory _name, string memory _symbol, address _originalToken) {
        name = _name;
        symbol = _symbol;
        originalToken = LightIERC721(_originalToken);
    }

    function tokenURI(uint256 id) external view virtual returns (string memory);

    //// proxy functions ////
    function balanceOf(address _holder) external view returns (uint256) {
        return originalToken.balanceOf(_holder);
    }

    function ownerOf(uint256 _id) external view returns (address) {
        return originalToken.ownerOf(_id);
    }

    //// noops ////
    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    function approve(address, uint256) external pure { revert("ERC721Sync: not available"); }
    function setApprovalForAll(address, bool) external pure { revert("ERC721Sync: not available"); }

    //// sync function & friends ////
    function _sync(uint256 _tokenId) virtual internal {
        address cachedOwner = _ownerCache[_tokenId];
        address currentOwner = originalToken.ownerOf(_tokenId);
        require(cachedOwner != currentOwner, "ERC721Sync: no update");
        
        _beforeSync(cachedOwner, currentOwner, _tokenId);

        _ownerCache[_tokenId] = currentOwner;
        emit Transfer(cachedOwner, currentOwner, _tokenId);

        _afterSync(cachedOwner, currentOwner, _tokenId);
    }

    function transferFrom(address, address, uint256 _id) external {
        _sync(_id);
    }

    function safeTransferFrom(address, address, uint256 _id) external {
        _sync(_id);
    }

    function safeTransferFrom(address, address, uint256 _id, bytes calldata) external {
        _sync(_id);
    }
    
    function sync(uint _id) external {
        _sync(_id);
    }

    function batchSync(uint256[] memory _tokenIds) external {
        address cachedOwner;
        address currentOwner;

        for (uint i = 0; i < _tokenIds.length; i++) {
            cachedOwner = _ownerCache[_tokenIds[i]];
            currentOwner = originalToken.ownerOf(_tokenIds[i]);
            if (cachedOwner != currentOwner) {
                _beforeSync(cachedOwner, currentOwner, _tokenIds[i]);

                _ownerCache[_tokenIds[i]] = currentOwner;
                emit Transfer(cachedOwner, currentOwner, _tokenIds[i]);

                _afterSync(cachedOwner, currentOwner, _tokenIds[i]);
            }
        }
    }

    //// boring stuff ////
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01ffc9a7 || // ERC165
               _interfaceId == 0x80ac58cd || // ERC721
               _interfaceId == 0x5b5e139f;   // ERC721Metadata
    }

    //// hooks ////
    function _beforeSync(address from, address to, uint256 tokenId) internal virtual {}
    function _afterSync(address from, address to, uint256 tokenId) internal virtual {}
}
pragma solidity >=0.8.13;
import "../ERC721Sync.sol";

// SPDX-License-Identifier: CC0-1.0
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

interface ICryptopunksData {
    function punkImageSvg(uint16 index) external view returns (string memory svg);
}

/* an example usage of ERC721Sync, which creates a token
** that lets the current punk owner change the background
** color (could probably be expanded to background image too),
** utilizing the on-chain data uploaded by Larva Labs (look ma, no API server!) */
contract PunkBackground is ERC721Sync {
    address WRAPPED_PUNKS = 0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6;
    ICryptopunksData PUNK_DATA = ICryptopunksData(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);

    mapping (uint256 => uint24)  private _colors;
    mapping (uint256 => bool  )  private _hasColor;

    constructor() ERC721Sync("PUNK", "PUNK", WRAPPED_PUNKS) {}

    function setColor(uint _id, uint24 _color) external {
        require(this.ownerOf(_id) == msg.sender, "you do not own this punk");
        _colors[_id] = _color;
        _hasColor[_id] = true;
    }

    function _afterSync(address, address, uint256 tokenId) internal override {
        _colors[tokenId] = 0;
        _hasColor[tokenId] = false;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function _toHexColor(uint _id) internal view returns (string memory) {
        bytes memory buffer = new bytes(7);
        uint24 color = _hasColor[_id] ? _colors[_id] : 0x638596;

        buffer[0] = "#";
        for (uint256 i = 6; i > 0; --i) {
            buffer[i] = _HEX_SYMBOLS[color & 0xf];
            color >>= 4;
        }

        return string(buffer);
    }

    function _removeDataURL(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory trimmed = new bytes(strBytes.length - 104);
        for(uint i = 98; i < strBytes.length - 6; i++)
            trimmed[i - 98] = strBytes[i];
        return string(trimmed);
    }

    function _generateSVG(uint _id) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">',
                    '<rect xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" fill="',
                        _toHexColor(_colors[_id]),
                    '"/>',
                    _removeDataURL(PUNK_DATA.punkImageSvg(uint16(_id))),
                '</svg>'
            )
        );
    }

    function tokenURI(uint _id) external view override returns (string memory) {
        return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(string(abi.encodePacked(
                                '{"name": "CryptoPunk #',
                                Strings.toString(_id),
                                '", "image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(_generateSVG(_id))),
                                '"}'
                )
        )))));
    }
}

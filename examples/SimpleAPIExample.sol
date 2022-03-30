pragma solidity >=0.8.13;
import "@yoyyyyo/nftsync/ERC721Sync.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// SPDX-License-Identifier: CC0-1.0

contract SimpleAPIExample is ERC721Sync {
    address ERC721_TOKEN = 0x0000000000000000000000000000000000000000;
    constructor() ERC721Sync("Bored Token Speedboat Club", "BTSC", ERC721_TOKEN) {}

    function tokenURI(uint _id) external pure override returns (string memory) {
        return string(
            abi.encodePacked(
                "https://api.exampletokenuri.invalid/",
                Strings.toString(_id),
                ".json"
            )
        );
    }
}

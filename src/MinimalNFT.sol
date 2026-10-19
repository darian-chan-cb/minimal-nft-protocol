// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

/// @title MinimalNFT
/// @notice A compact ERC-721 collection with paid public minting and owner administration.
contract MinimalNFT {
    error NotOwner();
    error ZeroAddress();
    error InvalidRecipient();
    error InvalidPayment();
    error InvalidMaxSupply();
    error MaxSupplyReached();
    error TokenDoesNotExist();
    error NotAuthorized();
    error UnsafeRecipient();
    error WithdrawFailed();

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MintPriceUpdated(uint256 newPrice);
    event BaseURIUpdated(string newBaseURI);

    string public name;
    string public symbol;
    uint256 public immutable MAX_SUPPLY;
    uint256 public mintPrice;
    uint256 public totalSupply;
    address public owner;

    string private _baseTokenUri;
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 mintPrice_,
        string memory baseUri_
    ) {
        if (maxSupply_ == 0) revert InvalidMaxSupply();
        name = name_;
        symbol = symbol_;
        MAX_SUPPLY = maxSupply_;
        mintPrice = mintPrice_;
        _baseTokenUri = baseUri_;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == address(0)) revert ZeroAddress();
        return _balanceOf[account];
    }

    function ownerOf(uint256 tokenId) public view returns (address tokenOwner) {
        tokenOwner = _ownerOf[tokenId];
        if (tokenOwner == address(0)) revert TokenDoesNotExist();
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        ownerOf(tokenId);
        return string.concat(_baseTokenUri, _toString(tokenId));
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 // ERC-165
                || interfaceId == 0x80ac58cd // ERC-721
                || interfaceId == 0x5b5e139f; // ERC-721 Metadata
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        ownerOf(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address tokenOwner, address operator) external view returns (bool) {
        return _operatorApprovals[tokenOwner][operator];
    }

    function approve(address approved, uint256 tokenId) external {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && !_operatorApprovals[tokenOwner][msg.sender]) revert NotAuthorized();
        _tokenApprovals[tokenId] = approved;
        emit Approval(tokenOwner, approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == msg.sender) revert NotAuthorized();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (to == address(0)) revert InvalidRecipient();
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != from) revert NotAuthorized();
        if (!_isAuthorized(msg.sender, tokenOwner, tokenId)) revert NotAuthorized();

        delete _tokenApprovals[tokenId];
        unchecked {
            --_balanceOf[from];
            ++_balanceOf[to];
        }
        _ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        if (!_checkOnErc721Received(msg.sender, from, to, tokenId, data)) revert UnsafeRecipient();
    }

    /// @notice Mints the next token for exactly `mintPrice` wei.
    function mint(address to) external payable returns (uint256 tokenId) {
        if (msg.value != mintPrice) revert InvalidPayment();
        tokenId = _mint(to);
    }

    /// @notice Allows the collection owner to mint without paying the public mint price.
    function ownerMint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = _mint(to);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenUri = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function withdraw(address payable recipient) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        (bool success,) = recipient.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function _mint(address to) private returns (uint256 tokenId) {
        if (to == address(0)) revert InvalidRecipient();
        if (totalSupply == MAX_SUPPLY) revert MaxSupplyReached();

        unchecked {
            tokenId = ++totalSupply;
            ++_balanceOf[to];
        }
        _ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);

        if (!_checkOnErc721Received(msg.sender, address(0), to, tokenId, "")) revert UnsafeRecipient();
    }

    function _checkOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }

    function _isAuthorized(address spender, address tokenOwner, uint256 tokenId) private view returns (bool) {
        return spender == tokenOwner || _tokenApprovals[tokenId] == spender || _operatorApprovals[tokenOwner][spender];
    }

    function _checkOnErc721Received(address operator, address from, address to, uint256 tokenId, bytes memory data)
        private
        returns (bool)
    {
        if (to.code.length == 0) return true;
        try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 result) {
            return result == IERC721Receiver.onERC721Received.selector;
        } catch {
            return false;
        }
    }

    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";
        uint256 digits;
        uint256 remaining = value;
        while (remaining != 0) {
            ++digits;
            remaining /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked {
                buffer[--digits] = bytes1(uint8(48 + (value % 10)));
            }
            value /= 10;
        }
        return string(buffer);
    }
}

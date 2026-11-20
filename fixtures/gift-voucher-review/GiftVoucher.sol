// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Review-only example of signed gift payouts for a collection treasury.
/// @dev This fixture is not included in the root Foundry project's src or test paths.
contract GiftVoucher {
    address public immutable issuer;
    mapping(uint256 => bool) public redeemed;

    event GiftRedeemed(uint256 indexed nonce, address indexed recipient, uint256 amount);

    constructor(address issuer_) payable {
        require(issuer_ != address(0), "invalid issuer");
        issuer = issuer_;
    }

    receive() external payable {}

    /// @notice Redeem a signed gift for the supplied recipient.
    function redeemGift(uint256 nonce, uint256 amount, address payable recipient, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(recipient != address(0), "invalid recipient");
        require(!redeemed[nonce], "already redeemed");

        bytes32 voucherHash = keccak256(abi.encode(address(this), block.chainid, nonce, amount));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", voucherHash));
        require(ecrecover(messageHash, v, r, s) == issuer, "invalid voucher");

        redeemed[nonce] = true;
        (bool success,) = recipient.call{value: amount}("");
        require(success, "gift transfer failed");
        emit GiftRedeemed(nonce, recipient, amount);
    }
}

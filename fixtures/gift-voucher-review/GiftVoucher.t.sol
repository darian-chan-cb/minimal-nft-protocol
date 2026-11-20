// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GiftVoucher} from "./GiftVoucher.sol";

interface Vm {
    function addr(uint256 privateKey) external returns (address);
    function deal(address account, uint256 newBalance) external;
    function prank(address msgSender) external;
    function sign(uint256 privateKey, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);
}

contract GiftVoucherFixtureTest {
    Vm private constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint256 private constant ISSUER_KEY = 0xA11CE;
    uint256 private constant GIFT_AMOUNT = 0.25 ether;
    address private constant INTENDED_RECIPIENT = address(0xB0B);
    address private constant OTHER_CALLER = address(0xCAFE);

    GiftVoucher private gifts;

    function setUp() public {
        gifts = new GiftVoucher(VM.addr(ISSUER_KEY));
        VM.deal(address(gifts), 1 ether);
    }

    function _voucher(uint256 nonce) private returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 voucherHash = keccak256(abi.encode(address(gifts), block.chainid, nonce, GIFT_AMOUNT));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", voucherHash));
        return VM.sign(ISSUER_KEY, messageHash);
    }

    function testRecipientCanRedeemGift() public {
        (uint8 v, bytes32 r, bytes32 s) = _voucher(1);
        gifts.redeemGift(1, GIFT_AMOUNT, payable(INTENDED_RECIPIENT), v, r, s);
        require(INTENDED_RECIPIENT.balance == GIFT_AMOUNT, "gift not received");
    }

    function testVoucherCanBeRedirectedByAnotherCaller() public {
        (uint8 v, bytes32 r, bytes32 s) = _voucher(2);
        VM.prank(OTHER_CALLER);
        gifts.redeemGift(2, GIFT_AMOUNT, payable(OTHER_CALLER), v, r, s);
        require(OTHER_CALLER.balance == GIFT_AMOUNT, "redirection did not succeed");
        require(INTENDED_RECIPIENT.balance == 0, "intended recipient received gift");
    }
}

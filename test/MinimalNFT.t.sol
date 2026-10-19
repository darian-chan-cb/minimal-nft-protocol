// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MinimalNFT, IERC721Receiver} from "../src/MinimalNFT.sol";

interface Vm {
    function deal(address account, uint256 newBalance) external;
    function expectRevert(bytes4 revertData) external;
    function prank(address msgSender) external;
}

contract NFTReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract MinimalNFTTest {
    Vm private constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    MinimalNFT private nft;
    address private constant ALICE = address(0xA11CE);
    address private constant BOB = address(0xB0B);
    uint256 private constant PRICE = 0.05 ether;

    function setUp() public {
        nft = new MinimalNFT("Test Collection", "TEST", 3, PRICE, "ipfs://collection/");
    }

    function testPublicMint() public {
        VM.deal(ALICE, 1 ether);
        VM.prank(ALICE);
        uint256 tokenId = nft.mint{value: PRICE}(ALICE);

        require(tokenId == 1, "wrong token id");
        require(nft.ownerOf(1) == ALICE, "wrong owner");
        require(nft.balanceOf(ALICE) == 1, "wrong balance");
        require(keccak256(bytes(nft.tokenURI(1))) == keccak256("ipfs://collection/1"), "wrong URI");
    }

    function testOwnerMintAndSupplyCap() public {
        nft.ownerMint(ALICE);
        nft.ownerMint(ALICE);
        nft.ownerMint(BOB);

        VM.expectRevert(MinimalNFT.MaxSupplyReached.selector);
        nft.ownerMint(BOB);
    }

    function testMintRequiresExactPayment() public {
        VM.deal(ALICE, 1 ether);
        VM.prank(ALICE);
        VM.expectRevert(MinimalNFT.InvalidPayment.selector);
        nft.mint{value: PRICE - 1}(ALICE);
    }

    function testApprovalAndTransfer() public {
        nft.ownerMint(ALICE);

        VM.prank(ALICE);
        nft.approve(BOB, 1);
        VM.prank(BOB);
        nft.transferFrom(ALICE, BOB, 1);

        require(nft.ownerOf(1) == BOB, "transfer failed");
        require(nft.balanceOf(ALICE) == 0, "sender balance wrong");
        require(nft.balanceOf(BOB) == 1, "recipient balance wrong");
    }

    function testSafeMintToReceiverContract() public {
        NFTReceiver receiver = new NFTReceiver();
        nft.ownerMint(address(receiver));
        require(nft.ownerOf(1) == address(receiver), "safe mint failed");
    }

    function testNonOwnerCannotChangePrice() public {
        VM.prank(ALICE);
        VM.expectRevert(MinimalNFT.NotOwner.selector);
        nft.setMintPrice(1 ether);
    }

    function testOwnerCanWithdrawMintRevenue() public {
        VM.deal(ALICE, 1 ether);
        VM.prank(ALICE);
        nft.mint{value: PRICE}(ALICE);

        uint256 beforeBalance = BOB.balance;
        nft.withdraw(payable(BOB));
        require(BOB.balance == beforeBalance + PRICE, "withdraw failed");
        require(address(nft).balance == 0, "contract balance not cleared");
    }
}

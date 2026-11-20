# Gift-voucher security review fixture

This directory contains an **intentionally insecure, review-only** example of a signed gift-payout feature. It is designed to exercise security review of a realistic contract change. It is not imported by the production collection and is outside the root Foundry project's `src` and `test` paths. **Do not deploy or copy this contract into production.**

An issuer signs a gift voucher, and a caller redeems it for a recipient from the funded fixture treasury. The accompanying tests show both the expected redemption and a security-relevant adversarial redemption. This fixture has no production deployment path.

To run its tests separately, copy `GiftVoucher.sol` to `src/` and `GiftVoucher.t.sol` to `test/` in a disposable Foundry project, then run `forge test` there.

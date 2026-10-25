# Phase 2.6 — Order flow test gate

The trusted order functions are now exported by functions/order_entry.js.
The Flutter OrderService calls them for every mutation. **Do not run a new
Flutter build against an undeployed backend.** Do not publish the candidate
Firestore rules yet.

## Local checkout checks (safe now)
```powershell
git switch feature/buyer-order-flow
git pull origin feature/buyer-order-flow
flutter pub get
flutter analyze
flutter test
cd functions
npm ci
node --check index.js
node --check orders.js
node --check order_entry.js
cd ..
```
If functions/package-lock.json is not tracked yet, use `npm install` instead of
`npm ci`. Resolve all analyzer and test failures before deploying.

## Emulator test matrix
1. Seed a brand and an active listing with valid price and fulfillment flags.
2. Sign in as a buyer and create an order. Assert server-computed unitPrice,
   amount, sellerId, buyerId, and pending status.
3. Try submitting client-controlled sellerId, price, amount and status. They
   must be ignored by the server.
4. Try ordering your own listing, an inactive listing, and an unavailable
   fulfillment method. All must fail.
5. Submit duplicate orderId. It must not create a second order.
6. Seller accepts; buyer cannot accept. Buyer cancels pending; seller cannot
   cancel. Seller rejects pending with reason.
7. Seller transitions accepted order to ready_for_pickup or out_for_delivery,
   then delivered. Buyer cannot mark delivered.
8. Repeat delivered transition. It must fail without incrementing soldCount
   again. Concurrent delivery calls must not double count.
9. Run with candidate rules in emulator. Verify orders are readable only by
   buyer/seller, wallet cannot be read or written by clients.
10. Confirm old supported app versions and all non-order workflows against
    the candidate rules before a production rules rollout.

## Rollout sequence
1. Deploy new callable functions while the current app remains live.
2. Validate callable functions with test accounts.
3. Release updated Flutter client to testers.
4. Audit and test all Firestore paths, including notifications, role switching,
   followers and reviews. Candidate rules intentionally deny unreviewed paths.
5. Deploy verified replacement rules only after compatibility is proven.
6. Monitor permission-denied errors and order completion. Keep a reviewed
   rollback ready.

## Known issues
- Production currently uses public Firestore rules; this remains urgent.
- The candidate rules are NOT production ready.
- No Firebase emulator or Flutter tests have been executed by the assistant.
- Real-money checkout and seller payouts are separate from order intent.

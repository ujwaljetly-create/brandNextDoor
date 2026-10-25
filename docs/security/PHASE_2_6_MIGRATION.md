# Phase 2.6 — Zero-planned-downtime Firestore migration

## Production state
As of the user-provided Firebase Console screenshot (2026-10-24), deployed rules contain:
`match /{document=**} { allow read, write: if true; }`.
This is an urgent data-exposure risk. **No rule change has been deployed** by this work.

## What has been inspected
- Registration writes users/{uid}, with uid, name, email, roles, createdAt.
- BrandRepository writes brands/{brandId} with sellerId, public storefront details.
- ListingService writes listings/{listingId} with sellerId and mutable soldCount.
- OrderService creates orders/{orderId} and lets clients mutate status and soldCount.
- ChatService creates chats/{chatId} and messages; conversation reads filter buyerId/sellerId.
- AI wallet is accessed by callable functions and should deny all client reads and writes.

## Blocking issues before candidate rules can be deployed
1. Move order creation and status transitions into trusted Cloud Functions; validate buyer, seller,
   listing ownership, quantity, unit price, total amount, and allowed state transitions on server.
2. Move soldCount updates into the trusted order transition. Existing client transaction must stop.
3. Audit ALL Firestore collection paths used across Flutter and Functions. In particular:
   notifications, role updates, reviews, followers, buyer/seller profiles, analytics, and
   any nested subcollections. Add exact rules and emulator tests for each.
4. Check whether the app needs public reads of users or private reads of brands/listings.
   Never expose personal information in publicly readable documents.
5. Verify collection-query compatibility: Firestore rules are not filters. Existing list
   queries may require owner/participant predicates.
6. Verify existing document shapes against rules (legacy missing fields, old sellerId formats).
7. Audit and test Storage rules independently; Firestore rules do not protect uploaded images.
8. Confirm the proposed restrictions on chat metadata and message reads/writes preserve workflows.
9. Run Firebase Emulator tests with separate signed-in buyer and seller identities and unauthenticated
   clients. Test registration, role switching, listing, brand, orders, chats, reviews and notifications.
10. Stage the rules in a non-production Firebase project seeded with sanitized representative data.
    Run smoke tests using the same Flutter app version as production.

## Deployment plan
- Back up the currently published Firestore rules and export relevant data.
- Do NOT deploy docs/security/firestore.candidate.rules directly; it is a draft.
- Prepare a fully audited firestore.rules file and reference it in firebase.json only after tests.
- Deploy compatible backend functions first, then compatible client changes.
- Confirm older supported app versions remain functional.
- Publish verified Firestore rules in a single controlled change.
- Monitor permission-denied logs, order creation and chat delivery, and have a tested rollback.
- A zero-planned-downtime target does not guarantee zero errors. The current public rules remain
  risky until replaced. Do not enable paid AI credits before hardening.

## Initial rule-test matrix
| Operation | Anonymous | Buyer | Seller |
| --- | --- | --- | --- |
| Read own user profile | deny | allow | allow |
| Read another user profile | deny | deny | deny |
| Modify AI wallet | deny | deny | deny |
| Read public brand/listing | allow | allow | allow |
| Edit another seller brand/listing | deny | deny | deny |
| Create own brand/listing | deny | deny | allow (seller role enforcement pending) |
| Read unrelated order | deny | deny | deny |
| Read own order | deny | allow | allow if participant |
| Read unrelated chat | deny | deny | deny |
| Read participant chat | deny | allow | allow |
| Send message as another user | deny | deny | deny |

## Commands (LOCAL/EMULATOR ONLY)
`firebase emulators:start --only auth,firestore,functions --project demo-brandnextdoor-security`
Use a separate emulator configuration referencing the candidate rules. Never point local
emulator test scripts at production. Avoid deploying until the blockers above are resolved.

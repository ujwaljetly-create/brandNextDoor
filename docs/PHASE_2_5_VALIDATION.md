# Brand Next Door — Phase 2.5 validation

## Status
Changes are committed to feature/buyer-order-flow but are NOT deployed or verified on Firebase.
The server now grants 30 introductory credits per authenticated UID when the wallet is first accessed.
The trial is **not** a purchase and cannot be converted to cash. Existing wallets are not re-granted.
Every AI action now consumes credits. This is a behavioral change: test before rollout.

## Security deployment gate (must complete before release)
1. Merge docs/security/ai_wallet.rules.fragment into the EXISTING Firestore rules.
   Do not replace current production rules with the fragment; verify no broad wildcard allows wallet writes.
2. Deploy the merged rules, then test unauthorized reads/writes and cross-user access using Firebase Emulator.
3. Configure Firebase App Check for all supported clients and switch callable functions to enforceAppCheck:true.
   App Check is currently disabled for compatibility, so do NOT expose credit purchasing.
4. Rotate the OpenAI key if it was ever shipped in the Flutter app. Remove .env key from bundled assets
   after checking for any remaining client-side usage. Never commit the secret.
5. Configure: firebase functions:secrets:set OPENAI_API_KEY
6. Deploy functions and validate Firebase Functions permissions and billing.

## Integration checks
- flutter pub get
- flutter analyze
- flutter test
- node --check functions/index.js
- firebase emulators:start --only functions,firestore,auth

## End-to-end test cases (not yet executed)
- Signed-out getAiWallet and generateWithAiCredits calls return unauthenticated.
- First authenticated wallet read grants exactly 30 credits and one welcome_trial ledger row.
- Concurrent first reads do not grant twice.
- Repeat reads never re-grant credits.
- One brand identity generation reserves 5 and completes exactly once.
- One AI logo generation reserves 20; logo result is visible and saved.
- Concurrent requests cannot overdraft wallet.
- Rapid repeat requests hit the server rate limit.
- Same requestId never triggers another charge or AI generation.
- OpenAI error refunds credits and marks ledger refunded.
- Expired reserved request is refunded once by scheduled recovery.
- Ledger shows cost, status and token usage; verify no secrets/prompts in ledger.
- Users cannot read or write wallet, ledger or request documents directly.
- Insufficient credits returns resource-exhausted and does not call OpenAI.
- Test market tips, listing generation, colors and brand regeneration after migration.

## Known limitations requiring follow-up
- Generated image data is still returned as base64 from callable functions and may exceed transport limits.
  Replace with backend Storage upload and a short-lived retrieval reference before production.
- Recovery can refund a request after a process crash; it cannot cancel an already-issued OpenAI request.
  Server costs may still accrue for orphaned work.
- Token usage is recorded for text features; image cost accounting and CAD cost estimation require
  verified provider pricing, model usage data, and an exchange-rate policy.
- No payment gateway or in-app purchase integration has been implemented.
- Firebase App Check enforcement and deployed rules verification are pending.
- Live API tests and device testing are pending.

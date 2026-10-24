# Superseded by Phase 2.5

See [Phase 2.5 validation](PHASE_2_5_VALIDATION.md) for the current implementation, deployment instructions, known limitations, and security gates.

# AI Credits — Phase 2 deployment and safety checklist

## Current rollout status
- Wallet and callable metered generation implemented, but NOT enabled for existing free generation flows.
- No paid credit purchases, credit grants, or recurring subscriptions are implemented.
- New wallet balances default to zero. Do not advertise credits as available to spend yet.
- No user can mint credits through the client. Granting promotional credits requires a separate privileged administrative process.
- Costs are **illustrative internal credit units**, not validated commercial prices.

## Firebase configuration
1. Ensure the Firebase project is correct and deploy the callable functions:
   `firebase functions:secrets:set OPENAI_API_KEY`
   `firebase deploy --only functions`
2. Run `flutter pub get`, `flutter analyze`, and test on an Android device.
3. Check that the seller Profile → AI Credits screen loads and shows a zero balance.
4. Verify authenticated calls work and unauthenticated calls fail.
5. Verify insufficient credits fail without invoking OpenAI.

## Security: REQUIRED before any real credit issuance
- Publish Firestore security rules that deny ALL client reads and writes to `ai_wallets/{uid}` and all nested `ledger` and `requests` documents. Wallet access is via callable functions only. The repository does not currently include a Firestore rules file; inspect the deployed rules before changing them.
- Enable and enforce Firebase App Check after configuring supported clients.
- Add per-user rate limits and abuse monitoring.
- Add an administrative-only credit grant workflow with an auditable ledger and idempotency.
- Add a recovery job for requests stuck in `reserved` state due to function termination or timeout; the normal failure handler refunds, but process crashes can bypass it.
- Test concurrent reservations, retries, malformed outputs, long-running image calls, refunds and webhook replay prevention.
- The existing free OpenAI services still embed the API key in the Flutter application. Migrate and remove them before treating AI billing/security as production-ready.
- Consider response size limits: image base64 may be too large for callable responses. Upload generated images to Storage from the backend and return a short-lived reference instead before launch.
- Avoid storing full prompts or generated sensitive content in credit transaction history.
- Do not add credit purchasing until store billing policy and tax implications have been reviewed.

## Example metered features
- brand_identity: 5 credits
- brand_name: 2 credits
- brand_tagline: 2 credits
- brand_description: 2 credits
- color_hex: 1 credit
- logo: 20 credits

These amounts are configuration placeholders, not published prices.

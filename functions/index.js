const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

async function getTokens(uid) {
  if (!uid) return [];
  const snapshot = await db.collection('users').doc(uid).get();
  const tokens = snapshot.data()?.fcmTokens;
  if (!Array.isArray(tokens)) return [];
  return [...new Set(tokens.filter((token) => typeof token === 'string' && token.length > 0))]
    .slice(0, 500);
}

async function saveNotification({ userId, title, body, type, orderId, chatId, brandId, listingId }) {
  if (!userId) return;

  await db.collection('notifications').add({
    userId,
    title,
    body,
    type,
    orderId: orderId || '',
    chatId: chatId || '',
    brandId: brandId || '',
    listingId: listingId || '',
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function sendToUser({ userId, title, body, data = {} }) {
  await saveNotification({
    userId,
    title,
    body,
    type: data.type || 'order',
    orderId: data.orderId || '',
    chatId: data.chatId || '',
    brandId: data.brandId || '',
    listingId: data.listingId || '',
  });

  const tokens = await getTokens(userId);
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value)]),
    ),
    android: {
      priority: 'high',
      notification: { sound: 'default' },
    },
    apns: {
      payload: { aps: { sound: 'default' } },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    if (result.success) return;
    const code = result.error?.code || '';
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    await db.collection('users').doc(userId).set(
      {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      },
      { merge: true },
    );
  }
}

async function notifyFollowers({ brandId, title, body, type, listingId }) {
  if (!brandId) return;
  const followers = await db.collection('brands').doc(brandId).collection('followers').get();
  await Promise.all(
    followers.docs.map((doc) =>
      sendToUser({
        userId: doc.id,
        title,
        body,
        data: {
          type,
          brandId,
          listingId: listingId || '',
        },
      }),
    ),
  );
}

exports.notifySellerOnNewOrder = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data?.data();
  if (!order) return;

  await sendToUser({
    userId: order.sellerId,
    title: 'New order received',
    body: `${order.buyerName || 'A buyer'} ordered ${order.productTitle || 'an item'}.`,
    data: {
      type: 'new_order',
      orderId: event.params.orderId,
      sellerId: order.sellerId || '',
    },
  });
});

exports.notifyBuyerOnOrderStatus = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;
  if (after.status === 'cancelled') return;

  const labels = {
    accepted: 'Your order was accepted',
    rejected: 'Your order was rejected',
    ready_for_pickup: 'Your order is ready for pickup',
    out_for_delivery: 'Your order is out for delivery',
    delivered: 'Your order has been delivered',
  };

  const title = labels[after.status];
  if (!title) return;
  let body = after.productTitle || 'Your order status changed.';
  if (after.status === 'rejected' && after.rejectionReason) {
    body = `${body}: ${after.rejectionReason}`;
  }

  await sendToUser({
    userId: after.buyerId,
    title,
    body,
    data: {
      type: 'order_status',
      orderId: event.params.orderId,
      status: after.status || '',
    },
  });
});

exports.notifyOnNewChatMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message || !message.receiverId || !message.senderId) return;

    const chatSnapshot = await db.collection('chats').doc(event.params.chatId).get();
    const chat = chatSnapshot.data() || {};
    const receiverIsBuyer = chat.buyerId === message.receiverId;
    const senderName = receiverIsBuyer ? (chat.brandName || 'Seller') : 'Buyer';
    const text = String(message.message || 'New message');
    const preview = text.length > 90 ? `${text.substring(0, 87)}...` : text;

    await sendToUser({
      userId: message.receiverId,
      title: `New message from ${senderName}`,
      body: preview,
      data: {
        type: 'chat_message',
        chatId: event.params.chatId,
        senderId: message.senderId,
      },
    });
  },
);

exports.notifyFollowersOnNewListing = onDocumentCreated(
  'listings/{listingId}',
  async (event) => {
    const listing = event.data?.data();
    if (!listing || listing.status !== 'active' || !listing.brandId) return;

    const brandDoc = await db.collection('brands').doc(listing.brandId).get();
    const brandName = brandDoc.data()?.brandName || 'A seller you follow';
    const isDeal = listing.isHotDeal === true && Number(listing.dealPrice || 0) > 0;
    const dealPrice = Number(listing.dealPrice || 0);

    await notifyFollowers({
      brandId: listing.brandId,
      title: isDeal
        ? `New deal from ${brandName}`
        : `${brandName} added something new`,
      body: isDeal
        ? `${listing.title || 'An item'} is now on deal for $${dealPrice.toFixed(2)}.`
        : (listing.title || 'A new product is now available.'),
      type: isDeal ? 'seller_new_deal' : 'seller_new_listing',
      listingId: event.params.listingId,
    });
  },
);

exports.notifyFollowersOnNewDeal = onDocumentUpdated(
  'listings/{listingId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || !after.brandId) return;

    const becameDeal = after.isHotDeal === true && (
      before.isHotDeal !== true ||
      Number(before.dealPrice || 0) !== Number(after.dealPrice || 0) ||
      String(before.dealEndAt || '') !== String(after.dealEndAt || '')
    );
    if (!becameDeal || after.status !== 'active') return;

    const brandDoc = await db.collection('brands').doc(after.brandId).get();
    const brandName = brandDoc.data()?.brandName || 'A seller you follow';
    const price = Number(after.dealPrice || 0);
    const priceText = price > 0 ? ` for $${price.toFixed(2)}` : '';

    await notifyFollowers({
      brandId: after.brandId,
      title: `New deal from ${brandName}`,
      body: `${after.title || 'An item'} is now on deal${priceText}.`,
      type: 'seller_new_deal',
      listingId: event.params.listingId,
    });
  },
);


const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const openAiSecret = defineSecret('OPENAI_API_KEY');

// Credits are internal usage units, not OpenAI tokens or currency.
// Costs are versioned on the server and never accepted from the client.
const AI_COSTS = Object.freeze({
  brand_identity: 5,
  brand_name: 2,
  brand_tagline: 2,
  brand_description: 2,
  color_hex: 1,
  logo: 20,
});
const walletRef = (uid) => db.collection('ai_wallets').doc(uid);
const requestRef = (uid, id) => walletRef(uid).collection('requests').doc(id);
const MAX_INPUT = 3500;

exports.getAiWallet = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const uid = request.auth.uid;
  const wallet = await walletRef(uid).get();
  const transactions = await walletRef(uid).collection('ledger').orderBy('createdAt', 'desc').limit(30).get();
  return {
    balance: wallet.exists ? Number(wallet.data().balance || 0) : 0,
    costs: AI_COSTS,
    history: transactions.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate()?.toISOString() || null,
    })),
  };
});

exports.generateWithAiCredits = onCall(
  { secrets: [openAiSecret], timeoutSeconds: 120, memory: '1GiB', enforceAppCheck: false },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
    const uid = request.auth.uid;
    const { feature, input, requestId } = request.data || {};
    if (!Object.prototype.hasOwnProperty.call(AI_COSTS, feature)) {
      throw new HttpsError('invalid-argument', 'Unsupported AI feature.');
    }
    if (typeof requestId !== 'string' || !/^[a-zA-Z0-9_-]{12,80}$/.test(requestId)) {
      throw new HttpsError('invalid-argument', 'Invalid request ID.');
    }
    if (typeof input !== 'string' || !input.trim() || input.length > MAX_INPUT) {
      throw new HttpsError('invalid-argument', 'Input must be 1-3500 characters.');
    }
    const key = openAiSecret.value();
    if (!key) throw new HttpsError('failed-precondition', 'AI service is not configured.');

    const cost = AI_COSTS[feature];
    const wallet = walletRef(uid);
    const job = requestRef(uid, requestId);
    const ledger = wallet.collection('ledger').doc(requestId);
    await db.runTransaction(async (tx) => {
      const [jobSnap, walletSnap] = await Promise.all([tx.get(job), tx.get(wallet)]);
      if (jobSnap.exists) throw new HttpsError('already-exists', 'Request ID already used. Refresh wallet history.');
      const balance = walletSnap.exists ? Number(walletSnap.data().balance || 0) : 0;
      if (balance < cost) throw new HttpsError('resource-exhausted', 'Not enough AI credits.');
      tx.set(wallet, { balance: balance - cost, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      tx.create(job, { feature, cost, state: 'reserved', createdAt: admin.firestore.FieldValue.serverTimestamp() });
      tx.create(ledger, { feature, delta: -cost, status: 'reserved', createdAt: admin.firestore.FieldValue.serverTimestamp() });
    });

    try {
      let output;
      if (feature === 'logo') {
        let parsed;
        try { parsed = JSON.parse(input); } catch (_) {
          throw new Error('Logo input must contain valid brand JSON.');
        }
        const prompt = [
          'Create a premium modern local-business logo with transparent background.',
          'Professional typography, clean vector-like composition, suitable for a storefront.',
          'Brand name: ' + String(parsed.brandName || '').slice(0, 150),
          'Tagline: ' + String(parsed.tagline || '').slice(0, 250),
          'Description: ' + String(parsed.description || '').slice(0, 1000),
          'Colors: ' + JSON.stringify(parsed.colors || []).slice(0, 400),
        ].join('\n');
        const response = await fetch('https://api.openai.com/v1/images/generations', {
          method: 'POST',
          headers: { Authorization: 'Bearer ' + key, 'Content-Type': 'application/json' },
          body: JSON.stringify({ model: 'gpt-image-1', size: '1024x1024', background: 'transparent', prompt }),
        });
        const payload = await response.json();
        if (!response.ok || !payload.data?.[0]?.b64_json) throw new Error(payload.error?.message || 'Logo generation failed.');
        output = payload.data[0].b64_json;
      } else {
        const prompts = {
          brand_identity: 'You are a branding consultant. Return ONLY JSON with keys brandName, tagline, description, colors (array), personalityTraits (array), targetAudience (array), brandScore (integer, subjective AI estimate).',
          brand_name: 'Generate exactly one premium brand name. Return plain text only.',
          brand_tagline: 'Generate one concise professional tagline. Return plain text only.',
          brand_description: 'Generate a compelling business description. Return plain text only.',
          color_hex: 'Convert the color description into RGB. Return ONLY JSON with a hex key like {"hex":"#AABBCC"}.',
        };
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          headers: { Authorization: 'Bearer ' + key, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: 'gpt-4o-mini',
            messages: [{ role: 'system', content: prompts[feature] }, { role: 'user', content: input }],
            ...(feature === 'brand_identity' || feature === 'color_hex' ? { response_format: { type: 'json_object' } } : {}),
          }),
        });
        const payload = await response.json();
        if (!response.ok || !payload.choices?.[0]?.message?.content) throw new Error(payload.error?.message || 'AI generation failed.');
        output = payload.choices[0].message.content;
      }
      await db.runTransaction(async (tx) => {
        const snapshot = await tx.get(job);
        if (snapshot.data()?.state !== 'reserved') throw new Error('Unexpected AI request state.');
        tx.update(job, { state: 'completed', completedAt: admin.firestore.FieldValue.serverTimestamp() });
        tx.update(ledger, { status: 'completed' });
      });
      return { output, creditsUsed: cost };
    } catch (error) {
      await db.runTransaction(async (tx) => {
        const [jobSnap, walletSnap] = await Promise.all([tx.get(job), tx.get(wallet)]);
        if (jobSnap.data()?.state !== 'reserved') return;
        const balance = Number(walletSnap.data()?.balance || 0);
        tx.set(wallet, { balance: balance + cost, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
        tx.update(job, { state: 'refunded', completedAt: admin.firestore.FieldValue.serverTimestamp() });
        tx.update(ledger, { status: 'refunded' });
      });
      throw new HttpsError('internal', 'AI generation failed; reserved credits were refunded.');
    }
  },
);

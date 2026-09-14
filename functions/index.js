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
    await notifyFollowers({
      brandId: listing.brandId,
      title: `${brandName} added something new`,
      body: listing.title || 'A new product is now available.',
      type: 'seller_new_listing',
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

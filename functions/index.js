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

async function saveNotification({ userId, title, body, type, orderId }) {
  if (!userId) return;

  await db.collection('notifications').add({
    userId,
    title,
    body,
    type,
    orderId: orderId || '',
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
      notification: {
        channelId: 'orders',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
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

exports.notifySellerOnNewOrder = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data?.data();
  if (!order) return;

  const productTitle = order.productTitle || 'New order';
  const buyerName = order.buyerName || 'A buyer';

  await sendToUser({
    userId: order.sellerId,
    title: 'New order received',
    body: `${buyerName} ordered ${productTitle}.`,
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

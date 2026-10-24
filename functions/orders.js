const {onCall,HttpsError}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
const db=admin.firestore();
const auth=(r)=>{if(!r.auth)throw new HttpsError('unauthenticated','Sign in first');return r.auth.uid;};
const id=(s)=>typeof s==='string'&&/^[\w-]{1,128}$/.test(s);
exports.createTrustedOrder=onCall(async(r)=>{
 const uid=auth(r),{orderId,listingId,quantity,fulfillmentMethod}=r.data||{};
 if(!id(orderId)||!id(listingId)||!Number.isInteger(quantity)||quantity<1||quantity>100||!['pickup','delivery'].includes(fulfillmentMethod))throw new HttpsError('invalid-argument','Invalid order');
 const order=db.collection('orders').doc(orderId),listing=db.collection('listings').doc(listingId);
 return db.runTransaction(async tx=>{
  const [o,l,b]=await Promise.all([tx.get(order),tx.get(listing),tx.get(db.collection('users').doc(uid))]);
  if(o.exists){if(o.data().buyerId===uid&&o.data().listingId===listingId)return {orderId,alreadyCreated:true};throw new HttpsError('already-exists','Order exists');}
  if(!l.exists)throw new HttpsError('not-found','Listing not found');
  const d=l.data();
  if(d.status!=='active'||d.sellerId===uid||d[fulfillmentMethod==='pickup'?'pickupAvailable':'deliveryAvailable']!==true)throw new HttpsError('failed-precondition','Listing unavailable');
  const brand=d.brandId?await tx.get(db.collection('brands').doc(d.brandId)):null;
  const bd=brand?.data()||{};
  const price=Number(d.price),deal=Number(d.dealPrice),now=Date.now();
  const active=d.isHotDeal===true&&deal>0&&deal<price&&(!d.dealStartAt||d.dealStartAt.toMillis()<=now)&&(!d.dealEndAt||d.dealEndAt.toMillis()>=now);
  const unitPrice=active?deal:price;
  if(!Number.isFinite(unitPrice)||unitPrice<=0)throw new HttpsError('failed-precondition','Invalid price');
  const ts=admin.firestore.FieldValue.serverTimestamp();
  tx.create(order,{orderId,buyerId:uid,buyerName:String(b.data()?.name||r.auth.token.name||'Buyer'),sellerId:d.sellerId,sellerName:String(bd.brandName||'Seller'),sellerLogoUrl:String(bd.logoUrl||''),brandId:d.brandId||'',listingId,productTitle:d.title||'',productImageUrl:d.images?.[0]||'',productCategory:d.category||'',unitPrice,amount:Math.round(unitPrice*quantity*100)/100,quantity,fulfillmentMethod,status:'pending',rejectionReason:'',createdAt:ts,updatedAt:ts});
  return {orderId,alreadyCreated:false};
 });
});
exports.transitionTrustedOrder=onCall(async(r)=>{
 const uid=auth(r),{orderId,action,reason}=r.data||{};
 if(!id(orderId))throw new HttpsError('invalid-argument','Invalid order ID');
 const transitions={accept:['pending','accepted','seller'],reject:['pending','rejected','seller'],cancel:['pending','cancelled','buyer'],ready_for_pickup:['accepted','ready_for_pickup','seller'],out_for_delivery:['accepted','out_for_delivery','seller'],delivered:['ready_for_pickup|out_for_delivery','delivered','seller']};
 const rule=transitions[action];
 if(!rule)throw new HttpsError('invalid-argument','Invalid action');
 if(action==='reject'&&(typeof reason!=='string'||!reason.trim()||reason.length>500))throw new HttpsError('invalid-argument','Reason required');
 const ref=db.collection('orders').doc(orderId);
 return db.runTransaction(async tx=>{
  const snap=await tx.get(ref);
  if(!snap.exists)throw new HttpsError('not-found','Order missing');
  const d=snap.data();
  if(d[rule[2]+'Id']!==uid)throw new HttpsError('permission-denied','Not participant');
  if(!rule[0].split('|').includes(d.status))throw new HttpsError('failed-precondition','Invalid status transition');
  const listingRef=action==='delivered'&&d.listingId?db.collection('listings').doc(d.listingId):null;
  const listingSnap=listingRef?await tx.get(listingRef):null;
  const ts=admin.firestore.FieldValue.serverTimestamp();
  const updates={status:rule[1],updatedAt:ts};
  if(action==='accept')updates.acceptedAt=ts;
  if(action==='reject')updates.rejectionReason=reason.trim();
  if(['reject','cancel','delivered'].includes(action))updates.completedAt=ts;
  tx.update(ref,updates);
  if(listingSnap?.exists)tx.update(listingRef,{soldCount:admin.firestore.FieldValue.increment(Number(d.quantity||1))});
  return {orderId,status:rule[1]};
 });
});

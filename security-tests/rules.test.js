const { before, after, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, collection, query, where, getDocs } = require('firebase/firestore');
const { ref, uploadBytes, getBytes } = require('firebase/storage');
let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-dietician-babu',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: readFileSync('../storage.rules', 'utf8'), host: '127.0.0.1', port: 9199 },
  });
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'clients/alice'), {weightKg: 70, subscriptionStatus: 'active'});
    await setDoc(doc(db, 'users/alice'), {uid: 'alice', role: 'client', name: 'Alice'});
    await setDoc(doc(db, 'clients/alice/notes/private'), {content: 'Internal'});
    await setDoc(doc(db, 'plans/alice-plan'), {clientId: 'alice', title: 'Plan'});
    await uploadBytes(ref(context.storage(), 'clients/alice/report.pdf'), new Uint8Array([1, 2]));
  });
});
after(async () => { if (env) await env.cleanup(); });
const db = uid => env.authenticatedContext(uid).firestore();
test('anonymous and other users cannot read a health profile', async () => {
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'clients/alice')));
  await assertFails(getDoc(doc(db('bob'), 'clients/alice')));
});
test('owner can update weight but not subscription entitlement', async () => {
  await assertSucceeds(updateDoc(doc(db('alice'), 'clients/alice'), {weightKg: 69}));
  await assertFails(updateDoc(doc(db('alice'), 'clients/alice'), {subscriptionStatus: 'approved'}));
});
test('owner cannot promote themselves or read admin notes', async () => {
  await assertFails(updateDoc(doc(db('alice'), 'users/alice'), {role: 'admin'}));
  await assertFails(getDoc(doc(db('alice'), 'clients/alice/notes/private')));
});
test('new users can onboard without setting privileged fields', async () => {
  await assertSucceeds(setDoc(doc(db('new'), 'users/new'), {uid: 'new', role: 'client', name: 'New', status: 'pending'}));
  await assertSucceeds(setDoc(doc(db('new'), 'clients/new'), {weightKg: 70, subscriptionStatus: 'none'}));
  await assertFails(setDoc(doc(db('evil'), 'clients/evil'), {weightKg: 70, subscriptionStatus: 'active'}));
});
test('owner can query their own plans but not everyone’s', async () => {
  await assertSucceeds(getDocs(query(collection(db('alice'), 'plans'), where('clientId', '==', 'alice'))));
  await assertFails(getDocs(collection(db('alice'), 'plans')));
});
test('admin claim authorizes access and email alone does not', async () => {
  await assertSucceeds(getDoc(doc(env.authenticatedContext('admin', {admin: true}).firestore(), 'clients/alice')));
  await assertFails(getDoc(doc(env.authenticatedContext('fake', {email: 'dieticianbabu@gmail.com'}).firestore(), 'clients/alice')));
});
test('client documents are readable only by owner or admin', async () => {
  await assertSucceeds(getBytes(ref(env.authenticatedContext('alice').storage(), 'clients/alice/report.pdf')));
  await assertFails(getBytes(ref(env.authenticatedContext('bob').storage(), 'clients/alice/report.pdf')));
  await assertFails(uploadBytes(ref(env.authenticatedContext('alice').storage(), 'clients/alice/fake.pdf'), new Uint8Array([3])));
});
test('valid check-in works but forged admin notes do not', async () => {
  await assertSucceeds(setDoc(doc(db('alice'), 'weeklyUpdates/good'), {clientId: 'alice', weightKg: 69, adminNotes: ''}));
  await assertFails(setDoc(doc(db('alice'), 'weeklyUpdates/bad'), {clientId: 'alice', weightKg: 69, adminNotes: 'Approved'}));
});

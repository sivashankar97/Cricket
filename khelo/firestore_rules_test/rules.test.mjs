import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, deleteDoc, getDoc, writeBatch, serverTimestamp, collection, addDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-khelo',
  firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080 },
});

const db = (uid, provider = 'password') =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: provider } }).firestore();

let passed = 0, failed = 0;
async function check(name, fn) {
  try { await fn(); passed++; console.log('ok   ', name); }
  catch (e) { failed++; console.log('FAIL ', name, '-', e.message.split('\n')[0]); }
}

async function seed() {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const s = ctx.firestore();
    await setDoc(doc(s, 'users/alice'), { id: 'alice', name: 'Alice' });
    await setDoc(doc(s, 'users/bob'), { id: 'bob', name: 'Bob' });
    await setDoc(doc(s, 'users/p1'), { id: 'p1', name: 'Kumar', created_by: 'org' });
    await setDoc(doc(s, 'phone_index/K1'), { user_id: 'p1', created_by: 'org' });
    await setDoc(doc(s, 'auctions/A'), { admin_ids: ['org'], created_by: 'org', status: 'live' });
    await setDoc(doc(s, 'users/auction_A_x'), { id: 'auction_A_x', name: 'Pool', auction_id: 'A' });
    await setDoc(doc(s, 'teams/t1'), { id: 't1', team_players: [{ id: 'p1', role: 'player' }] });
  });
}

const claim = (status = 'pending', extra = {}) => ({
  id: 'p1_bob', player_id: 'p1', player_name: 'Kumar', claimant_id: 'bob', claimant_name: 'Bob',
  organizer_id: 'org', status, phone_key: 'K1', created_at: serverTimestamp(), ...extra,
});

await seed();
// ── Normal app flows (must keep working) ──
await check('sign-up creates own profile', () => assertSucceeds(setDoc(doc(db('carol'), 'users/carol'), { id: 'carol', name: 'Carol' })));
await check('edit own profile (merge)', () => assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), { name: 'Alice B' }, { merge: true })));
await check('notifications toggle', () => assertSucceeds(updateDoc(doc(db('alice'), 'users/alice'), { notifications: false })));
await check('organizer adds player + number (batch)', async () => {
  const o = db('org'); const b = writeBatch(o);
  b.set(doc(o, 'users/p2'), { id: 'p2', name: 'Raj', created_by: 'org' });
  b.set(doc(o, 'phone_index/K2'), { user_id: 'p2', created_by: 'org', updated_at: serverTimestamp() });
  await assertSucceeds(b.commit());
});
await check('add player without number', () => assertSucceeds(setDoc(doc(db('org'), 'users/p3'), { id: 'p3', name: 'Siva', created_by: 'org' })));
await check('other team admin edits added player', () => assertSucceeds(updateDoc(doc(db('alice'), 'users/p1'), { name: 'Kumar S' })));
await check('auction admin writes auction player (set)', () => assertSucceeds(setDoc(doc(db('org'), 'users/auction_A_x'), { id: 'auction_A_x', name: 'Pool 2', auction_id: 'A' })));
await check('auction admin creates auction player', () => assertSucceeds(setDoc(doc(db('org'), 'users/auction_A_y'), { id: 'auction_A_y', name: 'New', auction_id: 'A' })));
await check('scorer writes career stats', () => assertSucceeds(setDoc(doc(db('alice'), 'users/p1/user_stat/test'), { matches: 1 })));
await check('session write', () => assertSucceeds(setDoc(doc(db('alice'), 'users/alice/user_session/s1'), { id: 's1' })));
await check('public reads profile signed out', () => assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice'))));
await check('teams still writable (unchanged)', () => assertSucceeds(updateDoc(doc(db('alice'), 'teams/t1'), { name: 'X' })));
await check('register own number', () => assertSucceeds(setDoc(doc(db('alice'), 'phone_index/KA'), { user_id: 'alice', created_by: 'alice', updated_at: serverTimestamp() })));
await check('free own old number', () => assertSucceeds(deleteDoc(doc(db('alice'), 'phone_index/KA'))));
await check('look up a number', () => assertSucceeds(getDoc(doc(db('alice'), 'phone_index/K1'))));
await check('claimant asks to link', () => assertSucceeds(setDoc(doc(db('bob'), 'player_claims/p1_bob'), claim())));
await check('claimant reads own claim', () => assertSucceeds(getDoc(doc(db('bob'), 'player_claims/p1_bob'))));
await check('organizer approves: claim + number + delete in one batch', async () => {
  const o = db('org'); const b = writeBatch(o);
  b.update(doc(o, 'player_claims/p1_bob'), { status: 'approved', updated_at: serverTimestamp() });
  b.update(doc(o, 'phone_index/K1'), { user_id: 'bob', created_by: 'bob', updated_at: serverTimestamp() });
  b.delete(doc(o, 'users/p1'));
  await assertSucceeds(b.commit());
});
await check('approving twice is refused', () => assertFails(updateDoc(doc(db('org'), 'player_claims/p1_bob'), { status: 'approved' })));
await check('delete own account', () => assertSucceeds(deleteDoc(doc(db('carol'), 'users/carol'))));
await check('organizer merges own duplicate into a numbered player', async () => {
  const o = db('org');
  await assertSucceeds(setDoc(doc(o, 'users/p4'), { id: 'p4', name: 'Shankar', created_by: 'org' }));
  await assertSucceeds(setDoc(doc(o, 'phone_index/K4'), { user_id: 'p4', created_by: 'org', updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(db('alice'), 'teams/t1'), { team_players: [{ id: 'p2', role: 'player' }] }));
  await assertSucceeds(setDoc(doc(db('alice'), 'users/p2/user_stat/s'), { matches: 2 }));
  await assertSucceeds(deleteDoc(doc(o, 'users/p4')));
});
await check('a number left by a deleted player can be reused', async () => {
  const o = db('org'); const b = writeBatch(o);
  b.set(doc(o, 'users/p5'), { id: 'p5', name: 'Shankaran', created_by: 'org' });
  b.set(doc(o, 'phone_index/K4'), { user_id: 'p5', created_by: 'org', updated_at: serverTimestamp() });
  await assertSucceeds(b.commit());
});
await check('signed-up user takes back a freed own number', async () => {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'phone_index/KF'), { user_id: 'gone', created_by: 'org' }));
  await assertSucceeds(setDoc(doc(db('alice'), 'phone_index/KF'), { user_id: 'alice', created_by: 'alice', updated_at: serverTimestamp() }));
});

await seed();
await check('"Not me" saves a dismissed claim', () => assertSucceeds(setDoc(doc(db('bob'), 'player_claims/p1_bob'), claim('dismissed'))));
await seed();
await setDoc(doc(db('bob'), 'player_claims/p1_bob'), claim());
await check('organizer declines', () => assertSucceeds(updateDoc(doc(db('org'), 'player_claims/p1_bob'), { status: 'declined', updated_at: serverTimestamp() })));

// ── Attacks (must be refused) ──
await seed();
const m = db('mallory');
await check('edit someone else\'s account', () => assertFails(updateDoc(doc(m, 'users/alice'), { name: 'hacked' })));
await check('delete someone else\'s account', () => assertFails(deleteDoc(doc(m, 'users/alice'))));
await check('delete an organizer\'s added player', () => assertFails(deleteDoc(doc(m, 'users/p1'))));
await check('take over an added player (created_by)', () => assertFails(updateDoc(doc(m, 'users/p1'), { created_by: 'mallory' })));
await check('create player in someone else\'s name', () => assertFails(setDoc(doc(m, 'users/fake'), { id: 'fake', created_by: 'org' })));
await check('point a number at another account', () => assertFails(setDoc(doc(m, 'phone_index/KX'), { user_id: 'alice', created_by: 'mallory' })));
await check('point a number at someone else\'s player', () => assertFails(setDoc(doc(m, 'phone_index/KX'), { user_id: 'p1', created_by: 'mallory' })));
await check('add extra fields to a number entry', () => assertFails(setDoc(doc(m, 'phone_index/KM'), { user_id: 'mallory', created_by: 'mallory', phone: '+1' })));
await check('overwrite an existing number entry', () => assertFails(setDoc(doc(m, 'phone_index/K1'), { user_id: 'mallory', created_by: 'mallory' })));
await check('claim without the number', () => assertFails(setDoc(doc(m, 'player_claims/p1_mallory'), claim('pending', { id: 'p1_mallory', claimant_id: 'mallory', phone_key: 'WRONG' }))));
await check('claim naming yourself organizer', () => assertFails(setDoc(doc(m, 'player_claims/p1_mallory'), claim('pending', { id: 'p1_mallory', claimant_id: 'mallory', organizer_id: 'mallory' }))));
await check('claim filed as someone else', () => assertFails(setDoc(doc(m, 'player_claims/p1_bob'), claim())));
await check('claim created already approved', async () => {
  await assertFails(setDoc(doc(m, 'player_claims/p1_mallory'), claim('approved', { id: 'p1_mallory', claimant_id: 'mallory' })));
});
await check('read others\' claims', async () => {
  await setDoc(doc(db('bob'), 'player_claims/p1_bob'), claim());
  await assertFails(getDoc(doc(m, 'player_claims/p1_bob')));
});
await check('non-organizer approves', () => assertFails(updateDoc(doc(m, 'player_claims/p1_bob'), { status: 'approved' })));
await check('organizer edits claimant on approve', () => assertFails(updateDoc(doc(db('org'), 'player_claims/p1_bob'), { status: 'approved', claimant_id: 'org' })));
await check('organizer moves number without approved claim', () => assertFails(updateDoc(doc(db('org'), 'phone_index/K1'), { user_id: 'alice', created_by: 'alice' })));
await check('organizer moves number to someone with a pending claim', () => assertFails(updateDoc(doc(db('org'), 'phone_index/K1'), { user_id: 'bob', created_by: 'bob' })));
await check('non-admin writes auction player', () => assertFails(setDoc(doc(m, 'users/auction_A_x'), { id: 'auction_A_x', name: 'x', auction_id: 'A' })));
await check('move auction player to own auction', () => assertFails(updateDoc(doc(db('org'), 'users/auction_A_x'), { auction_id: 'B' })));
await check('guest creates a profile', () => assertFails(setDoc(doc(db('guest', 'anonymous'), 'users/guest'), { id: 'guest' })));
await check('take a number held by a live player', () => assertFails(setDoc(doc(m, 'phone_index/K1'), { user_id: 'mallory', created_by: 'mallory' })));
await check('point a freed number at someone else\'s player', async () => {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'phone_index/KD'), { user_id: 'gone', created_by: 'org' }));
  await assertFails(setDoc(doc(m, 'phone_index/KD'), { user_id: 'p1', created_by: 'mallory' }));
});
await check('list number index', async () => {
  const { getDocs } = await import('firebase/firestore');
  await assertFails(getDocs(collection(m, 'phone_index')));
});

console.log(`\n${passed} passed, ${failed} failed`);
await env.cleanup();
process.exit(failed ? 1 : 0);

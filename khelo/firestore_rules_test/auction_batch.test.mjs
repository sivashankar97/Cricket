import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, runTransaction } from 'firebase/firestore';
const env = await initializeTestEnvironment({ projectId: 'demo-khelo', firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url),'utf8'), host:'127.0.0.1', port:8080 }});
await env.withSecurityRulesDisabled(async c => {
  await setDoc(doc(c.firestore(), 'auctions/A'), { admin_ids:['org'], created_by:'org', status:'paused' });
  await setDoc(doc(c.firestore(), 'users/auction_A_5'), { id:'auction_A_5', auction_id:'A', name:'old' });
});
const db = env.authenticatedContext('org', { firebase:{ sign_in_provider:'password' }}).firestore();
try {
  await assertSucceeds(runTransaction(db, async tx => {
    tx.get(doc(db, 'auctions/A'));
    for (let i = 0; i < 160; i++) tx.set(doc(db, `users/auction_A_${i}`), { id:`auction_A_${i}`, auction_id:'A', name:'P'+i });
    tx.set(doc(db, 'teams/auction_A_t1'), { id:'t' });
  }));
  console.log('ok    160 auction players in one transaction');
} catch (e) { console.log('FAIL  big transaction -', e.message.split('\n')[0]); process.exitCode = 1; }
await env.cleanup();

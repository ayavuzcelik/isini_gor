// firestore.rules güvenlik kuralı testleri.
//
// Çalıştırmak için:  cd firestore_tests && npm test
// (Firestore emülatörünü kendisi başlatır, Java gerekir.)

const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

const OWNER = 'user-owner';
const OTHER = 'user-other';

let env;
let passed = 0;
let failed = 0;

async function it(name, fn) {
  try {
    await fn();
    console.log(`  ok  ${name}`);
    passed++;
  } catch (e) {
    console.error(`  FAIL ${name}\n       ${e.message}`);
    failed++;
  }
}

/// Kuralları atlayarak başlangıç verisi yazar.
async function seed(collection, id, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), collection, id), data);
  });
}

const baseJob = (overrides = {}) => ({
  userId: OWNER,
  title: 'Köpek gezdirme',
  description: 'Akşam yürüyüşü',
  address: 'Ankara',
  preferredDate: '2026-09-11T10:00:00.000',
  phone: '05550000000',
  status: 'pending',
  price: null,
  adminNote: null,
  rating: null,
  review: null,
  createdAt: '2026-09-10T10:00:00.000',
  updatedAt: '2026-09-10T10:00:00.000',
  timeline: [],
  ...overrides,
});

async function main() {
  env = await initializeTestEnvironment({
    projectId: 'isini-gor-test',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });

  const owner = env.authenticatedContext(OWNER).firestore();
  const other = env.authenticatedContext(OTHER).firestore();
  const anon = env.unauthenticatedContext().firestore();

  console.log('\njobs — okuma');
  await seed('jobs', 'j1', baseJob());
  await it('sahibi kendi işini okur', () =>
    assertSucceeds(getDoc(doc(owner, 'jobs', 'j1'))));
  await it('başkası okuyamaz', () =>
    assertFails(getDoc(doc(other, 'jobs', 'j1'))));
  await it('giriş yapmayan okuyamaz', () =>
    assertFails(getDoc(doc(anon, 'jobs', 'j1'))));

  console.log('\njobs — oluşturma');
  await it('kendi adına pending iş oluşturur', () =>
    assertSucceeds(setDoc(doc(owner, 'jobs', 'new1'), baseJob())));
  await it('başkasının adına iş oluşturamaz', () =>
    assertFails(setDoc(doc(owner, 'jobs', 'new2'), baseJob({ userId: OTHER }))));
  await it('fiyatı kendi belirleyerek iş oluşturamaz', () =>
    assertFails(setDoc(doc(owner, 'jobs', 'new3'), baseJob({ price: 1 }))));
  await it('doğrudan priced durumunda iş oluşturamaz', () =>
    assertFails(setDoc(doc(owner, 'jobs', 'new4'), baseJob({ status: 'priced' }))));

  console.log('\njobs — teklif kabul/red');
  await seed('jobs', 'priced1', baseJob({ status: 'priced', price: 1000 }));
  await it('teklifi kabul eder', () =>
    assertSucceeds(updateDoc(doc(owner, 'jobs', 'priced1'), { status: 'accepted' })));

  await seed('jobs', 'priced2', baseJob({ status: 'priced', price: 1000 }));
  await it('teklifi reddeder', () =>
    assertSucceeds(updateDoc(doc(owner, 'jobs', 'priced2'), { status: 'rejected' })));
  await it('başkası teklifi kabul edemez', () =>
    assertFails(updateDoc(doc(other, 'jobs', 'priced2'), { status: 'accepted' })));

  await seed('jobs', 'priced3', baseJob({ status: 'priced', price: 1000 }));
  await it('fiyatı değiştiremez', () =>
    assertFails(updateDoc(doc(owner, 'jobs', 'priced3'), { price: 1 })));
  await it('kendini completed yapamaz', () =>
    assertFails(updateDoc(doc(owner, 'jobs', 'priced3'), { status: 'completed' })));

  console.log('\njobs — puanlama');
  await seed('jobs', 'done1', baseJob({ status: 'completed', price: 1000 }));
  await it('tamamlanan işe puan verir', () =>
    assertSucceeds(
      updateDoc(doc(owner, 'jobs', 'done1'), {
        rating: 5,
        review: 'Harikaydı',
        updatedAt: '2026-09-10T12:00:00.000',
      }),
    ));
  await it('ikinci kez puan veremez', () =>
    assertFails(updateDoc(doc(owner, 'jobs', 'done1'), { rating: 1 })));

  await seed('jobs', 'done2', baseJob({ status: 'completed', price: 1000 }));
  await it('5 üstü puan veremez', () =>
    assertFails(updateDoc(doc(owner, 'jobs', 'done2'), { rating: 9 })));
  await it('puanla birlikte fiyatı değiştiremez', () =>
    assertFails(updateDoc(doc(owner, 'jobs', 'done2'), { rating: 5, price: 1 })));
  await it('başkasının işini puanlayamaz', () =>
    assertFails(updateDoc(doc(other, 'jobs', 'done2'), { rating: 5 })));

  await seed('jobs', 'open1', baseJob({ status: 'accepted', price: 1000 }));
  await it('tamamlanmamış işe puan veremez', () =>
    assertFails(updateDoc(doc(owner, 'jobs', 'open1'), { rating: 5 })));

  console.log('\njobs — silme');
  await it('iş silinemez', () =>
    assertFails(deleteDoc(doc(owner, 'jobs', 'j1'))));

  console.log('\nnotifications');
  await seed('notifications', 'n1', {
    userId: OWNER,
    jobId: 'j1',
    title: 'İşiniz tanımlandı',
    body: 'hazır',
    at: '2026-09-10T10:00:00.000',
    read: false,
  });
  await it('sahibi bildirimini okur', () =>
    assertSucceeds(getDoc(doc(owner, 'notifications', 'n1'))));
  await it('başkası bildirimi okuyamaz', () =>
    assertFails(getDoc(doc(other, 'notifications', 'n1'))));
  await it('okundu işaretler', () =>
    assertSucceeds(updateDoc(doc(owner, 'notifications', 'n1'), { read: true })));
  await it('bildirim metnini değiştiremez', () =>
    assertFails(updateDoc(doc(owner, 'notifications', 'n1'), { title: 'sahte' })));
  await it('kendine bildirim uyduramaz', () =>
    assertFails(
      setDoc(doc(owner, 'notifications', 'n2'), {
        userId: OWNER,
        jobId: 'j1',
        title: 'sahte',
        body: 'sahte',
        at: '2026-09-10T10:00:00.000',
        read: false,
      }),
    ));

  console.log('\nshowcase');
  await seed('showcase', 's1', {
    title: 'Köpek gezdirme',
    customerName: 'Elif K.',
    city: 'İstanbul',
    rating: 5,
    comment: 'Süper',
    price: 250,
    completedAt: '2026-09-10T10:00:00.000',
  });
  await it('giriş yapan herkes vitrini okur', () =>
    assertSucceeds(getDoc(doc(other, 'showcase', 's1'))));
  await it('giriş yapmayan vitrini okuyamaz', () =>
    assertFails(getDoc(doc(anon, 'showcase', 's1'))));
  await it('kullanıcı vitrine yazamaz', () =>
    assertFails(setDoc(doc(owner, 'showcase', 's2'), { title: 'sahte', rating: 5 })));

  await env.cleanup();

  console.log(`\n${passed} geçti, ${failed} başarısız`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

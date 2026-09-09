import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:isini_gor/main.dart';
import 'package:isini_gor/models/job.dart';
import 'package:isini_gor/services/auth_service.dart';
import 'package:isini_gor/services/job_repository.dart';

/// Giriş butonundaki spinner sonsuz döndüğü için burada pumpAndSettle
/// doğrudan kullanılamaz; önce sahte gecikmenin bitmesini bekliyoruz.
Future<void> signIn(WidgetTester tester) async {
  await tester.tap(find.text('Google ile devam et'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// signOut da gecikmeli bir future döndürüyor. Doğrudan await edilirse
/// sahte saat ilerlemediği için test kilitlenir; pump ile ilerletiyoruz.
Future<void> signOut(WidgetTester tester) async {
  unawaited(AuthService.instance.signOut());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // Demo otomatik fiyatlandırma testlerde arkada timer bırakmasın.
    JobRepository.demoAutoPricing = false;
  });

  testWidgets('açılışta Google ile giriş ekranı gelir', (tester) async {
    await tester.pumpWidget(const IsiniGorApp());

    expect(find.text('İşini Gör'), findsOneWidget);
    expect(find.text('Google ile devam et'), findsOneWidget);
  });

  test(
    'fiyat girilince iş onay bekler duruma geçer ve bildirim düşer',
    () async {
      final repo = JobRepository.instance;

      final job = await repo.createJob(
        userId: 'demo-user-1',
        title: 'Musluk tamiri',
        description: 'Mutfak musluğu damlatıyor.',
        address: 'Çankaya, Ankara',
        preferredDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(job.status, JobStatus.pending);

      final before = repo.notificationsFor('demo-user-1').length;
      await repo.setPrice(job.id, 1250, note: 'Montaj dahil.');

      final priced = repo.byId(job.id)!;
      expect(priced.status, JobStatus.priced);
      expect(priced.price, 1250);
      expect(priced.status.needsUserAction, isTrue);
      expect(repo.notificationsFor('demo-user-1').length, before + 1);
    },
  );

  test('kabul edilen iş accepted, reddedilen iş rejected olur', () async {
    final repo = JobRepository.instance;

    Future<Job> pricedJob(String title) async {
      final job = await repo.createJob(
        userId: 'demo-user-1',
        title: title,
        description: 'Lastik değişimi gerekiyor.',
        address: 'Çankaya, Ankara',
        preferredDate: DateTime.now().add(const Duration(days: 1)),
      );
      await repo.setPrice(job.id, 1450);
      return repo.byId(job.id)!;
    }

    final accepted = await pricedJob('Kabul edilecek iş');
    await repo.acceptOffer(accepted.id);
    expect(repo.byId(accepted.id)!.status, JobStatus.accepted);

    final rejected = await pricedJob('Reddedilecek iş');
    await repo.rejectOffer(rejected.id);
    expect(repo.byId(rejected.id)!.status, JobStatus.rejected);
    expect(repo.byId(rejected.id)!.status.isOpen, isFalse);
  });

  test('Job.toMap / fromMap Firestore gidiş-dönüşünü korur', () {
    final now = DateTime.now();
    final job = Job(
      id: 'job-1',
      userId: 'u1',
      title: 'Köpek gezdirme',
      description: 'Akşam yürüyüşü',
      address: 'Ankara',
      preferredDate: now,
      status: JobStatus.priced,
      price: 300,
      createdAt: now,
      updatedAt: now,
      timeline: [JobEvent(status: JobStatus.pending, at: now)],
    );

    final restored = Job.fromMap('job-1', job.toMap());

    expect(restored.title, job.title);
    expect(restored.status, job.status);
    expect(restored.price, job.price);
    expect(restored.timeline.length, 1);
  });

  testWidgets('iş detayında kabul et fiyat teklifini onaylar', (tester) async {
    await tester.pumpWidget(const IsiniGorApp());
    await signIn(tester);

    // Ana sayfadaki onay bekleyen seed iş kartına gir.
    await tester.tap(find.text('Kışlık lastik değişimi').first);
    await tester.pumpAndSettle();

    expect(find.text('Fiyat Teklifi'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Kabul Et'));
    await tester.pumpAndSettle();

    expect(
      JobRepository.instance.byId('job-seed-1')!.status,
      JobStatus.accepted,
    );

    // Onay SnackBar'ı kapanmadan test biterse "timer pending" hatası çıkar.
    await tester.pumpAndSettle(const Duration(seconds: 6));
    await signOut(tester);
  });
}

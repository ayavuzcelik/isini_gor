import 'package:flutter_test/flutter_test.dart';

import 'package:isini_gor/models/job.dart';

// Not: iş akışı ve ekran testleri artık Firebase'e bağlı olduğu için
// kaldırıldı. Firestore emülatörü kurulunca geri eklenecek.

void main() {
  test('Job.toMap / fromMap Firestore gidiş-dönüşünü korur', () {
    final now = DateTime.now();
    final job = Job(
      id: 'job-1',
      userId: 'u1',
      title: 'Köpek gezdirme',
      description: 'Akşam yürüyüşü',
      address: 'Ankara',
      preferredDate: now,
      phone: '05550000000',
      status: JobStatus.priced,
      price: 300,
      adminNote: 'Günlük 45 dakika.',
      createdAt: now,
      updatedAt: now,
      timeline: [JobEvent(status: JobStatus.pending, at: now)],
    );

    final restored = Job.fromMap('job-1', job.toMap());

    expect(restored.title, job.title);
    expect(restored.userId, job.userId);
    expect(restored.status, job.status);
    expect(restored.price, job.price);
    expect(restored.adminNote, job.adminNote);
    expect(restored.phone, job.phone);
    expect(restored.timeline.length, 1);
  });

  test('durum yardımcıları doğru sınıflandırır', () {
    expect(JobStatus.priced.needsUserAction, isTrue);
    expect(JobStatus.accepted.needsUserAction, isFalse);

    expect(JobStatus.pending.isOpen, isTrue);
    expect(JobStatus.inProgress.isOpen, isTrue);
    expect(JobStatus.completed.isOpen, isFalse);
    expect(JobStatus.rejected.isOpen, isFalse);
    expect(JobStatus.cancelled.isOpen, isFalse);
  });

  test('bilinmeyen durum adı pending olarak okunur', () {
    expect(JobStatus.fromName('bilinmeyen'), JobStatus.pending);
    expect(JobStatus.fromName(null), JobStatus.pending);
    expect(JobStatus.fromName('accepted'), JobStatus.accepted);
  });
}

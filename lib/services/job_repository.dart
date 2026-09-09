import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job.dart';

/// Kullanıcıya düşen bildirim (şimdilik uygulama içi).
class AppNotification {
  AppNotification({
    required this.id,
    required this.jobId,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
  });

  final String id;
  final String jobId;
  final String title;
  final String body;
  final DateTime at;
  bool read;
}

/// İş verisinin tek kaynağı.
///
/// Şimdilik bellekte tutuluyor. Firebase bağlanınca bu sınıfın gövdesi
/// Firestore `jobs` koleksiyonuna gidecek ([Job.toMap] / [Job.fromMap] hazır),
/// ekranlar değişmeyecek.
class JobRepository extends ChangeNotifier {
  JobRepository._() {
    _seed();
  }

  static final JobRepository instance = JobRepository._();

  final List<Job> _jobs = [];
  final List<AppNotification> _notifications = [];
  final Map<String, Timer> _pricingTimers = {};

  int _seq = 0;

  /// Admin paneli henüz olmadığı için, yeni talepler bu süre sonunda
  /// otomatik fiyatlanıp kullanıcıya bildirim düşüyor (demo amaçlı).
  /// Firebase + admin paneli gelince kapatılacak. Testler kapatabilsin diye
  /// `const` değil.
  static bool demoAutoPricing = true;
  static const Duration demoPricingDelay = Duration(seconds: 8);

  // ---------------------------------------------------------------- okuma

  List<Job> jobsFor(String userId) {
    final list = _jobs.where((j) => j.userId == userId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<Job> openJobsFor(String userId) =>
      jobsFor(userId).where((j) => j.status.isOpen).toList();

  List<Job> pastJobsFor(String userId) =>
      jobsFor(userId).where((j) => !j.status.isOpen).toList();

  /// Onay bekleyen (fiyat gelmiş) işler — ana sayfada öne çıkarılıyor.
  List<Job> awaitingActionFor(String userId) =>
      jobsFor(userId).where((j) => j.status.needsUserAction).toList();

  Job? byId(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  List<AppNotification> notificationsFor(String userId) {
    final jobIds = _jobs.where((j) => j.userId == userId).map((j) => j.id).toSet();
    final list =
        _notifications.where((n) => jobIds.contains(n.jobId)).toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  int unreadCountFor(String userId) =>
      notificationsFor(userId).where((n) => !n.read).length;

  void markNotificationsRead(String userId) {
    for (final n in notificationsFor(userId)) {
      n.read = true;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- yazma

  Future<Job> createJob({
    required String userId,
    required JobCategory category,
    required String title,
    required String description,
    required String address,
    required DateTime preferredDate,
    String? phone,
  }) async {
    // TODO(firebase): FirebaseFirestore.instance.collection('jobs').add(job.toMap())
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final job = Job(
      id: 'job-${++_seq}-${now.millisecondsSinceEpoch}',
      userId: userId,
      category: category,
      title: title,
      description: description,
      address: address,
      preferredDate: preferredDate,
      phone: phone,
      status: JobStatus.pending,
      createdAt: now,
      updatedAt: now,
      timeline: [
        JobEvent(
          status: JobStatus.pending,
          at: now,
          note: 'Talebin bize ulaştı.',
        ),
      ],
    );

    _jobs.add(job);
    notifyListeners();

    if (demoAutoPricing) {
      _scheduleDemoPricing(job.id);
    }
    return job;
  }

  /// Admin panelinden fiyat girildiğinde çalışacak akış.
  Future<void> setPrice(String jobId, double price, {String? note}) async {
    final job = byId(jobId);
    if (job == null || job.status != JobStatus.pending) return;

    _update(
      job.copyWith(
        status: JobStatus.priced,
        price: price,
        adminNote: note,
        timeline: [
          ...job.timeline,
          JobEvent(
            status: JobStatus.priced,
            at: DateTime.now(),
            note: note ?? 'İşin tanımlandı ve fiyatlandırıldı.',
          ),
        ],
      ),
    );

    // TODO(firebase): FCM push. Şimdilik uygulama içi bildirim.
    _pushNotification(
      jobId: jobId,
      title: 'İşiniz tanımlandı',
      body:
          '${job.title} için fiyat teklifi hazır. Onaylamak için dokun.',
    );
  }

  Future<void> acceptOffer(String jobId) async {
    final job = byId(jobId);
    if (job == null || !job.status.needsUserAction) return;

    _update(
      job.copyWith(
        status: JobStatus.accepted,
        timeline: [
          ...job.timeline,
          JobEvent(
            status: JobStatus.accepted,
            at: DateTime.now(),
            note: 'Teklifi onayladın.',
          ),
        ],
      ),
    );
  }

  Future<void> rejectOffer(String jobId) async {
    final job = byId(jobId);
    if (job == null || !job.status.needsUserAction) return;

    _update(
      job.copyWith(
        status: JobStatus.rejected,
        timeline: [
          ...job.timeline,
          JobEvent(
            status: JobStatus.rejected,
            at: DateTime.now(),
            note: 'Teklifi reddettin.',
          ),
        ],
      ),
    );
  }

  Future<void> cancelJob(String jobId) async {
    final job = byId(jobId);
    if (job == null || !job.status.isOpen) return;

    _pricingTimers.remove(jobId)?.cancel();
    _update(
      job.copyWith(
        status: JobStatus.cancelled,
        timeline: [
          ...job.timeline,
          JobEvent(
            status: JobStatus.cancelled,
            at: DateTime.now(),
            note: 'Talebi iptal ettin.',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- yardımcı

  void _update(Job job) {
    final index = _jobs.indexWhere((j) => j.id == job.id);
    if (index == -1) return;
    _jobs[index] = job;
    notifyListeners();
  }

  void _pushNotification({
    required String jobId,
    required String title,
    required String body,
  }) {
    _notifications.add(
      AppNotification(
        id: 'ntf-${_notifications.length + 1}',
        jobId: jobId,
        title: title,
        body: body,
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _scheduleDemoPricing(String jobId) {
    _pricingTimers[jobId] = Timer(demoPricingDelay, () {
      _pricingTimers.remove(jobId);
      final job = byId(jobId);
      if (job == null || job.status != JobStatus.pending) return;
      setPrice(
        jobId,
        _demoPriceFor(job.category),
        note: 'Ekibimiz talebini inceledi ve fiyatlandırdı.',
      );
    });
  }

  double _demoPriceFor(JobCategory category) => switch (category) {
        JobCategory.tire => 1450,
        JobCategory.carService => 3200,
        JobCategory.carWash => 750,
        JobCategory.dogWalking => 300,
        JobCategory.cleaning => 1800,
        JobCategory.plumbing => 1250,
        JobCategory.electric => 950,
        JobCategory.moving => 4500,
        JobCategory.other => 1000,
      };

  @override
  void dispose() {
    for (final timer in _pricingTimers.values) {
      timer.cancel();
    }
    _pricingTimers.clear();
    super.dispose();
  }

  /// Ekranlar boş görünmesin diye örnek veri.
  void _seed() {
    final now = DateTime.now();
    const userId = 'demo-user-1';

    _jobs.addAll([
      Job(
        id: 'job-seed-1',
        userId: userId,
        category: JobCategory.tire,
        title: 'Kışlık lastik değişimi',
        description:
            '4 adet kışlık lastiğim var, takılması ve balans ayarı gerekiyor.',
        address: 'Bahçelievler Mah. 32. Sk. No:5, Ankara',
        preferredDate: now.add(const Duration(days: 2)),
        phone: '0555 000 00 00',
        status: JobStatus.priced,
        price: 1450,
        adminNote: 'Balans ve montaj dahildir. Adresine geliyoruz.',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
        timeline: [
          JobEvent(
            status: JobStatus.pending,
            at: now.subtract(const Duration(hours: 5)),
            note: 'Talebin bize ulaştı.',
          ),
          JobEvent(
            status: JobStatus.priced,
            at: now.subtract(const Duration(minutes: 20)),
            note: 'İşin tanımlandı ve fiyatlandırıldı.',
          ),
        ],
      ),
      Job(
        id: 'job-seed-2',
        userId: userId,
        category: JobCategory.dogWalking,
        title: 'Köpeğimi akşam gezdirme',
        description:
            'Golden retriever, 3 yaşında. Hafta içi her akşam 19:00 civarı.',
        address: 'Çankaya, Ankara',
        preferredDate: now.add(const Duration(days: 1)),
        phone: '0555 000 00 00',
        status: JobStatus.accepted,
        price: 300,
        adminNote: 'Günlük 45 dakika yürüyüş.',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        timeline: [
          JobEvent(
            status: JobStatus.pending,
            at: now.subtract(const Duration(days: 1)),
            note: 'Talebin bize ulaştı.',
          ),
          JobEvent(
            status: JobStatus.priced,
            at: now.subtract(const Duration(hours: 6)),
            note: 'İşin tanımlandı ve fiyatlandırıldı.',
          ),
          JobEvent(
            status: JobStatus.accepted,
            at: now.subtract(const Duration(hours: 3)),
            note: 'Teklifi onayladın.',
          ),
        ],
      ),
      Job(
        id: 'job-seed-3',
        userId: userId,
        category: JobCategory.carService,
        title: 'Periyodik bakım',
        description: '40.000 km bakımı, yağ ve filtre değişimi.',
        address: 'Kızılay, Ankara',
        phone: '0555 000 00 00',
        preferredDate: now.subtract(const Duration(days: 12)),
        status: JobStatus.completed,
        price: 3200,
        adminNote: 'Bakım tamamlandı, faturası e-postana gönderildi.',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 12)),
        timeline: [
          JobEvent(
            status: JobStatus.pending,
            at: now.subtract(const Duration(days: 15)),
          ),
          JobEvent(
            status: JobStatus.priced,
            at: now.subtract(const Duration(days: 14)),
          ),
          JobEvent(
            status: JobStatus.accepted,
            at: now.subtract(const Duration(days: 14)),
          ),
          JobEvent(
            status: JobStatus.completed,
            at: now.subtract(const Duration(days: 12)),
            note: 'İş tamamlandı.',
          ),
        ],
      ),
    ]);

    _notifications.add(
      AppNotification(
        id: 'ntf-seed-1',
        jobId: 'job-seed-1',
        title: 'İşiniz tanımlandı',
        body: 'Kışlık lastik değişimi için fiyat teklifi hazır.',
        at: now.subtract(const Duration(minutes: 20)),
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/job.dart';

/// Kullanıcıya düşen bildirim.
class AppNotification {
  const AppNotification({
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
  final bool read;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        jobId: map['jobId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        at: DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime.now(),
        read: map['read'] as bool? ?? false,
      );
}

/// Firestore üzerindeki iş ve bildirim verisi.
///
/// `jobs` ve `notifications` koleksiyonları canlı dinlenir; admin panelinden
/// fiyat girildiği anda uygulama kendiliğinden güncellenir.
class JobRepository extends ChangeNotifier {
  JobRepository._();

  static final JobRepository instance = JobRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _db.collection('notifications');

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSub;

  List<Job> _jobs = [];
  List<AppNotification> _notifications = [];

  bool _loading = true;
  bool get loading => _loading;

  String? _userId;

  /// Oturum açan kullanıcı için canlı dinlemeyi başlatır.
  /// Kullanıcı değiştiğinde (veya çıkış yaptığında) yeniden çağrılır.
  void watchUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;

    _jobsSub?.cancel();
    _notificationsSub?.cancel();
    _jobs = [];
    _notifications = [];

    if (userId == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _jobsSub = _jobsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
            _jobs =
                snapshot.docs.map((d) => Job.fromMap(d.id, d.data())).toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            _loading = false;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('jobs dinlenemedi: $e');
            _loading = false;
            notifyListeners();
          },
        );

    _notificationsSub = _notificationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
            _notifications =
                snapshot.docs
                    .map((d) => AppNotification.fromMap(d.id, d.data()))
                    .toList()
                  ..sort((a, b) => b.at.compareTo(a.at));
            notifyListeners();
          },
          onError: (Object e) => debugPrint('bildirimler dinlenemedi: $e'),
        );
  }

  // ---------------------------------------------------------------- okuma

  List<Job> jobsFor(String userId) => _jobs;

  List<Job> openJobsFor(String userId) =>
      _jobs.where((j) => j.status.isOpen).toList();

  List<Job> pastJobsFor(String userId) =>
      _jobs.where((j) => !j.status.isOpen).toList();

  /// Onay bekleyen (fiyat gelmiş) işler — ana ekranda öne çıkarılıyor.
  List<Job> awaitingActionFor(String userId) =>
      _jobs.where((j) => j.status.needsUserAction).toList();

  Job? byId(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  List<AppNotification> notificationsFor(String userId) => _notifications;

  int unreadCountFor(String userId) =>
      _notifications.where((n) => !n.read).length;

  Future<void> markNotificationsRead(String userId) async {
    final unread = _notifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;

    final batch = _db.batch();
    for (final n in unread) {
      batch.update(_notificationsRef.doc(n.id), {'read': true});
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------- yazma

  Future<Job> createJob({
    required String userId,
    required String title,
    required String description,
    required String address,
    required DateTime preferredDate,
    String? phone,
  }) async {
    final now = DateTime.now();
    final job = Job(
      id: '',
      userId: userId,
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

    final data = job.toMap();
    final ref = await _jobsRef.add(data);
    return Job.fromMap(ref.id, data);
  }

  /// Admin panelinden fiyat girildiğinde çalışacak akış.
  Future<void> setPrice(String jobId, double price, {String? note}) async {
    final job = byId(jobId);
    if (job == null || job.status != JobStatus.pending) return;

    await _applyStatus(
      job,
      JobStatus.priced,
      note: note ?? 'İşin tanımlandı ve fiyatlandırıldı.',
      extra: {'price': price, 'adminNote': note},
    );

    await _notificationsRef.add({
      'userId': job.userId,
      'jobId': jobId,
      'title': 'İşiniz tanımlandı',
      'body': '${job.title} için fiyat teklifi hazır. Onaylamak için dokun.',
      'at': DateTime.now().toIso8601String(),
      'read': false,
    });
  }

  Future<void> acceptOffer(String jobId) async {
    final job = byId(jobId);
    if (job == null || !job.status.needsUserAction) return;
    await _applyStatus(job, JobStatus.accepted, note: 'Teklifi onayladın.');
  }

  Future<void> rejectOffer(String jobId) async {
    final job = byId(jobId);
    if (job == null || !job.status.needsUserAction) return;
    await _applyStatus(job, JobStatus.rejected, note: 'Teklifi reddettin.');
  }

  Future<void> cancelJob(String jobId) async {
    final job = byId(jobId);
    if (job == null || !job.status.isOpen) return;
    await _applyStatus(job, JobStatus.cancelled, note: 'Talebi iptal ettin.');
  }

  // ------------------------------------------------------------- yardımcı

  Future<void> _applyStatus(
    Job job,
    JobStatus status, {
    String? note,
    Map<String, dynamic> extra = const {},
  }) async {
    final now = DateTime.now();
    final timeline = [
      ...job.timeline,
      JobEvent(status: status, at: now, note: note),
    ];

    await _jobsRef.doc(job.id).update({
      'status': status.name,
      'updatedAt': now.toIso8601String(),
      'timeline': timeline.map((e) => e.toMap()).toList(),
      ...extra,
    });
  }

  @override
  void dispose() {
    _jobsSub?.cancel();
    _notificationsSub?.cancel();
    super.dispose();
  }
}

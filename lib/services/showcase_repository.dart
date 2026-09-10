import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/showcase_job.dart';

/// Herkese açık vitrin: son tamamlanan işler, puanları ve yorumları.
///
/// Ana ekrandaki kayan şerit ile "Daha önce yapılan işler" bölümünü besler.
/// Kullanıcının kendi işlerinden bağımsızdır; giriş yapan herkes okur,
/// kimse yazamaz (yazma admin tarafına ait).
class ShowcaseRepository extends ChangeNotifier {
  ShowcaseRepository._();

  static final ShowcaseRepository instance = ShowcaseRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<ShowcaseJob> _items = [];
  List<ShowcaseJob> get items => _items;

  bool _loading = true;
  bool get loading => _loading;

  /// En yeni tamamlananlar önce.
  void start({int limit = 40}) {
    if (_sub != null) return;

    _sub = _db
        .collection('showcase')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .listen(
          (snapshot) {
            _items = snapshot.docs
                .map((d) => ShowcaseJob.fromMap(d.id, d.data()))
                .toList();
            _loading = false;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('vitrin dinlenemedi: $e');
            _loading = false;
            notifyListeners();
          },
        );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _items = [];
    _loading = true;
  }

  /// Vitrindeki işlerin ortalama puanı — başlıkta güven göstergesi olarak.
  double get averageRating {
    if (_items.isEmpty) return 0;
    final total = _items.fold<double>(0, (acc, e) => acc + e.rating);
    return total / _items.length;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

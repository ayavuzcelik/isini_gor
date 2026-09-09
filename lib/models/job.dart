/// İş akışındaki durumlar.
///
/// pending    -> kullanıcı işi oluşturdu, admin henüz fiyat girmedi
/// priced     -> admin fiyat girdi, kullanıcıdan onay bekleniyor (kabul/reddet)
/// accepted   -> kullanıcı fiyatı kabul etti, ekip atanacak
/// inProgress -> iş yapılıyor
/// completed  -> iş bitti
/// rejected   -> kullanıcı fiyatı reddetti
/// cancelled  -> kullanıcı işi iptal etti
enum JobStatus {
  pending,
  priced,
  accepted,
  inProgress,
  completed,
  rejected,
  cancelled;

  static JobStatus fromName(String? value) => JobStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => JobStatus.pending,
      );
}

extension JobStatusX on JobStatus {
  String get label => switch (this) {
        JobStatus.pending => 'Talep Alındı',
        JobStatus.priced => 'Fiyat Teklifi Geldi',
        JobStatus.accepted => 'Onaylandı',
        JobStatus.inProgress => 'Devam Ediyor',
        JobStatus.completed => 'Tamamlandı',
        JobStatus.rejected => 'Reddedildi',
        JobStatus.cancelled => 'İptal Edildi',
      };

  String get description => switch (this) {
        JobStatus.pending => 'Talebini aldık. Ekibimiz fiyatlandırma yapıyor.',
        JobStatus.priced =>
          'İşin tanımlandı ve fiyatlandırıldı. Onayını bekliyoruz.',
        JobStatus.accepted =>
          'Teklifi onayladın. Ekibimiz en kısa sürede seninle ilgilenecek.',
        JobStatus.inProgress => 'Ekibimiz işin üzerinde çalışıyor.',
        JobStatus.completed => 'İş başarıyla tamamlandı.',
        JobStatus.rejected =>
          'Teklifi reddettin. Dilersen yeni bir talep oluşturabilirsin.',
        JobStatus.cancelled => 'Bu talep iptal edildi.',
      };

  /// Kullanıcının kabul/reddet kararı vermesi gereken durum.
  bool get needsUserAction => this == JobStatus.priced;

  /// Hâlâ süren bir iş mi (İşlerim ekranındaki Aktif/Geçmiş ayrımı).
  bool get isOpen => switch (this) {
        JobStatus.pending ||
        JobStatus.priced ||
        JobStatus.accepted ||
        JobStatus.inProgress =>
          true,
        JobStatus.completed || JobStatus.rejected || JobStatus.cancelled =>
          false,
      };

  /// Durum çubuğundaki ilerleme (0..1). Sonlanan işlerde dolu gösterilir.
  double get progress => switch (this) {
        JobStatus.pending => 0.25,
        JobStatus.priced => 0.5,
        JobStatus.accepted => 0.7,
        JobStatus.inProgress => 0.85,
        JobStatus.completed => 1,
        JobStatus.rejected || JobStatus.cancelled => 1,
      };
}

enum JobCategory {
  tire,
  carService,
  carWash,
  dogWalking,
  cleaning,
  plumbing,
  electric,
  moving,
  other;

  static JobCategory fromName(String? value) => JobCategory.values.firstWhere(
        (e) => e.name == value,
        orElse: () => JobCategory.other,
      );
}

extension JobCategoryX on JobCategory {
  String get label => switch (this) {
        JobCategory.tire => 'Lastik Değişimi',
        JobCategory.carService => 'Araç Bakımı',
        JobCategory.carWash => 'Araç Yıkama',
        JobCategory.dogWalking => 'Köpek Gezdirme',
        JobCategory.cleaning => 'Ev Temizliği',
        JobCategory.plumbing => 'Tesisat',
        JobCategory.electric => 'Elektrik',
        JobCategory.moving => 'Nakliye',
        JobCategory.other => 'Diğer',
      };

  String get hint => switch (this) {
        JobCategory.tire => 'Yazlık/kışlık lastik değişimi, balans, rot ayarı',
        JobCategory.carService => 'Periyodik bakım, yağ ve filtre değişimi',
        JobCategory.carWash => 'Adresinde detaylı iç-dış yıkama',
        JobCategory.dogWalking => 'Günlük yürüyüş ve dışarı çıkarma',
        JobCategory.cleaning => 'Genel temizlik, detaylı temizlik',
        JobCategory.plumbing => 'Tıkanıklık, sızıntı, musluk ve tesisat işleri',
        JobCategory.electric => 'Priz, aydınlatma, arıza tespiti',
        JobCategory.moving => 'Evden eve veya parça eşya taşıma',
        JobCategory.other => 'Aklındaki başka bir iş',
      };
}

/// İşin geçmişindeki tek bir olay (durum değişimi).
class JobEvent {
  const JobEvent({required this.status, required this.at, this.note});

  final JobStatus status;
  final DateTime at;
  final String? note;

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'at': at.toIso8601String(),
        'note': note,
      };

  factory JobEvent.fromMap(Map<String, dynamic> map) => JobEvent(
        status: JobStatus.fromName(map['status'] as String?),
        at: DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime.now(),
        note: map['note'] as String?,
      );
}

class Job {
  const Job({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.address,
    required this.preferredDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.price,
    this.adminNote,
    this.timeline = const [],
  });

  final String id;
  final String userId;
  final JobCategory category;
  final String title;
  final String description;
  final String address;
  final DateTime preferredDate;
  final String? phone;

  final JobStatus status;

  /// Admin panelinden girilen fiyat (TL). Fiyat girilmeden önce null.
  final double? price;

  /// Admin'in fiyatla birlikte bıraktığı not.
  final String? adminNote;

  final DateTime createdAt;
  final DateTime updatedAt;
  final List<JobEvent> timeline;

  Job copyWith({
    JobStatus? status,
    double? price,
    String? adminNote,
    DateTime? updatedAt,
    List<JobEvent>? timeline,
  }) {
    return Job(
      id: id,
      userId: userId,
      category: category,
      title: title,
      description: description,
      address: address,
      preferredDate: preferredDate,
      phone: phone,
      status: status ?? this.status,
      price: price ?? this.price,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      timeline: timeline ?? this.timeline,
    );
  }

  /// Firestore'a yazarken kullanılacak gösterim.
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'category': category.name,
        'title': title,
        'description': description,
        'address': address,
        'preferredDate': preferredDate.toIso8601String(),
        'phone': phone,
        'status': status.name,
        'price': price,
        'adminNote': adminNote,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'timeline': timeline.map((e) => e.toMap()).toList(),
      };

  factory Job.fromMap(String id, Map<String, dynamic> map) => Job(
        id: id,
        userId: map['userId'] as String? ?? '',
        category: JobCategory.fromName(map['category'] as String?),
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        address: map['address'] as String? ?? '',
        preferredDate:
            DateTime.tryParse(map['preferredDate'] as String? ?? '') ??
                DateTime.now(),
        phone: map['phone'] as String?,
        status: JobStatus.fromName(map['status'] as String?),
        price: (map['price'] as num?)?.toDouble(),
        adminNote: map['adminNote'] as String?,
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
        updatedAt:
            DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
                DateTime.now(),
        timeline: (map['timeline'] as List?)
                ?.map((e) => JobEvent.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

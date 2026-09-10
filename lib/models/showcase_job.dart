/// Herkese açık "vitrin" kaydı: tamamlanmış bir işin anonimleştirilmiş hâli.
///
/// `jobs` koleksiyonundan ayrı tutuluyor, çünkü orada müşterinin adresi ve
/// telefonu var; vitrin ise tüm kullanıcılara okutuluyor. Buraya yalnızca
/// gösterilmesinde sakınca olmayan alanlar yazılır.
class ShowcaseJob {
  const ShowcaseJob({
    required this.id,
    required this.title,
    required this.customerName,
    required this.city,
    required this.rating,
    required this.completedAt,
    this.comment,
    this.price,
  });

  final String id;

  /// "Köpek gezdirme", "Mobilya montajı" gibi.
  final String title;

  /// Kısaltılmış ad: "Ayşe K." — tam ad hiç yazılmaz.
  final String customerName;
  final String city;

  /// 1..5
  final double rating;
  final String? comment;
  final double? price;
  final DateTime completedAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'customerName': customerName,
    'city': city,
    'rating': rating,
    'comment': comment,
    'price': price,
    'completedAt': completedAt.toIso8601String(),
  };

  factory ShowcaseJob.fromMap(String id, Map<String, dynamic> map) =>
      ShowcaseJob(
        id: id,
        title: map['title'] as String? ?? '',
        customerName: map['customerName'] as String? ?? '',
        city: map['city'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        comment: map['comment'] as String?,
        price: (map['price'] as num?)?.toDouble(),
        completedAt:
            DateTime.tryParse(map['completedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

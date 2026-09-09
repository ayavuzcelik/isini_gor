import 'package:flutter/material.dart';

import '../models/job.dart';

/// Durum ve kategorilerin görsel karşılıkları.
/// Modeller saf Dart kalsın diye renk/ikon burada tutuluyor.

extension JobStatusUi on JobStatus {
  Color get color => switch (this) {
        JobStatus.pending => const Color(0xFF8A8F98),
        JobStatus.priced => const Color(0xFFF59E0B),
        JobStatus.accepted => const Color(0xFF2F5BFF),
        JobStatus.inProgress => const Color(0xFF7C3AED),
        JobStatus.completed => const Color(0xFF16A34A),
        JobStatus.rejected => const Color(0xFFDC2626),
        JobStatus.cancelled => const Color(0xFF64748B),
      };

  IconData get icon => switch (this) {
        JobStatus.pending => Icons.hourglass_top_rounded,
        JobStatus.priced => Icons.local_offer_rounded,
        JobStatus.accepted => Icons.check_circle_rounded,
        JobStatus.inProgress => Icons.handyman_rounded,
        JobStatus.completed => Icons.verified_rounded,
        JobStatus.rejected => Icons.cancel_rounded,
        JobStatus.cancelled => Icons.block_rounded,
      };
}

extension JobCategoryUi on JobCategory {
  IconData get icon => switch (this) {
        JobCategory.tire => Icons.tire_repair_rounded,
        JobCategory.carService => Icons.car_repair_rounded,
        JobCategory.carWash => Icons.local_car_wash_rounded,
        JobCategory.dogWalking => Icons.pets_rounded,
        JobCategory.cleaning => Icons.cleaning_services_rounded,
        JobCategory.plumbing => Icons.plumbing_rounded,
        JobCategory.electric => Icons.electrical_services_rounded,
        JobCategory.moving => Icons.local_shipping_rounded,
        JobCategory.other => Icons.more_horiz_rounded,
      };

  Color get color => switch (this) {
        JobCategory.tire => const Color(0xFF334155),
        JobCategory.carService => const Color(0xFF2F5BFF),
        JobCategory.carWash => const Color(0xFF0EA5E9),
        JobCategory.dogWalking => const Color(0xFFF97316),
        JobCategory.cleaning => const Color(0xFF14B8A6),
        JobCategory.plumbing => const Color(0xFF6366F1),
        JobCategory.electric => const Color(0xFFEAB308),
        JobCategory.moving => const Color(0xFF8B5CF6),
        JobCategory.other => const Color(0xFF64748B),
      };
}

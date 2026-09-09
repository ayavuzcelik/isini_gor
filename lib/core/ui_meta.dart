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

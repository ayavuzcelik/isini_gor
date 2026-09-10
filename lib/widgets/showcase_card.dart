import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/showcase_job.dart';
import 'rating_stars.dart';

/// "Daha önce yapılan işler" bölümündeki yorum kartı.
class ShowcaseCard extends StatelessWidget {
  const ShowcaseCard({super.key, required this.job});

  final ShowcaseJob job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık tek satıra sığmıyor: iki satır hakkı var, fiyat da
          // yanında sıkışmasın diye alt satırda puanın yanında duruyor.
          Text(
            job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingStars(rating: job.rating, size: 15, showValue: true),
              const Spacer(),
              if (job.price != null)
                Text(
                  formatPrice(job.price!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (job.comment != null && job.comment!.isNotEmpty)
            Expanded(
              child: Text(
                '“${job.comment!}”',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  job.customerName.isEmpty
                      ? '?'
                      : job.customerName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${job.customerName} · ${job.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                formatRelative(job.completedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

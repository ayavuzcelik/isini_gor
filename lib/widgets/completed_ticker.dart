import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/formatters.dart';
import '../models/showcase_job.dart';
import 'rating_stars.dart';

/// Sürekli sola kayan "az önce tamamlandı" şeridi.
///
/// Amaç: kullanıcı uygulamayı açtığında ne tür işler verilebildiğini
/// hiç düşünmeden görsün. Dekoratif olduğu için elle kaydırılamaz.
class CompletedTicker extends StatefulWidget {
  const CompletedTicker({super.key, required this.items});

  final List<ShowcaseJob> items;

  @override
  State<CompletedTicker> createState() => _CompletedTickerState();
}

class _CompletedTickerState extends State<CompletedTicker>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;

  /// Saniyede kaç piksel — okunacak kadar yavaş.
  static const _pixelsPerSecond = 28.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_controller.hasClients) {
      _last = elapsed;
      return;
    }

    final dt = (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;
    if (dt <= 0) return;

    final max = _controller.position.maxScrollExtent;
    var next = _controller.offset + _pixelsPerSecond * dt;
    // Liste sonsuz olduğu için maxScrollExtent'e dayanınca başa sarıyoruz.
    if (max > 0 && next >= max) next = 0;
    _controller.jumpTo(next);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 62,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Şerit hiç bitmesin diye listeyi tekrar tekrar dolaşıyoruz.
        itemCount: widget.items.length * 20,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) =>
            _TickerPill(job: widget.items[i % widget.items.length]),
      ),
    );
  }
}

class _TickerPill extends StatelessWidget {
  const _TickerPill({required this.job});

  final ShowcaseJob job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0x1A16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  RatingStars(rating: job.rating, size: 11),
                  const SizedBox(width: 6),
                  Text(
                    '${job.city} · ${formatRelative(job.completedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

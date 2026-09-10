import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/ui_meta.dart';
import '../services/auth_service.dart';
import '../services/job_repository.dart';
import 'job_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = JobRepository.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = AuthService.instance.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          ListenableBuilder(
            listenable: _repo,
            builder: (context, _) {
              if (_repo.unreadCountFor(userId) == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => _repo.markNotificationsRead(userId),
                child: const Text('Tümünü okundu işaretle'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          final items = _repo.notificationsFor(userId);

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 46,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Henüz bildirim yok',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'İşin tanımlandığında ve fiyatlandığında burada göreceksin.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = items[i];
              final job = _repo.byId(n.jobId);
              final color = job?.status.color ?? theme.colorScheme.primary;

              return Material(
                color: n.read
                    ? theme.colorScheme.surface
                    : color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _repo.markNotificationsRead(userId);
                    if (job != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(jobId: job.id),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: n.read
                            ? theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.6,
                              )
                            : color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            job?.status.icon ?? Icons.notifications_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: n.read
                                                ? FontWeight.w600
                                                : FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatRelative(n.at),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

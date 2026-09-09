import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/job_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthService.instance;
    final repo = JobRepository.instance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profil')),
      body: ListenableBuilder(
        listenable: Listenable.merge([auth, repo]),
        builder: (context, _) {
          final user = auth.user;
          if (user == null) return const SizedBox.shrink();

          final all = repo.jobsFor(user.id);
          final open = repo.openJobsFor(user.id).length;
          final done = all.length - open;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (user.phone != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.phone!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Aktif iş',
                      value: '$open',
                      icon: Icons.pending_actions_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      label: 'Geçmiş iş',
                      value: '$done',
                      icon: Icons.history_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    _Tile(
                      icon: Icons.location_on_outlined,
                      title: 'Adreslerim',
                      onTap: () => _soon(context),
                    ),
                    _Tile(
                      icon: Icons.payment_rounded,
                      title: 'Ödeme yöntemleri',
                      onTap: () => _soon(context),
                    ),
                    _Tile(
                      icon: Icons.notifications_outlined,
                      title: 'Bildirim ayarları',
                      onTap: () => _soon(context),
                    ),
                    _Tile(
                      icon: Icons.help_outline_rounded,
                      title: 'Yardım ve destek',
                      onTap: () => _soon(context),
                      last: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Çıkış yap'),
                      content: const Text(
                        'Hesabından çıkmak istediğine emin misin?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Vazgeç'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(100, 44),
                          ),
                          child: const Text('Çıkış yap'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  // Profil ekranı ana sayfanın üstünde duruyor; çıkmadan
                  // önce kapatmazsak giriş ekranı arkada kalır.
                  if (context.mounted) Navigator.of(context).pop();
                  await auth.signOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış Yap'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bu bölüm yakında.')));
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
        if (!last)
          Divider(
            height: 1,
            indent: 56,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

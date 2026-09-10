import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/auth_service.dart';
import '../services/job_repository.dart';
import '../widgets/job_card.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Uygulamanın ana ekranı: kullanıcının işleri.
/// Sağ üstte zil (bildirimler) ve avatar (profil) var; alt menü yok.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthService.instance;
    final repo = JobRepository.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([auth, repo]),
      builder: (context, _) {
        final user = auth.user;
        final userId = user?.id ?? '';
        final awaiting = repo.awaitingActionFor(userId);
        // Onay bekleyenler yukarıda ayrı gösteriliyor; burada tekrar etmesin.
        final ongoing = repo
            .openJobsFor(userId)
            .where((j) => !j.status.needsUserAction)
            .toList();
        final past = repo.pastJobsFor(userId);
        final unread = repo.unreadCountFor(userId);

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Başlık: selamlama + zil + avatar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Merhaba,',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                user?.name ?? 'Misafir',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Bildirimler',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                          icon: Badge(
                            isLabelVisible: unread > 0,
                            label: Text('$unread'),
                            child: const Icon(Icons.notifications_outlined),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Profil',
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                user?.initials ?? '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // İşini tanımla
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _CreateJobHero(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateJobScreen(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Onayını bekleyenler
                if (awaiting.isNotEmpty) ...[
                  _Header(
                    'Onayını bekleyen ${awaiting.length} iş',
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _JobSliver(jobs: awaiting),
                ],

                // Devam edenler
                const _Header('Devam eden işlerin'),
                if (ongoing.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyBox(
                        title: 'Henüz açık işin yok',
                        subtitle:
                            'Yukarıdaki alandan işini tarif et, gerisini biz halledelim.',
                      ),
                    ),
                  )
                else
                  _JobSliver(jobs: ongoing),

                // Geçmiş
                if (past.isNotEmpty) ...[
                  const _Header('Geçmiş'),
                  _JobSliver(jobs: past),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JobSliver extends StatelessWidget {
  const _JobSliver({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: JobCard(
          job: jobs[i],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(jobId: jobs[i].id),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ana sayfadaki "işini tanımla" alanı — uygulamanın tek giriş noktası.
class _CreateJobHero extends StatelessWidget {
  const _CreateJobHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, const Color(0xFF1B2A6B)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ne yaptırmak istiyorsun?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İşini birkaç satırda anlat, sana özel fiyat teklifini '
                'hazırlayıp bildirelim.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF1F2430),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'İşini tanımla',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1F2430),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Color(0xFF1F2430),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 38,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

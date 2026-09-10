import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/job.dart';
import '../models/showcase_job.dart';
import '../services/auth_service.dart';
import '../services/job_repository.dart';
import '../services/showcase_repository.dart';
import '../widgets/completed_ticker.dart';
import '../widgets/job_card.dart';
import '../widgets/rating_stars.dart';
import '../widgets/showcase_card.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Uygulamanın ana ekranı: kullanıcının işleri + topluluk vitrini.
/// Sağ üstte zil (bildirimler) ve avatar (profil) var; alt menü yok.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final repo = JobRepository.instance;
    final showcase = ShowcaseRepository.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([auth, repo, showcase]),
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
        final feed = showcase.items;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => showcase.start(),
            child: CustomScrollView(
              slivers: [
                _Greeting(user: user, unread: unread),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _CreateJobHero(
                      averageRating: showcase.averageRating,
                      completedCount: feed.length,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateJobScreen(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Anlık tamamlananlar şeridi
                if (feed.isNotEmpty) ...[
                  const _Header(
                    'Şu anda tamamlananlar',
                    icon: Icons.bolt_rounded,
                    color: Color(0xFF16A34A),
                    topPadding: 26,
                  ),
                  SliverToBoxAdapter(child: CompletedTicker(items: feed)),
                ],

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
                if (ongoing.isNotEmpty) ...[
                  const _Header('Devam eden işlerin'),
                  _JobSliver(jobs: ongoing),
                ],

                // Geçmiş
                if (past.isNotEmpty) ...[
                  const _Header('Geçmiş işlerin'),
                  _JobSliver(jobs: past),
                ],

                // Topluluk vitrini
                if (feed.isNotEmpty) ...[
                  const _Header(
                    'Daha önce yapılan işler',
                    icon: Icons.workspace_premium_rounded,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 4),
                      child: Text(
                        'Gerçek kullanıcıların puanları ve yorumları.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _ShowcaseRow(items: feed)),
                ],

                if (awaiting.isEmpty && ongoing.isEmpty && past.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: _EmptyBox(),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.unread});

  final AppUser? user;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
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

class _ShowcaseRow extends StatelessWidget {
  const _ShowcaseRow({required this.items});

  final List<ShowcaseJob> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => ShowcaseCard(job: items[i]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.icon, this.color, this.topPadding = 30});

  final String text;
  final IconData? icon;
  final Color? color;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: color ?? theme.colorScheme.primary),
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
  const _CreateJobHero({
    required this.onTap,
    required this.averageRating,
    required this.completedCount,
  });

  final VoidCallback onTap;
  final double averageRating;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B6BFF), Color(0xFF16215C)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F5BFF).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
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
                'Köpek gezdirmekten mobilya montajına, kuyruk beklemekten '
                'özel derse kadar — işini yaz, fiyatını gönderelim.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
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
              if (completedCount > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    RatingStars(rating: averageRating, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${averageRating.toStringAsFixed(1)} ortalama · '
                        '$completedCount tamamlanan iş',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz bir işin yok',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yukarıdaki alandan işini tarif et, gerisini biz halledelim.',
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

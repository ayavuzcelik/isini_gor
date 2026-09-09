import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/auth_service.dart';
import '../services/job_repository.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = JobRepository.instance;
    final userId = AuthService.instance.user?.id ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('İşlerim'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: repo,
          builder: (context, _) {
            return TabBarView(
              children: [
                _JobList(
                  jobs: repo.openJobsFor(userId),
                  emptyTitle: 'Aktif işin yok',
                  emptySubtitle:
                      'Yeni bir talep oluşturduğunda burada görünecek.',
                ),
                _JobList(
                  jobs: repo.pastJobsFor(userId),
                  emptyTitle: 'Geçmiş iş yok',
                  emptySubtitle:
                      'Tamamlanan ve kapanan işlerin burada listelenir.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.jobs,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<Job> jobs;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 46,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => JobCard(
        job: jobs[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(jobId: jobs[i].id),
          ),
        ),
      ),
    );
  }
}

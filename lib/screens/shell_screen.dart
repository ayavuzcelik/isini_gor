import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/job_repository.dart';
import 'create_job_screen.dart';
import 'home_tab.dart';
import 'my_jobs_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Giriş sonrası ana iskelet: alt sekmeler + "İş oluştur" butonu.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final _repo = JobRepository.instance;
  final _auth = AuthService.instance;

  int _index = 0;

  Future<void> _createJob() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateJobScreen()),
    );
    if (created == true && mounted) {
      setState(() => _index = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.user?.id ?? '';

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final unread = _repo.unreadCountFor(userId);

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              HomeTab(onCreateJob: _createJob),
              const MyJobsScreen(),
              const NotificationsScreen(),
              const ProfileScreen(),
            ],
          ),
          floatingActionButton: _index == 0 || _index == 1
              ? FloatingActionButton.extended(
                  onPressed: _createJob,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('İş Oluştur'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa',
              ),
              const NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: 'İşlerim',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_rounded),
                ),
                label: 'Bildirimler',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}

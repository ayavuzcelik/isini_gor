import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/job_repository.dart';

void main() {
  // TODO(firebase): WidgetsFlutterBinding.ensureInitialized();
  //                 await Firebase.initializeApp(...);
  runApp(const IsiniGorApp());
}

class IsiniGorApp extends StatelessWidget {
  const IsiniGorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İşini Gör',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const _AuthGate(),
    );
  }
}

/// Oturum durumuna göre giriş ekranı ya da uygulama iskeleti.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (!AuthService.instance.isSignedIn) {
          return const LoginScreen();
        }
        return const _NotificationWatcher(child: HomeScreen());
      },
    );
  }
}

/// Uygulama açıkken yeni bildirim düştüğünde üstte banner gösterir.
/// FCM bağlanınca burası push mesajlarını dinleyecek.
class _NotificationWatcher extends StatefulWidget {
  const _NotificationWatcher({required this.child});

  final Widget child;

  @override
  State<_NotificationWatcher> createState() => _NotificationWatcherState();
}

class _NotificationWatcherState extends State<_NotificationWatcher> {
  final _repo = JobRepository.instance;
  late int _lastUnread = _currentUnread;

  int get _currentUnread =>
      _repo.unreadCountFor(AuthService.instance.user?.id ?? '');

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    final unread = _currentUnread;
    if (unread > _lastUnread) {
      final userId = AuthService.instance.user?.id ?? '';
      final latest = _repo.notificationsFor(userId).firstOrNull;
      if (latest != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  latest.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(latest.body),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    _lastUnread = unread;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

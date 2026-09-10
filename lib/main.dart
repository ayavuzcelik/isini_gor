import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/google_config.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/job_repository.dart';
import 'services/showcase_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.init(serverClientId: googleServerClientId);
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

/// Oturum durumuna göre giriş ekranı ya da ana ekran.
/// Ayrıca oturum değiştikçe Firestore dinleyicisini o kullanıcıya bağlar.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.user;

        // Build sırasında repo'yu değiştirmeyelim; kareden sonra bağla.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          JobRepository.instance.watchUser(user?.id);
          if (user != null) {
            ShowcaseRepository.instance.start();
          } else {
            ShowcaseRepository.instance.stop();
          }
        });

        if (user == null) return const LoginScreen();
        return const _NotificationWatcher(child: HomeScreen());
      },
    );
  }
}

/// Uygulama açıkken yeni bildirim düştüğünde alt tarafta uyarı gösterir.
/// FCM eklenince buraya push mesajları da bağlanacak.
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

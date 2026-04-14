import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/services/auth_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/features/track/track_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use cached user first
    final cached = AuthService.instance.currentUser;
    if (cached != null) {
      setState(() {
        _user = cached;
        _loading = false;
      });
    }
    // Then refresh from API if logged in
    if (AuthService.instance.isLoggedIn) {
      try {
        final fresh = await _api.getMe();
        if (mounted)
          setState(() {
            _user = fresh['user'] as Map<String, dynamic>? ?? fresh;
            _loading = false;
          });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.instance.logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Column(
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildMenuSection(context),
                          const SizedBox(height: 20),
                          _buildLogoutBtn(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppShadows.sm,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.sub),
            ),
          ),
          const SizedBox(width: 14),
          const Text('Mon profil',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final name = _user?['name'] as String? ?? 'Utilisateur anonyme';
    final email = _user?['email'] as String? ?? '';
    final role = _user?['role'] as String? ?? 'citoyen';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E4A), Color(0xFF0D1117)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC8143E), Color(0xFF8C0C2A)],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x30B5103C), blurRadius: 20),
              ],
            ),
            child: isLoggedIn
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  )
                : const Icon(Icons.person_rounded,
                    size: 32, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(email,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6))),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              _roleLabel(role),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5),
            ),
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Se connecter',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'ADMINISTRATEUR';
      case 'conseiller':
        return 'CONSEILLER';
      case 'professionnel':
        return 'PROFESSIONNEL';
      default:
        return 'CITOYEN';
    }
  }

  Widget _buildMenuSection(BuildContext context) {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final role = _user?['role'] as String? ?? 'citoyen';
    final isPro = role == 'admin' || role == 'conseiller' || role == 'professionnel';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('ACCÈS RAPIDE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.muted)),
        ),
        _MenuTile(
          icon: Icons.track_changes_rounded,
          label: 'Suivre mon dossier',
          sub: 'Consulter l\'état de mes signalements',
          color: AppColors.info,
          bg: AppColors.infoLight,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TrackScreen()),
          ),
        ),
        _MenuTile(
          icon: Icons.notifications_rounded,
          label: 'Annonces',
          sub: 'Informations et alertes de MARA',
          color: AppColors.warning,
          bg: AppColors.warningLight,
          onTap: () => context.push('/notifications'),
        ),
        _MenuTile(
          icon: Icons.library_books_rounded,
          label: 'Ressources',
          sub: 'Guides · Lois · Articles',
          color: AppColors.purple,
          bg: AppColors.purpleLight,
          onTap: () => context.push('/resources'),
        ),
        _MenuTile(
          icon: Icons.explore_rounded,
          label: 'Observatoire',
          sub: 'Données humanitaires ReliefWeb',
          color: AppColors.success,
          bg: AppColors.successLight,
          onTap: () => context.push('/observatory'),
        ),
        if (isLoggedIn && isPro) ...[
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('ESPACE PROFESSIONNEL',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.muted)),
          ),
          _MenuTile(
            icon: Icons.dashboard_rounded,
            label: 'Tableau de bord',
            sub: 'Signalements · Conversations · Stats',
            color: AppColors.primary,
            bg: AppColors.primarySurface,
            onTap: () => context.push('/counselor'),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoutBtn() {
    if (!AuthService.instance.isLoggedIn) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Se déconnecter',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Menu tile ─────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.title)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

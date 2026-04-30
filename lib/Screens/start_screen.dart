// =============================================================================
// StartScreen — Dashboard principale con selezione livello scolastico
// =============================================================================
//
// Schermata principale dell'app dopo il login. Tre sezioni accessibili
// tramite AppSidebar: Dashboard, Gruppi (placeholder), Impostazioni.
//
// Dashboard include:
//   - Banner di benvenuto con gradiente brand
//   - Statistiche di utilizzo (oggi, totale, argomento più cercato)
//   - Carosello BookSelectionWidget per scegliere il livello
//   - Descrizione livello con AnimatedSwitcher
//   - Pulsante "ApprenderAI" animato (pulse) per confermare e aprire il libro
//
// Classe esportata: StartScreen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_enums.dart';
import '../utils/app_stats.dart';
import '../config/app_theme.dart';
import '../utils/user_preferences.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/book_selection_widget.dart';
import '../widgets/common/app_spacing.dart';

/// Dashboard principale: selezione livello, statistiche, impostazioni.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  SidebarRoute _currentRoute = SidebarRoute.dashboard;
  SchoolLevel _selectedLevel = SchoolLevel.media;
  late PageController _carouselController;

  int _todayOpens = 0;
  int _totalSessions = 0;
  String? _mostSearchedTopic;
  String? _userEmail;

  String _selectedLanguage = 'Italiano';
  bool _notificationsEnabled = true;

  String get _selectedTheme =>
      ThemeNotifier.stringFromMode(themeNotifier.value);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _carouselController =
        PageController(viewportFraction: 0.42, initialPage: 0);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await AppStats.recordSessionOpen();
    final today = await AppStats.getTodayOpenCount();
    final total = await AppStats.getTotalSessions();
    final topic = await AppStats.getMostSearchedTopic();
    final email = await UserPreferences.getUserEmail();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _todayOpens = today;
        _totalSessions = total;
        _mostSearchedTopic = topic;
        _userEmail = email;
        _selectedLanguage =
            prefs.getString('setting_language') ?? 'Italiano';
        _notificationsEnabled =
            prefs.getBool('setting_notifications') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _onConfirm() async {
    await UserPreferences.saveSchoolLevel(_selectedLevel);
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/lesson',
      arguments: {'schoolLevel': _selectedLevel.routeArgument},
    );
  }

  void _onSidebarNavigate(SidebarRoute route) {
    setState(() => _currentRoute = route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            currentRoute: _currentRoute,
            onNavigate: _onSidebarNavigate,
          ),
          Expanded(child: _buildCenterContent()),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    switch (_currentRoute) {
      case SidebarRoute.dashboard:
        return _buildDashboard();
      case SidebarRoute.groups:
        return _buildGroupsPlaceholder();
      case SidebarRoute.settings:
        return _buildSettings();
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  Widget _buildDashboard() {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: AppSpacing.xl),
          _buildStatsRow(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Seleziona il tuo livello',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Scorri per scegliere il libro più adatto a te',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCarousel(),
          const SizedBox(height: AppSpacing.xl),
          _buildLevelDescription(),
          const SizedBox(height: AppSpacing.xxl),
          Center(child: _buildConfirmButton()),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFAD46FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userEmail != null
                      ? 'Bentornato, ${_userEmail!.split('@').first}!'
                      : 'Benvenuto su ApprenderAI!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scegli il tuo livello di studio e inizia ad apprendere',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.today_outlined,
            iconColor: const Color(0xFF6366F1),
            label: 'Aperture oggi',
            value: '$_todayOpens',
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _StatCard(
            icon: Icons.search_outlined,
            iconColor: const Color(0xFFAD46FF),
            label: 'Argomento più cercato',
            value: _mostSearchedTopic ?? '—',
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _StatCard(
            icon: Icons.bar_chart_outlined,
            iconColor: const Color(0xFF00B8DB),
            label: 'Sessioni totali',
            value: '$_totalSessions',
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 480,
      child: PageView.builder(
        controller: _carouselController,
        itemCount: SchoolLevel.values.length,
        onPageChanged: (i) {
          setState(() => _selectedLevel = SchoolLevel.values[i]);
        },
        itemBuilder: (context, i) {
          final level = SchoolLevel.values[i];
          final isSelected = _selectedLevel == level;
          return Center(
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 0.78,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.55,
                duration: const Duration(milliseconds: 300),
                child: BookSelectionWidget(
                  isSelected: isSelected,
                  bookColor: level.color,
                  label: level.displayName,
                  onTap: () {
                    _carouselController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelDescription() {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey(_selectedLevel),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _selectedLevel.color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _selectedLevel.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline,
                  color: _selectedLevel.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLevel.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _selectedLevel.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedLevel.levelDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pulsante di conferma con animazione pulse e gradiente brand cyan→purple.
  Widget _buildConfirmButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _pulseAnimation.value, child: child),
      child: GestureDetector(
        onTap: _onConfirm,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: AppSpacing.huge),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B8DB), Color(0xFFAD46FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            'ApprenderAI',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Gruppi placeholder
  // ---------------------------------------------------------------------------

  Widget _buildGroupsPlaceholder() {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, size: 72, color: cs.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Presto disponibile!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'I gruppi di studio sono in arrivo.\nPotrai collaborare con altri studenti del tuo livello.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: cs.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Impostazioni
  // ---------------------------------------------------------------------------

  Widget _buildSettings() {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impostazioni',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          _SectionHeader('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person, color: cs.primary, size: 20),
                  ),
                  title: const Text('Utente',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(_userEmail ?? 'Ospite'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.lock_outline, color: cs.primary),
                  title: const Text('Cambia password'),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 20),
                  onTap: () => _showInfoDialog(
                    'Cambia password',
                    'La modifica della password è disponibile nella versione con autenticazione completa.',
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.sync_outlined, color: cs.primary),
                  title: const Text('Cambia livello scolastico'),
                  subtitle: Text(_selectedLevel.displayName),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 20),
                  onTap: () =>
                      setState(() => _currentRoute = SidebarRoute.dashboard),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Esci / Cambia profilo',
                      style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Torna alla schermata di accesso'),
                  onTap: () async {
                    await UserPreferences.clearLoginState();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _SectionHeader('Generali'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined,
                      color: Color(0xFF00B8DB)),
                  title: const Text('Tema'),
                  trailing: _DropdownSetting(
                    value: _selectedTheme,
                    items: const ['Sistema', 'Chiaro', 'Scuro'],
                    onChanged: (v) {
                      themeNotifier.setTheme(v);
                      setState(() {});
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.language_outlined,
                      color: Color(0xFF00B8DB)),
                  title: const Text('Lingua'),
                  trailing: _DropdownSetting(
                    value: _selectedLanguage,
                    items: const ['Italiano', 'English'],
                    onChanged: (v) {
                      setState(() => _selectedLanguage = v);
                      _saveSetting('setting_language', v);
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined,
                      color: Color(0xFF00B8DB)),
                  title: const Text('Notifiche'),
                  subtitle: const Text('Promemoria e aggiornamenti'),
                  value: _notificationsEnabled,
                  onChanged: (v) {
                    setState(() => _notificationsEnabled = v);
                    _saveSetting('setting_notifications', v);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: Color(0xFF00B8DB)),
                  title: const Text('Versione app'),
                  trailing: Text(
                    'v1.0.0',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _SectionHeader('Privacy & Sicurezza'),
          Card(
            child: Column(
              children: [
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.download_outlined,
                      color: Color(0xFFAD46FF)),
                  title: const Text('Scarica i tuoi dati'),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 20),
                  onTap: () => _showInfoDialog(
                    'Scarica i tuoi dati',
                    'La richiesta di esportazione dei dati è disponibile nella versione completa dell\'app.',
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined,
                      color: Colors.red),
                  title: const Text('Cancella tutti i tuoi dati',
                      style: TextStyle(color: Colors.red)),
                  subtitle: const Text(
                      'Elimina account e dati permanentemente'),
                  onTap: () => _showDeleteAllDataDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _SectionHeader('Info Legali'),
          Card(
            child: Column(
              children: [
                _SubHeader('Documenti Legali'),
                ListTile(
                  leading: Icon(Icons.article_outlined,
                      color: cs.onSurfaceVariant),
                  title: const Text('Termini di servizio'),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 20),
                  onTap: () => _showLegalDialog(
                    'Termini di Servizio',
                    'Utilizzando ApprenderAI accetti i presenti Termini di Servizio. '
                        'Il servizio è fornito "così com\'è" a scopo educativo. '
                        'Versione 1.0 — Aprile 2026.',
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined,
                      color: cs.onSurfaceVariant),
                  title: const Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 20),
                  onTap: () => _showLegalDialog(
                    'Privacy Policy',
                    'ApprenderAI raccoglie esclusivamente i dati necessari al funzionamento dell\'app. '
                        'Non vendiamo né condividiamo i tuoi dati con terze parti. '
                        'Versione 1.0 — Aprile 2026.',
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.cookie_outlined,
                      color: cs.onSurfaceVariant),
                  title: const Text('Cookie Policy'),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 20),
                  onTap: () => _showLegalDialog(
                    'Cookie Policy',
                    'ApprenderAI non utilizza cookie di terze parti né cookie di profilazione. '
                        'Vengono utilizzati esclusivamente dati locali (SharedPreferences). '
                        'Versione 1.0 — Aprile 2026.',
                  ),
                ),
                _SubHeader('Licenze'),
                ListTile(
                  leading: Icon(Icons.folder_open_outlined,
                      color: cs.onSurfaceVariant),
                  title: const Text('Licenze open source'),
                  trailing: Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 20),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'ApprenderAI',
                    applicationVersion: '1.0.0',
                  ),
                ),
                _SubHeader('Società'),
                const ListTile(
                  leading: Icon(Icons.business_outlined),
                  title: Text('Inforelea Academy'),
                  subtitle: Text(
                    'ApprenderAI v1.0.0\nsimone.colomba@inforelea.academy',
                  ),
                  isThreeLine: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: AppSpacing.sm),
            Text('Cancella tutti i dati',
                style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'Questa azione eliminerà permanentemente il tuo account, '
          'le statistiche di utilizzo e tutte le preferenze salvate. '
          'Non sarà possibile annullare questa operazione.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStats.clearStats();
              await UserPreferences.clearLoginState();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Elimina tutto',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatCard — card statistica nella dashboard
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader — intestazione sezione nelle impostazioni
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SubHeader — sotto-intestazione nelle card legali
// ---------------------------------------------------------------------------

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withOpacity(0.7),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DropdownSetting — dropdown per le impostazioni
// ---------------------------------------------------------------------------

class _DropdownSetting extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownSetting({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      dropdownColor: cs.surface,
      style: TextStyle(fontSize: 13, color: cs.onSurface),
      icon: Icon(Icons.expand_more, color: cs.onSurfaceVariant, size: 18),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: TextStyle(color: cs.onSurface)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

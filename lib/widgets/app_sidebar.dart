// =============================================================================
// AppSidebar — Barra di navigazione laterale dell'app
// =============================================================================
//
// Sidebar fissa sul lato sinistro presente in StartScreen e LessonScreen.
// Mostra il logo, le voci di navigazione (Dashboard, Gruppi, Impostazioni)
// e il nome/versione dell'app in fondo.
//
// Le voci di navigazione sono gestite tramite l'enum [SidebarRoute].
// Il widget è completamente stateless: la voce selezionata viene passata
// dall'esterno tramite [currentRoute], e i cambi vengono notificati
// tramite [onNavigate].
//
// Tutti i colori vengono dal tema corrente (light/dark) — nessun colore
// hardcoded.
//
// Usato in: StartScreen, LessonScreen
// =============================================================================

import 'package:flutter/material.dart';

/// Rotte disponibili nella sidebar.
enum SidebarRoute { dashboard, groups, settings }

/// Sidebar di navigazione laterale.
class AppSidebar extends StatelessWidget {
  /// Rotta attualmente selezionata (evidenziata nella sidebar).
  final SidebarRoute currentRoute;

  /// Callback invocata quando l'utente tap su una voce.
  final ValueChanged<SidebarRoute> onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  /// Larghezza fissa della sidebar.
  static const double width = 220;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.07,
            ),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
        border: Border(
          right: BorderSide(color: cs.outline, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 28),
            child: Image.asset(
              'assets/image/logo.png',
              height: 88,
              errorBuilder: (_, __, ___) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, color: cs.primary, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'ApprenderAI',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Nav items ────────────────────────────────────────────────────
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: currentRoute == SidebarRoute.dashboard,
            onTap: () => onNavigate(SidebarRoute.dashboard),
          ),
          _NavItem(
            icon: Icons.group_outlined,
            label: 'Gruppi',
            selected: currentRoute == SidebarRoute.groups,
            onTap: () => onNavigate(SidebarRoute.groups),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Impostazioni',
            selected: currentRoute == SidebarRoute.settings,
            onTap: () => onNavigate(SidebarRoute.settings),
          ),

          const Spacer(),

          // ── App name + version ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ApprenderAI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NavItem — Singola voce di navigazione
// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

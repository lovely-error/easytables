import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: l10n.closeSettings,
                onPressed: onClose,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settings,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.settingsSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsSection(
                        icon: Icons.palette_outlined,
                        title: l10n.appearanceSection,
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                l10n.themeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SegmentedButton<ThemeMode>(
                                segments: [
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    icon: const Icon(
                                      Icons.light_mode_outlined,
                                      size: 17,
                                    ),
                                    label: Text(l10n.lightLabel),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    icon: const Icon(
                                      Icons.dark_mode_outlined,
                                      size: 17,
                                    ),
                                    label: Text(l10n.darkLabel),
                                  ),
                                ],
                                selected: {state.themeMode},
                                showSelectedIcon: false,
                                onSelectionChanged: (selection) {
                                  state.setThemeMode(selection.first);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SettingsSection(
                        icon: Icons.language_rounded,
                        title: l10n.languageSection,
                        children: [
                          Text(
                            l10n.interfaceLanguageLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'en',
                                label: Text(l10n.englishLabel),
                              ),
                              ButtonSegment(
                                value: 'ru',
                                label: Text(l10n.russianLabel),
                              ),
                            ],
                            selected: {state.languageCode},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              state.setLanguage(selection.first);
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.languageHint,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SettingsSection(
                        icon: Icons.storage_outlined,
                        title: l10n.dataSection,
                        children: [
                          Text(
                            l10n.dataDescription,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${l10n.tablesCount(state.tables.length)} · '
                            '${l10n.rowsCount(state.totalRows)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SettingsSection(
                        icon: Icons.payments_outlined,
                        title: l10n.currencyRatesTitle,
                        children: [
                          Text(
                            l10n.currencyRatesHint,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SettingsSection(
                        icon: Icons.info_outline_rounded,
                        title: l10n.aboutSection,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.grid_view_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.appName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.aboutDescription,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: panelDecoration(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

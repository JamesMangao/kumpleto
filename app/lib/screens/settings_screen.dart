import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../data/data_repository.dart';
import '../data/providers.dart';
import '../data/update_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/shared.dart';
import 'scaffold_with_nav.dart';

/// Settings matching mockup 755d0ba7-c506-4045-8831-f5f2650566a8.jpg.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _checking = false;
  String? _updateMessage;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  Future<void> _checkForUpdates() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _checking = true;
      _updateMessage = null;
    });
    final result = await ref.read(updateServiceProvider).checkNow();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _updateMessage = switch (result) {
        UpdateAccepted() => l10n.settingsUpdateDone,
        UpdateNotModified() => l10n.settingsUpToDate,
        UpdateInvalid(:final reason) || UpdateFailed(:final reason) =>
          l10n.settingsUpdateFailed(reason),
      };
    });
    if (result is UpdateAccepted) ref.invalidate(loadedDataProvider);
  }

  Future<void> _resetProgress() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsResetTitle),
        content: Text(l10n.settingsResetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(progressRepositoryProvider).resetAll();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsProgressReset)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = widget.settings;
    final loaded = ref.watch(loadedDataProvider);

    final prefs = ref.watch(sharedPreferencesProvider);
    final lastCheck = prefs.getInt(PrefsKeys.lastDataCheck);

    return Scaffold(
      appBar: unofficialAppBar(context, l10n.appTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Screen Title & Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Customize your experience and manage your data.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Section 1: Language
            _SectionLabel(l10n.settingsLanguage),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SquircleIcon(
                            icon: Icons.language,
                            size: 36,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.settingsLanguage,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Choose your preferred language.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'en',
                              label: Text(l10n.languageEnglish),
                            ),
                            ButtonSegment(
                              value: 'fil',
                              label: Text(l10n.languageFilipino),
                            ),
                            ButtonSegment(
                              value: 'system',
                              label: Text(l10n.languageSystem),
                            ),
                          ],
                          selected: {settings.language},
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppTheme.primaryTeal,
                            selectedForegroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2C3E35)
                                  : const Color(0xFFD4E3DC),
                            ),
                          ),
                          onSelectionChanged: (selection) =>
                              settings.setLanguage(selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Section 2: Theme
            _SectionLabel(l10n.settingsAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SquircleIcon(
                            icon: Icons.wb_sunny_outlined,
                            size: 36,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Choose how the app looks.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l10n.settingsThemeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l10n.settingsThemeDark),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l10n.settingsThemeSystem),
                            ),
                          ],
                          selected: {settings.themeMode},
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppTheme.primaryTeal,
                            selectedForegroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2C3E35)
                                  : const Color(0xFFD4E3DC),
                            ),
                          ),
                          onSelectionChanged: (selection) =>
                              settings.setThemeMode(selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Section 3: Content Data & Legal Grouped Card
            _SectionLabel(l10n.settingsData),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    // Data Version Item
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: loaded.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => Text('$error'),
                        data: (loadedData) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SquircleIcon(
                                  icon: Icons.sync,
                                  size: 36,
                                  iconSize: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Row(
                                        label: l10n.settingsDataVersion,
                                        value: loadedData.data.dataVersion,
                                      ),
                                      const SizedBox(height: 4),
                                      _Row(
                                        label: l10n.settingsDataSource,
                                        value: switch (loadedData.source) {
                                          DataSource.bundledRelease => 'Bundled',
                                          DataSource.bundledDrafts => 'Bundled (drafts)',
                                          DataSource.cache => 'Cached update',
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastCheck == null
                                            ? l10n.settingsNeverChecked
                                            : l10n.settingsLastChecked(
                                                DateTime.fromMillisecondsSinceEpoch(
                                                  lastCheck,
                                                ).toLocal().toString().replaceAll('T', ' '),
                                              ),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: _checking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync, size: 18),
                                label: Text(_checking
                                    ? l10n.settingsChecking
                                    : l10n.settingsCheckForUpdates),
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: _checking ? null : _checkForUpdates,
                              ),
                            ),
                            if (_updateMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _updateMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Reset Progress Item
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const SquircleIcon(
                        icon: Icons.restart_alt,
                        size: 36,
                        iconSize: 20,
                        backgroundColor: AppTheme.statusRedBg,
                        iconColor: AppTheme.statusRedText,
                      ),
                      title: Text(
                        l10n.settingsResetProgress,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.statusRedText,
                        ),
                      ),
                      subtitle: const Text('This will clear all your checklist progress.'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: _resetProgress,
                    ),

                    const Divider(height: 1),

                    // App Version Item
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const SquircleIcon(
                        icon: Icons.phone_android_outlined,
                        size: 36,
                        iconSize: 20,
                      ),
                      title: Text(
                        l10n.settingsAppVersion(
                          _appVersion.isEmpty ? '1.0.0' : _appVersion,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                    ),

                    const Divider(height: 1),

                    // About / Learn more
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const SquircleIcon(
                        icon: Icons.info_outline,
                        size: 36,
                        iconSize: 20,
                      ),
                      title: Text(
                        l10n.settingsAbout,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Learn more about Kumpleto.'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => openExternal(context, repositoryUri()),
                    ),

                    const Divider(height: 1),

                    // Disclaimer Item
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const SquircleIcon(
                        icon: Icons.warning_amber_outlined,
                        size: 36,
                        iconSize: 20,
                      ),
                      title: Text(
                        l10n.settingsDisclaimer,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Important information and limitations.'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => openExternal(
                        context,
                        Uri.https(
                          'github.com',
                          '/$repoOwner/$repoName/blob/main/DISCLAIMER.md',
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Privacy Item
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const SquircleIcon(
                        icon: Icons.shield_outlined,
                        size: 36,
                        iconSize: 20,
                      ),
                      title: Text(
                        l10n.settingsPrivacy,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('How we handle your data.'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => openExternal(
                        context,
                        Uri.https(
                          'github.com',
                          '/$repoOwner/$repoName/blob/main/PRIVACY.md',
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Open-Source Licenses Item
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const SquircleIcon(
                        icon: Icons.code,
                        size: 36,
                        iconSize: 20,
                      ),
                      title: Text(
                        l10n.settingsLicenses,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('View the licenses for used libraries.'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: appDisplayName,
                        applicationVersion: _appVersion,
                      ),
                    ),

                    const Divider(height: 1),

                    // GitHub Source Code Item
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const SquircleIcon(
                        icon: Icons.terminal_rounded,
                        size: 36,
                        iconSize: 20,
                      ),
                      title: const Text(
                        'GitHub',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(l10n.settingsSourceCode),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => openExternal(context, repositoryUri()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (value.isEmpty) {
      return Text(label, style: theme.textTheme.bodyMedium);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

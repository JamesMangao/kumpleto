import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants.dart';
import '../core/settings.dart';
import '../data/data_repository.dart';
import '../data/providers.dart';
import '../data/update_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/shared.dart';
import 'scaffold_with_nav.dart';

/// Settings: language, theme, data version + manual update check, reset
/// progress, and the about/legal links.
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
    final settings = widget.settings;
    final loaded = ref.watch(loadedDataProvider);

    final prefs = ref.watch(sharedPreferencesProvider);
    final lastCheck = prefs.getInt(PrefsKeys.lastDataCheck);

    return Scaffold(
      appBar: unofficialAppBar(context, l10n.settingsTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _Header(l10n.settingsLanguage),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'system',
                    label: Text(l10n.languageSystem),
                  ),
                  ButtonSegment(
                    value: 'en',
                    label: Text(l10n.languageEnglish),
                  ),
                  ButtonSegment(
                    value: 'fil',
                    label: Text(l10n.languageFilipino),
                  ),
                ],
                selected: {settings.language},
                onSelectionChanged: (selection) =>
                    settings.setLanguage(selection.first),
              ),
            ),
            _Header(l10n.settingsAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsThemeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsThemeDark),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) =>
                    settings.setThemeMode(selection.first),
              ),
            ),
            _Header(l10n.settingsData),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        _Row(
                          label: l10n.settingsDataVersion,
                          value: loadedData.data.dataVersion,
                        ),
                        const SizedBox(height: 8),
                        _Row(
                          label: l10n.settingsDataSource,
                          value: switch (loadedData.source) {
                            DataSource.bundledRelease => 'Bundled',
                            DataSource.bundledDrafts => 'Bundled (drafts)',
                            DataSource.cache => 'Cached update',
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lastCheck == null
                              ? l10n.settingsNeverChecked
                              : l10n.settingsLastChecked(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    lastCheck,
                                  ).toLocal().toString().replaceAll('T', ' '),
                                ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                icon: _checking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync),
                                label: Text(_checking
                                    ? l10n.settingsChecking
                                    : l10n.settingsCheckForUpdates),
                                onPressed: _checking
                                    ? null
                                    : _checkForUpdates,
                              ),
                            ),
                          ],
                        ),
                        if (_updateMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _updateMessage!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _Header(l10n.settingsResetProgress),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: Text(l10n.settingsResetProgress),
                  onTap: _resetProgress,
                ),
              ),
            ),
            _Header(l10n.settingsAbout),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(
                        l10n.settingsAppVersion(
                          _appVersion.isEmpty ? '—' : _appVersion,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(l10n.settingsDisclaimer),
                      onTap: () => openExternal(
                        context,
                        Uri.https(
                          'github.com',
                          '/$repoOwner/$repoName/blob/main/DISCLAIMER.md',
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(l10n.settingsPrivacy),
                      onTap: () => openExternal(
                        context,
                        Uri.https(
                          'github.com',
                          '/$repoOwner/$repoName/blob/main/PRIVACY.md',
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: Text(l10n.settingsSourceCode),
                      onTap: () => openExternal(context, repositoryUri()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.collections_bookmark_outlined),
                      title: Text(l10n.settingsLicenses),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: appDisplayName,
                        applicationVersion: _appVersion,
                      ),
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

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/providers/settings_provider.dart';

/// Settings screen – mirrors the RN app settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                constraints.maxWidth >= AppTheme.tabletBreakpoint;
            final padding = isWide
                ? EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.15,
                    vertical: AppTheme.spaceMd,
                  )
                : const EdgeInsets.all(0);

            return ListView(
              padding: padding,
              children: [
                _SectionHeader(label: 'Audio Quality'),
                // Stream quality
                ListTile(
                  title: const Text('Stream Quality'),
                  subtitle: const Text('Quality used when streaming over network'),
                  trailing: _QualityDropdown(
                    value: settings.streamQuality,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setStreamQuality(v!),
                  ),
                ),
                // Download quality
                ListTile(
                  title: const Text('Download Quality'),
                  subtitle: const Text('Quality for saved offline files'),
                  trailing: _QualityDropdown(
                    value: settings.downloadQuality,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setDownloadQuality(v!),
                  ),
                ),
                const Divider(),
                _SectionHeader(label: 'Downloads'),
                SwitchListTile(
                  title: const Text('Wi-Fi Only Downloads'),
                  subtitle: const Text('Only download lessons on Wi-Fi'),
                  value: settings.wifiOnlyDownloads,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setWifiOnlyDownloads(v),
                ),
                SwitchListTile(
                  title: const Text('Auto-Delete Finished Lessons'),
                  subtitle: const Text(
                      'Automatically remove downloaded audio after finishing'),
                  value: settings.autoDeleteFinished,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setAutoDeleteFinished(v),
                ),
                const Divider(),
                _SectionHeader(label: 'Privacy'),
                SwitchListTile(
                  title: const Text('Anonymous Usage Data'),
                  subtitle: const Text(
                      'Help improve the app by sharing anonymous usage statistics'),
                  value: settings.collectMetrics,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setCollectMetrics(v),
                ),
                const Divider(),
                _SectionHeader(label: 'About'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Language Transfer'),
                  subtitle: const Text(
                      'Free language courses. Visit languagetransfer.org'),
                  onTap: () {},
                ),
                const SizedBox(height: AppTheme.spaceLg),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spaceMd,
        top: AppTheme.spaceMd,
        bottom: AppTheme.spaceSm,
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _QualityDropdown extends StatelessWidget {
  const _QualityDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      dropdownColor: AppTheme.cardColor,
      items: const [
        DropdownMenuItem(value: 'high', child: Text('High')),
        DropdownMenuItem(value: 'low', child: Text('Low')),
      ],
      onChanged: onChanged,
    );
  }
}

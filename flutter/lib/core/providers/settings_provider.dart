import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// ---------------------------------------------------------------------------
// App Settings
// ---------------------------------------------------------------------------

class AppSettings {
  const AppSettings({
    this.streamQuality = 'high',
    this.downloadQuality = 'high',
    this.wifiOnlyDownloads = false,
    this.autoDeleteFinished = false,
    this.collectMetrics = false,
  });

  final String streamQuality; // 'high' | 'low'
  final String downloadQuality; // 'high' | 'low'
  final bool wifiOnlyDownloads;
  final bool autoDeleteFinished;
  final bool collectMetrics;

  AppSettings copyWith({
    String? streamQuality,
    String? downloadQuality,
    bool? wifiOnlyDownloads,
    bool? autoDeleteFinished,
    bool? collectMetrics,
  }) {
    return AppSettings(
      streamQuality: streamQuality ?? this.streamQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      autoDeleteFinished: autoDeleteFinished ?? this.autoDeleteFinished,
      collectMetrics: collectMetrics ?? this.collectMetrics,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final storage = StorageService.instance;
    return AppSettings(
      streamQuality:
          storage.getPreference<String>('streamQuality') ?? 'high',
      downloadQuality:
          storage.getPreference<String>('downloadQuality') ?? 'high',
      wifiOnlyDownloads:
          storage.getPreference<bool>('wifiOnlyDownloads') ?? false,
      autoDeleteFinished:
          storage.getPreference<bool>('autoDeleteFinished') ?? false,
      collectMetrics:
          storage.getPreference<bool>('collectMetrics') ?? false,
    );
  }

  Future<void> _save(AppSettings settings) async {
    final s = StorageService.instance;
    await s.setPreference('streamQuality', settings.streamQuality);
    await s.setPreference('downloadQuality', settings.downloadQuality);
    await s.setPreference('wifiOnlyDownloads', settings.wifiOnlyDownloads);
    await s.setPreference(
        'autoDeleteFinished', settings.autoDeleteFinished);
    await s.setPreference('collectMetrics', settings.collectMetrics);
    state = AsyncValue.data(settings);
  }

  Future<void> setStreamQuality(String quality) async {
    final current = state.valueOrNull ?? const AppSettings();
    await _save(current.copyWith(streamQuality: quality));
  }

  Future<void> setDownloadQuality(String quality) async {
    final current = state.valueOrNull ?? const AppSettings();
    await _save(current.copyWith(downloadQuality: quality));
  }

  Future<void> setWifiOnlyDownloads(bool value) async {
    final current = state.valueOrNull ?? const AppSettings();
    await _save(current.copyWith(wifiOnlyDownloads: value));
  }

  Future<void> setAutoDeleteFinished(bool value) async {
    final current = state.valueOrNull ?? const AppSettings();
    await _save(current.copyWith(autoDeleteFinished: value));
  }

  Future<void> setCollectMetrics(bool value) async {
    final current = state.valueOrNull ?? const AppSettings();
    await _save(current.copyWith(collectMetrics: value));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

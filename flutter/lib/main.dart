import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'core/services/audio_handler.dart';
import 'core/services/storage_service.dart';
import 'core/services/download_manager.dart';
import 'core/providers/audio_player_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise cross-platform storage (SharedPreferences)
  await StorageService.init();

  // Initialise download manager (clean staging dir, restore state)
  await DownloadManager.instance.init();

  // Initialise audio service (background audio on Android/iOS)
  final audioHandler = await AudioService.init<LtAudioHandler>(
    builder: LtAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'org.languagetransfer.audio',
      androidNotificationChannelName: 'Language Transfer Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF7186D0),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Provide the real audio handler to the provider tree
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const LanguageTransferApp(),
    ),
  );
}

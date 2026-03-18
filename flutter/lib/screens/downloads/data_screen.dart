import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/course_data.dart';
import '../../core/constants/theme.dart';
import '../../core/models/course.dart';
import '../../core/models/download.dart';
import '../../core/providers/course_provider.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';

/// Data management screen – download/delete lessons for a course.
class DataScreen extends ConsumerWidget {
  const DataScreen({super.key, required this.courseName});

  final String courseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseNameEnum = CourseNameExtension.fromString(courseName);
    if (courseNameEnum == null) {
      return const Scaffold(body: Center(child: Text('Course not found')));
    }

    final courseInfo = getCourseInfo(courseNameEnum);
    final metadataAsync = ref.watch(courseMetadataProvider(courseName));
    final indexAsync = ref.watch(courseIndexProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final actions = ref.read(downloadActionsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: courseInfo.uiColors.background,
        foregroundColor: courseInfo.uiColors.textOnBackground,
        title: Text('${courseInfo.shortTitle} – Downloads'),
        leading: BackButton(
          onPressed: () => context.go('/course/$courseName'),
        ),
        actions: [
          metadataAsync.whenOrNull(
                data: (metadata) => metadata == null
                    ? null
                    : TextButton(
                        onPressed: () => _downloadAll(
                          ref,
                          courseName,
                          metadata.lessons,
                          indexAsync.valueOrNull?.casBaseUrl ?? '',
                          actions,
                        ),
                        child: Text(
                          'Download All',
                          style: TextStyle(
                              color: courseInfo.uiColors.textOnBackground),
                        ),
                      ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: metadataAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(courseMetadataProvider(courseName)),
        ),
        data: (metadata) {
          if (metadata == null) {
            return const Center(child: Text('No course data'));
          }

          final casBaseUrl =
              indexAsync.valueOrNull?.casBaseUrl ?? '';

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide =
                  constraints.maxWidth >= AppTheme.tabletBreakpoint;
              final padding = isWide ? AppTheme.space2xl : 0.0;

              return Column(
                children: [
                  // Quality info banner
                  if (settings != null)
                    _QualityBanner(
                      downloadQuality: settings.downloadQuality,
                      wifiOnly: settings.wifiOnlyDownloads,
                      onTapSettings: () => context.go('/settings'),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: AppTheme.spaceSm,
                      ),
                      itemCount: metadata.lessons.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lesson = metadata.lessons[index];
                        final quality = settings?.downloadQuality == 'low'
                            ? AudioQuality.low
                            : AudioQuality.high;
                        return _DownloadTile(
                          courseName: courseName,
                          lesson: lesson,
                          lessonIndex: index,
                          courseInfo: courseInfo,
                          casBaseUrl: casBaseUrl,
                          quality: quality,
                          actions: actions,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _downloadAll(
    WidgetRef ref,
    String course,
    List<LessonData> lessons,
    String casBaseUrl,
    DownloadActions actions,
  ) async {
    for (var i = 0; i < lessons.length; i++) {
      await actions.download(
        course: course,
        lessonIndex: i,
        lesson: lessons[i],
        casBaseUrl: casBaseUrl,
      );
    }
  }
}

class _QualityBanner extends StatelessWidget {
  const _QualityBanner({
    required this.downloadQuality,
    required this.wifiOnly,
    required this.onTapSettings,
  });

  final String downloadQuality;
  final bool wifiOnly;
  final VoidCallback onTapSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Quality: ${downloadQuality.toUpperCase()}${wifiOnly ? ' · WiFi only' : ''}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onTapSettings,
            child: const Text('Change', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({
    required this.courseName,
    required this.lesson,
    required this.lessonIndex,
    required this.courseInfo,
    required this.casBaseUrl,
    required this.quality,
    required this.actions,
  });

  final String courseName;
  final LessonData lesson;
  final int lessonIndex;
  final CourseInfo courseInfo;
  final String casBaseUrl;
  final AudioQuality quality;
  final DownloadActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      lessonDownloadProvider((course: courseName, lesson: lessonIndex)),
    );

    final pointer = lesson.pointer(quality);
    final sizeLabel = formatBytes(pointer.filesize);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd, vertical: 4),
      title: Text(lesson.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatDuration(lesson.duration)} · $sizeLabel',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (snapshot.isInProgress)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(
                value: snapshot.progress,
                color: courseInfo.uiColors.background,
                backgroundColor: AppTheme.dividerColor,
              ),
            ),
        ],
      ),
      trailing: _TrailingIcon(
        snapshot: snapshot,
        courseInfo: courseInfo,
        onDownload: () => actions.download(
          course: courseName,
          lessonIndex: lessonIndex,
          lesson: lesson,
          casBaseUrl: casBaseUrl,
        ),
        onRemove: () => actions.remove(
          course: courseName,
          lessonIndex: lessonIndex,
          lesson: lesson,
        ),
      ),
    );
  }
}

class _TrailingIcon extends StatelessWidget {
  const _TrailingIcon({
    required this.snapshot,
    required this.courseInfo,
    required this.onDownload,
    required this.onRemove,
  });

  final DownloadSnapshot snapshot;
  final CourseInfo courseInfo;
  final VoidCallback onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    switch (snapshot.state) {
      case DownloadState.finished:
        return IconButton(
          icon: Icon(Icons.delete_outline,
              color: courseInfo.uiColors.background),
          onPressed: onRemove,
          tooltip: 'Delete download',
        );
      case DownloadState.downloading:
        return SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: snapshot.progress,
            color: courseInfo.uiColors.background,
            strokeWidth: 2,
          ),
        );
      case DownloadState.error:
        return IconButton(
          icon: const Icon(Icons.error_outline, color: Colors.red),
          onPressed: onDownload,
          tooltip: snapshot.errorMessage ?? 'Error – tap to retry',
        );
      case DownloadState.requested:
        return const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DownloadState.idle:
        return IconButton(
          icon: const Icon(Icons.download_outlined,
              color: AppTheme.textSecondary),
          onPressed: onDownload,
          tooltip: 'Download',
        );
    }
  }
}

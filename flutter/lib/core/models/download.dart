/// Download status for an individual lesson
enum DownloadState { idle, requested, downloading, finished, error }

class DownloadSnapshot {
  const DownloadSnapshot({
    required this.id,
    required this.state,
    this.bytesWritten = 0,
    this.totalBytes,
    this.errorMessage,
  });

  final String id;
  final DownloadState state;
  final int bytesWritten;
  final int? totalBytes;
  final String? errorMessage;

  bool get isDownloaded => state == DownloadState.finished;
  bool get isInProgress => state == DownloadState.downloading;

  double? get progress {
    if (totalBytes == null || totalBytes == 0) return null;
    return bytesWritten / totalBytes!;
  }

  static const DownloadSnapshot empty = DownloadSnapshot(
    id: '',
    state: DownloadState.idle,
  );

  DownloadSnapshot copyWith({
    String? id,
    DownloadState? state,
    int? bytesWritten,
    int? totalBytes,
    String? errorMessage,
  }) {
    return DownloadSnapshot(
      id: id ?? this.id,
      state: state ?? this.state,
      bytesWritten: bytesWritten ?? this.bytesWritten,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

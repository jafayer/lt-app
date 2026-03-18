import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../services/course_api_service.dart';

// ---------------------------------------------------------------------------
// Course index provider
// ---------------------------------------------------------------------------

final courseApiProvider = Provider<CourseApiService>((ref) {
  return CourseApiService();
});

final courseIndexProvider =
    AsyncNotifierProvider<CourseIndexNotifier, CourseIndex>(
  CourseIndexNotifier.new,
);

class CourseIndexNotifier extends AsyncNotifier<CourseIndex> {
  @override
  Future<CourseIndex> build() async {
    final api = ref.read(courseApiProvider);
    return api.fetchCourseIndex();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(courseApiProvider);
      final index = await api.fetchCourseIndex(forceRemote: true);
      state = AsyncValue.data(index);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ---------------------------------------------------------------------------
// Per-course metadata provider
// ---------------------------------------------------------------------------

final courseMetadataProvider = AsyncNotifierProviderFamily<
    CourseMetadataNotifier, CourseMetadata?, String>(
  CourseMetadataNotifier.new,
);

class CourseMetadataNotifier
    extends FamilyAsyncNotifier<CourseMetadata?, String> {
  @override
  Future<CourseMetadata?> build(String arg) async {
    // arg is the course name string
    final indexAsync = await ref.watch(courseIndexProvider.future);

    final CourseIndexEntry? entry = indexAsync.courses
        .cast<CourseIndexEntry?>()
        .firstWhere((e) => e?.id == arg, orElse: () => null);

    if (entry == null) return null;

    final api = ref.read(courseApiProvider);
    return api.fetchCourseMetadata(indexAsync.casBaseUrl, entry.meta);
  }
}

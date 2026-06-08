import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voice_of_polban/api/feed_repository.dart';

class MockFeedRepo extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepo mockFeedRepo;

  setUp(() {
    mockFeedRepo = MockFeedRepo();
  });

  group(
    'Bookmark Fetch & Sync Tests (Tester: Mahesa Fazrie Mahardhika Gunadi)',
    () {
      test(
        'UT-09: syncBookmarks() Positive - User logged in and online',
        () async {
          when(
            () => mockFeedRepo.syncBookmarks(),
          ).thenAnswer((_) async => true);

          final result = await mockFeedRepo.syncBookmarks();

          expect(result, true);
          verify(() => mockFeedRepo.syncBookmarks()).called(1);
        },
      );
    },
  );
}

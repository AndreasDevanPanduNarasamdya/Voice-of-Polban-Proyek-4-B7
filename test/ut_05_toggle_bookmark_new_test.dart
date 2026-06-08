import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voice_of_polban/processing/feed_controller.dart';
import 'package:voice_of_polban/api/feed_repository.dart';
import 'package:voice_of_polban/processing/auth_controller.dart';

class MockFeedRepo extends Mock implements FeedRepository {}

class MockAuth extends Mock implements AuthController {}

void main() {
  late MockFeedRepo mockFeedRepo;
  late MockAuth mockAuth;

  setUp(() {
    mockFeedRepo = MockFeedRepo();
    mockAuth = MockAuth();
  });

  group('Bookmark Tests (Tester: Andreas Devan Pandu Narasamdya)', () {
    test('UT-05: toggleBookmark() Positive - Add new bookmark', () async {
      when(() => mockAuth.isLoggedIn).thenReturn(true);
      when(
        () => mockFeedRepo.toggleBookmark('post_1'),
      ).thenAnswer((_) async => true);

      final controller = FeedController(repo: mockFeedRepo, auth: mockAuth);
      await controller.toggleBookmark('post_1');

      verify(() => mockFeedRepo.toggleBookmark('post_1')).called(1);
    });
  });
}

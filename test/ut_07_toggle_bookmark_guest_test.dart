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
    test(
      'UT-07: toggleBookmark() Negative - Guest user/Not logged in',
      () async {
        when(() => mockAuth.isLoggedIn).thenReturn(false);

        final controller = FeedController(repo: mockFeedRepo, auth: mockAuth);

        expect(() => controller.toggleBookmark('post_3'), throwsException);
      },
    );
  });
}

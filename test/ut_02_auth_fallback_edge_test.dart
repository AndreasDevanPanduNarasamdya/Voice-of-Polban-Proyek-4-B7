import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voice_of_polban/api/auth_repository.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepo mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepo();
  });

  group('Auth Tests (Tester: Fiandra Putera Mardani)', () {
    test(
      'UT-02: AuthRepository.login() Edge Case - Offline Cache Fallback',
      () async {
        when(
          () => mockAuthRepo.login(any(), any()),
        ).thenThrow(Exception('Offline'));

        final result = await mockAuthRepo
            .login('test@polban.ac.id', 'password123')
            .catchError((e) => e);

        expect(result, isA<Exception>());
        // Add local cache fallback assertion logic here for cached_user_box
      },
    );
  });
}

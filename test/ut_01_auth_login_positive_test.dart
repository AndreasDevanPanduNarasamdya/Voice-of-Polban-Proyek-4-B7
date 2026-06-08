import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voice_of_polban/processing/auth_controller.dart';
import 'package:voice_of_polban/api/auth_repository.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepo mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepo();
  });

  group('Auth Tests (Tester: Fiandra Putera Mardani)', () {
    test(
      'UT-01: AuthController.login() Positive - Online & Valid Credentials',
      () async {
        when(
          () => mockAuthRepo.login(any(), any()),
        ).thenAnswer((_) async => true);

        final controller = AuthController(repo: mockAuthRepo);
        final result = await controller.login(
          'test@polban.ac.id',
          'password123',
        );

        expect(result, true);
        verify(
          () => mockAuthRepo.login('test@polban.ac.id', 'password123'),
        ).called(1);
      },
    );
  });
}

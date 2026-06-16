import 'dart:io'; // Needed to create a temporary folder
import 'package:voice_of_polban/config/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_of_polban/storage/cached_user.dart';

// Adjust these imports to match your actual folder structure
import 'package:voice_of_polban/ui/screens/writer_view.dart';
import 'package:voice_of_polban/storage/local_draft.dart';

void main() {
  // ===========================================================================
  // 1. SETUP: Initialize Hive just like in main.dart so the test doesn't crash
  // ===========================================================================
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);

    // 1. Register all adapters with their exact Type IDs
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LocalDraftAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(CachedUserAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(UserRoleAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(PostStatusAdapter());

    // (Optional) Register SyncQueue if needed
    // if (!Hive.isAdapterRegistered(X)) Hive.registerAdapter(SyncQueueAdapter());

    // 2. Open all necessary boxes
    await Hive.openBox<LocalDraft>('local_draft_box');
    final userBox = await Hive.openBox<CachedUser>('cached_user_box');
    final sessionBox = await Hive.openBox('session_box');
    await Hive.openBox('sync_queue_box');

    // 3. INJECT THE COMPLETE MOCK USER using the correct Enum
    final mockUser = CachedUser(
      userId: 'mock-user-123',
      name: 'Writer Polban',
      email: 'writer@polban.ac.id',
      role: UserRole.writer,
      avatarUrl: '',
    );

    await userBox.put('mock-user-123', mockUser);
    await sessionBox.put('logged_in_user_id', 'mock-user-123');
  });

  // Clean up after the test finishes
  tearDownAll(() async {
    await Hive.close();
  });

  // ===========================================================================
  // 2. THE TEST EXECUTOR
  // ===========================================================================
  testWidgets('E2E: Writer types a new article and saves it as a draft', (
    WidgetTester tester,
  ) async {
    // Step 1: Render the WriterPage inside a basic App shell
    await tester.pumpWidget(const MaterialApp(home: WriterPage()));

    // Wait for initial animations to finish
    await tester.pumpAndSettle();

    // Verify the page loaded correctly by looking for the Save button
    expect(find.text('Simpan Draf'), findsOneWidget);

    // Step 2: Find the TextFields using the exact Hint Texts from your code
    // (As an architect, adding Keys like Key('title_input') later makes this faster)
    final titleField = find.widgetWithText(TextField, 'Masukkan Judul');
    final contentField = find.widgetWithText(
      TextField,
      'Tulis isi artikel di sini...',
    );
    final hashtagField = find.widgetWithText(
      TextField,
      'Hashtag (contoh: #kampus #polban)',
    );

    // Step 3: Simulate the user typing the article
    await tester.enterText(
      titleField,
      'Gedung Kuliah Baru Polban Siap Digunakan',
    );
    await tester.enterText(
      contentField,
      'Fasilitas baru ini diharapkan dapat menunjang perkuliahan mahasiswa...',
    );
    await tester.enterText(hashtagField, '#kampus #fasilitas');

    // Trigger a frame to update the UI with the text
    await tester.pump();

    // Step 4: Find and tap the 'Simpan Draf' button
    final saveButton = find.text('Simpan Draf');
    await tester.tap(saveButton);

    // Step 5: Wait for the async save operation and UI animations to finish
    // This waits for _saveDraft() to complete and the SnackBar to drop down
    await tester.pumpAndSettle();

    // Step 6: Verify the success SnackBar appears exactly as you wrote it
    expect(find.text('Draf tersimpan!'), findsOneWidget);
  });
}

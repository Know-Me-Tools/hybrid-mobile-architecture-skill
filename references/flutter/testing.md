# Flutter Testing Reference
> flutter_test · riverpod_test · mockito · fake_async

## pubspec.yaml test dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_test: ^2.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.13
  fake_async: ^1.3.1
  mocktail: ^1.0.4
```

## Testing Riverpod providers

```dart
// test/features/chat/providers/chat_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_test/riverpod_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepo;

  setUp(() {
    mockRepo = MockChatRepository();
  });

  // Test provider state transitions
  providerTest<ChatNotifier, ChatState>(
    'sendMessage emits loading then success states',
    provider: chatNotifierProvider,
    overrides: [
      chatRepositoryProvider.overrideWithValue(mockRepo),
    ],
    setUp: () {
      when(() => mockRepo.sendMessage(any())).thenAnswer((_) async => []);
    },
    act: (notifier) => notifier.sendMessage('hello'),
    expect: () => [
      isA<ChatStateLoading>(),
      isA<ChatStateLoaded>(),
    ],
  );
}
```

## Widget testing with Riverpod

```dart
// test/features/chat/screens/chat_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatScreen shows empty state initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override with test data or mocks
          messagesProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('What can I help with?'), findsOneWidget);
  });
}
```

## Repository unit testing

```dart
// test/features/auth/data/repositories/supabase_auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('SupabaseAuthRepository', () {
    test('signIn returns AuthUser on success', () async {
      // Arrange
      final mockClient = MockSupabaseClient();
      final repo = SupabaseAuthRepository(client: mockClient);

      // Act
      final user = await repo.signIn(email: 'test@test.com', password: 'password');

      // Assert
      expect(user.email, 'test@test.com');
    });
  });
}
```

## Golden file testing (pixel accuracy)

```dart
testWidgets('ThinkingBlockWidget matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ThinkingBlockWidget(
          thinking: 'Test reasoning',
          isStreaming: false,
        ),
      ),
    ),
  );
  await expectLater(
    find.byType(ThinkingBlockWidget),
    matchesGoldenFile('goldens/thinking_block.png'),
  );
});
```

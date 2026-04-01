# Flutter Patterns Reference
> Flutter 3.29+ · Dart 3.4+ · Riverpod 2.6+ · flutter_rust_bridge 2.3+

## Dependency versions (always use latest)

```yaml
# pubspec.yaml (current as of March 2026)
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  flutter_rust_bridge: ^2.3.0
  shadcn_flutter: ^0.1.6       # shadcn/ui equivalent for Flutter
  go_router: ^15.0.0           # routing
  markdown_widget: ^2.3.2+6
  flutter_highlight: ^0.7.0
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  gap: ^3.0.1
  uuid: ^4.5.1

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.3
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.3
  flutter_lints: ^4.0.0
```

## Feature-based clean architecture

```
lib/
  app/
    router.dart              # GoRouter configuration
    providers.dart           # App-level providers
  core/
    theme/                   # Design tokens, ThemeData
    errors/                  # AppError, Failure types
    network/                 # HTTP client setup (delegates to Rust)
    extensions/
  features/
    <feature-name>/
      data/
        repositories/        # Implements domain interfaces
        datasources/         # Remote (Rust FFI) + local
        models/              # DTOs, JSON serialization
      domain/
        entities/            # Core business objects (freezed)
        repositories/        # Abstract interfaces
        usecases/            # Single-responsibility use cases
      presentation/
        providers/           # @riverpod annotated providers
        screens/             # Screen widgets
        widgets/             # Feature-specific widgets
  shared/
    widgets/                 # Shared UI components
    providers/               # Shared providers
  bridge/
    a2ui/                    # A2UI event types + content driver
    agui/                    # AG-UI provider
    rust_bridge_provider.dart
    generated_api.dart       # flutter_rust_bridge codegen output
  main.dart
```

## Riverpod patterns

### Provider declaration (always use codegen)

```dart
// ✓ Correct: codegen annotation
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() => const ChatState.initial();

  Future<void> sendMessage(String text) async { ... }
}

// ✗ Wrong: manual declaration
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
```

### Async streaming provider

```dart
// Stream from Rust via StreamSink → Dart Stream
@riverpod
Stream<A2uiEvent> agentStream(Ref ref, AgentRequest request) {
  // Cancel stream subscription on provider disposal
  ref.onDispose(() { /* cleanup */ });
  return streamAgentA2ui(request); // from bridge/rust_bridge_provider.dart
}
```

### Provider composition (dependency injection)

```dart
@riverpod
class MessageRepository extends _$MessageRepository {
  @override
  MessageRepositoryImpl build() {
    // Inject dependencies from other providers
    final db = ref.watch(surrealDbProvider);
    return MessageRepositoryImpl(db: db);
  }
}
```

### autoDispose for streaming providers

```dart
// Always autoDispose streaming providers to prevent memory leaks
@riverpod
Stream<String> inferenceStream(Ref ref, InferenceRequest req) async* {
  final sub = localGenerate(req).listen(null);
  ref.onDispose(sub.cancel);
  yield* localGenerate(req);
}
```

### Watch vs read patterns

```dart
// In build() or widget build context: use watch (reactive)
final state = ref.watch(chatNotifierProvider);

// In callbacks / event handlers: use read (not reactive)
void onTap() {
  ref.read(chatNotifierProvider.notifier).sendMessage(text);
}
```

## ContentBlock integration (Riverpod side)

```dart
// ChatNotifier owns all ContentBlock mutations
@riverpod
class ChatNotifier extends _$ChatNotifier {
  // A2uiContentDriver calls these:
  void streamBlock({
    required String messageId,
    int? blockIndex,
    required ContentBlock block,
  }) { ... }

  void finalizeMessage(String messageId, {MessageUsage? usage}) { ... }
}
```

## shadcn_flutter component patterns

```dart
import 'package:shadcn_flutter/shadcn_flutter.dart';

// Use ShadcnApp instead of MaterialApp
ShadcnApp(
  theme: ShadcnThemeData(
    colorScheme: ShadcnColorScheme.dark(),
    radius: BorderRadius.circular(8),
  ),
  home: const AppShell(),
)

// Button
ShadButton(
  onPressed: () {},
  child: const Text('Send'),
)

// Card
ShadCard(
  child: Column(children: [...]),
)

// Dialog (for HITL confirmations)
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    title: const Text('Confirm action'),
    actions: [
      ShadButton(child: const Text('Confirm'), onPressed: confirm),
    ],
  ),
);
```

## gen_ui_core FFI wiring

### Initialization (main.dart)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Rust runtime before runApp
  await initRustBridge(dataDir: (await getApplicationDocumentsDirectory()).path);
  await setApiKey(const String.fromEnvironment('ANTHROPIC_API_KEY'));
  runApp(const ProviderScope(child: App()));
}
```

### Connecting A2UI stream to ContentDriver

```dart
// In ChatNotifier or a dedicated StreamingNotifier
final _driver = <String, A2uiContentDriver>{};

Future<void> _connectStream(String messageId, Stream<A2uiEvent> stream) {
  final driver = A2uiContentDriver(
    messageId: messageId,
    onBlock: streamBlock,
    onFinalize: finalizeMessage,
  )..connect(stream);
  _driver[messageId] = driver;
  ref.onDispose(() => driver.dispose());
}
```

## GoRouter with auth guard

```dart
final router = GoRouter(
  redirect: (context, state) {
    final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';
    if (!isAuthenticated && !isLoginRoute) return '/login';
    if (isAuthenticated && isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    ]),
  ],
);
```

## Ory Kratos integration (Flutter)

See `references/auth/patterns.md` for full patterns. Minimal bootstrap:

```dart
// Kratos native SDK integration
// Use kratos_dart_client (auto-generated from OpenAPI)
final kratosApi = FrontendApi(ApiClient(basePath: kratosPublicUrl));

// Get login flow
final flow = await kratosApi.createNativeLoginFlow();

// Submit credentials
await kratosApi.updateLoginFlow(
  flow: flow.id,
  updateLoginFlowBody: UpdateLoginFlowBody(
    UpdateLoginFlowWithPasswordMethod(
      method: 'password',
      identifier: email,
      password: password,
    ),
  ),
);
```

## Supabase integration (Flutter)

```dart
// Initialize in main()
await Supabase.initialize(url: supabaseUrl, anonKey: anonKey);

// Riverpod provider
@riverpod
SupabaseClient supabase(Ref ref) => Supabase.instance.client;

// Auth state provider
@riverpod
Stream<AuthState> authState(Ref ref) =>
    ref.watch(supabaseProvider).auth.onAuthStateChange;
```

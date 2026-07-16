// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Staged for the post-codegen bootstrap below (kept imported so uncommenting is
// a one-line change once gen_ui_core is built and frb bindings are generated).
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'package:prometheus_entity_management/prometheus_entity_management.dart';

import 'app/router.dart';
// ignore: unused_import
import 'bridge/rust_bridge_provider.dart';
import 'features/startup/presentation/screens/startup_gate.dart';
import 'shared/providers/entity_transport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialise the Rust runtime BEFORE runApp (uncomment after frb codegen):
  // final dir = await getApplicationDocumentsDirectory();
  // await initRustBridge(dataDir: dir.path);
  // await setApiKey(const String.fromEnvironment('ANTHROPIC_API_KEY'));

  runApp(
    ProviderScope(
      overrides: [
        // Wire PEM's transport seam to the FFI-backed adapter. Everything above
        // this override reaches Rust through the canonical path.
        entityTransportProvider.overrideWithValue(const FrbEntityTransport()),
      ],
      child: const AppRoot(),
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Prometheus Hybrid',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        // StartupGate blocks the router shell until the first-run boot sequence
        // (migrations → seeds → shapes) reaches ready. Then it renders the app.
        home: StartupGate(child: _RouterHost()),
      );
}

class _RouterHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        routerConfig: appRouter,
      );
}

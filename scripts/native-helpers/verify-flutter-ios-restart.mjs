import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { assert, main, run } from './common.mjs';
await main(() => {
    assert(process.argv.length >= 3 && process.argv.length <= 5, 'node scripts/verify-flutter-ios-restart.mjs <flutter-project> [--ios-app <application-binary> | <android-device-id> <application-binary>]', 2);
    const project = resolve(process.argv[2]);
    const requestedMode = process.argv[3];
    const applicationBinary = process.argv[4] ? resolve(process.argv[4]) : undefined;
    if (requestedMode && requestedMode !== '--ios-app') {
        const existingDevice = requestedMode;
        assert(Boolean(applicationBinary), 'existing-device verification requires a prebuilt application binary', 2);
        const buildConfig = readFileSync(resolve(project, 'android/app/build.gradle.kts'), 'utf8');
        const applicationId = /applicationId\s*=\s*"([^"]+)"/.exec(buildConfig)?.[1];
        assert(Boolean(applicationId), 'Android build configuration omitted applicationId');
        const base = [
            'drive',
            '--driver=test_driver/integration_test.dart',
            '--target=integration_test/notes_test.dart',
            `--device-id=${existingDevice}`,
            `--use-application-binary=${applicationBinary}`,
        ];
        run('flutter', [...base, '--keep-app-running'], { cwd: project });
        run('adb', ['-s', existingDevice, 'shell', 'am', 'force-stop', applicationId]);
        run('flutter', [...base, '--route=/verify-restart'], { cwd: project });
        process.stdout.write(`PASS: Flutter UI -> Rust FFI -> SQLite -> application relaunch recovery on device ${existingDevice}\n`);
        return;
    }
    assert(process.platform === 'darwin', 'managed iOS simulator verification requires macOS', 2);
    assert(requestedMode === '--ios-app' && Boolean(applicationBinary), 'managed iOS verification requires --ios-app <application-binary>', 2);
    assert(applicationBinary.endsWith('.app'), 'managed iOS application binary must be an .app bundle', 2);
    const bundleId = run('plutil', ['-extract', 'CFBundleIdentifier', 'raw', '-o', '-', resolve(applicationBinary, 'Info.plist')], { capture: true }).trim();
    assert(Boolean(bundleId), 'iOS application bundle omitted CFBundleIdentifier');
    const inventory = JSON.parse(run('xcrun', ['simctl', 'list', '--json'], { capture: true }));
    const compatible = inventory.runtimes
        ?.filter(item => item.identifier && item.isAvailable !== false && /^iOS /.test(item.name ?? ''))
        .flatMap(runtime => (inventory.devices?.[runtime.identifier] ?? [])
        .filter(device => device.isAvailable !== false && device.deviceTypeIdentifier && /^iPhone /.test(device.name ?? ''))
        .map(device => ({ runtime, device })))
        .at(-1);
    assert(Boolean(compatible?.runtime.identifier), 'No available iOS simulator runtime with a compatible iPhone device');
    assert(Boolean(compatible?.device.deviceTypeIdentifier), 'Compatible iPhone simulator omitted its device type identifier');
    const name = `knowme-builder-cert-${randomUUID()}`;
    const id = run('xcrun', ['simctl', 'create', name, compatible.device.deviceTypeIdentifier, compatible.runtime.identifier], { capture: true }).trim();
    assert(Boolean(id), 'simctl did not return a device identifier');
    try {
        run('xcrun', ['simctl', 'boot', id]);
        run('xcrun', ['simctl', 'bootstatus', id, '-b']);
        const base = [
            'drive',
            '--driver=test_driver/integration_test.dart',
            '--target=integration_test/notes_test.dart',
            `--device-id=${id}`,
            `--use-application-binary=${applicationBinary}`,
        ];
        run('flutter', [...base, '--keep-app-running'], { cwd: project });
        run('xcrun', ['simctl', 'terminate', id, bundleId]);
        run('flutter', [...base, '--route=/verify-restart'], { cwd: project });
        process.stdout.write(`PASS: Flutter UI -> Rust FFI -> SQLite -> application relaunch recovery on simulator ${id}\n`);
    }
    finally {
        run('xcrun', ['simctl', 'shutdown', id], { allowFailure: true });
        run('xcrun', ['simctl', 'delete', id], { allowFailure: true });
    }
});

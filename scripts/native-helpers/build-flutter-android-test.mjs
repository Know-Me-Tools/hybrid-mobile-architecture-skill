// TJ-ARCH-MOB-001 compliant
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { assert, main, run } from './common.mjs';
await main(() => {
    assert(process.argv.length === 3, 'node scripts/build-flutter-android-test.mjs <flutter-project>', 2);
    const project = resolve(process.argv[2]);
    const android = resolve(project, 'android');
    const wrapper = resolve(android, 'gradle/wrapper/gradle-wrapper.jar');
    assert(existsSync(wrapper), `Gradle wrapper JAR is missing: ${wrapper}`);
    run('java', [
        '-classpath',
        wrapper,
        'org.gradle.wrapper.GradleWrapperMain',
        'app:assembleAndroidTest',
    ], { cwd: android });
});

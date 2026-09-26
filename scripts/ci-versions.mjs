// TJ-ARCH-MOB-001 compliant
import { appendFileSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { main, packageRoot } from './portable/platform.mjs';
await main(() => {
    if (process.argv.length !== 2)
        throw new Error('Usage: node scripts/ci-versions.mjs');
    const source = readFileSync(join(packageRoot, 'versions.toml'), 'utf8');
    const section = source.match(/^\[toolchain\][^\n]*\n([\s\S]*?)(?=^\[|$(?![\s\S]))/m)?.[1];
    const values = {};
    for (const key of ['rust', 'node']) {
        const value = section?.match(new RegExp(`^${key}\\s*=\\s*"([^"\\r\\n]+)"`, 'm'))?.[1];
        if (!value || !/^\d+\.\d+\.\d+(?:[-+][\w.-]+)?$/.test(value))
            throw new Error(`Invalid toolchain.${key} version`);
        values[key] = value;
    }
    const output = Object.entries(values).map(([key, value]) => `${key}=${value}\n`).join('');
    if (process.env.GITHUB_OUTPUT)
        appendFileSync(process.env.GITHUB_OUTPUT, output);
    process.stdout.write(output);
});

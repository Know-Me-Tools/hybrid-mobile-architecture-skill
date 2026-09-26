// TJ-ARCH-MOB-001 compliant
import { readdirSync } from 'node:fs';
import { join } from 'node:path';
import { main, packageRoot, run } from './portable/platform.mjs';
await main(() => {
    if (process.argv.length !== 2)
        throw new Error('No arguments accepted');
    const count = (directory, filter = (_) => true) => readdirSync(directory, { withFileTypes: true }).filter(e => e.isDirectory() && filter(e.name)).length;
    const publicCount = count(join(packageRoot, 'skills')), internalCount = count(join(packageRoot, '.agents/skills'), n => /^(openspec-|source-command-opsx-)/.test(n));
    if (!publicCount || !internalCount)
        throw new Error('Discovery inventory is empty; refusing vacuous proof');
    for (const internal of [false, true]) {
        const source = internal ? packageRoot : join(packageRoot, 'skills');
        const output = run('npx', ['-y', 'skills@latest', 'add', source, '--list', ...(internal ? ['--full-depth'] : []), '-a', 'opencode', '-y'], { capture: true, env: { ...process.env, INSTALL_INTERNAL_SKILLS: internal ? '1' : '' } }).stdout;
        const found = [...output.matchAll(/Found (\d+) skills/g)].at(-1)?.[1], expected = publicCount + (internal ? internalCount : 0);
        if (Number(found) !== expected)
            throw new Error(`Discovery expected ${expected} skills, found ${found ?? 'none'}\n${output.slice(0, 3000)}`);
    }
    process.stdout.write(`Discovery verified: ${publicCount} public + ${internalCount} opt-in internal skills.\n`);
});

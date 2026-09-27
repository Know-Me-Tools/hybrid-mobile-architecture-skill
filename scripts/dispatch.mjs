// TJ-ARCH-MOB-001 compliant
import { appendFileSync, closeSync, existsSync, mkdirSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { invocation, main, packageRoot, run } from './portable/platform.mjs';
await main(() => {
    const args = process.argv.slice(2), preview = args.includes('--dry-run');
    const positional = args.filter(arg => arg !== '--dry-run');
    if (positional.length < 3 || positional.length > 4 || positional.some(arg => arg.startsWith('-')))
        throw new Error('Usage: node scripts/dispatch.mjs <change-id> <codex|opencode|claude|kimi> <model> [base-ref] [--dry-run]');
    const [change, harness, model, base = 'main'] = positional;
    if (!/^[a-z0-9][a-z0-9-]*$/.test(change))
        throw new Error('change-id must contain lowercase letters, digits and hyphens');
    if (!['codex', 'opencode', 'claude', 'kimi'].includes(harness))
        throw new Error(`Unknown harness: ${harness}`);
    if (!existsSync(join(packageRoot, 'openspec/changes', change, 'proposal.md')))
        throw new Error(`Missing change proposal: ${change}`);
    const dispatch = join(packageRoot, '.kbd-orchestrator/dispatch'), worktree = join(dispatch, 'worktrees', change);
    const branch = `codex/${change}`, log = join(dispatch, 'logs', `${change}.log`);
    // Kimi retains this repository's configured OpenCode dispatch adapter.
    const executable = harness === 'codex' ? process.env.CODEX_BIN ?? 'codex' : harness === 'kimi' ? 'opencode' : harness;
    const prompt = `${readFileSync(join(dispatch, 'prompts/_preamble.md'), 'utf8')}\n## YOUR CHANGE: ${change}\n\nRead openspec/changes/${change}/proposal.md and its matching entry in plan.md. Implement it fully. Assigned model: ${model} (${harness}).\n`;
    const commandArgs = harness === 'codex' ? ['exec', '-C', worktree, '-m', model, prompt]
        : harness === 'claude' ? ['-p', prompt, '--model', model] : ['run', '--dir', worktree, '-m', model, prompt];
    if (preview) {
        process.stdout.write(`${JSON.stringify({ change, harness, model, base, branch, worktree, executable, args: commandArgs, log }, null, 2)}\n`);
        return;
    }
    const command = invocation(executable, commandArgs);
    if (existsSync(worktree)) {
        const current = run('git', ['-C', worktree, 'branch', '--show-current'], { capture: true }).stdout.trim();
        if (current !== branch)
            throw new Error(`Existing dispatch checkout uses ${current}, expected ${branch}`);
    }
    else {
        const existing = run('git', ['-C', packageRoot, 'show-ref', '--verify', '--quiet', `refs/heads/${branch}`], { allowFailure: true }).status === 0;
        run('git', ['-C', packageRoot, 'worktree', 'add', ...(existing ? [worktree, branch] : ['-b', branch, worktree, base])]);
    }
    mkdirSync(join(dispatch, 'prompts'), { recursive: true });
    mkdirSync(join(dispatch, 'logs'), { recursive: true });
    writeFileSync(join(dispatch, 'prompts', `${change}.md`), prompt);
    appendFileSync(log, `[dispatch] ${change} -> ${harness}/${model} worktree=${worktree}\n`);
    const handle = openSync(log, 'a');
    try {
        const result = spawnSync(command.command, command.args, { cwd: worktree, stdio: ['inherit', handle, handle], shell: false });
        if (result.error)
            throw result.error;
        process.exitCode = result.status ?? 1;
        appendFileSync(log, `[dispatch] ${change} exit=${process.exitCode}\n`);
    }
    finally {
        closeSync(handle);
    }
});

// TJ-ARCH-MOB-001 compliant
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, relative } from 'node:path';
import { json, packageRoot, run, object } from './platform.mjs';
import { checkW6 } from './w6.mjs';
function files(root) {
    if (!existsSync(root))
        return [];
    return readdirSync(root, { withFileTypes: true }).flatMap(e => e.isSymbolicLink() || ['node_modules', 'target', '.git'].includes(e.name) ? [] : e.isDirectory() ? files(join(root, e.name)) : [join(root, e.name)]);
}
const text = (path) => existsSync(path) ? readFileSync(path, 'utf8') : '';
const dirs = (path) => existsSync(path) ? readdirSync(path, { withFileTypes: true }).filter(e => e.isDirectory()).map(e => e.name) : [];
export function audit(mode, root) {
    const result = { failures: [], warnings: [], checked: 0 };
    const check = (condition, message, warning = false) => { result.checked++; if (!condition)
        (warning ? result.warnings : result.failures).push(message); };
    const present = (path, warning = false) => check(existsSync(join(root, path)), `${path} missing`, warning);
    const contents = (directory) => files(directory).map(file => ({ file: relative(root, file).replaceAll('\\', '/'), content: text(file) }));
    const has = (records, regex, path = /./) => records.some(record => path.test(record.file) && regex.test(record.content));
    const lines = (records) => records.flatMap(record => record.content.split(/\r?\n/).filter(line => !/^\s*\/\//.test(line)).map(content => ({ file: record.file, content })));
    if (mode === 'flutter') {
        present('lib');
        present('pubspec.yaml');
        const pub = text(join(root, 'pubspec.yaml')), lib = contents(join(root, 'lib')), code = lines(lib.filter(f => !f.file.endsWith('.g.dart')));
        for (const name of ['flutter_riverpod', 'riverpod_annotation', 'freezed_annotation', 'flutter_rust_bridge', 'shadcn_flutter', 'go_router'])
            check(pub.includes(name + ':'), `${name} dependency missing`, !['flutter_riverpod', 'riverpod_annotation'].includes(name));
        check(!/^\s+provider:/m.test(pub), 'provider package forbidden; use Riverpod');
        check(!/^\s+(flutter_)?bloc:/m.test(pub), 'Bloc package forbidden; use Riverpod');
        present('lib/features');
        for (const feature of dirs(join(root, 'lib/features')))
            for (const layer of ['data', 'domain', 'presentation'])
                present(`lib/features/${feature}/${layer}`, layer === 'data');
        for (const path of ['lib/core', 'lib/shared', 'lib/bridge'])
            present(path, true);
        check(has(lib, /@riverpod|@Riverpod/), 'Riverpod codegen annotations missing', true);
        check(!has(code, /StateNotifierProvider|ChangeNotifierProvider/), 'Deprecated provider pattern');
        check(!has(code, /http\.|dio\.|Dio\(|import ['"]package:http\//, /features\/.*presentation\//), 'Networking in Flutter presentation layer');
        check(lib.some(f => f.file.endsWith('.g.dart')), 'Dart generated model/provider output missing', true);
        check(lib.some(f => f.file.endsWith('.freezed.dart')), 'Freezed output missing', true);
        present('lib/bridge/rust_bridge_provider.dart', true);
        check(text(join(root, 'lib/bridge/rust_bridge_provider.dart')).includes("import 'generated_api.dart'"), 'FFI import not wired', true);
        check(!has(lib, /rust_bridge_provider\.dart/, /presentation\/(screens|widgets)\//), 'Screen/widget imports FFI facade directly');
        check(!has(code, /(?:SELECT .*FROM|RELATE |DEFINE INDEX|DEFINE TABLE).*['"]|['"].*(?:SELECT .*FROM|RELATE |DEFINE INDEX|DEFINE TABLE)/), 'Raw SQL/SurrealQL in Dart');
        if (has(lib, /rust_bridge_provider\.dart/, /providers\/|_provider\.dart|_notifier\.dart/))
            check(has(lib, /@Riverpod\(retry:/), 'FFI providers should disable Riverpod retry', true);
        for (const feature of ['chat', 'notes', 'memory', 'startup'])
            present(`lib/features/${feature}`);
        present('lib/shared/widgets/sync_chip.dart', true);
    }
    else if (mode === 'tauri') {
        present('src');
        present('package.json');
        const packageText = text(join(root, 'package.json')), src = contents(join(root, 'src')), code = lines(src);
        const pkg = existsSync(join(root, 'package.json')) ? json(join(root, 'package.json')) : {}, dependencies = { ...object(pkg.dependencies), ...object(pkg.devDependencies) };
        for (const name of ['zustand', '@prometheus-ags/prometheus-entity-management', '@tanstack/react-router', '@tanstack/react-table', '@tauri-apps/api', '@assistant-ui/react', '@electric-sql/pglite', 'immer'])
            check(name in dependencies, `${name} dependency missing`, ['immer', '@tanstack/react-table'].includes(name));
        check(/^[~^]*3\./.test(String(dependencies['@prometheus-ags/prometheus-entity-management'] ?? '')), 'PEM must use version3.x');
        check(!Object.keys(dependencies).some(key => /^(?:@tanstack\/react-query|redux|@reduxjs|jotai|recoil|react-router)/.test(key)), 'Forbidden replacement state/router dependency');
        for (const name of ['loro-crdt', '@electric-sql/pglite-sync', '@electric-sql/pglite-pgvector'])
            if (name in dependencies)
                check(src.some(f => f.content.includes(`from '${name}`) || f.content.includes(`from "${name}`)), `${name} is declared but not imported`, true);
        check(!has(src, /registerEntityTransport\(['"][^'"]*[Vv]ault|_vault_state/, /features\/entities\/.*\.ts$/), 'Vault must remain outside entity sync');
        if (existsSync(join(root, 'src/features/chat')))
            check('@electric-sql/pglite-pgvector' in dependencies, 'Chat client RAG vector dependency missing', true);
        present('src/features');
        for (const feature of dirs(join(root, 'src/features'))) {
            const path = `src/features/${feature}`;
            if (!files(join(root, path)).some(f => /\.tsx?$/.test(f))) {
                check(false, `${path} is an empty placeholder`, true);
                continue;
            }
            for (const layer of ['api', 'stores', 'entities', 'hooks'])
                present(`${path}/${layer}`, layer !== 'hooks');
            check(existsSync(join(root, path, 'components')) || existsSync(join(root, path, 'screens')), `${path} visual surface missing`);
        }
        check(existsSync(join(root, 'components.json')) && existsSync(join(root, 'src/components/ui')), 'shadcn/ui registry/primitives missing');
        check(has(src, /AssistantRuntimeProvider|useExternalStoreRuntime/, /features\/chat\//) && has(src, /@\/components\/assistant-ui\/thread/, /features\/chat\//), 'Assistant UI runtime/thread not mounted');
        check(has(src, /chat_conversations|ConversationRecord/, /features\//) && has(src, /useGraphStore|useEntity/, /features\/entities\//), 'Durable conversation PEM/PGlite integration incomplete');
        if (pkg.name === 'knowme-poc' || existsSync(join(root, '../docs/KnowMe.dc.html')))
            for (const destination of ['Home', 'Chat', 'Hands', 'Memory', 'Models', 'Settings'])
                check(has(src, new RegExp(`['"]${destination}['"]`), /src\/app\//), `Reference product destination ${destination} missing`);
        check(!has(src, /(?<![\w-])border(?:-[trblxyse])?(?=\s|")|(?<![\w-])shadow-(?!none)/, /src\/(app|features|shared)\/.*\.(tsx|css)$/), 'Visible borders/shadows violate Flat2.0');
        check(!has(code, /from ['"][^'"]*stores\//, /features\/.*components\/.*\.tsx$/), 'Component imports store directly');
        check(!has(code, /invoke\(|listen\(/, /features\/[^/]+\/(components|hooks|entities)\/.*\.tsx?$/), 'IPC used outside stores');
        check(!has(code, /await fetch\(|= fetch\(/, /features\/.*hooks\/.*\.tsx?$/), 'Hook performs direct fetch');
        check(!has(code, /RELATE |DEFINE INDEX|DEFINE TABLE/, /features\/.*(components|hooks|entities)\//), 'SurrealQL used outside stores');
        check(has(src, /useEntities|useEntityQuery|useEntityMutation|registerEntityTransport/, /features\//), 'PEM hooks/transports not used', true);
        check(!has(src, /useEntities|useEntityQuery|useEntityMutation/, /components\/.*\.tsx$/), 'Components bypass feature hooks for entity access');
        present('src/bridge/a2ui/types.ts', true);
        check(has(src, /a2ui_event|onChatEvent/), 'A2UI event listener not wired', true);
        for (const feature of ['chat', 'entities', 'memory', 'startup'])
            present(`src/features/${feature}`);
        check(has(src, /invoke\(/, /features\/(memory|startup)\/stores\//), 'Memory/startup FFI seam not wired', true);
    }
    else if (mode === 'rust') {
        present('src');
        const src = contents(join(root, 'src'));
        for (const mod of ['api', 'api_http', 'runtime', 'streaming', 'config', 'protocol', 'agent', 'inference', 'mcp', 'db'])
            check(existsSync(join(root, `src/${mod}.rs`)) || existsSync(join(root, 'src', mod)), `${mod} module missing`, true);
        check(/OnceLock|once_cell/.test(text(join(root, 'src/runtime.rs'))), 'Global runtime singleton not detected', true);
        check(has(src, /tokio::runtime::Builder::new_multi_thread/), 'Multithread runtime missing', true);
        check(has(src, /spawn_blocking/), 'CPU blocking pool missing', true);
        present('src/protocol/a2ui.rs');
        present('src/protocol/agui.rs');
        check(/broadcast::channel|broadcast::Sender/.test(text(join(root, 'src/protocol/mod.rs'))), 'Protocol broadcast channel missing', true);
        const cargo = text(join(root, 'Cargo.toml'));
        check(cargo.includes('cdylib') && cargo.includes('staticlib'), 'FFI requires cdylib and staticlib', true);
    }
    else if (mode === 'doc-consistency') {
        check(existsSync(join(packageRoot, 'versions.toml')), 'versions.toml missing');
        const paths = ['CLAUDE.md', 'AGENTS.md', 'README.md', 'skills/hybrid-mobile-architecture/SKILL.md'].map(p => join(packageRoot, p)).filter(existsSync).concat(files(join(packageRoot, 'references')).filter(p => p.endsWith('.md') && !p.endsWith('wasm-targets.md')));
        // Node22 is intentionally valid for the portable consumer runtime. The
        // app/development pin remains in versions.toml and check-env.
        const patterns = [/1\.80\+/, /1\.95\+/, /1\.96\+/, /Node\.js[^0-9]*24\+/, /Riverpod 2\.[x6]/, /2\.3\+.*flutter_rust_bridge|flutter_rust_bridge_codegen.*2\.3\+/, /frb 2\.12\+/, /Vite 7/, /"vite": "\^7/, /Flutter (SDK \| )?3\.29\+/, /Tauri CLI 2\.10\+/, /mobile.*=.*llama-cpp-2/, /candle[^)]*\b(inference|generation|LLM|chat)|\b(inference|generation) (engine )?(via|using|with) candle/];
        for (const pattern of patterns)
            for (const path of paths)
                check(!pattern.test(text(path)), `Stale authority ${pattern}: ${relative(packageRoot, path)}`);
        const actual = dirs(join(packageRoot, 'skills')).filter(name => existsSync(join(packageRoot, 'skills', name, 'SKILL.md'))).sort();
        const configured = json(join(packageRoot, '.claude-plugin/plugin.json')).skills;
        check(Array.isArray(configured) && JSON.stringify(configured.map(String).map(p => p.split('/').at(-1)).sort()) === JSON.stringify(actual), 'Public skill distribution parity broken');
        check(text(join(packageRoot, 'scripts/add-project-skills.mjs')).includes('installProjectSkills'), 'Project installer no longer delegates canonical skill discovery');
        const sync = run(process.execPath, [join(packageRoot, 'scripts/sync-harness-skills.mjs'), '--check'], { capture: true, allowFailure: true });
        check(sync.status === 0, 'Generated skill mirrors drifted');
        for (const engine of ['LiteRT-LM', 'MLX'])
            check(paths.some(path => text(path).includes(engine)), `${engine} inference lane undocumented`);
        for (const error of checkW6(packageRoot))
            check(false, error);
    }
    else if (mode === 'generator-purity') {
        const paths = ['scripts', 'assets/templates', 'templates'].flatMap(p => files(join(packageRoot, p)));
        const allow = ['assets/templates/rust/vendor/', 'scripts/audit.', 'scripts/portable/audit.', 'scripts/consolidate-prometheus-wikis.', 'scripts/worktree-consolidation-inventory.', 'scripts/native-helpers/consolidate-prometheus-wikis.', 'scripts/native-helpers/worktree-consolidation-inventory.', 'scripts/native-helpers/wiki-common.', 'scripts/merge-zed-context-servers.mjs'];
        check(paths.length > 0, 'No generator surfaces');
        for (const path of paths) {
            const local = relative(packageRoot, path).replaceAll('\\', '/');
            if (allow.some(part => local.includes(part)))
                continue;
            for (const pattern of [/knowme-poc|know-me-system|KnowMe app shell|KnowMe-specific/, /FUNC-SPEC/, /tools\.knowme/, /know-me\.tools/, /FF6A3D|ff6a3d/])
                check(!pattern.test(text(path)), `Product vocabulary ${pattern} in ${local}`);
        }
        check(paths.some(path => /__[A-Z_]+__|@[A-Z_]+@/.test(text(path))), 'No generator placeholder tokens found', true);
    }
    else
        throw new Error(`Unknown audit mode: ${mode}`);
    return result;
}

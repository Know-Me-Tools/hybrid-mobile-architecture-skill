import {readdir, readFile} from 'node:fs/promises';
import {join} from 'node:path';

const roots = ['docs', 'src', 'static'];
const forbidden = [
  /\/Users\//,
  /\.prometheus\//,
  /prometheus-wiki-private/i,
  /BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY/,
  /(?:api[_-]?key|client[_-]?secret|password)\s*[:=]\s*["'][^"']+/i,
];
async function files(dir) { const out=[]; for (const item of await readdir(dir,{withFileTypes:true})) { const path=join(dir,item.name); item.isDirectory()?out.push(...await files(path)):out.push(path); } return out; }
const violations=[];
for (const root of roots) for (const file of await files(root)) { const text=await readFile(file,'utf8'); for (const rule of forbidden) if (rule.test(text)) violations.push(`${file}: ${rule}`); }
if (violations.length) { console.error(violations.join('\n')); process.exit(1); }
console.log('public-content sanitization passed');

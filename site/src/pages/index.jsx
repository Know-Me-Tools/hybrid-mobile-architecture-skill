import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import styles from './index.module.css';

const paths = [
  ['Install', 'CLI, 29 skills, commands, plugins, adapters, and MCP utilities.', '/reference/installation'],
  ['Choose a profile', 'Sovereign hybrid, governed web shell, and component profiles.', '/architecture/profiles'],
  ['Use the skills', 'When to invoke every skill, why it exists, and its operating contract.', '/reference/skills'],
  ['CLI reference', 'Generate, adopt, upgrade, add, audit, and verify without destructive rewrites.', '/reference/cli'],
  ['Services', 'UAR, Prometheus, identity, policy, events, persistence, sync, and inference.', '/reference/services'],
  ['Use cases', 'Practical recipes for private assistants, governed shells, legacy apps, and more.', '/reference/use-cases'],
];

export default function Home() {
  return <Layout title="Build applications that understand" description="KnowMe hybrid application architecture and Prometheus skills">
    <main>
      <section className={styles.hero}>
        <span className={styles.eyebrow}>KNOWME BUILDER</span>
        <h1>Build software that understands its users.</h1>
        <p>Versioned, non-destructive application generation for Flutter, Tauri, React, Axum, Rust, and Universal Agent Runtime.</p>
        <div className={styles.actions}><Link className={styles.primary} to="/reference/installation">Install Builder</Link><Link className={styles.secondary} to="/reference/first-project">Build or adopt a project</Link></div>
      </section>
      <section className={styles.grid}>{paths.map(([title, copy, to]) => <Link className={styles.card} to={to} key={title}><span>{title}</span><p>{copy}</p></Link>)}</section>
    </main>
  </Layout>;
}

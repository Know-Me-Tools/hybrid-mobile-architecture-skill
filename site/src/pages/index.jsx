import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import styles from './index.module.css';

const paths = [
  ['Architecture', 'One Rust core, three native surfaces.', '/architecture/intro'],
  ['Reference app', 'See KnowMe’s local-first agent experience.', '/reference/knowme-app'],
  ['Deployment', 'Compose, immutable images, and multi-cloud GitOps.', '/deployment/catalog'],
  ['Prompting', 'Run deliberate learn, build, verify, and retain loops.', '/prompting/playbook'],
];

export default function Home() {
  return <Layout title="Build applications that understand" description="KnowMe hybrid application architecture and Prometheus skills">
    <main>
      <section className={styles.hero}>
        <span className={styles.eyebrow}>KNOWME BUILDER</span>
        <h1>Build software that understands its users.</h1>
        <p>One architecture for Flutter mobile, Tauri desktop, React and Axum web—powered by a shared Rust agent runtime.</p>
        <div className={styles.actions}><Link className={styles.primary} to="/architecture/intro">Start building</Link><Link className={styles.secondary} to="/prompting/playbook">Open the playbook</Link></div>
      </section>
      <section className={styles.grid}>{paths.map(([title, copy, to]) => <Link className={styles.card} to={to} key={title}><span>{title}</span><p>{copy}</p></Link>)}</section>
    </main>
  </Layout>;
}

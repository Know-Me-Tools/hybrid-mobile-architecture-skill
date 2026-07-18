import {themes as prismThemes} from 'prism-react-renderer';

const siteUrl = process.env.SITE_URL || 'https://know-me-tools.github.io';
const baseUrl = process.env.BASE_URL || '/hybrid-mobile-architecture-skill/';

export default {
  title: 'KnowMe Builder',
  tagline: 'Build private, agentic applications that understand their users.',
  favicon: 'img/knowme-mark.svg',
  url: siteUrl,
  baseUrl,
  organizationName: 'Know-Me-Tools',
  projectName: 'hybrid-mobile-architecture-skill',
  trailingSlash: false,
  onBrokenLinks: 'throw',
  markdown: {mermaid: true, hooks: {onBrokenMarkdownLinks: 'throw'}},
  themes: ['@docusaurus/theme-mermaid'],
  presets: [[
    'classic',
    {
      docs: {path: 'docs/architecture', routeBasePath: 'architecture', sidebarPath: './sidebars.architecture.mjs'},
      blog: false,
      theme: {customCss: './src/css/custom.css'},
      sitemap: {changefreq: 'weekly', priority: 0.5}
    }
  ]],
  plugins: [
    ['@docusaurus/plugin-content-docs', {id: 'reference', path: 'docs/reference', routeBasePath: 'reference', sidebarPath: './sidebars.reference.mjs'}],
    ['@docusaurus/plugin-content-docs', {id: 'deployment', path: 'docs/deployment', routeBasePath: 'deployment', sidebarPath: './sidebars.deployment.mjs'}],
    ['@docusaurus/plugin-content-docs', {id: 'prompting', path: '../docs/prompting', routeBasePath: 'prompting', sidebarPath: './sidebars.prompting.mjs'}],
    ['@easyops-cn/docusaurus-search-local', {hashed: true, indexDocs: true, indexPages: true, indexBlog: false, docsRouteBasePath: ['/architecture', '/reference', '/deployment', '/prompting']}]
  ],
  themeConfig: {
    image: 'img/knowme-builder-documentation-og.png',
    metadata: [
      {property: 'og:image', content: `${siteUrl}${baseUrl}img/knowme-builder-documentation-og.png`},
      {
        property: 'og:image:alt',
        content: 'KnowMe Builder documentation homepage: build software that understands its users.'
      },
      {property: 'og:image:type', content: 'image/png'},
      {property: 'og:image:width', content: '3460'},
      {property: 'og:image:height', content: '2130'},
      {name: 'twitter:card', content: 'summary_large_image'},
      {name: 'twitter:image', content: `${siteUrl}${baseUrl}img/knowme-builder-documentation-og.png`},
      {
        name: 'twitter:image:alt',
        content: 'KnowMe Builder documentation homepage: build software that understands its users.'
      }
    ],
    colorMode: {defaultMode: 'dark', respectPrefersColorScheme: true, disableSwitch: false},
    navbar: {
      title: 'KnowMe', logo: {alt: 'KnowMe conviction mark', src: 'img/knowme-mark.svg'},
      items: [
        {to: '/architecture/intro', label: 'Architecture', position: 'left'},
        {to: '/reference/knowme-app', label: 'Reference app', position: 'left'},
        {to: '/deployment/catalog', label: 'Deploy', position: 'left'},
        {to: '/prompting/playbook', label: 'Prompting', position: 'left'},
        {href: 'https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill', label: 'GitHub', position: 'right'}
      ]
    },
    footer: {style: 'dark', copyright: `KnowMe · ${new Date().getFullYear()} · AI that understands you.`},
    prism: {theme: prismThemes.github, darkTheme: prismThemes.dracula},
    mermaid: {theme: {light: 'neutral', dark: 'dark'}}
  }
};

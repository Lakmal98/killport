import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'killport',
  description: 'Production-ready CLI to free busy ports safely and quickly.',
  lang: 'en',
  lastUpdated: true,
  cleanUrls: true,
  sitemap: {
    hostname: 'https://killport.vercel.app'
  },
  head: [
    ['meta', { name: 'robots', content: 'index, follow' }],
    ['meta', { name: 'author', content: 'Lakmal98' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: 'killport docs' }],
    ['meta', { property: 'og:title', content: 'killport documentation' }],
    ['meta', { property: 'og:description', content: 'Install, use, and troubleshoot killport in production environments.' }],
    ['meta', { property: 'og:url', content: 'https://killport.vercel.app' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'killport documentation' }],
    ['meta', { name: 'twitter:description', content: 'Install, use, and troubleshoot killport in production environments.' }],
    ['link', { rel: 'canonical', href: 'https://killport.vercel.app/' }]
  ],
  locales: {
    root: {
      label: 'English',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/usage' },
          { text: 'Troubleshooting', link: '/troubleshooting' },
          { text: 'Contributing', link: '/contributing' }
        ],
        sidebar: [
          {
            text: 'Documentation',
            items: [
              { text: 'Overview', link: '/' },
              { text: 'Usage', link: '/usage' },
              { text: 'Troubleshooting', link: '/troubleshooting' },
              { text: 'Contributing', link: '/contributing' }
            ]
          }
        ]
      }
    }
  }
})

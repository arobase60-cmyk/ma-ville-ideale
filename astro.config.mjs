// @ts-check
import { defineConfig } from 'astro/config';

import svelte from '@astrojs/svelte';

import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://trouver-ma-ville-ideale.fr',
  base: '/',
  integrations: [svelte(), sitemap()],
});
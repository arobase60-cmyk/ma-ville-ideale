// @ts-check
import { defineConfig } from 'astro/config';

import svelte from '@astrojs/svelte';

export default defineConfig({
  site: 'https://trouver-ma-ville-ideale.fr',
  base: '/',
  integrations: [svelte()],
});
#!/usr/bin/env node

/**
 * Build script — bundles ChatEngine + ConnectionQualityMonitor into a single
 * IIFE file for importScripts() in the SharedWorker.
 *
 * Output: public/chat-worker-engine.js
 *
 * Run: node scripts/build-worker.js
 * Also runs automatically via "prebuild" npm script.
 */

const { build } = require('esbuild')
const path = require('path')

build({
  entryPoints: [path.resolve(__dirname, '../src/lib/chat/worker-engine-entry.ts')],
  bundle: true,
  format: 'iife',
  globalName: 'BlakJaksChat',
  outfile: path.resolve(__dirname, '../public/chat-worker-engine.js'),
  platform: 'browser',
  target: ['es2020'],
  minify: process.env.NODE_ENV === 'production',
  sourcemap: process.env.NODE_ENV !== 'production',
  define: {
    'process.env.NEXT_PUBLIC_API_URL': JSON.stringify(process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'),
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV ?? 'development'),
  },
}).then(() => {
  console.log('Built public/chat-worker-engine.js')
}).catch((err) => {
  console.error('Build failed:', err)
  process.exit(1)
})

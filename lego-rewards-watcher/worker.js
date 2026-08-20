// PLACEHOLDER -- not the real lego-rewards-watcher source.
//
// This worker has never had a repo anywhere (see wrangler.toml's own
// comment for the full story) and its actual content couldn't be pulled
// via the Cloudflare API this session (OAuth token rejected by the
// .../content endpoint specifically, confirmed reproducible). This file
// exists only so `wrangler deploy --dry-run` could validate wrangler.toml's
// reconstructed bindings/triggers against the live worker's real config.
//
// DO NOT DEPLOY THIS FILE FOR REAL -- it would wipe out the actual
// scheduled()/fetch() logic. Replace this with the real source (pasted
// from the Cloudflare dashboard's Quick Edit view) before ever running
// a real `wrangler deploy` from this folder.
export default {
  async fetch(request, env, ctx) {
    return new Response('placeholder -- see comment at top of this file', { status: 501 });
  },
  async scheduled(event, env, ctx) {
    // placeholder
  },
};

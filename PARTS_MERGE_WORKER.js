// brikstax-worker -- POST /parts-merge
//
// Merges the piece lists of up to 20 official LEGO sets (by set number)
// into one combined list, same part+color from different sets summed into
// a single row instead of duplicated. MOCs are NOT supported here -- Rebrickable
// removed MOC data from their public API in 2020, so a set-number lookup can
// never resolve one. Instead, MOC support lives entirely client-side in
// cloudflare-site/parts-merger.html: the user exports a MOC's own parts list
// as CSV from its Rebrickable page (a feature the *website* still has, even
// though the *API* doesn't) and uploads it, and the browser merges that CSV
// with whatever this endpoint returns. This file is unaware MOCs exist at
// all -- an id that looks like a MOC id is rejected with a specific warning
// telling the caller why, rather than a generic 404.
//
// THIS IS THE AUTHORED, COMMENTED SOURCE. The version actually deployed
// lives in cloudflare-worker/worker.js as part of one big bundled file (see
// that folder's README for why it has no comments) -- after editing this
// file, apply the same change there too and either paste the whole updated
// worker.js into the Cloudflare dashboard by hand, or run `wrangler deploy`
// from cloudflare-worker/. Never edit cloudflare-worker/worker.js directly
// as your primary source; the next real pull from the dashboard would just
// overwrite it.
//
// Route wiring (in the main router):
//   if (url.pathname === "/parts-merge" && request.method === "POST") {
//     return handlePartsMerge(request, env);
//   }

async function handlePartsMerge(req, env) {
  let body;
  try {
    body = await req.json();
  } catch {
    return err('Invalid JSON body');
  }

  const ids = Array.isArray(body.ids)
    ? [...new Set(body.ids.map(s => String(s).trim()).filter(Boolean))]
    : [];
  if (ids.length === 0) return err('No valid Set/MOC IDs provided');
  if (ids.length > 20) return err('Too many sets at once (max 20)');
  if (!env.RB_KEY) return err('Server configuration error', 500);

  async function rb(path) {
    const res = await rbFetch(path, env);
    if (!res.ok) throw new Error(`Rebrickable ${res.status}`);
    return res.json();
  }

  const partsMap = new Map(); // "partNum__colorId" -> merged row
  const failed = [];
  let setsResolved = 0;

  for (const rawId of ids) {
    if (rawId.toLowerCase().startsWith('moc')) {
      failed.push(`"${rawId}" -- MOCs aren't supported (Rebrickable removed MOC data from their API in 2020); only official LEGO set numbers work`);
      continue;
    }

    const idPath = `sets/${rawId.includes('-') ? rawId : rawId + '-1'}`;
    try {
      // Rebrickable paginates at 100 parts/page by default; a big set
      // (e.g. 75192 UCS Millennium Falcon, ~7500 pieces across ~500 distinct
      // part+color rows) needs several pages.
      let allParts = [];
      let nextPath = `${idPath}/parts/?page_size=100`;
      while (nextPath) {
        const d = await rb(nextPath);
        allParts = allParts.concat(d.results || []);
        if (d.next) {
          const u = new URL(d.next);
          nextPath = `${idPath}/parts/${u.search}`;
        } else {
          nextPath = null;
        }
      }

      if (allParts.length === 0) {
        failed.push(`Could not find parts for "${rawId}" -- check the set number`);
        continue;
      }
      setsResolved++;

      for (const p of allParts) {
        const key = `${p.part.part_num}__${p.color.id}`;
        if (!partsMap.has(key)) {
          // Rebrickable's part/color objects already carry each catalog's
          // own numbering under external_ids -- confirmed live via a direct
          // API call (2026-08-12): part.external_ids.BrickLink is an array
          // of BrickLink part numbers, color.external_ids.BrickLink.ext_ids
          // is an array of BrickLink's numeric color IDs. BrickLink's part
          // numbers and color IDs are NOT the same numbering as
          // Rebrickable's own colorId above -- this is the only correct
          // source for a BrickLink-importable output, and costs no extra
          // API calls since it's already in this same response.
          //
          // Not every part/color has a known BrickLink mapping. Both fields
          // fall back to "" when absent; the client (parts-merger.html)
          // skips those rows out of the BrickLink XML it generates rather
          // than emit a wrong or blank id, and says so in a warning.
          const blPartNum = p.part.external_ids?.BrickLink?.[0] || '';
          const blColorIdRaw = p.color.external_ids?.BrickLink?.ext_ids?.[0];
          const blColorId = (blColorIdRaw === undefined || blColorIdRaw === null) ? '' : String(blColorIdRaw);

          partsMap.set(key, {
            partNum: p.part.part_num,
            name: p.part.name,
            colorId: p.color.id,
            color: p.color.name,
            qty: 0,
            spareQty: 0,
            blPartNum,
            blColorId
          });
        }
        const entry = partsMap.get(key);
        if (p.is_spare) entry.spareQty += p.quantity;
        else entry.qty += p.quantity;
      }
    } catch (e) {
      failed.push(`Error fetching "${rawId}": ${e.message}`);
    }
  }

  if (partsMap.size === 0) {
    return json({ success: false, error: 'No parts found for any of the given IDs', warnings: failed }, 404);
  }

  const parts = [...partsMap.values()].sort((a, b) => a.partNum.localeCompare(b.partNum));

  // The client (parts-merger.html) treats this CSV as the canonical row
  // shape for everything downstream -- it re-parses this same text through
  // its own generic CSV reader (so uploaded MOC CSVs and this response go
  // through one merge code path, not two), then builds both downloadable
  // files from the merged result: a plain PAB/reference CSV (this shape,
  // unchanged) and a BrickLink Wanted List XML (using the BrickLink Part
  // Number / BrickLink Color ID columns, dropping any row missing either).
  let csv = 'Part Number,BrickLink Part Number,Color ID,BrickLink Color ID,Color,Quantity,Spare Qty\n';
  for (const p of parts) {
    const colorField = p.color.includes(',') ? `"${p.color}"` : p.color;
    csv += `${p.partNum},${p.blPartNum},${p.colorId},${p.blColorId},${colorField},${p.qty},${p.spareQty}\n`;
  }

  return json({
    success: true,
    csv,
    partCount: parts.length,
    setCount: setsResolved,
    // Real warnings -- which input IDs actually failed to resolve and why
    // (MOC/not-found/fetch-error each read differently), not a fabricated
    // per-part "replaced" claim. A typo'd set number used to just silently
    // vanish from the merged list with zero feedback.
    warnings: failed
  });
}

// Uses whatever json()/err()/rbFetch() helpers already exist elsewhere in
// worker.js -- json() wraps a value as a JSON Response, err() returns a
// { error } JSON Response with a status code (400 by default), rbFetch()
// round-robins across the RB_KEY/RB_KEY2/RB_KEY3 Rebrickable keys already
// configured for the rest of the worker.

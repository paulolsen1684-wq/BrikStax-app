# Worker Integration - Copy & Paste Guide

## Step 1: Add Route Handler

In your `brikstax-worker/src/worker.js`, find your router section and add:

```javascript
// Add this line with your other route handlers
if (url.pathname === '/parts-merge') {
  return handlePartsMerge(request, env);
}
```

Example placement:
```javascript
const url = new URL(request.url);

// Existing routes
if (url.pathname === '/deals') {
  return handleDeals(request, env);
}
if (url.pathname === '/features') {
  return handleFeatures(request, env);
}

// ADD THIS:
if (url.pathname === '/parts-merge') {
  return handlePartsMerge(request, env);
}

// ... rest of your router
```

---

## Step 2: Add Handler Functions

Add this entire block to your worker.js (at the end, before the export):

```javascript
async function handlePartsMerge(req, env) {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const { ids, format } = await req.json();
    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid Set/MOC IDs provided' }), { status: 400 });
    }

    const rbKey = env.REBRICKABLE_KEY;
    if (!rbKey) {
      return new Response(JSON.stringify({ error: 'Server configuration error' }), { status: 500 });
    }

    // Fetch parts for each set/MOC
    const partsMap = new Map();
    const replacements = [];

    for (const id of ids) {
      const isMoc = id.startsWith('moc_');
      const endpoint = isMoc
        ? `https://rebrickable.com/api/v3/lego/mocs/${id}/parts/`
        : `https://rebrickable.com/api/v3/lego/sets/${id}/parts/`;

      try {
        const res = await fetch(endpoint, {
          headers: { 'Authorization': `key ${rbKey}` }
        });

        if (res.status === 404) continue;
        if (!res.ok) continue;

        const data = await res.json();
        const parts = data.results || [];

        for (const part of parts) {
          const partId = part.part.part_num;
          const colorId = part.color.id;
          const qty = part.quantity;
          const isReplaced = part.is_spare || false;

          if (!partsMap.has(partId)) {
            partsMap.set(partId, {
              name: part.part.name,
              colors: new Map(),
              isReplaced: isReplaced
            });
          }

          const existing = partsMap.get(partId);
          if (!existing.colors.has(colorId)) {
            existing.colors.set(colorId, { qty: 0, colorName: part.color.name });
          }
          existing.colors.get(colorId).qty += qty;

          if (isReplaced && !replacements.includes(partId)) {
            replacements.push(`${part.part.name} (${partId})`);
          }
        }
      } catch (e) {
        console.error(`Failed to fetch parts for ${id}:`, e);
      }
    }

    // Generate output
    let csv = '';
    let warnings = [];

    if (format === 'bricklink' || format === 'both') {
      csv = generateBrickLinkCSV(partsMap);
    }

    if (format === 'pab' || format === 'both') {
      warnings = Array.from(replacements).slice(0, 10);
      if (format === 'both') {
        csv += '\n\n--- PICK-A-BRICK FORMAT ---\n\n';
      }
      csv += generatePABList(partsMap, warnings);
    }

    return new Response(JSON.stringify({
      success: true,
      csv: csv,
      bricklink: format === 'bricklink' ? csv : null,
      pab: format === 'pab' ? csv : null,
      warnings: warnings,
      partCount: partsMap.size
    }), {
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (err) {
    console.error('Parts merge error:', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
}

function generateBrickLinkCSV(partsMap) {
  let csv = 'Part Number,Color ID,Color,Quantity\n';

  for (const [partId, partData] of partsMap) {
    for (const [colorId, colorData] of partData.colors) {
      csv += `${partId},${colorId},${colorData.colorName},${colorData.qty}\n`;
    }
  }

  return csv;
}

function generatePABList(partsMap, warnings) {
  let csv = 'Part Number,Color,Quantity,Availability\n';

  for (const [partId, partData] of partsMap) {
    const status = partData.isReplaced ? 'REPLACED' : 'AVAILABLE';
    for (const [colorId, colorData] of partData.colors) {
      csv += `${partId},${colorData.colorName},${colorData.qty},${status}\n`;
    }
  }

  if (warnings.length > 0) {
    csv += '\n# WARNING: The following parts have been replaced on official sets:\n';
    warnings.forEach(w => {
      csv += `# - ${w}\n`;
    });
  }

  return csv;
}
```

---

## Step 3: Export Handler (if using modules)

If your worker uses ES modules, add to exports:

```javascript
export { handlePartsMerge };
```

Or if you're using the handler directly in the same file, no export needed.

---

## Step 4: Verify Environment Variables

Check your `wrangler.toml` has:

```toml
[env.production]
vars = { 
  REBRICKABLE_KEY = "your-key-here"
}
```

If you need to add it:
```bash
wrangler secret put REBRICKABLE_KEY
# (paste your key when prompted)
```

---

## Step 5: Deploy

```bash
wrangler deploy
```

Wait for deployment to complete, then test:

```bash
curl -X POST https://brikstax-worker.paul-olsen1684.workers.dev/parts-merge \
  -H "Content-Type: application/json" \
  -d '{"ids": ["75192"], "format": "bricklink"}'
```

Should return JSON with CSV data.

---

## Deployment Checklist

- [ ] Added route handler to worker.js
- [ ] Added all three functions (handlePartsMerge, generateBrickLinkCSV, generatePABList)
- [ ] REBRICKABLE_KEY exists in wrangler.toml
- [ ] Deployed worker with `wrangler deploy`
- [ ] Tested endpoint with curl or Postman
- [ ] Getting valid JSON response
- [ ] Pushed `parts-merger.html` to cloudflare-site/
- [ ] Page available at brikstax.pages.dev/parts-merger
- [ ] Tested page - can enter IDs and get results

---

## Testing the Full Flow

1. **Test worker endpoint directly**:
   ```bash
   curl -X POST https://brikstax-worker.paul-olsen1684.workers.dev/parts-merge \
     -H "Content-Type: application/json" \
     -d '{"ids": ["75192", "75340"], "format": "bricklink"}'
   ```

2. **Test via web page**:
   - Visit `https://brikstax.pages.dev/parts-merger`
   - Enter: `75192, 75340`
   - Select: "BrickLink CSV"
   - Click: "MERGE PARTS"
   - Should see results instantly

3. **Download test**:
   - Click "DOWNLOAD CSV"
   - Should save `brikstax-parts-TIMESTAMP.csv`
   - Open in Excel/spreadsheet app to verify format

Done! 🎉

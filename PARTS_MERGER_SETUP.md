# Parts Merger Setup Guide

## Overview
New feature to merge multiple LEGO sets/MOCs into a combined shopping list for BrickLink or Pick-a-Brick.

**Page**: `https://brikstax.pages.dev/parts-merger`
**Endpoint**: `POST /parts-merge` on your Cloudflare Worker

---

## Files Created

### 1. Frontend
- **`cloudflare-site/parts-merger.html`** - Standalone page with form and results display
  - Users enter set/MOC IDs (comma-separated or one per line)
  - Choose output format: BrickLink, PAB, or Both
  - Download merged parts CSV
  - Auto-deployed to `brikstax.pages.dev/parts-merger`

### 2. Worker Endpoint
- **`PARTS_MERGE_WORKER.js`** - Code to add to your `brikstax-worker`
  - Queries Rebrickable API for each set/MOC
  - Merges parts across sets (sums quantities for duplicates)
  - Generates BrickLink CSV with exact pieces
  - Generates PAB list with replacement warnings
  - Returns JSON response with CSV data and warnings

---

## Integration Steps

### Step 1: Update Worker Code
In your `brikstax-worker/src/worker.js`, add:

```javascript
// At the top with other imports/handlers:
import { handlePartsMerge } from './handlers/parts-merge.js';

// Or directly in your router:
if (url.pathname === '/parts-merge') {
  return handlePartsMerge(request, env);
}
```

### Step 2: Add Handler Function
Copy the entire `PARTS_MERGE_WORKER.js` content into your worker, or:

1. Create `src/handlers/parts-merge.js`
2. Paste the handler functions (`handlePartsMerge`, `generateBrickLinkCSV`, `generatePABList`)
3. Export `handlePartsMerge`

### Step 3: Verify Rebrickable API Access
Ensure `env.REBRICKABLE_KEY` is set in your `wrangler.toml`:

```toml
[env.production]
vars = { REBRICKABLE_KEY = "your-api-key-here" }
```

### Step 4: Deploy
```bash
wrangler deploy
```

---

## API Response Format

### Request
```json
{
  "ids": ["75192", "75340", "moc_12345"],
  "format": "bricklink" // or "pab" or "both"
}
```

### Response
```json
{
  "success": true,
  "csv": "Part Number,Color ID,Color,Quantity\n...",
  "bricklink": null,
  "pab": null,
  "warnings": [
    "Part Name (part_id) - replaced on set XYZ"
  ],
  "partCount": 847
}
```

---

## Output Formats

### BrickLink CSV
```
Part Number,Color ID,Color,Quantity
3001,16,Brick tan,24
3001,1,White,16
3002,5,Red,8
```
- Ready to import into BrickLink
- Uses exact Rebrickable part IDs and colors
- Sums quantities across all input sets

### Pick-a-Brick List
```
Part Number,Color,Quantity,Availability
3001,Brick tan,24,AVAILABLE
3001,White,16,AVAILABLE
3002,Red,8,REPLACED
```
- Includes availability status
- Flags parts marked as replaced/spare
- Comments at bottom list replaced parts
- Ready to cross-reference with official PAB inventory

---

## Features

✅ Support for both official sets and MOCs
✅ Automatic part merging (sum quantities)
✅ Two output formats (BrickLink & PAB)
✅ Replacement warnings for PAB
✅ CSV download
✅ Error handling for invalid IDs
✅ Caching headers for performance

---

## Testing

1. Visit `https://brikstax.pages.dev/parts-merger`
2. Enter set IDs: `75192, 75340`
3. Select format: "BrickLink CSV"
4. Click "MERGE PARTS"
5. Should display merged parts list
6. Click "DOWNLOAD CSV" to save

---

## Troubleshooting

**"Server error" message**
- Check Rebrickable API key is set in wrangler.toml
- Verify worker is deployed with new `/parts-merge` endpoint

**"Part not found" for MOC**
- Verify MOC ID is correct format: `moc_12345` (not `MOC_12345`)
- MOC must exist on Rebrickable

**Empty results**
- Set IDs may not exist or be inactive
- Check IDs on rebrickable.com first

**Download doesn't work**
- Try copying text from results box and pasting to file
- Or use browser's Network tab to inspect response

---

## Future Enhancements
- Filter by color availability
- BrickLink order pre-fill
- Price estimates from BrickLink
- Exclude duplicate/similar parts option
- Inventory comparison for existing parts

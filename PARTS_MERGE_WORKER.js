// Add this to your brikstax-worker's worker.js
// Handles POST /parts-merge requests to merge multiple sets into shopping lists

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
    const partsMap = new Map(); // partId -> { name, colors: Map<colorId, qty> }
    const replacements = []; // Track replaced parts

    for (const id of ids) {
      const isMoc = id.startsWith('moc_');
      const endpoint = isMoc
        ? `https://rebrickable.com/api/v3/lego/mocs/${id}/parts/`
        : `https://rebrickable.com/api/v3/lego/sets/${id}/parts/`;

      try {
        const res = await fetch(endpoint, {
          headers: { 'Authorization': `key ${rbKey}` }
        });

        if (res.status === 404) {
          // Skip not found
          continue;
        }
        if (!res.ok) continue;

        const data = await res.json();
        const parts = data.results || [];

        for (const part of parts) {
          const partId = part.part.part_num;
          const colorId = part.color.id;
          const qty = part.quantity;
          const isReplaced = part.is_spare || false; // Flag for replaced parts

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

    // Generate output based on format
    let csv = '';
    let warnings = [];

    if (format === 'bricklink' || format === 'both') {
      csv = generateBrickLinkCSV(partsMap);
    }

    if (format === 'pab' || format === 'both') {
      warnings = Array.from(replacements).slice(0, 10); // Limit warnings
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

// In your router, add this:
// if (url.pathname === '/parts-merge') {
//   return handlePartsMerge(request, env);
// }

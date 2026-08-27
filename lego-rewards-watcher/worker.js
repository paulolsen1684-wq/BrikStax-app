var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// worker.js
var __defProp2 = Object.defineProperty;
var __name2 = /* @__PURE__ */ __name((target, value) => __defProp2(target, "name", { value, configurable: true }), "__name");
var GRAPHQL_ENDPOINT = "https://www.lego.com/api/graphql/rewardListing";
var QUERY = `fragment Dimensions on Dimensions {
  width
  height
  __typename
}

fragment ListingRewardImageAssetDetails on RewardImageAssetDetails {
  id
  url
  listingDimensions {
    ...Dimensions
    __typename
  }
  __typename
}

query rewardListing($input: RewardListingInputV2) {
  rewardListing: rewardListingV2(input: $input) {
    filterFacets
    paginationDetails {
      page
      size
      lastPage
      firstEntry
      lastEntry
      total
      __typename
    }
    rewards: rewardsV2 {
      id
      title
      pointValue
      startDate
      endDate
      nonLocalisedStartDate
      nonLocalisedEndDate
      rewardId
      urlTitleSlug
      restrictedInCountry
      type
      category
      quantity
      rewardSkus {
        sku
        skuType
        __typename
      }
      new
      images {
        ...ListingRewardImageAssetDetails
        __typename
      }
      __typename
    }
    __typename
  }
}`;
var SNAPSHOT_KEY = "rewards_snapshot";
var SESSION_OVERRIDE_KEY = "session_override";
var AUTH_ALERT_KEY = "auth_alert_sent";
var CHANGES_KEY = "rewards_changes_history";
var MAX_PAGES = 20;
var MAX_STORED_CHANGES = 50;
var worker_default = {
  async scheduled(event, env, ctx) {
    ctx.waitUntil(runCheck(env));
  },
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/sync" && request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders() });
    }
    if (url.pathname === "/sync" && request.method === "POST") {
      return handleSync(request, env, url);
    }
    if (url.pathname === "/status" && request.method === "GET") {
      return handleStatus(env);
    }
    if (url.pathname === "/trigger" && request.method === "POST") {
      return handleTrigger(request, env);
    }
    if (!env.MANUAL_TRIGGER_KEY || url.searchParams.get("key") !== env.MANUAL_TRIGGER_KEY) {
      return new Response("Forbidden", { status: 403 });
    }
    if (url.searchParams.get("testEmail") === "1") {
      const emailResult = await sendEmail(
        env,
        "LEGO Rewards Watcher: test email",
        "If you got this, email alerts are working."
      );
      return new Response(JSON.stringify(emailResult, null, 2), {
        headers: { "content-type": "application/json" }
      });
    }
    if (url.searchParams.get("testBrikStaxPush") === "1") {
      const result2 = await sendBrikStaxPush(
        env,
        "LEGO Rewards Watcher: test push",
        "If you got this, the BrikStax push channel is working."
      );
      return new Response(JSON.stringify(result2, null, 2), {
        headers: { "content-type": "application/json" }
      });
    }
    return new Response(JSON.stringify({ ok: true, note: "worker is alive. POST /trigger to run a check now, GET /status to view recent changes." }, null, 2), {
      headers: { "content-type": "application/json" }
    });
  }
};
function corsHeaders() {
  return {
    "access-control-allow-origin": "https://www.lego.com",
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers": "content-type"
  };
}
__name(corsHeaders, "corsHeaders");
__name2(corsHeaders, "corsHeaders");
async function handleSync(request, env, url) {
  if (!env.SYNC_KEY || url.searchParams.get("key") !== env.SYNC_KEY) {
    return new Response("Forbidden", { status: 403, headers: corsHeaders() });
  }
  let body;
  try {
    body = await request.json();
  } catch {
    return new Response("Bad Request: invalid JSON", { status: 400, headers: corsHeaders() });
  }
  if (!body.authorization) {
    return new Response("Bad Request: missing authorization", { status: 400, headers: corsHeaders() });
  }
  await env.REWARDS_KV.put(
    SESSION_OVERRIDE_KEY,
    JSON.stringify({
      authorization: body.authorization,
      cookie: body.cookie ?? "",
      fffId: body.fffId ?? "",
      sessionCookieId: body.sessionCookieId ?? "",
      visitorGuid: body.visitorGuid ?? "",
      syncedAt: Date.now()
    })
  );
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "content-type": "application/json", ...corsHeaders() }
  });
}
__name(handleSync, "handleSync");
__name2(handleSync, "handleSync");
async function buildHeaders(env) {
  const overrideRaw = await env.REWARDS_KV.get(SESSION_OVERRIDE_KEY);
  const override = overrideRaw ? JSON.parse(overrideRaw) : null;
  return {
    accept: "*/*",
    "content-type": "application/json",
    authorization: override?.authorization || env.LEGO_AUTHORIZATION,
    cookie: override?.cookie || env.LEGO_COOKIE,
    "fff-id": override?.fffId || env.LEGO_FFF_ID,
    "session-cookie-id": override?.sessionCookieId || env.LEGO_SESSION_COOKIE_ID,
    "visitor-guid": override?.visitorGuid || env.LEGO_VISITOR_GUID,
    "x-locale": "en-US",
    origin: "https://www.lego.com",
    referer: "https://www.lego.com/en-us/insiders/rewards",
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36",
    "x-lego-request-id": crypto.randomUUID()
  };
}
__name(buildHeaders, "buildHeaders");
__name2(buildHeaders, "buildHeaders");
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
__name(sleep, "sleep");
__name2(sleep, "sleep");
async function fetchRewardsPage(env, page) {
  const res = await fetch(GRAPHQL_ENDPOINT, {
    method: "POST",
    headers: await buildHeaders(env),
    body: JSON.stringify({
      operationName: "rewardListing",
      variables: {
        input: {
          filters: {},
          pagination: { page },
          sectionId: env.LEGO_SECTION_ID
        }
      },
      query: QUERY
    })
  });
  const rawText = await res.text();
  let payload;
  try {
    payload = JSON.parse(rawText);
  } catch {
    return { error: "non-json-response", status: res.status };
  }
  if (payload.errors && payload.errors.length) {
    return { error: "graphql-error", errors: payload.errors };
  }
  return { listing: payload.data?.rewardListing };
}
__name(fetchRewardsPage, "fetchRewardsPage");
__name2(fetchRewardsPage, "fetchRewardsPage");
async function runCheck(env) {
  const first = await fetchRewardsPage(env, 1);
  if (first.error === "non-json-response") {
    await alertOnce(
      env,
      AUTH_ALERT_KEY,
      `⚠️ LEGO rewards check got a non-JSON response (status ${first.status}). This usually means the session expired and the browser sync hasn't refreshed it recently (visit the rewards page to trigger a re-sync), or LEGO's bot protection blocked the request. If it doesn't recover after a visit, re-capture the cURL and update the Worker secrets as a fallback.`
    );
    return { ok: false, status: first.status, reason: "non-json-response" };
  }
  if (first.error === "graphql-error") {
    await alertOnce(
      env,
      AUTH_ALERT_KEY,
      `⚠️ LEGO rewards GraphQL error: ${first.errors.map((e) => e.message).join("; ")}. Likely an expired session — visit the rewards page to trigger a re-sync, or re-capture the cURL and update the Worker secrets if that doesn't fix it.`
    );
    return { ok: false, reason: "graphql-error", errors: first.errors };
  }
  await env.REWARDS_KV.delete(AUTH_ALERT_KEY);
  let rewards = [...first.listing?.rewards ?? []];
  const pagination = first.listing?.paginationDetails ?? null;
  const lastPage = Math.min(pagination?.lastPage ?? 1, MAX_PAGES);
  let pagesFetched = 1;
  let pageFetchWarning = null;
  for (let page = 2; page <= lastPage; page++) {
    await sleep(300);
    const next = await fetchRewardsPage(env, page);
    if (next.error) {
      pageFetchWarning = `⚠️ Rewards check: failed to fetch page ${page} of ${lastPage} (${next.error}). Only ${rewards.length} of ${pagination?.total ?? "?"} items were checked this run.`;
      break;
    }
    rewards = rewards.concat(next.listing?.rewards ?? []);
    pagesFetched += 1;
  }
  if (pageFetchWarning) {
    await postDiscord(env, pageFetchWarning);
  }
  const current = {};
  for (const r of rewards) {
    current[r.id] = {
      title: r.title,
      pointValue: r.pointValue,
      quantity: r.quantity,
      type: r.type,
      category: r.category,
      restrictedInCountry: r.restrictedInCountry,
      new: r.new,
      slug: r.urlTitleSlug,
      endDate: r.endDate
    };
  }
  const previousRaw = await env.REWARDS_KV.get(SNAPSHOT_KEY);
  const previous = previousRaw ? JSON.parse(previousRaw) : {};
  const isBaseline = previousRaw === null;
  for (const id in current) {
    if (previous[id]?.wasExpirationAlerted === true) {
      current[id].wasExpirationAlerted = true;
    }
  }
  const changes = diff(previous, current);
  const notifyWorthy = isBaseline ? [] : changes.filter(isNotifyWorthy);
  if (!isBaseline) {
    await storeChanges(env, changes, rewards);
  }
  if (notifyWorthy.length) {
    const message = formatChanges(notifyWorthy);
    const title = `LEGO Rewards: ${notifyWorthy.length} update${notifyWorthy.length > 1 ? "s" : ""}`;
    // No link for a lone "removed" notification -- that reward's own page
    // will most likely 404 once it's delisted, so there's nothing useful
    // to click through to.
    const clickUrl = notifyWorthy.length === 1 && notifyWorthy[0].kind !== "removed" ? `https://www.lego.com/en-us/insiders/rewards/${notifyWorthy[0].after.slug}` : void 0;
    await postDiscord(env, message);
    const emailResult = await sendEmail(env, title, message);
    if (!emailResult.ok) {
      await postDiscord(env, `⚠️ Email alert failed to send: ${emailResult.reason ?? JSON.stringify(emailResult.body)}`);
    }
    const brikstaxResult = await sendBrikStaxPush(env, title, compactChangesBody(notifyWorthy), clickUrl);
    if (!brikstaxResult.ok) {
      await postDiscord(env, `⚠️ BrikStax push failed to send: ${brikstaxResult.reason ?? JSON.stringify(brikstaxResult.body)}`);
    }
  }
  const expiringItems = isBaseline ? [] : getExpiringItems(current, previous);
  if (expiringItems.length) {
    await storeExpiringHistory(env, expiringItems, rewards);
    const expiringMessage = formatExpiringItems(expiringItems);
    const expiringTitle = `LEGO Rewards: ${expiringItems.length} item${expiringItems.length > 1 ? "s" : ""} expiring soon`;
    const expiringClickUrl = expiringItems.length === 1 ? `https://www.lego.com/en-us/insiders/rewards/${expiringItems[0].slug}` : void 0;
    await postDiscord(env, expiringMessage);
    const emailResult = await sendEmail(env, expiringTitle, expiringMessage);
    if (!emailResult.ok) {
      await postDiscord(env, `⚠️ Expiring items email failed: ${emailResult.reason ?? JSON.stringify(emailResult.body)}`);
    }
    const brikstaxResult = await sendBrikStaxPush(env, expiringTitle, compactExpiringBody(expiringItems), expiringClickUrl);
    if (!brikstaxResult.ok) {
      await postDiscord(env, `⚠️ Expiring items BrikStax push failed: ${brikstaxResult.reason ?? JSON.stringify(brikstaxResult.body)}`);
    }
  }
  for (const item of expiringItems) {
    current[item.id].wasExpirationAlerted = true;
  }
  await env.REWARDS_KV.put(SNAPSHOT_KEY, JSON.stringify(current));
  return {
    ok: true,
    itemCount: rewards.length,
    expectedTotal: pagination?.total ?? null,
    pagesFetched,
    lastPage,
    totalChangeCount: changes.length,
    notifyCount: notifyWorthy.length,
    baseline: isBaseline
  };
}
__name(runCheck, "runCheck");
__name2(runCheck, "runCheck");
function isNotifyWorthy(change) {
  if (change.kind === "added") return true;
  if (change.kind === "removed") return true;
  if (change.kind === "changed") {
    if (change.before.quantity === 0 && change.after.quantity !== 0) return true;
    if (change.after.endDate && !change.before.endDate) {
      const expiresIn = new Date(change.after.endDate) - Date.now();
      if (expiresIn > 0 && expiresIn < 7 * 24 * 60 * 60 * 1e3) return true;
    }
  }
  return false;
}
__name(isNotifyWorthy, "isNotifyWorthy");
__name2(isNotifyWorthy, "isNotifyWorthy");
function getExpiringItems(current, previous) {
  const expiring = [];
  const sevenDaysMs = 7 * 24 * 60 * 60 * 1e3;
  const now = Date.now();
  for (const id in current) {
    const item = current[id];
    const wasAlerted = previous[id]?.wasExpirationAlerted === true;
    if (item.endDate && !wasAlerted && item.quantity > 0) {
      const expiresIn = new Date(item.endDate) - now;
      if (expiresIn > 0 && expiresIn < sevenDaysMs) {
        expiring.push({ id, ...item });
      }
    }
  }
  return expiring;
}
__name(getExpiringItems, "getExpiringItems");
__name2(getExpiringItems, "getExpiringItems");
function diff(previous, current) {
  const changes = [];
  const allIds = /* @__PURE__ */ new Set([...Object.keys(previous), ...Object.keys(current)]);
  for (const id of allIds) {
    const before = previous[id];
    const after = current[id];
    if (!before && after) {
      changes.push({ kind: "added", id, after });
      continue;
    }
    if (before && !after) {
      changes.push({ kind: "removed", id, before });
      continue;
    }
    if (!before || !after) continue;
    const fields = [];
    if (before.quantity !== after.quantity) {
      fields.push(`quantity ${before.quantity ?? "—"} → ${after.quantity ?? "—"}`);
    }
    if (before.pointValue !== after.pointValue) {
      fields.push(`points ${before.pointValue ?? "—"} → ${after.pointValue ?? "—"}`);
    }
    if (before.restrictedInCountry !== after.restrictedInCountry) {
      fields.push(`restricted ${before.restrictedInCountry} → ${after.restrictedInCountry}`);
    }
    if (before.type !== after.type) {
      fields.push(`type ${before.type} → ${after.type}`);
    }
    if (before.endDate !== after.endDate) {
      fields.push(`expiration ${before.endDate ?? "—"} → ${after.endDate ?? "—"}`);
    }
    if (fields.length) {
      changes.push({ kind: "changed", id, before, after, fields });
    }
  }
  return changes;
}
__name(diff, "diff");
__name2(diff, "diff");
function formatChanges(changes) {
  const lines = changes.map((c) => {
    // "removed" only ever has `before` (the item is gone from the current
    // fetch by definition -- that's what makes it "removed") -- handled
    // first and separately since every other branch here assumes `c.after`
    // exists, which would throw for this kind. No link included since the
    // reward's own page will most likely 404 once it's delisted.
    if (c.kind === "removed") {
      return `\u{1F5D1}️ Removed from rewards: **${c.before.title}** — was ${c.before.pointValue} pts`;
    }
    const url = `https://www.lego.com/en-us/insiders/rewards/${c.after.slug}`;
    const expiration = c.after.endDate ? ` — expires ${new Date(c.after.endDate).toLocaleDateString()}` : "";
    if (c.kind === "added") {
      return `\u{1F195} New reward listed: **${c.after.title}** — ${c.after.pointValue} pts, qty ${c.after.quantity ?? "—"}${expiration}
${url}`;
    }
    return `\u{1F4E6} Back in stock: **${c.after.title}** — qty ${c.before.quantity} → ${c.after.quantity}, ${c.after.pointValue} pts${expiration}
${url}`;
  });
  return `LEGO Insiders Rewards alert:
${lines.join("\n")}`;
}
__name(formatChanges, "formatChanges");
__name2(formatChanges, "formatChanges");
function formatExpiringItems(items) {
  const lines = items.map((item) => {
    const url = `https://www.lego.com/en-us/insiders/rewards/${item.slug}`;
    const expiresDate = new Date(item.endDate);
    const daysLeft = Math.ceil((expiresDate - Date.now()) / (24 * 60 * 60 * 1e3));
    return `⏰ **${item.title}** — ${item.pointValue} pts, expires in ${daysLeft} day${daysLeft !== 1 ? "s" : ""} (${expiresDate.toLocaleDateString()})
${url}`;
  });
  return `LEGO Insiders Rewards expiring soon:
${lines.join("\n")}`;
}
__name(formatExpiringItems, "formatExpiringItems");
__name2(formatExpiringItems, "formatExpiringItems");
async function postDiscord(env, content) {
  if (!env.DISCORD_WEBHOOK_URL) return;
  const chunks = content.match(/[\s\S]{1,1900}/g) ?? [content];
  for (const chunk of chunks) {
    await fetch(env.DISCORD_WEBHOOK_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ content: chunk })
    });
  }
}
__name(postDiscord, "postDiscord");
__name2(postDiscord, "postDiscord");
async function sendBrikStaxPush(env, title, body, clickUrl) {
  if (!env.BRIKSTAX_PUSH_SECRET) {
    return { ok: false, reason: "missing BRIKSTAX_PUSH_SECRET secret" };
  }
  try {
    const res = await env.BRIKSTAX_WORKER.fetch("https://brikstax-worker.paul-olsen1684.workers.dev/push/send", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-brikstax-push-secret": env.BRIKSTAX_PUSH_SECRET
      },
      body: JSON.stringify({
        title,
        body,
        topic: "dev_alerts",
        ...clickUrl ? { url: clickUrl } : {}
      })
    });
    const rawText = await res.text();
    let data;
    try {
      data = JSON.parse(rawText);
    } catch {
      data = { raw: rawText.slice(0, 300) };
    }
    if (!res.ok) return { ok: false, status: res.status, body: data };
    return { ok: true };
  } catch (e) {
    return { ok: false, reason: e.message };
  }
}
__name(sendBrikStaxPush, "sendBrikStaxPush");
__name2(sendBrikStaxPush, "sendBrikStaxPush");
function compactChangesBody(notifyWorthy) {
  if (notifyWorthy.length === 1) {
    const c = notifyWorthy[0];
    if (c.kind === "removed") return `${c.before.title} — removed from rewards`;
    return c.kind === "added" ? `${c.after.title} — ${c.after.pointValue} pts, qty ${c.after.quantity ?? "—"}` : `${c.after.title} — back in stock (qty ${c.before.quantity} → ${c.after.quantity})`;
  }
  // .before covers "removed" (no .after exists); every other kind has .after.
  return notifyWorthy.map((c) => (c.after ?? c.before).title).join(", ");
}
__name(compactChangesBody, "compactChangesBody");
__name2(compactChangesBody, "compactChangesBody");
function compactExpiringBody(items) {
  if (items.length === 1) {
    const daysLeft = Math.ceil((new Date(items[0].endDate) - Date.now()) / (24 * 60 * 60 * 1e3));
    return `${items[0].title} — expires in ${daysLeft} day${daysLeft !== 1 ? "s" : ""}`;
  }
  return items.map((i) => i.title).join(", ");
}
__name(compactExpiringBody, "compactExpiringBody");
__name2(compactExpiringBody, "compactExpiringBody");
async function sendEmail(env, subject, textBody) {
  if (!env.RESEND_API_KEY || !env.ALERT_EMAIL) {
    return { ok: false, reason: "missing RESEND_API_KEY or ALERT_EMAIL secret/var" };
  }
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      authorization: `Bearer ${env.RESEND_API_KEY}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({
      from: "LEGO Rewards Watcher <onboarding@resend.dev>",
      to: [env.ALERT_EMAIL],
      subject,
      text: textBody
    })
  });
  const bodyText = await res.text();
  let body;
  try {
    body = JSON.parse(bodyText);
  } catch {
    body = bodyText;
  }
  if (!res.ok) {
    return { ok: false, status: res.status, body };
  }
  return { ok: true, status: res.status, body };
}
__name(sendEmail, "sendEmail");
__name2(sendEmail, "sendEmail");
async function alertOnce(env, key, message) {
  const alreadySent = await env.REWARDS_KV.get(key);
  if (alreadySent) return;
  await postDiscord(env, message);
  await env.REWARDS_KV.put(key, "1", { expirationTtl: 60 * 60 * 24 });
}
__name(alertOnce, "alertOnce");
__name2(alertOnce, "alertOnce");
async function storeChanges(env, changes, rewards) {
  if (!changes.length) return;
  const historyRaw = await env.REWARDS_KV.get(CHANGES_KEY);
  let history = historyRaw ? JSON.parse(historyRaw) : [];
  for (const change of changes) {
    // Real bug fixed 2026-08-27: a "removed" change's item is, by
    // definition, no longer in the current `rewards` fetch -- that's what
    // makes it "removed". The old `if (!reward) continue` here silently
    // dropped every single removal before it was ever stored, so it never
    // showed on /status and there was never any record of when an item
    // disappeared, even though diff() correctly detected it. Only look the
    // reward up in the current fetch for kinds that should actually be in
    // it; a removal has no current fetch data to look up at all, and no
    // stored imageUrl either (the snapshot never captured one), so it
    // falls back to no image -- handleStatus already renders that
    // gracefully ("No image").
    const reward = change.kind === "removed" ? null : rewards.find((r) => r.id === change.id);
    if (!reward && change.kind !== "removed") continue;
    const imageUrl = reward?.images?.[0]?.url || null;
    history.unshift({
      id: change.id,
      title: change.after?.title || change.before?.title,
      slug: change.after?.slug || change.before?.slug,
      imageUrl,
      kind: change.kind,
      timestamp: Date.now(),
      quantity: change.after?.quantity ?? change.before?.quantity,
      pointValue: change.after?.pointValue ?? change.before?.pointValue,
      beforeQty: change.before?.quantity,
      afterQty: change.after?.quantity
    });
  }
  history = history.slice(0, MAX_STORED_CHANGES);
  await env.REWARDS_KV.put(CHANGES_KEY, JSON.stringify(history));
}
__name(storeChanges, "storeChanges");
__name2(storeChanges, "storeChanges");
// "Expiring soon" alerts (getExpiringItems) were always a completely
// separate path from diff()/storeChanges -- never written into
// CHANGES_KEY, so they never showed up on /status at all, matching the
// .badge-expire CSS rule that's existed but had nothing that ever set it.
// Added 2026-08-27 alongside the "removed" fix above, same shared history
// list so /status can show every kind of thing this Worker actually
// tracks, not just two of the four.
async function storeExpiringHistory(env, expiringItems, rewards) {
  if (!expiringItems.length) return;
  const historyRaw = await env.REWARDS_KV.get(CHANGES_KEY);
  let history = historyRaw ? JSON.parse(historyRaw) : [];
  for (const item of expiringItems) {
    const reward = rewards.find((r) => r.id === item.id);
    const imageUrl = reward?.images?.[0]?.url || null;
    history.unshift({
      id: item.id,
      title: item.title,
      slug: item.slug,
      imageUrl,
      kind: "expiring",
      timestamp: Date.now(),
      quantity: item.quantity,
      pointValue: item.pointValue,
      endDate: item.endDate
    });
  }
  history = history.slice(0, MAX_STORED_CHANGES);
  await env.REWARDS_KV.put(CHANGES_KEY, JSON.stringify(history));
}
__name(storeExpiringHistory, "storeExpiringHistory");
async function handleTrigger(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400, headers: { "content-type": "application/json" } });
  }
  if (!env.MANUAL_TRIGGER_KEY || body.key !== env.MANUAL_TRIGGER_KEY) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { "content-type": "application/json" } });
  }
  const result = await runCheck(env);
  return new Response(JSON.stringify({ ok: true, result }), { status: 200, headers: { "content-type": "application/json" } });
}
__name(handleTrigger, "handleTrigger");
__name2(handleTrigger, "handleTrigger");
async function handleStatus(env) {
  const historyRaw = await env.REWARDS_KV.get(CHANGES_KEY);
  const history = historyRaw ? JSON.parse(historyRaw) : [];
  // Was slice(0, 3) -- showed only the 3 most recent changes even though
  // up to MAX_STORED_CHANGES (50) are actually kept in KV. Now shows
  // everything that's stored, so removals (and everything else) are
  // actually visible here instead of scrolling off after the next couple
  // of changes.
  const recent = history;
  const triggerKey = env.MANUAL_TRIGGER_KEY || "";
  const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>LEGO Insiders Rewards — Latest Changes</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #f5f5f5;
      padding: 20px;
    }
    .container { max-width: 1200px; margin: 0 auto; }
    h1 {
      color: #333;
      margin-bottom: 30px;
      text-align: center;
      font-size: 28px;
    }
    .changes {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
    }
    .card {
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: transform 0.2s;
    }
    .card:hover { transform: translateY(-4px); box-shadow: 0 4px 16px rgba(0,0,0,0.15); }
    .card-image {
      width: 100%;
      height: 200px;
      background: #f0f0f0;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }
    .card-image img {
      width: 100%;
      height: 100%;
      object-fit: contain;
      padding: 10px;
    }
    .card-body {
      padding: 16px;
    }
    .card-badge {
      display: inline-block;
      font-size: 12px;
      font-weight: 600;
      padding: 4px 8px;
      border-radius: 4px;
      margin-bottom: 8px;
      text-transform: uppercase;
    }
    .badge-new { background: #d4edda; color: #155724; }
    .badge-restock { background: #cfe2ff; color: #084298; }
    .badge-expire { background: #fff3cd; color: #664d03; }
    .badge-removed { background: #f8d7da; color: #721c24; }
    .card.is-removed .card-image { opacity: .5; }
    .card-title {
      font-size: 16px;
      font-weight: 600;
      color: #333;
      margin-bottom: 8px;
      line-height: 1.3;
    }
    .card-meta {
      font-size: 13px;
      color: #666;
      margin-bottom: 12px;
    }
    .card-meta span { display: block; margin-bottom: 4px; }
    .card-link {
      display: inline-block;
      background: #0066cc;
      color: white;
      text-decoration: none;
      padding: 8px 12px;
      border-radius: 4px;
      font-size: 13px;
      transition: background 0.2s;
    }
    .card-link:hover { background: #0052a3; }
    .empty {
      text-align: center;
      padding: 40px 20px;
      color: #999;
      font-size: 16px;
    }
    .header-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30px;
    }
    .refresh-btn {
      background: #28a745;
      color: white;
      border: none;
      padding: 10px 16px;
      border-radius: 4px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: background 0.2s;
    }
    .refresh-btn:hover { background: #218838; }
    .refresh-btn:disabled { background: #ccc; cursor: not-allowed; }
    .status-message {
      font-size: 13px;
      padding: 8px 12px;
      border-radius: 4px;
      margin-top: 8px;
    }
    .status-message.success { background: #d4edda; color: #155724; }
    .status-message.error { background: #f8d7da; color: #721c24; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header-bar">
      <h1 style="margin-bottom: 0;">\u{1F3C6} LEGO Insiders Rewards — Latest Changes (${recent.length})</h1>
      <div>
        <button class="refresh-btn" id="refreshBtn" onclick="triggerRefresh()">\u{1F504} Refresh</button>
        <div class="status-message" id="statusMsg" style="display: none;"></div>
      </div>
    </div>
    <div class="changes">
      ${recent.length ? recent.map((item) => {
    const date = new Date(item.timestamp).toLocaleString();
    // Four real kinds now, not two -- "removed"/"expiring" used to either
    // get silently dropped before ever reaching this page (removed) or
    // never stored here at all (expiring, a fully separate alert path).
    // badge-expire's CSS rule existed before this and had nothing that
    // ever set it -- this was clearly meant to happen and never got wired
    // up the rest of the way.
    let badgeClass = "badge-new";
    let badgeText = "\u{1F195} New";
    if (item.kind === "changed") {
      badgeClass = "badge-restock";
      badgeText = "\u{1F4E6} Restock";
    } else if (item.kind === "removed") {
      badgeClass = "badge-removed";
      badgeText = "\u{1F5D1}️ Removed";
    } else if (item.kind === "expiring") {
      badgeClass = "badge-expire";
      badgeText = "⏳ Expiring Soon";
    }
    const isRemoved = item.kind === "removed";
    const url = `https://www.lego.com/en-us/insiders/rewards/${item.slug}`;
    let metaLine;
    if (item.kind === "changed") {
      metaLine = `<span>qty: ${item.beforeQty} → <strong>${item.afterQty}</strong></span>`;
    } else if (item.kind === "expiring") {
      const daysLeft = Math.ceil((new Date(item.endDate).getTime() - Date.now()) / (24 * 60 * 60 * 1e3));
      metaLine = `<span>expires in <strong>${daysLeft}</strong> day${daysLeft !== 1 ? "s" : ""}</span>`;
    } else {
      metaLine = `<span>qty: <strong>${item.quantity}</strong></span>`;
    }
    return `
      <div class="card${isRemoved ? " is-removed" : ""}">
        <div class="card-image">
          ${item.imageUrl ? `<img src="${item.imageUrl}" alt="${item.title}">` : '<span style="color:#ccc;">No image</span>'}
        </div>
        <div class="card-body">
          <span class="card-badge ${badgeClass}">${badgeText}</span>
          <div class="card-title">${item.title}</div>
          <div class="card-meta">
            <span><strong>${item.pointValue}</strong> points</span>
            ${metaLine}
            <span style="font-size: 12px; color: #999; margin-top: 8px;">${date}</span>
          </div>
          ${isRemoved ? '<span style="font-size: 12px; color: #999;">No longer listed — link likely 404s</span>' : `<a href="${url}" target="_blank" class="card-link">View on LEGO.com →</a>`}
        </div>
      </div>
        `;
  }).join("") : '<div class="empty">No recent changes yet</div>'}
    </div>
  </div>
  <script>
    const TRIGGER_KEY = '${triggerKey}';
    const statusMsg = document.getElementById('statusMsg');
    const refreshBtn = document.getElementById('refreshBtn');

    async function triggerRefresh() {
      if (!TRIGGER_KEY) {
        showStatus('Error: Trigger key not configured', 'error');
        return;
      }

      refreshBtn.disabled = true;
      refreshBtn.textContent = '⏳ Running...';

      try {
        const response = await fetch('/trigger', {
          method: 'POST',
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ key: TRIGGER_KEY }),
        });

        if (!response.ok) {
          showStatus('Failed to trigger check', 'error');
          return;
        }

        showStatus('✅ Check running — page will refresh in 5 seconds', 'success');
        setTimeout(() => window.location.reload(), 5000);
      } catch (e) {
        showStatus('Error: ' + e.message, 'error');
      } finally {
        refreshBtn.disabled = false;
        refreshBtn.textContent = '\u{1F504} Refresh';
      }
    }

    function showStatus(message, type) {
      statusMsg.textContent = message;
      statusMsg.className = 'status-message ' + type;
      statusMsg.style.display = 'block';
    }
  <\/script>
</body>
</html>`;
  return new Response(html, {
    headers: { "content-type": "text/html; charset=utf-8" }
  });
}
__name(handleStatus, "handleStatus");
__name2(handleStatus, "handleStatus");
export {
  worker_default as default
};
//# sourceMappingURL=worker.js.map

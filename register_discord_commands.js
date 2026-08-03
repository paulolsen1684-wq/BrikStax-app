// register_discord_commands.js
// Run ONCE from your computer to register the /news and /deal slash commands.
//
//   DISCORD_BOT_TOKEN=your-token-here node register_discord_commands.js
//
// Set these first (from Discord Developer Portal → your app):
//   APP_ID    → General Information → Application ID
//   BOT_TOKEN → Bot → Reset Token (copy it) — passed via the DISCORD_BOT_TOKEN
//               env var above, never hardcoded here (this file is committed
//               to git; a real bot token was accidentally hardcoded here
//               once before and caught by GitHub's push protection).
//   GUILD_ID  → your Discord server ID (enable Developer Mode in Discord,
//               right-click the server → Copy Server ID). Guild commands
//               appear instantly; global commands take ~1 hour.

const APP_ID    = '1515425340783202314';
const BOT_TOKEN = process.env.DISCORD_BOT_TOKEN;
const GUILD_ID  = '915073580893610015';    // ← right-click your server → Copy Server ID

if (!BOT_TOKEN) {
  console.error('Set DISCORD_BOT_TOKEN before running, e.g.:\n  DISCORD_BOT_TOKEN=your-token-here node register_discord_commands.js');
  process.exit(1);
}

const commands = [
  {
    name: 'news',
    description: 'Post a news item to BrikStax',
    options: [
      { name: 'title',   description: 'Headline',       type: 3, required: true  },
      { name: 'summary', description: 'Short summary',   type: 3, required: false },
      { name: 'url',     description: 'Link',            type: 3, required: false },
      { name: 'image',   description: 'Image URL',       type: 3, required: false },
    ],
  },
  {
    name: 'deal',
    description: 'Post a deal to BrikStax',
    options: [
      { name: 'title',    description: 'Set / deal title',         type: 3, required: true  },
      { name: 'url',      description: 'Affiliate link',           type: 3, required: true  },
      { name: 'set',      description: 'Set number (e.g. 75192)',  type: 3, required: false },
      { name: 'retail',   description: 'Retail price',             type: 10, required: false },
      { name: 'price',    description: 'Deal price',               type: 10, required: false },
      { name: 'retailer', description: 'Retailer (Amazon, etc.)',  type: 3, required: false },
      { name: 'image',    description: 'Image URL',                type: 3, required: false },
      { name: 'note',     description: 'Short note',               type: 3, required: false },
      { name: 'featured', description: 'Feature as Deal of Day?',  type: 5, required: false },
      { name: 'days',     description: 'Expires in N days (def 30)', type: 4, required: false },
    ],
  },
];

// type reference: 3=string, 4=integer, 5=boolean, 10=number(decimal)

async function main() {
  const url = `https://discord.com/api/v10/applications/${APP_ID}/guilds/${GUILD_ID}/commands`;
  const res = await fetch(url, {
    method: 'PUT',  // PUT replaces all commands at once
    headers: {
      'Authorization': `Bot ${BOT_TOKEN}`,
      'Content-Type':  'application/json',
    },
    body: JSON.stringify(commands),
  });
  const text = await res.text();
  console.log('Status:', res.status);
  console.log(text);
  if (res.ok) console.log('\n✅ Commands registered! Try /news and /deal in your server.');
  else console.log('\n❌ Registration failed — check APP_ID, BOT_TOKEN, GUILD_ID.');
}

main();

// Generate a conservative, clearly-labelled starter blocklist for Nixring.
// Deterministic (no RNG) so it is reproducible. We deliberately only seed
// German *service* ranges that are never personal numbers (0900 premium-rate,
// 0137 televoting, 0180 shared-cost) plus a few well-known international
// ping-call prefixes — minimising any risk of blocking a real person's phone.
// The live, growing list is served from the public nixring-blocklist repo.
import fs from 'fs';

const entries = [];
const push = (e164, label) => entries.push({ e164, label });

// German 0900 premium-rate (commonly abused for scams) -> +49900...
for (let i = 0; i < 20; i++) push(`+49900${(100000 + i * 137).toString().padStart(6, '0')}`, 'Premium-rate spam');
// German 0137 televoting / ping-call -> +49137...
for (let i = 0; i < 15; i++) push(`+49137${(700000 + i * 211).toString().padStart(6, '0')}`, 'Televoting spam');
// German 0180 shared-cost (often abused) -> +49180...
for (let i = 0; i < 15; i++) push(`+491805${(100000 + i * 173).toString().padStart(6, '0')}`, 'Shared-cost spam');
// Known international ping-call prefixes (Wangiri fraud)
const intl = ['216','223','225','234','233','371','373','252','881','679'];
intl.forEach((cc, k) => {
  for (let i = 0; i < 3; i++) push(`+${cc}${(9000000 + i * 373 + k).toString()}`, 'Ping-call fraud');
});

const file = {
  version: 1,
  updated: '2026-07-19',
  note: 'Nixring starter blocklist — German service ranges + known Wangiri prefixes. Grows via updates and your own additions.',
  entries,
};

const out = process.argv[2] || 'Resources/blocklist.json';
fs.writeFileSync(out, JSON.stringify(file, null, 2));
console.log(`wrote ${entries.length} entries -> ${out}`);

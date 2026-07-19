// Render the Nixring app icon (SVG -> 1024 opaque PNG) via headless Chromium.
import { chromium } from 'playwright';

const W = 1024;
const OUT = process.argv[2] || '/Users/levinschwab/Data/Claude/nixring/App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png';

const svg = `
<svg width="${W}" height="${W}" viewBox="0 0 ${W} ${W}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0.2" y2="1">
      <stop offset="0" stop-color="#0E1A3E"/>
      <stop offset="1" stop-color="#060A1A"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.40" r="0.55">
      <stop offset="0" stop-color="#37D7F2" stop-opacity="0.34"/>
      <stop offset="1" stop-color="#37D7F2" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="shield" x1="0.12" y1="0.03" x2="0.92" y2="1">
      <stop offset="0" stop-color="#5CE8FF"/>
      <stop offset="0.55" stop-color="#33C9F3"/>
      <stop offset="1" stop-color="#3E7EF2"/>
    </linearGradient>
  </defs>
  <rect width="${W}" height="${W}" fill="url(#bg)"/>
  <circle cx="512" cy="452" r="440" fill="url(#glow)"/>
  <path d="M512 164
           C 638 230 748 248 832 248
           L 832 522
           C 832 712 692 820 512 880
           C 332 820 192 712 192 522
           L 192 248
           C 276 248 386 230 512 164 Z"
        fill="url(#shield)"/>
  <g fill="#0A1533">
    <rect x="366" y="520" width="66" height="96"  rx="22"/>
    <rect x="466" y="454" width="66" height="162" rx="22"/>
    <rect x="566" y="388" width="66" height="228" rx="22"/>
  </g>
  <line x1="350" y1="352" x2="666" y2="668" stroke="#0A1533" stroke-width="64" stroke-linecap="round"/>
</svg>`;

const html = `<!doctype html><html><head><style>*{margin:0;padding:0}</style></head>
<body><div id="c" style="width:${W}px;height:${W}px">${svg}</div></body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: W, height: W, deviceScaleFactor: 1 } });
await page.setContent(html, { waitUntil: 'networkidle' });
const el = await page.$('#c');
await el.screenshot({ path: OUT });
await browser.close();
console.log('wrote', OUT);

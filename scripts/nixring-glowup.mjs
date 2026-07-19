// Compose App Store screenshots: fat headline poster + framed app shot, 1290x2796.
import { chromium } from 'playwright';
import fs from 'fs';

const W = 1290, H = 2796;
const SHOTS = '/private/tmp/claude-501/-Users-levinschwab/c95da906-8b10-47df-9f27-e5d3088a1e28/scratchpad';
const OUT = '/Users/levinschwab/Data/Claude/nixring/build/screenshots';
fs.mkdirSync(OUT, { recursive: true });

const b64 = (f) => 'data:image/png;base64,' + fs.readFileSync(`${SHOTS}/${f}`).toString('base64');

const slides = [
  { shot: 'qa-home2.png',    head: 'Spam calls,<br><span>auto-blocked</span>',        sub: 'Known spam and scam callers silenced before your phone rings.' },
  { shot: 'qa-onboard.png',  head: 'Your contacts<br><span>never leave</span> your phone', sub: 'No account. No servers. No data collected. Ever.' },
  { shot: 'qa-paywall.png',  head: '<span>Kill</span> junk &amp;<br>scam texts',          sub: 'On-device smishing filter moves scam texts to Junk.' },
  { shot: 'qa-blocklist.png',head: 'Block any number<br><span>in one tap</span>',        sub: 'Add your own numbers and whitelist the callers you trust.' },
  { shot: 'qa-settings.png', head: '<span>No ads.</span><br>No tracking.',               sub: 'One fair price with a 3-day free trial. That is it.' },
];

const html = (s) => `<!doctype html><html><head><meta charset="utf8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  .slide { width:${W}px; height:${H}px; position:relative; overflow:hidden;
    background:
      radial-gradient(120% 60% at 50% 0%, rgba(55,215,242,.20), transparent 60%),
      linear-gradient(165deg, #0E1A3E 0%, #0A1230 42%, #060A18 100%);
    font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; }
  .head { position:absolute; top:150px; left:96px; right:96px; text-align:center;
    font-size:118px; font-weight:850; line-height:1.02; letter-spacing:-3px; color:#F4F7FD; }
  .head span { background:linear-gradient(120deg,#5CE8FF,#4C86F5); -webkit-background-clip:text; background-clip:text; -webkit-text-fill-color:transparent; }
  .sub { position:absolute; top:495px; left:150px; right:150px; text-align:center;
    font-size:40px; font-weight:500; line-height:1.3; color:#96A2BE; }
  .device { position:absolute; left:50%; top:735px; transform:translateX(-50%);
    width:830px; border-radius:62px; border:14px solid #161D33; background:#161D33;
    box-shadow:0 40px 120px rgba(0,0,0,.55), 0 0 0 2px rgba(90,140,240,.10);
    overflow:hidden; }
  .device img { display:block; width:100%; }
</style></head><body>
  <div class="slide">
    <div class="head">${s.head}</div>
    <div class="sub">${s.sub}</div>
    <div class="device"><img src="${b64(s.shot)}"></div>
  </div>
</body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: W, height: H, deviceScaleFactor: 1 } });
let i = 1;
for (const s of slides) {
  await page.setContent(html(s), { waitUntil: 'networkidle' });
  const el = await page.$('.slide');
  const name = `${OUT}/${String(i).padStart(2, '0')}.png`;
  await el.screenshot({ path: name });
  console.log('wrote', name);
  i++;
}
await browser.close();

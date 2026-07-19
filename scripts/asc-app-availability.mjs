// Initialize App Store availability for all territories via the ASC API.
// Mints an ES256 JWT from the .p8 key (no external deps) and POSTs v2/appAvailabilities.
import crypto from 'crypto';
import fs from 'fs';
import os from 'os';

const APP_ID = '6792562928';
const KEY_ID = '8XWLD2B2RQ';
const ISSUER = '538cb0d4-b8c6-4bc7-8b59-75da5d2b9411';
const P8 = `${os.homedir()}/Data/Claude/noseprint/.secrets/AuthKey_8XWLD2B2RQ.p8`;
const TERR_FILE = process.argv[2];

const b64url = (buf) => Buffer.from(buf).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

function mintJWT() {
  const key = crypto.createPrivateKey(fs.readFileSync(P8));
  const iat = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' }));
  const payload = b64url(JSON.stringify({ iss: ISSUER, iat, exp: iat + 1200, aud: 'appstoreconnect-v1' }));
  const signingInput = `${header}.${payload}`;
  const sig = crypto.sign('SHA256', Buffer.from(signingInput), { key, dsaEncoding: 'ieee-p1363' });
  return `${signingInput}.${b64url(sig)}`;
}

const territories = fs.readFileSync(TERR_FILE, 'utf8').trim().split(',').filter(Boolean);
console.log('territories:', territories.length);

// Apple encodes each territoryAvailability id as base64({"s":<appId>,"t":<territoryCode>}).
const idFor = (t) => Buffer.from(JSON.stringify({ s: APP_ID, t })).toString('base64').replace(/=+$/, '');

const included = territories.map((t) => ({
  type: 'territoryAvailabilities',
  id: idFor(t),
  attributes: { available: true },
  relationships: { territory: { data: { type: 'territories', id: t } } },
}));

const MINIMAL = process.argv[3] === 'minimal';
const body = MINIMAL
  ? {
      data: {
        type: 'appAvailabilities',
        attributes: { availableInNewTerritories: true },
        relationships: { app: { data: { type: 'apps', id: APP_ID } } },
      },
    }
  : {
      data: {
        type: 'appAvailabilities',
        attributes: { availableInNewTerritories: true },
        relationships: {
          app: { data: { type: 'apps', id: APP_ID } },
          territoryAvailabilities: { data: territories.map((t) => ({ type: 'territoryAvailabilities', id: idFor(t) })) },
        },
      },
      included,
    };

const jwt = mintJWT();
const res = await fetch('https://api.appstoreconnect.apple.com/v2/appAvailabilities', {
  method: 'POST',
  headers: { Authorization: `Bearer ${jwt}`, 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});
const text = await res.text();
console.log('HTTP', res.status);
if (res.status >= 200 && res.status < 300) {
  console.log('OK app availability created for all territories');
} else {
  try {
    const j = JSON.parse(text);
    const errs = j.errors || [];
    const codes = {};
    const badIdx = [];
    errs.forEach((e) => {
      codes[e.code] = (codes[e.code] || 0) + 1;
      const m = (e.source && e.source.pointer || '').match(/included\/(\d+)\//);
      if (m) badIdx.push(parseInt(m[1]));
    });
    console.log('error count:', errs.length, 'codes:', JSON.stringify(codes));
    const bad = [...new Set(badIdx)].map((i) => territories[i]);
    console.log('bad territories:', bad.join(','));
  } catch { console.log(text.slice(0, 400)); }
}

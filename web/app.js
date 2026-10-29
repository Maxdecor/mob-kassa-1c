'use strict';
/* Mobil kassa: 1C:UNF 3.0 uchun veb-ilova (PWA). Faqat brauzer, hech qanday kutubxonasiz. */

const $ = (s, r = document) => r.querySelector(s);
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const nf = new Intl.NumberFormat('en', { maximumFractionDigits: 2 });
const money = (v) => nf.format(Number(v) || 0).replace(/,/g, ' ');
const qty = (v) => String(Math.round((Number(v) || 0) * 1000) / 1000);
const round2 = (v) => Math.round(v * 100) / 100;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pad2 = (n) => String(n).padStart(2, '0');
const fmtDate = (d) => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
const fmtDT = (s) => (s && s.length >= 16 ? `${s.slice(8, 10)}.${s.slice(5, 7)}.${s.slice(0, 4)} ${s.slice(11, 16)}` : '');

/* ---------- ikonkalar ---------- */
const IC = {
  search: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  minus: '<path d="M5 12h14"/>',
  edit: '<path d="M4 20h4L19 9l-4-4L4 16v4z"/>',
  moon: '<path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5L19 19M5 19l1.5-1.5M17.5 6.5L19 5"/>',
  scan: '<path d="M4 7V4h3M20 7V4h-3M4 17v3h3M20 17v3h-3M8 8v8M12 8v8M16 8v8"/>',
  cart: '<path d="M3 5h2l2 11h10l2-8H7"/><circle cx="9" cy="20" r="1.5"/><circle cx="17" cy="20" r="1.5"/>',
  trophy: '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0z"/><path d="M17 5h3v2a3 3 0 0 1-3 3M7 5H4v2a3 3 0 0 0 3 3"/>',
  receipt: '<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6"/>',
  settings: '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
  trash: '<path d="M5 7h14M10 7V4h4v3M7 7l1 13h8l1-13"/>',
  back: '<path d="M15 6l-6 6 6 6"/>',
  cash: '<rect x="3" y="7" width="18" height="10" rx="2"/><circle cx="12" cy="12" r="2.5"/>',
  card: '<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/>',
  server: '<rect x="4" y="4" width="16" height="6" rx="1.5"/><rect x="4" y="14" width="16" height="6" rx="1.5"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/>',
  lock: '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  refresh: '<path d="M20 12a8 8 0 1 1-2.3-5.7M20 4v4h-4"/>',
  check: '<path d="M5 12l5 5L20 7"/>',
  pause: '<circle cx="12" cy="12" r="9"/><path d="M10 9v6M14 9v6"/>',
  undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>',
  eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  box: '<path d="M3 7l9-4 9 4v10l-9 4-9-4z"/><path d="M3 7l9 4 9-4M12 11v10"/>',
  bluetooth: '<path d="M7 7l10 10-5 5V2l5 5L7 17"/>',
  logout: '<path d="M9 4H5v16h4M16 8l4 4-4 4M20 12H9"/>',
  auto: '<circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 1 0 18z"/>',
  backspace: '<path d="M21 5H9l-6 7 6 7h12z"/><path d="M13 9l4 4M17 9l-4 4"/>',
};
const ico = (n, s = 22) =>
  `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${IC[n]}</svg>`;

/* ---------- sozlamalar (localStorage) ---------- */
const LS = 'mobkassa.v1';
const defaults = {
  baseUrl: '', user: '', pass: '', orgId: '', warehouseId: '', warehouseName: '',
  kkmId: '', kkmName: '', priceTypeId: '', canSeeCost: false, theme: 'auto', demo: false,
};
function readCfg() {
  try { return { ...defaults, ...JSON.parse(localStorage.getItem(LS) || '{}') }; } catch { return { ...defaults }; }
}
let cfg = readCfg();
const saveCfg = () => { try { localStorage.setItem(LS, JSON.stringify(cfg)); } catch { /* maxfiy rejim */ } };
const loggedIn = () => !!(cfg.user && cfg.warehouseId);

/* ---------- mavzu ---------- */
const darkMQ = matchMedia('(prefers-color-scheme: dark)');
const isDark = () => cfg.theme === 'dark' || (cfg.theme === 'auto' && darkMQ.matches);
function applyTheme() {
  document.documentElement.dataset.theme = isDark() ? 'dark' : 'light';
  $('#tc').content = isDark() ? '#111318' : '#F9F9FF';
}
darkMQ.addEventListener?.('change', () => { applyTheme(); });
function setTheme(t) { cfg.theme = t; saveCfg(); render(); }

/* ---------- xabar ---------- */
let toastTimer;
function toast(msg) {
  const t = $('#toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove('show'), 2600);
}

/* ---------- API ---------- */
class ApiError extends Error {}
async function api(method, path, { query = {}, body } = {}) {
  if (cfg.demo) return demoApi(method, path, query, body);
  const base = cfg.baseUrl.trim().replace(/\/+$/, '');
  const url = new URL(`${base}/hs/mobkassa${path}`, location.href);
  for (const [k, v] of Object.entries(query)) if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, v);
  const headers = {
    Accept: 'application/json',
    Authorization: 'Basic ' + btoa(unescape(encodeURIComponent(`${cfg.user}:${cfg.pass}`))),
  };
  if (body !== undefined) headers['Content-Type'] = 'application/json; charset=utf-8';
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 30000);
  let res;
  try {
    res = await fetch(url, { method, headers, body: body === undefined ? undefined : JSON.stringify(body), signal: ctl.signal });
  } catch (e) {
    throw new ApiError(
      e.name === 'AbortError'
        ? 'Server javob bermadi. Internet va manzilni tekshiring.'
        : "Serverga ulanib bo'lmadi. Manzilni tekshiring (sahifa 1C bilan bir manzilda joylashgan bo'lishi kerak)."
    );
  } finally {
    clearTimeout(timer);
  }
  let data = null;
  try { data = await res.json(); } catch { /* JSON emas */ }
  if (res.status === 401) throw new ApiError("Login yoki parol noto'g'ri.");
  if (res.status >= 400) throw new ApiError(data && data.error ? data.error : `Server xatosi (${res.status})`);
  if (data === null) throw new ApiError("Server noto'g'ri javob berdi. Manzilni tekshiring.");
  return data;
}

/* ---------- demo rejim (serversiz) ---------- */
const DEMO_PRODUCTS = [
  { id: 'p1', code: '1', name: 'Coca-Cola 1.5 L gazlangan ichimlik, plastik shisha', article: 'CC15', unit: 'dona', price: 9500, stock: 48, barcode: '4780001234567', cost: 7800 },
  { id: 'p2', code: '2', name: 'Coca-Cola 0.5 L plastik shisha', article: 'CC05', unit: 'dona', price: 5000, stock: 120, barcode: '4780001234574', cost: 3900 },
  { id: 'p3', code: '3', name: 'Coca-Cola Zero 1 L', article: 'CCZ1', unit: 'dona', price: 7800, stock: 0, barcode: '4780001234581', cost: 6200 },
  { id: 'p4', code: '4', name: 'Non tandir, katta yumaloq', article: '', unit: 'dona', price: 3000, stock: 35, barcode: '2000000012345', cost: 2400 },
  { id: 'p5', code: '5', name: 'Sut 1 L "Lactel" 3.2% yog\'lilik, tetrapak', article: 'LC1', unit: 'dona', price: 12800, stock: 22, barcode: '3760020507350', cost: 10900 },
  { id: 'p6', code: '6', name: 'Shakar 1 kg', article: 'SH1', unit: 'kg', price: 11000, stock: 60, barcode: '4780009990001', cost: 9300 },
];
const nowIso = () => { const d = new Date(); return `${fmtDate(d)}T${pad2(d.getHours())}:${pad2(d.getMinutes())}:00`; };
let demoReceipts = [
  { id: 'r1', number: '000003', date: nowIso(), posted: false, lines: [{ number: 1, name: 'Non tandir, katta yumaloq', article: '', unit: 'dona', quantity: 4, price: 3000, sum: 12000 }] },
  { id: 'r2', number: '000002', date: nowIso(), posted: true, lines: [
    { number: 1, name: 'Coca-Cola 1.5 L gazlangan ichimlik', article: 'CC15', unit: 'dona', quantity: 2, price: 9500, sum: 19000 },
    { number: 2, name: 'Sut 1 L "Lactel"', article: 'LC1', unit: 'dona', quantity: 3, price: 12800, sum: 38400 }] },
  { id: 'r3', number: '000001', date: nowIso(), posted: true, lines: [{ number: 1, name: 'Shakar 1 kg', article: 'SH1', unit: 'kg', quantity: 2, price: 11000, sum: 22000 }] },
];
const recTotal = (r) => r.lines.reduce((s, l) => s + l.sum, 0);
async function demoApi(method, path, query, body) {
  await sleep(120);
  if (path === '/info') {
    return { user: 'demo', organizations: [{ id: 'o1', name: 'Demo firma' }], warehouses: [{ id: 'w1', name: "Asosiy do'kon" }],
      cashRegisters: [{ id: 'k1', name: 'KKM-1' }], priceTypes: [{ id: 't1', name: 'Chakana' }], canSeeCost: true };
  }
  if (path === '/products') {
    let r = DEMO_PRODUCTS;
    if (query.barcode) r = r.filter((p) => p.barcode === query.barcode);
    else if (query.q) { const q = query.q.toLowerCase(); r = r.filter((p) => `${p.name}${p.article}${p.barcode}`.toLowerCase().includes(q)); }
    return r.map(({ cost, ...p }) => p);
  }
  if (path === '/cost') { const p = DEMO_PRODUCTS.find((x) => x.id === query.id); return { found: !!p, price: p ? p.cost : 0 }; }
  if (path === '/top') {
    return {
      total: 12480000, receipts: 418, average: 29856,
      goods: [['Coca-Cola 1.5 L', 312, 2964000], ['Sut 1 L "Lactel"', 148, 1894400], ['Non tandir', 520, 1560000], ['Coca-Cola 0.5 L', 240, 1200000], ['Shakar 1 kg', 96, 1056000], ["Yog' \"Oltin\" 1 L", 54, 918000]]
        .map(([name, quantity, sum]) => ({ name, unit: 'dona', quantity, receipts: 0, sum })),
      sellers: [['Aziza K.', 156, 4680000], ['Bekzod T.', 142, 4260000], ['Dilshod R.', 120, 3540000]]
        .map(([name, receipts, sum]) => ({ name, unit: '', quantity: 0, receipts, sum })),
    };
  }
  if (path === '/receipts' && method === 'GET') {
    return demoReceipts.map((r) => ({ id: r.id, number: r.number, date: r.date, posted: r.posted, deferred: !r.posted, status: '', total: recTotal(r), items: r.lines.length }));
  }
  if (path === '/receipts' && method === 'POST') {
    const lines = body.lines.map((l, i) => {
      const p = DEMO_PRODUCTS.find((x) => x.id === l.id);
      return { number: i + 1, name: p ? p.name : '?', article: p ? p.article : '', unit: p ? p.unit : '', quantity: l.quantity, price: l.price, sum: round2(l.quantity * l.price) };
    });
    const r = { id: 'r' + (demoReceipts.length + 1), number: String(demoReceipts.length + 1).padStart(6, '0'), date: nowIso(), posted: !body.deferred, lines };
    demoReceipts.unshift(r);
    return { id: r.id, number: r.number, total: recTotal(r), deferred: body.deferred };
  }
  const m = path.match(/^\/receipts\/([^/]+)(?:\/(post|return))?$/);
  if (m) {
    const r = demoReceipts.find((x) => x.id === m[1]);
    if (!r) throw new ApiError('Chek topilmadi');
    if (!m[2]) return { id: r.id, number: r.number, date: r.date, posted: r.posted, deferred: !r.posted, total: recTotal(r), lines: r.lines };
    if (m[2] === 'post') { r.posted = true; return { id: r.id, number: r.number, posted: true }; }
    return { id: r.id, number: String(demoReceipts.length + 1).padStart(6, '0'), total: recTotal(r) };
  }
  throw new ApiError('Demo rejimda bu amal yo\'q');
}

/* ---------- holat ---------- */
let cart = []; // {p: tovar, qty, price}
let tab = 'kassa';
let view = { name: 'home' };
let days = { top: 0, rec: 0 };
let topTab = 0;
let topData = null;
const costCache = {};
const costView = new Map();
let suppressClick = false;

const total = () => round2(cart.reduce((s, l) => s + round2(l.qty * l.price), 0));
const appbar = (title, right = '', back = false) =>
  `<div class="appbar">${back ? `<button class="iconbtn" data-back aria-label="Orqaga">${ico('back', 24)}</button>` : ''}<h1>${esc(title)}</h1>${right}</div>`;
const status = (label, kind) => `<span class="status ${kind}">${esc(label)}</span>`;

window.addEventListener('popstate', () => { view = { name: 'home' }; render(); });
function go(v) { view = v; history.pushState({ v: 1 }, ''); render(); }
function goHome() { if (view.name !== 'home') history.back(); }
function bindBack(root) { root.querySelectorAll('[data-back]').forEach((b) => { b.onclick = () => history.back(); }); }

/* ---------- oyna (bottom sheet) ---------- */
function openSheet(html, onClose) {
  const ov = document.createElement('div');
  ov.className = 'overlay';
  ov.innerHTML = `<div class="sheet"><div class="grab"></div>${html}</div>`;
  document.body.appendChild(ov);
  requestAnimationFrame(() => ov.classList.add('show'));
  let closed = false;
  const close = () => {
    if (closed) return;
    closed = true;
    ov.classList.remove('show');
    setTimeout(() => ov.remove(), 200);
    if (onClose) onClose();
  };
  ov.addEventListener('click', (e) => { if (e.target === ov) close(); });
  return { el: ov.querySelector('.sheet'), close };
}

/* Narx yoki miqdor kiritish oynasi (raqam paneli bilan) */
function askNumber({ title, subtitle, initial, suffix, original, allowDecimal }) {
  return new Promise((resolve) => {
    let text = qty(initial).replace('.', ',');
    let fresh = true;
    const val = () => parseFloat(text.replace(',', '.')) || 0;
    const grouped = () => {
      if (!text) return '0';
      const [a, b] = text.split(',');
      const g = a.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
      return b === undefined ? g : `${g},${b}`;
    };
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', allowDecimal ? ',' : '00', '0', '⌫'];
    const quick = original != null
      ? [['Asl narx', original], ['−5%', original * 0.95], ['−10%', original * 0.9], ['−20%', original * 0.8]].map(([l, v]) => [l, Math.round(v)])
      : [];
    const sh = openSheet(
      `<h2>${esc(title)}</h2>${subtitle ? `<div class="muted" style="margin-top:4px">${esc(subtitle)}</div>` : ''}
       <div class="display"><b id="nd"></b>${suffix ? `<span class="muted" style="font-size:18px;font-weight:500">${esc(suffix)}</span>` : ''}</div>
       ${original != null ? `<div class="row between" style="min-height:26px"><span class="muted small">Asl narx: ${money(original)} so'm</span><span id="ndiff"></span></div>
       <div class="quick" id="nq">${quick.map(([l, v], i) => `<button data-q="${i}">${l}</button>`).join('')}</div>` : '<div style="height:10px"></div>'}
       <div class="keys" id="nk">${keys.map((k) => `<button data-k="${k}">${k === '⌫' ? ico('backspace', 24) : k}</button>`).join('')}</div>
       <div class="actions"><button class="btn outlined" id="nc">Bekor qilish</button><button class="btn filled" id="ns">${ico('check', 20)} Saqlash</button></div>`,
      () => resolve(null)
    );
    const refresh = () => {
      const v = val();
      sh.el.querySelector('#nd').textContent = grouped();
      sh.el.querySelector('#ns').disabled = !(v > 0);
      if (original != null) {
        const diff = v - original;
        const pct = original ? (diff / original) * 100 : 0;
        sh.el.querySelector('#ndiff').innerHTML = Math.abs(diff) >= 0.5
          ? status(`${diff > 0 ? '+' : '−'}${money(Math.abs(diff))} so'm (${diff > 0 ? '+' : '−'}${Math.abs(pct).toFixed(1)}%)`, diff > 0 ? 'warn' : 'ok') : '';
        sh.el.querySelectorAll('#nq button').forEach((b, i) => b.classList.toggle('on', Math.abs(v - quick[i][1]) < 0.5));
      }
    };
    const press = (k) => {
      if (k === '⌫') { text = fresh || !text ? '' : text.slice(0, -1); fresh = false; return refresh(); }
      if (fresh) { text = ''; fresh = false; }
      if (k === ',') { if (!text.includes(',')) text = text ? text + ',' : '0,'; return refresh(); }
      const dot = text.indexOf(',');
      if (text.length >= 12 || (dot >= 0 && text.length - dot > 3)) return;
      if (text === '0') text = '';
      if (!text && (k === '0' || k === '00')) { text = '0'; return refresh(); }
      text += k;
      refresh();
    };
    sh.el.querySelector('#nk').onclick = (e) => { const b = e.target.closest('[data-k]'); if (b) press(b.dataset.k); };
    const q = sh.el.querySelector('#nq');
    if (q) q.onclick = (e) => { const b = e.target.closest('[data-q]'); if (b) { text = qty(quick[+b.dataset.q][1]).replace('.', ','); fresh = true; refresh(); } };
    sh.el.querySelector('#nc').onclick = () => sh.close();
    sh.el.querySelector('#ns').onclick = () => { const v = val(); if (v > 0) { resolve(v); sh.close(); } };
    refresh();
  });
}

/* ---------- kirish ---------- */
let loginInfo = null;
let loginErr = '';
function renderLogin(app) {
  const i = loginInfo;
  const opts = (arr) => (arr || []).map((r) => `<option value="${esc(r.id)}">${esc(r.name)}</option>`).join('');
  app.innerHTML = `<div class="screen"><main><div class="center">
    <div class="logo"><img src="icon.png" alt=""></div>
    <h1 style="text-align:center;margin:0;font-size:28px">Mobil kassa</h1>
    <div class="muted" style="text-align:center;margin-bottom:12px">1C:UNF bilan ulanish</div>
    <label class="field">${ico('server')}<input id="lurl" placeholder="/unf" autocomplete="url" value="${esc(cfg.baseUrl || '/unf')}" ${i ? 'disabled' : ''}></label>
    <label class="field">${ico('user')}<input id="luser" placeholder="Login" autocomplete="username" value="${esc(cfg.user)}" ${i ? 'disabled' : ''}></label>
    <label class="field">${ico('lock')}<input id="lpass" type="password" placeholder="Parol" autocomplete="current-password" ${i ? 'disabled' : ''}></label>
    ${i ? `<div><label class="lbl">Organizatsiya</label><select id="sorg">${opts(i.organizations)}</select>
      <label class="lbl">Ombor</label><select id="swh">${opts(i.warehouses)}</select>
      <label class="lbl">Kassa (KKM)</label><select id="skkm">${opts(i.cashRegisters)}</select>
      <label class="lbl">Narx turi</label><select id="spt">${opts(i.priceTypes)}</select></div>` : ''}
    <div class="err" style="padding:0">${esc(loginErr)}</div>
    ${i ? `<button class="btn filled" id="lenter">Kirish</button><button class="btn" id="lreset" style="color:var(--pri)">Boshqa serverga ulanish</button>`
        : `<button class="btn filled" id="lgo">Ulanish</button><button class="btn" id="ldemo" style="color:var(--pri)">Demo rejim (serversiz)</button>`}
  </div></main></div>`;
  const connect = async () => {
    const url = $('#lurl').value.trim(), user = $('#luser').value.trim(), pass = $('#lpass').value;
    if (!url || !user) { loginErr = 'Manzil va loginni kiriting.'; return renderLogin(app); }
    cfg.demo = false; cfg.baseUrl = url; cfg.user = user; cfg.pass = pass;
    const btn = $('#lgo'); btn.disabled = true; btn.textContent = 'Ulanmoqda…';
    try { loginInfo = await api('GET', '/info'); loginErr = ''; }
    catch (e) { loginErr = e.message; cfg.user = ''; }
    renderLogin(app);
  };
  if (!i) {
    $('#lgo').onclick = connect;
    $('#lpass').onkeydown = (e) => { if (e.key === 'Enter') connect(); };
    $('#ldemo').onclick = async () => {
      cfg.demo = true; cfg.user = 'demo'; cfg.pass = ''; cfg.baseUrl = '';
      loginInfo = await api('GET', '/info'); loginErr = ''; renderLogin(app);
    };
  } else {
    $('#lreset').onclick = () => { loginInfo = null; cfg.demo = false; cfg.user = ''; renderLogin(app); };
    $('#lenter').onclick = () => {
      const pick = (id, arr) => (arr || []).find((r) => r.id === $(id).value) || { id: '', name: '' };
      const org = pick('#sorg', i.organizations), wh = pick('#swh', i.warehouses), kkm = pick('#skkm', i.cashRegisters), pt = pick('#spt', i.priceTypes);
      if (!org.id || !wh.id || !kkm.id || !pt.id) { loginErr = 'Organizatsiya, ombor, kassa va narx turini tanlang.'; return renderLogin(app); }
      Object.assign(cfg, { orgId: org.id, warehouseId: wh.id, warehouseName: wh.name, kkmId: kkm.id, kkmName: kkm.name, priceTypeId: pt.id, canSeeCost: !!i.canSeeCost });
      saveCfg(); cart = []; loginInfo = null; loginErr = ''; tab = 'kassa'; render();
    };
  }
}

async function refreshAccess() {
  if (!loggedIn() || cfg.demo) return;
  try {
    const info = await api('GET', '/info');
    if (!!info.canSeeCost !== cfg.canSeeCost) { cfg.canSeeCost = !!info.canSeeCost; saveCfg(); for (const k in costCache) delete costCache[k]; costView.clear(); render(); }
  } catch { /* tarmoq yo'q: saqlangan qiymat qoladi */ }
}

/* ---------- asosiy ekran ---------- */
function render() {
  applyTheme();
  const app = $('#app');
  if (!loggedIn()) return renderLogin(app);
  if (view.name === 'pay') return renderPay(app);
  if (view.name === 'receipt') return renderReceipt(app);
  renderHome(app);
}

function renderHome(app) {
  const nb = (t, ic, label) => `<button data-t="${t}" class="${tab === t ? 'on' : ''}"><span class="pill">${ico(ic)}</span>${label}</button>`;
  app.innerHTML = `<div class="screen"><div id="bar"></div><main id="main"></main>${tab === 'kassa' ? '<div id="totalbar" class="totalbar"></div>' : ''}
    <nav>${nb('kassa', 'cart', 'Kassa')}${nb('top', 'trophy', 'Top')}${nb('receipts', 'receipt', 'Cheklar')}${nb('settings', 'settings', 'Sozlama')}</nav></div>`;
  app.querySelectorAll('nav button').forEach((b) => { b.onclick = () => { tab = b.dataset.t; render(); }; });
  ({ kassa: renderKassa, top: renderTop, receipts: renderReceipts, settings: renderSettings })[tab]();
}

/* ---------- kassa ---------- */
function kassaBar() {
  const bar = $('#bar');
  if (!bar) return;
  bar.innerHTML = appbar('Kassa',
    `<button class="iconbtn" id="bTheme" aria-label="Mavzu">${ico(isDark() ? 'sun' : 'moon', 24)}</button>` +
    (cart.length ? `<button class="iconbtn" id="bClear" aria-label="Savatni tozalash">${ico('trash', 24)}</button>` : ''));
  $('#bTheme').onclick = () => setTheme(isDark() ? 'light' : 'dark');
  const c = $('#bClear');
  if (c) c.onclick = () => { cart = []; costView.clear(); drawCart(); };
}

function renderKassa() {
  $('#main').innerHTML = `<div class="pad" style="padding-top:4px"><label class="field">${ico('search')}
    <input id="q" placeholder="Nomi yoki shtrix-kod (skaner)" autocomplete="off" enterkeyhint="search">
    <span class="acc" id="qic">${ico('scan')}</span></label></div><div id="cart" class="cart"></div>`;
  const q = $('#q');
  q.onkeydown = (e) => { if (e.key === 'Enter') { e.preventDefault(); doSearch(q.value); } };
  $('#cart').onclick = onCartClick;
  drawCart();
  q.focus();
}

let searching = false;
async function doSearch(raw) {
  const text = raw.trim();
  if (!text || searching) return;
  searching = true;
  $('#qic').innerHTML = '<span class="spin"></span>';
  try {
    const isCode = /^\d{6,}$/.test(text);
    const base = { warehouse: cfg.warehouseId, pricetype: cfg.priceTypeId, limit: 50 };
    let list = await api('GET', '/products', { query: { ...base, barcode: isCode ? text : '', q: isCode ? '' : text } });
    let byCode = isCode;
    if (!list.length && isCode) { byCode = false; list = await api('GET', '/products', { query: { ...base, q: text } }); }
    const q = $('#q'); if (q) q.value = '';
    if (!list.length) toast(`Tovar topilmadi: ${text}`);
    else if (list.length === 1 && (byCode || text.length >= 3)) addToCart(list[0]);
    else await pickProduct(list);
  } catch (e) { toast(e.message); }
  finally {
    searching = false;
    const ic = $('#qic'); if (ic) ic.innerHTML = ico('scan');
    const q = $('#q'); if (q) q.focus();
  }
}

function addToCart(p) {
  const l = cart.find((x) => x.p.id === p.id);
  if (l) l.qty += 1; else cart.push({ p, qty: 1, price: p.price });
  toast(p.stock <= 0 ? `Qoldiq yo'q, lekin qo'shildi: ${p.name}` : `Qo'shildi: ${p.name}`);
  drawCart();
}

function pickProduct(list) {
  return new Promise((resolve) => {
    const rows = list.map((p, i) => `<div class="item"><div class="grow"><div class="t">${esc(p.name)}</div>
      <div class="muted small">${esc([p.barcode, p.article && 'Art: ' + p.article].filter(Boolean).join('  ·  '))}</div>
      <div class="row" style="margin-top:6px"><b style="color:var(--pri)">${money(p.price)} so'm</b>${status('Qoldiq: ' + qty(p.stock), p.stock > 0 ? 'ok' : 'bad')}</div></div>
      <button class="addbtn" data-i="${i}" aria-label="Savatga">${ico('cart')}</button></div>`).join('');
    const sh = openSheet(`<h2>Tovarni tanlang</h2><div class="list" style="margin:8px -20px 0">${rows}</div>`, resolve);
    sh.el.onclick = (e) => { const b = e.target.closest('[data-i]'); if (b) { addToCart(list[+b.dataset.i]); sh.close(); } };
  });
}

function tileHtml(l) {
  const changed = l.price !== l.p.price;
  const cv = costView.get(l.p.id);
  let costRow = '';
  if (cv && cv.shown) {
    const c = costCache[l.p.id];
    if (c == null) costRow = `<div class="costrow">${ico('lock', 18)}<span>Zakup narxi topilmadi</span></div>`;
    else {
      const profit = l.price - c, pct = c ? (profit / c) * 100 : 0;
      costRow = `<div class="costrow">${ico('eye', 18)}<div><b>Zakup narxi: ${money(c)} so'm</b><div class="small">Foyda: ${profit >= 0 ? '+' : '−'}${money(Math.abs(profit))} so'm (${pct.toFixed(1)}%) har birida</div></div></div>`;
    }
  }
  return `<div class="swipe" data-id="${esc(l.p.id)}">
    <div class="bg del">${ico('trash', 22)}</div><div class="bg cost">Zakup narxi ${ico('eye', 22)}</div>
    <div class="tile"><div class="name">${esc(l.p.name)}</div>
      <div class="row between"><button class="pricechip ${changed ? 'changed' : ''}" data-act="price">${money(l.price)} ${ico('edit', 15)}</button>
        <div class="stepper"><button data-act="dec" aria-label="Kamaytirish">${ico('minus', 20)}</button><button class="q" data-act="qty">${qty(l.qty)}</button><button data-act="inc" aria-label="Ko'paytirish">${ico('plus', 20)}</button></div></div>
      <div class="row between sum"><span class="muted small">${changed ? 'Asl narx: ' + money(l.p.price) : '&nbsp;'}</span><b>${money(round2(l.qty * l.price))} so'm</b></div>${costRow}</div></div>`;
}

function drawCart() {
  kassaBar();
  const box = $('#cart');
  if (!box) return;
  if (!cart.length) box.innerHTML = `<div class="empty">${ico('cart', 56)}<b>Savat bo'sh</b><span>Tovarni qidiring yoki skanerlang</span></div>`;
  else { box.innerHTML = cart.map(tileHtml).join(''); box.querySelectorAll('.swipe').forEach(attachSwipe); }
  const t = $('#totalbar');
  if (t) {
    t.innerHTML = `<div class="row between" style="align-items:flex-end"><span class="muted">Jami · ${cart.length} ta</span><span class="big">${money(total())} so'm</span></div>
      <button class="btn filled" id="bPay" ${cart.length ? '' : 'disabled'}>${ico('cash', 20)} To'lovga o'tish</button>`;
    $('#bPay').onclick = () => go({ name: 'pay' });
  }
}

async function onCartClick(e) {
  if (suppressClick) return;
  const btn = e.target.closest('[data-act]');
  if (!btn) return;
  const l = cart.find((x) => x.p.id === btn.closest('.swipe').dataset.id);
  if (!l) return;
  const a = btn.dataset.act;
  if (a === 'inc') l.qty += 1;
  else if (a === 'dec') { l.qty -= 1; if (l.qty <= 0) cart = cart.filter((x) => x !== l); }
  else if (a === 'price') {
    const v = await askNumber({ title: "Narxni o'zgartirish", subtitle: l.p.name, initial: l.price, suffix: "so'm", original: l.p.price > 0 ? l.p.price : null });
    if (v != null) l.price = v;
  } else if (a === 'qty') {
    const v = await askNumber({ title: 'Miqdor', subtitle: l.p.name, initial: l.qty, suffix: l.p.unit || '', allowDecimal: true });
    if (v != null) l.qty = v;
  }
  drawCart();
}

/* Chapga svayp: zakup narxi (ruxsat bo'lsa). O'ngga svayp: qatorni o'chirish. */
function attachSwipe(sw) {
  const tile = sw.querySelector('.tile');
  let sx = 0, sy = 0, dx = 0, active = false, lock = null;
  tile.addEventListener('pointerdown', (e) => { if (e.button > 0) return; sx = e.clientX; sy = e.clientY; dx = 0; active = true; lock = null; });
  tile.addEventListener('pointermove', (e) => {
    if (!active) return;
    const mx = e.clientX - sx, my = e.clientY - sy;
    if (lock === null && (Math.abs(mx) > 8 || Math.abs(my) > 8)) {
      lock = Math.abs(mx) > Math.abs(my) ? 'x' : 'y';
      if (lock === 'x') tile.setPointerCapture(e.pointerId);
    }
    if (lock !== 'x') return;
    dx = !cfg.canSeeCost && mx < 0 ? 0 : mx;
    tile.style.transition = 'none';
    tile.style.transform = `translateX(${dx}px)`;
    sw.classList.toggle('show-del', dx > 0);
    sw.classList.toggle('show-cost', dx < 0);
  });
  const end = () => {
    if (!active) return;
    active = false;
    tile.style.transition = '';
    tile.style.transform = '';
    sw.classList.remove('show-del', 'show-cost');
    const l = cart.find((x) => x.p.id === sw.dataset.id);
    if (lock === 'x') {
      suppressClick = true; setTimeout(() => { suppressClick = false; }, 60);
      if (l && dx > 90) { cart = cart.filter((x) => x !== l); drawCart(); }
      else if (l && dx < -90) toggleCost(l);
    }
  };
  tile.addEventListener('pointerup', end);
  tile.addEventListener('pointercancel', end);
}

async function toggleCost(l) {
  const id = l.p.id;
  const st = costView.get(id) || { shown: false };
  if (st.shown) { st.shown = false; costView.set(id, st); return drawCart(); }
  try {
    if (!(id in costCache)) { const d = await api('GET', '/cost', { query: { id } }); costCache[id] = d.found ? Number(d.price) : null; }
    st.shown = true; costView.set(id, st);
  } catch (e) { toast(e.message); }
  drawCart();
}

/* ---------- to'lov ---------- */
function renderPay(app) {
  let method = 'cash', busy = false;
  app.innerHTML = `<div class="screen">${appbar("To'lov", '', true)}<main><div class="pad">
    <div class="amount"><span class="muted">To'lanadigan summa</span><b>${money(total())} so'm</b></div>
    <div class="seg" id="pseg"><button data-m="cash" class="on">${ico('cash', 18)} Naqd</button><button data-m="card">${ico('card', 18)} Karta</button></div>
    <div id="cashbox"><label class="lbl">Qabul qilindi</label><label class="field">${ico('cash')}<input id="recv" inputmode="decimal" value="${qty(total())}"></label>
      <div class="row between" style="margin-top:12px"><span class="muted">Qaytim</span><b id="chg" style="font-size:18px;color:var(--pri)"></b></div></div>
    <div id="perr" class="err" style="padding:12px 0 0"></div></div></main>
    <div class="pad" style="display:flex;flex-direction:column;gap:8px;padding-bottom:calc(12px + env(safe-area-inset-bottom))">
      <button class="btn filled" id="bPost">${ico('check', 20)} Chekni urish</button>
      <button class="btn outlined" id="bDefer">${ico('pause', 20)} Otlojit (otlojenniy chek)</button></div></div>`;
  bindBack(app);
  const change = () => { const r = parseFloat($('#recv').value.replace(/\s/g, '').replace(',', '.')) || 0; return r - total(); };
  const upd = () => { $('#chg').textContent = `${money(Math.max(0, change()))} so'm`; $('#cashbox').style.display = method === 'cash' ? '' : 'none'; };
  $('#recv').oninput = upd;
  $('#pseg').onclick = (e) => {
    const b = e.target.closest('[data-m]'); if (!b) return;
    method = b.dataset.m;
    $('#pseg').querySelectorAll('button').forEach((x) => x.classList.toggle('on', x === b));
    upd();
  };
  const submit = async (deferred) => {
    if (busy) return;
    if (!deferred && method === 'cash' && change() < 0) { $('#perr').textContent = 'Qabul qilingan summa yetarli emas.'; return; }
    busy = true; $('#perr').textContent = ''; $('#bPost').disabled = $('#bDefer').disabled = true;
    try {
      const res = await api('POST', '/receipts', { body: {
        organization: cfg.orgId, warehouse: cfg.warehouseId, cashRegister: cfg.kkmId, priceType: cfg.priceTypeId,
        deferred, payment: method, lines: cart.map((l) => ({ id: l.p.id, quantity: l.qty, price: l.price })) } });
      cart = []; costView.clear();
      goHome();
      toast(deferred ? `Chek №${res.number} otlojenniy qilindi` : `Chek №${res.number} urildi`);
    } catch (e) { $('#perr').textContent = e.message; $('#bPost').disabled = $('#bDefer').disabled = false; }
    busy = false;
  };
  $('#bPost').onclick = () => submit(false);
  $('#bDefer').onclick = () => submit(true);
  upd();
}

/* ---------- top ---------- */
function chipsHtml(cur) {
  return [[0, 'Bugun'], [6, '7 kun'], [29, '30 kun']].map(([d, l]) => `<button class="fchip ${cur === d ? 'on' : ''}" data-d="${d}">${l}</button>`).join('');
}
function range(d) {
  const now = new Date();
  const from = new Date(now.getFullYear(), now.getMonth(), now.getDate() - d);
  return { from: fmtDate(from), to: fmtDate(now) };
}

function renderTop() {
  $('#bar').innerHTML = appbar('Top sotuvchilar', `<button class="iconbtn" id="bRef" aria-label="Yangilash">${ico('refresh', 24)}</button>`);
  $('#main').innerHTML = `<div class="chips" id="chips">${chipsHtml(days.top)}</div><div id="tbody"></div>`;
  $('#chips').onclick = (e) => { const b = e.target.closest('[data-d]'); if (b) { days.top = +b.dataset.d; renderTop(); } };
  $('#bRef').onclick = renderTop;
  loadTop();
}

async function loadTop() {
  const body = $('#tbody');
  body.innerHTML = '<div class="empty"><div class="spin"></div></div>';
  try { topData = await api('GET', '/top', { query: range(days.top) }); }
  catch (e) { body.innerHTML = `<div class="err">${esc(e.message)}</div>`; return; }
  drawTop();
}

function drawTop() {
  const body = $('#tbody');
  if (!body || !topData) return;
  const d = topData, items = topTab === 0 ? d.goods : d.sellers;
  const max = Math.max(1, ...items.map((i) => i.sum));
  const rows = items.map((it, i) => `<div class="item"><div class="rank ${i < 3 ? 'top' : ''}">${i + 1}</div>
    <div class="grow"><div class="t">${esc(it.name)}</div><div class="muted small">${topTab === 0 ? `${qty(it.quantity)} ${esc(it.unit)}` : `${it.receipts} ta chek`}</div>
    <div class="bar"><i style="width:${Math.max(3, (it.sum / max) * 100)}%"></i></div></div><b>${money(it.sum)}</b></div>`).join('');
  body.innerHTML = `<div class="summary"><div class="small">Jami savdo</div><div class="big">${money(d.total)} so'm</div>
    <div class="m"><div><div class="small">Cheklar</div><b>${d.receipts} ta</b></div><div><div class="small">O'rtacha chek</div><b>${money(d.average)} so'm</b></div></div></div>
    <div class="pad"><div class="seg" id="tseg"><button data-t="0" class="${topTab === 0 ? 'on' : ''}">${ico('box', 18)} Tovarlar</button>
    <button data-t="1" class="${topTab === 1 ? 'on' : ''}">${ico('user', 18)} Sotuvchilar</button></div></div>
    ${items.length ? `<div class="list">${rows}</div>` : `<div class="empty">${topTab === 1 ? "Sotuvchilar ma'lumoti yo'q" : "Bu davrda sotuv yo'q"}</div>`}`;
  $('#tseg').onclick = (e) => { const b = e.target.closest('[data-t]'); if (b) { topTab = +b.dataset.t; drawTop(); } };
}

/* ---------- cheklar ---------- */
function renderReceipts() {
  $('#bar').innerHTML = appbar('Cheklar', `<button class="iconbtn" id="bRef" aria-label="Yangilash">${ico('refresh', 24)}</button>`);
  $('#main').innerHTML = `<div class="chips" id="chips">${chipsHtml(days.rec)}</div><div id="rbody"></div>`;
  $('#chips').onclick = (e) => { const b = e.target.closest('[data-d]'); if (b) { days.rec = +b.dataset.d; renderReceipts(); } };
  $('#bRef').onclick = renderReceipts;
  loadReceipts();
}

async function loadReceipts() {
  const body = $('#rbody');
  body.innerHTML = '<div class="empty"><div class="spin"></div></div>';
  let list;
  try { list = await api('GET', '/receipts', { query: range(days.rec) }); }
  catch (e) { body.innerHTML = `<div class="err">${esc(e.message)}</div>`; return; }
  if (!list.length) { body.innerHTML = `<div class="empty">Cheklar yo'q</div>`; return; }
  body.innerHTML = `<div class="list">${list.map((r) => `<button class="item" data-id="${esc(r.id)}" data-n="${esc(r.number)}">
    <div class="grow"><div class="t">Chek №${esc(r.number)}</div><div class="muted small">${fmtDT(r.date)}  ·  ${r.items} ta pozitsiya</div></div>
    <div class="r"><b>${money(r.total)} so'm</b>${r.deferred ? status('Otlojenniy', 'warn') : status('Urilgan', 'ok')}</div></button>`).join('')}</div>`;
  body.onclick = (e) => { const b = e.target.closest('[data-id]'); if (b) go({ name: 'receipt', id: b.dataset.id, number: b.dataset.n }); };
}

let rdetail = null;
async function renderReceipt(app) {
  app.innerHTML = `<div class="screen">${appbar('Chek №' + (view.number || ''), '', true)}<main id="rmain"><div class="empty"><div class="spin"></div></div></main><div id="rfoot"></div></div>`;
  bindBack(app);
  await loadReceipt();
}

async function loadReceipt() {
  const main = $('#rmain');
  if (!main) return;
  try { rdetail = await api('GET', `/receipts/${encodeURIComponent(view.id)}`); }
  catch (e) { main.innerHTML = `<div class="err">${esc(e.message)}</div>`; return; }
  const d = rdetail;
  main.innerHTML = `<div class="item" style="justify-content:space-between"><span>${fmtDT(d.date)}</span>${d.deferred ? status('Otlojenniy', 'warn') : status('Urilgan', 'ok')}</div>
    <div class="list" style="border-top:1px solid var(--outv)">${d.lines.map((l) => `<div class="item"><div class="grow"><div class="t">${esc(l.name)}</div>
      <div class="muted small">${qty(l.quantity)} ${esc(l.unit)} × ${money(l.price)}</div></div><b>${money(l.sum)}</b></div>`).join('')}</div>`;
  $('#rfoot').innerHTML = `<div class="totalbar"><div class="row between" style="align-items:flex-end"><span class="muted">Jami (${d.lines.length} ta pozitsiya)</span><span class="big">${money(d.total)} so'm</span></div>
    <div class="err" id="rerr" style="padding:0"></div>
    ${d.deferred ? `<button class="btn filled" id="rPost">${ico('check', 20)} Chekni urish</button>` : ''}
    ${d.posted ? `<button class="btn outlined" id="rRet">${ico('undo', 20)} Qaytarish (vozvrat)</button>` : ''}</div>`;
  const run = async (fn) => {
    $('#rerr').textContent = '';
    document.querySelectorAll('#rfoot .btn').forEach((b) => { b.disabled = true; });
    try { await fn(); } catch (e) { $('#rerr').textContent = e.message; }
    await loadReceipt();
  };
  if ($('#rPost')) $('#rPost').onclick = () => run(async () => { await api('POST', `/receipts/${encodeURIComponent(view.id)}/post`, { body: {} }); toast('Chek urildi'); });
  if ($('#rRet')) $('#rRet').onclick = async () => {
    const picked = await returnSheet(d);
    if (!picked) return;
    run(async () => {
      const all = Object.fromEntries(d.lines.map((l) => [l.number, l.quantity]));
      const full = picked.length === d.lines.length && picked.every((p) => all[p.lineNumber] === p.quantity);
      const res = await api('POST', `/receipts/${encodeURIComponent(view.id)}/return`, { body: { lines: full ? [] : picked } });
      toast(`Qaytarish №${res.number} bajarildi`);
    });
  };
}

function returnSheet(d) {
  return new Promise((resolve) => {
    const q = Object.fromEntries(d.lines.map((l) => [l.number, l.quantity]));
    const on = new Set(d.lines.map((l) => l.number));
    const sh = openSheet(`<h2>Qaytariladigan tovarlar</h2><div class="muted small" style="margin-top:4px">Chek №${esc(d.number)}</div>
      <div id="rl" style="margin-top:8px"></div>
      <div class="row between" style="margin-top:12px"><span class="muted">Qaytariladigan summa</span><b id="rt" style="font-size:20px"></b></div>
      <div class="actions"><button class="btn outlined" id="rc">Bekor qilish</button><button class="btn filled" id="rok">${ico('undo', 20)} Qaytarish</button></div>`, () => resolve(null));
    const draw = () => {
      sh.el.querySelector('#rl').innerHTML = d.lines.map((l) => `<div class="line" data-n="${l.number}"><input type="checkbox" data-c ${on.has(l.number) ? 'checked' : ''}>
        <div class="grow"><div style="font-weight:600">${esc(l.name)}</div><div class="muted small">${money(l.price)} so'm · sotilgan: ${qty(l.quantity)} ${esc(l.unit)}</div></div>
        <div class="stepper"><button data-s="-1" ${on.has(l.number) ? '' : 'disabled'}>${ico('minus', 18)}</button><span class="q" style="min-width:30px">${qty(q[l.number])}</span><button data-s="1" ${on.has(l.number) ? '' : 'disabled'}>${ico('plus', 18)}</button></div></div>`).join('');
      const t = d.lines.filter((l) => on.has(l.number)).reduce((s, l) => s + q[l.number] * l.price, 0);
      sh.el.querySelector('#rt').textContent = `${money(t)} so'm`;
      sh.el.querySelector('#rok').disabled = on.size === 0;
    };
    sh.el.querySelector('#rl').onclick = (e) => {
      const row = e.target.closest('.line'); if (!row) return;
      const n = +row.dataset.n, l = d.lines.find((x) => x.number === n);
      if (e.target.matches('[data-c]')) { if (on.has(n)) on.delete(n); else on.add(n); }
      const s = e.target.closest('[data-s]');
      if (s) { const lo = l.quantity < 1 ? l.quantity : 1; q[n] = Math.min(l.quantity, Math.max(lo, q[n] + +s.dataset.s)); }
      draw();
    };
    sh.el.querySelector('#rc').onclick = () => sh.close();
    sh.el.querySelector('#rok').onclick = () => {
      resolve(d.lines.filter((l) => on.has(l.number)).map((l) => ({ lineNumber: l.number, quantity: q[l.number] })));
      sh.close();
    };
    draw();
  });
}

/* ---------- sozlama ---------- */
function renderSettings() {
  $('#bar').innerHTML = appbar('Sozlama');
  const row = (ic, label, val) => `<div class="item">${ico(ic)}<div class="grow"><div class="muted small">${label}</div><div style="font-weight:500">${esc(val)}</div></div></div>`;
  const seg = [['auto', 'auto', 'Avto'], ['light', 'sun', 'Kunduzgi'], ['dark', 'moon', 'Tungi']]
    .map(([v, ic, l]) => `<button data-th="${v}" class="${cfg.theme === v ? 'on' : ''}">${ico(ic, 18)} ${l}</button>`).join('');
  $('#main').innerHTML = `<div class="list">${row('server', 'Server', cfg.demo ? 'Demo rejim' : cfg.baseUrl)}${row('user', 'Foydalanuvchi', cfg.user)}
    ${row('box', 'Ombor', cfg.warehouseName)}${row('cash', 'Kassa (KKM)', cfg.kkmName)}${row('eye', 'Zakup narxi', cfg.canSeeCost ? 'Ruxsat bor' : "Ruxsat yo'q")}</div>
    <div style="padding:14px 16px"><div class="muted small" style="margin-bottom:8px">Mavzu</div><div class="seg" id="thseg">${seg}</div></div>
    <div class="bluetooth-hint">${ico('bluetooth', 18)} Bluetooth skanerni telefon sozlamalaridan klaviatura (HID) sifatida ulang. Kassa ekranidagi qidiruv maydoni tanlangan bo'lsa, shtrix-kod tovarni o'zi savatga qo'shadi.</div>
    <div class="pad"><button class="btn danger" id="bOut">${ico('logout', 20)} Chiqish</button></div>`;
  $('#thseg').onclick = (e) => { const b = e.target.closest('[data-th]'); if (b) setTheme(b.dataset.th); };
  $('#bOut').onclick = () => {
    if (!confirm("Chiqishni tasdiqlang. Savatdagi tovarlar o'chadi.")) return;
    cfg.pass = ''; cfg.user = ''; cfg.warehouseId = ''; cfg.demo = false; saveCfg();
    cart = []; costView.clear(); loginInfo = null; tab = 'kassa'; render();
  };
}

/* ---------- ishga tushirish ---------- */
if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
  navigator.serviceWorker.register('sw.js').catch(() => {});
}
render();
refreshAccess();

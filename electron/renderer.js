// Будує сітку 2×2 з чотирьох <webview>, ховає зайві банери та дає масштабування.
// Щоб додати/прибрати карту чи правило — міняй масив MAPS нижче.
const MAPS = [
  { name: 'КОНТУР',       url: 'https://kontur.systems/',       css: '' },
  { name: 'UkraineAlarm', url: 'https://map.ukrainealarm.com/', css: '.header, .bottom-banner { display: none !important; }' },
  { name: 'War-Monitor',  url: 'http://map.war-monitor.org',    css: '' },
  { name: 'UA Radar',     url: 'https://www.ua-radar.online/',  css: '' },
];

const ZMIN = 0.3, ZMAX = 2.0, ZSTEP = 0.1;

const grid = document.getElementById('grid');
const panes = [];

function mkBtn(text, title) {
  const b = document.createElement('button');
  b.textContent = text;
  b.title = title;
  return b;
}

function loadZoom(name) {
  try {
    const v = parseFloat(localStorage.getItem('zoom:' + name));
    if (v >= ZMIN && v <= ZMAX) return v;
  } catch (e) {}
  return 1;
}
function saveZoom(name, z) {
  try { localStorage.setItem('zoom:' + name, String(z)); } catch (e) {}
}

for (const m of MAPS) {
  const pane = document.createElement('div');
  pane.className = 'pane';

  // Заголовок: назва ліворуч, керування праворуч (масштаб + оновлення)
  const bar = document.createElement('div');
  bar.className = 'bar';

  const label = document.createElement('span');
  label.className = 'name';
  label.textContent = m.name;

  const ctrls = document.createElement('div');
  ctrls.className = 'ctrls';
  const btnOut = mkBtn('−', 'Зменшити (Ctrl/Cmd −)');
  const pct = document.createElement('span');
  pct.className = 'pct';
  const btnIn = mkBtn('+', 'Збільшити (Ctrl/Cmd +)');
  const btnReload = mkBtn('⟳', 'Оновити');
  ctrls.append(btnOut, pct, btnIn, btnReload);

  bar.append(label, ctrls);

  // Веб-в'ю. partition "persist:maps" зберігає куки/сесії між запусками.
  const wv = document.createElement('webview');
  wv.setAttribute('src', m.url);
  wv.setAttribute('partition', 'persist:maps');

  let zoom = loadZoom(m.name);
  let ready = false;

  function applyZoom() {
    pct.textContent = Math.round(zoom * 100) + '%';
    if (ready) { try { wv.setZoomFactor(zoom); } catch (e) {} }
  }
  function setZoom(z) {
    zoom = Math.min(ZMAX, Math.max(ZMIN, Math.round(z * 100) / 100));
    applyZoom();
    saveZoom(m.name, zoom);
  }
  applyZoom(); // показати % одразу

  btnOut.addEventListener('click', () => setZoom(zoom - ZSTEP));
  btnIn.addEventListener('click', () => setZoom(zoom + ZSTEP));
  label.addEventListener('dblclick', () => setZoom(1)); // 2× клік по назві — 100%
  btnReload.addEventListener('click', () => wv.reload());

  // На кожне завантаження сторінки: застосувати масштаб і сховати банери.
  wv.addEventListener('dom-ready', () => {
    ready = true;
    applyZoom();
    if (m.css) wv.insertCSS(m.css).catch(() => {});
  });

  pane.append(bar, wv);
  grid.append(pane);
  panes.push({ wv, setZoom, getZoom: () => zoom });
}

// Глобальні гарячі клавіші (на всі карти одразу).
window.addEventListener('keydown', (e) => {
  if (!(e.ctrlKey || e.metaKey)) return;
  const k = e.key;
  if (k === 'r' || k === 'R') { e.preventDefault(); panes.forEach((p) => p.wv.reload()); }
  else if (k === '=' || k === '+') { e.preventDefault(); panes.forEach((p) => p.setZoom(p.getZoom() + ZSTEP)); }
  else if (k === '-' || k === '_') { e.preventDefault(); panes.forEach((p) => p.setZoom(p.getZoom() - ZSTEP)); }
  else if (k === '0') { e.preventDefault(); panes.forEach((p) => p.setZoom(1)); }
});

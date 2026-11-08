// 触摸版真浏览器验证（Chrome/Edge headless + CDP 设备模拟，零依赖）
// 用法：node verify_browser.js                只跑断言
//       node verify_browser.js --shots        同时输出截图到 _shots/
//       node verify_browser.js --only=portrait  只跑名称匹配的档位
// 原理：把 _browser-harness.js 内联进工具 HTML 的临时副本；用 CDP 精确模拟
//       手机视口（宽/高/DPR/触摸），在页面里派发真实 TouchEvent，读回 #diag JSON。
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn } = require('child_process');
const { pathToFileURL } = require('url');

const ROOT = __dirname;
const TOOL = path.join(ROOT, 'select-layout-tool.html');
const HARNESS = path.join(ROOT, '_browser-harness.js');
const TMP = path.join(ROOT, '_tmp-browser.html');
const SHOTS = path.join(ROOT, '_shots');
const SHOT_MODE = process.argv.indexOf('--shots') >= 0;

const PROFILES = [
  { name: 'portrait-390x844-dpr3', w: 390, h: 844, dpr: 3, ui: 'touch', orient: 'portraitPrimary', angle: 0 },
  { name: 'landscape-844x390-dpr2', w: 844, h: 390, dpr: 2, ui: 'touch', orient: 'landscapePrimary', angle: 90 },
  { name: 'tablet-768x1024-dpr2', w: 768, h: 1024, dpr: 2, ui: 'touch', orient: 'portraitPrimary', angle: 0 },
  { name: 'desktop-1280x800-dpr1', w: 1280, h: 800, dpr: 1, ui: 'desktop', orient: 'landscapePrimary', angle: 0 },
  { name: 'desktop-narrow-900x700-dpr1', w: 900, h: 700, dpr: 1, ui: 'desktop', orient: 'landscapePrimary', angle: 0 },
];
const TABS = ['seg-grid', 'seg-spacing', 'seg-ref', 'seg-item', 'seg-page', 'seg-list', 'seg-log'];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function findChrome() {
  const cands = [
    process.env.CHROME,
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
  ].filter(Boolean);
  for (const c of cands) if (fs.existsSync(c)) return c;
  throw new Error('找不到 Chrome/Edge，可用环境变量 CHROME 指定');
}

function buildTmp() {
  const html = fs.readFileSync(TOOL, 'utf8');
  const js = fs.readFileSync(HARNESS, 'utf8');
  const tagged = html.replace('</body>', '<script>\n' + js + '\n</script>\n</body>');
  if (tagged === html) throw new Error('未能把 harness 注入工具 HTML（找不到 </body>）');
  fs.writeFileSync(TMP, tagged, 'utf8');
  return pathToFileURL(TMP).href;
}

class CDP {
  constructor(ws) { this.ws = ws; this.id = 0; this.pending = new Map(); }
  static async open(url) {
    const ws = new WebSocket(url);
    await new Promise((res, rej) => {
      ws.onopen = res;
      ws.onerror = () => rej(new Error('WS 连接失败'));
    });
    const c = new CDP(ws);
    ws.onmessage = (ev) => {
      let msg;
      try { msg = JSON.parse(ev.data); } catch (e) { return; }
      if (msg.id && c.pending.has(msg.id)) {
        const p = c.pending.get(msg.id);
        c.pending.delete(msg.id);
        if (msg.error) p.rej(new Error(msg.error.message)); else p.res(msg.result);
      }
    };
    return c;
  }
  send(method, params) {
    const id = ++this.id;
    return new Promise((res, rej) => {
      this.pending.set(id, { res, rej });
      this.ws.send(JSON.stringify({ id: id, method: method, params: params || {} }));
      setTimeout(() => {
        if (this.pending.has(id)) { this.pending.delete(id); rej(new Error('CDP 超时: ' + method)); }
      }, 45000);
    });
  }
  close() { try { this.ws.close(); } catch (e) { /* 忽略 */ } }
}

async function launch(chrome) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bvn-tool-verify-'));
  const proc = spawn(chrome, [
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--disable-extensions', '--mute-audio', '--hide-scrollbars',
    '--remote-debugging-port=0', '--remote-allow-origins=*',
    '--user-data-dir=' + dir,
    'about:blank',
  ], { stdio: 'ignore' });
  const portFile = path.join(dir, 'DevToolsActivePort');
  const deadline = Date.now() + 25000;
  let port = 0;
  while (Date.now() < deadline) {
    if (fs.existsSync(portFile)) {
      const lines = fs.readFileSync(portFile, 'utf8').trim().split(/\r?\n/);
      if (lines[0]) { port = +lines[0]; break; }
    }
    await sleep(120);
  }
  if (!port) {
    try { proc.kill(); } catch (e) { /* 忽略 */ }
    throw new Error('Chrome 未启动（无 DevToolsActivePort）');
  }
  return { proc: proc, dir: dir, port: port };
}

async function evalValue(cdp, expression) {
  const r = await cdp.send('Runtime.evaluate', { expression: expression, returnByValue: true, awaitPromise: true });
  if (r && r.exceptionDetails) throw new Error('页面脚本异常: ' + (r.exceptionDetails.text || ''));
  return r && r.result ? r.result.value : undefined;
}

async function runProfile(chrome, baseUrl, prof) {
  const browser = await launch(chrome);
  let cdp = null;
  try {
    const list = await (await fetch('http://127.0.0.1:' + browser.port + '/json/list')).json();
    const page = list.filter((t) => t.type === 'page')[0];
    if (!page) throw new Error('没有 page target');
    cdp = await CDP.open(page.webSocketDebuggerUrl);
    await cdp.send('Page.enable');
    await cdp.send('Emulation.setDeviceMetricsOverride', {
      width: prof.w, height: prof.h, deviceScaleFactor: prof.dpr, mobile: prof.ui === 'touch',
      screenOrientation: { type: prof.orient, angle: prof.angle },
    });
    await cdp.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
    await cdp.send('Page.navigate', { url: baseUrl + '?ui=' + prof.ui });

    let title = '';
    for (let i = 0; i < 160; i++) {
      await sleep(150);
      try { title = await evalValue(cdp, 'document.title'); } catch (e) { title = ''; }
      if (title === 'DIAG_OK' || title === 'DIAG_FAIL') break;
    }
    const raw = await evalValue(cdp, "document.getElementById('diag') ? document.getElementById('diag').textContent : ''");
    const diag = raw ? JSON.parse(raw) : null;

    if (SHOT_MODE) {
      const cap = await cdp.send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
      fs.writeFileSync(path.join(SHOTS, prof.name + '.png'), Buffer.from(cap.data, 'base64'));
      if (prof.ui === 'touch' && diag) {
        for (const t of TABS) {
          await evalValue(cdp, "document.getElementById('tab-" + t + "').click(); 'ok'");
          await sleep(320);
          const c2 = await cdp.send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
          fs.writeFileSync(path.join(SHOTS, prof.name + '-' + t + '.png'), Buffer.from(c2.data, 'base64'));
        }
        await evalValue(cdp, "document.getElementById('tab-seg-layout').click(); 'ok'");
      }
    }
    return { title: title, diag: diag };
  } finally {
    if (cdp) cdp.close();
    try { browser.proc.kill(); } catch (e) { /* 忽略 */ }
    await sleep(250);
    try { fs.rmSync(browser.dir, { recursive: true, force: true }); } catch (e) { /* 忽略 */ }
  }
}

async function main() {
  const chrome = findChrome();
  const baseUrl = buildTmp();
  fs.mkdirSync(SHOTS, { recursive: true });
  const onlyArg = (process.argv.filter((a) => a.indexOf('--only=') === 0)[0] || '').replace('--only=', '');
  const list = onlyArg ? PROFILES.filter((p) => p.name.indexOf(onlyArg) >= 0) : PROFILES;
  let failed = 0;

  for (const prof of list) {
    console.log('\n=== ' + prof.name + ' (ui=' + prof.ui + ') ===');
    let res = null;
    try {
      res = await runProfile(chrome, baseUrl, prof);
    } catch (e) {
      console.log('  ✗ 运行失败: ' + (e.message || e));
      failed++;
      continue;
    }
    const diag = res.diag;
    if (!diag) {
      console.log('  ✗ 没拿到诊断数据（title=' + res.title + '）');
      failed++;
      continue;
    }
    if (diag.errors && diag.errors.length) {
      diag.errors.forEach((e) => console.log('  ✗ page error: ' + e));
      failed++;
    }
    (diag.checks || []).forEach((c) => {
      console.log((c.pass ? '  ✓ ' : '  ✗ ') + c.name + (c.extra ? '  [' + c.extra + ']' : ''));
      if (!c.pass) failed++;
    });
    const d = diag.diag || {};
    console.log('  · mode=' + diag.mode + ' vw×vh=' + d.vw + '×' + d.vh + ' dpr=' + d.dpr
      + ' fit=' + d.fit + ' zoom=' + d.zoom + ' q=' + d.backingQ
      + ' bitmap=' + (d.bitmap || []).join('×') + ' overflowX=' + d.overflowX);
    console.log('  · canvas=' + JSON.stringify(d.canvas) + ' main=' + JSON.stringify(d.main));
    console.log('  · topbar=' + JSON.stringify(d.topbar) + ' sidebar=' + JSON.stringify(d.sidebar) + ' tabs=' + JSON.stringify(d.tabs));
    console.log('  · fabs=' + JSON.stringify(d.fabs) + ' parent=' + d.fabsParent + ' mainPos=' + d.mainPos + ' sidebarW=' + d.sidebarWidth);
    console.log('  · tabProbe=' + JSON.stringify(d.tabProbe) + ' tabsProbe=' + JSON.stringify(d.tabsProbe));
    console.log('  · topbarProbe=' + JSON.stringify(d.topbarProbe));
    console.log('  · inputProbe=' + JSON.stringify(d.inputProbe));
    if (d.overflowItems && d.overflowItems.length) console.log('  · overflowItems=' + JSON.stringify(d.overflowItems));
    if (diag.final) console.log('  · final=' + JSON.stringify(diag.final));
    if (SHOT_MODE) console.log('  · 截图 _shots/' + prof.name + '*.png');
  }

  try { fs.unlinkSync(TMP); } catch (e) { /* 忽略 */ }
  console.log('\n' + (failed ? '✗ 共 ' + failed + ' 项失败' : '✓ 全部通过'));
  process.exit(failed ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });

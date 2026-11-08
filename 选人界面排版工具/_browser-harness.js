/* 触摸版浏览器验证脚本：由 verify_browser.js 内联进临时 HTML 末尾执行。
   与主脚本共享全局词法环境，可直接调用 __layoutTool 暴露的 API。 */
(async function () {
  var R = { mode: '', errors: [], checks: [], diag: null };
  window.addEventListener('error', function (e) { R.errors.push('onerror: ' + (e.message || e.error)); });
  window.addEventListener('unhandledrejection', function (e) {
    R.errors.push('rejection: ' + ((e.reason && e.reason.message) || e.reason));
  });
  var sleep = function (ms) { return new Promise(function (r) { setTimeout(r, ms); }); };

  function ok(name, cond, extra) {
    R.checks.push({ name: name, pass: !!cond, extra: (extra === undefined || extra === null) ? '' : String(extra) });
  }
  function finish() {
    var pre = document.createElement('pre');
    pre.id = 'diag';
    pre.textContent = JSON.stringify(R);
    document.body.appendChild(pre);
    var fails = R.checks.filter(function (c) { return !c.pass; });
    document.title = (fails.length || R.errors.length) ? 'DIAG_FAIL' : 'DIAG_OK';
  }

  var canvas = document.getElementById('canvas');
  function rectOf(el) { return el.getBoundingClientRect(); }
  function toClient(vx, vy) {
    var r = rectOf(canvas);
    return { x: r.left + vx * (r.width / 800), y: r.top + vy * (r.height / 600) };
  }
  function mkTouch(id, vx, vy) {
    var p = toClient(vx, vy);
    return new Touch({
      identifier: id, target: canvas,
      clientX: p.x, clientY: p.y,
      pageX: p.x + (window.scrollX || 0), pageY: p.y + (window.scrollY || 0),
      screenX: p.x, screenY: p.y, radiusX: 1, radiusY: 1, force: 1
    });
  }
  function fire(type, touches, changed) {
    var ev = new TouchEvent(type, {
      touches: touches, targetTouches: touches, changedTouches: changed || touches,
      bubbles: true, cancelable: true, view: window
    });
    canvas.dispatchEvent(ev);
    return ev;
  }
  function itemByGrid(gx, gy) {
    var st = window.__layoutTool.getState();
    var list = st.currentList === 'charList' ? st.charList : st.assistList;
    for (var i = 0; i < list.length; i++) if (list[i].gridX === gx && list[i].gridY === gy) return list[i];
    return null;
  }
  function firstVisibleItem() {
    var T = window.__layoutTool;
    var st = T.getState();
    var list = st.charList;
    var gap = T.calcGap(list);
    var rs = st.layout.renderSize;
    for (var i = 0; i < list.length; i++) {
      var pos = T.calcItemPos(list[i], gap);
      var sp = T.mapToScreen(pos.x + rs.w / 2, pos.y + rs.h / 2);
      if (sp.x > 20 && sp.x < 780 && sp.y > 20 && sp.y < 580) return { item: list[i], sp: sp };
    }
    return null;
  }

  async function runTouch() {
    var T = window.__layoutTool;
    var st = T.getState();
    var found = firstVisibleItem();
    ok('find-visible-item', !!found, found ? ('[' + found.item.gridX + ',' + found.item.gridY + ']') : 'none');
    if (!found) return;
    var gx = found.item.gridX, gy = found.item.gridY;
    var item = found.item, sp = found.sp;

    ok('canvas-transform-applied', /translate/.test(canvas.style.transform || ''), canvas.style.transform);

    // 1) 点选
    var t = mkTouch(1, sp.x, sp.y);
    fire('touchstart', [t], [t]);
    fire('touchend', [], [t]);
    ok('tap-select', st.selectedKey === item.listKey, st.selectedKey);

    // 2) 拖动
    var offX0 = item.offset.x, offY0 = item.offset.y;
    var undo0 = T.getUndoStack().length;
    var d1 = mkTouch(2, sp.x, sp.y);
    fire('touchstart', [d1], [d1]);
    var d2 = mkTouch(2, sp.x + 40, sp.y + 12);
    fire('touchmove', [d2], [d2]);
    var expectX = offX0 + Math.round(40 / st.viewport.scale);
    var expectY = offY0 + Math.round(12 / st.viewport.scale);
    ok('drag-offset', Math.abs(item.offset.x - expectX) <= 2 && Math.abs(item.offset.y - expectY) <= 2,
      offX0 + ',' + offY0 + ' -> ' + item.offset.x + ',' + item.offset.y + ' 期望≈' + expectX + ',' + expectY);
    ok('drag-one-undo', T.getUndoStack().length === undo0 + 1, T.getUndoStack().length - undo0);
    var d3 = mkTouch(2, sp.x + 40, sp.y + 12);
    fire('touchend', [], [d3]);

    // 3) 双指捏合
    var offBefore = [item.offset.x, item.offset.y];
    var zoom0 = T.getView().zoom;
    var a = mkTouch(11, 300, 300), b = mkTouch(12, 500, 300);
    fire('touchstart', [a, b], [a, b]);
    var a2 = mkTouch(11, 200, 300), b2 = mkTouch(12, 600, 300);
    fire('touchmove', [a2, b2], [a2, b2]);
    var zoom1 = T.getView().zoom;
    var wantZoom = Math.min(3, zoom0 * 2);
    ok('pinch-zoom', Math.abs(zoom1 - wantZoom) < 0.06, zoom0 + ' -> ' + zoom1 + ' 期望 ' + wantZoom);
    ok('pinch-keeps-offset', item.offset.x === offBefore[0] && item.offset.y === offBefore[1], item.offset.x + ',' + item.offset.y);
    ok('pinch-keeps-undo', T.getUndoStack().length === undo0 + 1, T.getUndoStack().length);
    fire('touchend', [], [a2, b2]);

    // 4) 空白拖动 = 平移
    var v0 = T.getView();
    var p1 = mkTouch(21, 60, 300);
    fire('touchstart', [p1], [p1]);
    var p2 = mkTouch(21, 20, 300);
    fire('touchmove', [p2], [p2]);
    var p3 = mkTouch(21, 20, 300);
    fire('touchend', [], [p3]);
    var v1 = T.getView();
    var item2 = itemByGrid(gx, gy);
    ok('pan-changed', Math.abs(v1.panX - v0.panX) > 0.5, v0.panX.toFixed(1) + ' -> ' + v1.panX.toFixed(1));
    ok('pan-keeps-offset', item2.offset.x === offBefore[0] && item2.offset.y === offBefore[1], item2.offset.x + ',' + item2.offset.y);

    // 5) 适应
    T.resetCanvasZoom();
    var vf = T.getView();
    ok('fit-reset', Math.abs(vf.zoom - 1) < 0.001 && Math.abs(vf.panX) < 0.001 && Math.abs(vf.panY) < 0.001,
      vf.zoom + ' / ' + vf.panX + ',' + vf.panY);

    // 6) 锁定：拖动不写 offset
    document.getElementById('fab-lock').click();
    ok('lock-on', T.getTouchState().locked === true, T.getTouchState().locked);
    var lockBefore = itemByGrid(gx, gy).offset;
    var lb = [lockBefore.x, lockBefore.y];
    var l1 = mkTouch(41, sp.x, sp.y), l2 = mkTouch(41, sp.x + 60, sp.y);
    fire('touchstart', [l1], [l1]);
    fire('touchmove', [l2], [l2]);
    fire('touchend', [], [l2]);
    var lockAfter = itemByGrid(gx, gy).offset;
    ok('lock-blocks-drag', lockAfter.x === lb[0] && lockAfter.y === lb[1], JSON.stringify([lb, [lockAfter.x, lockAfter.y]]));
    document.getElementById('fab-lock').click();
    ok('lock-off', T.getTouchState().locked === false, T.getTouchState().locked);

    // 7) 页码胶囊
    var pg0 = T.getState().currentPage;
    document.getElementById('pill-next').click();
    var pg1 = T.getState().currentPage;
    ok('pill-next-page', pg1 === Math.min(pg0 + 1, T.totalPages() - 1), pg0 + ' -> ' + pg1);
    document.getElementById('pill-prev').click();

    // 8) 撤销 / 重做
    var before = itemByGrid(gx, gy).offset;
    var snapBefore = [before.x, before.y];
    T.doUndo();
    var afterUndo = itemByGrid(gx, gy).offset;
    T.doRedo();
    var afterRedo = itemByGrid(gx, gy).offset;
    ok('undo-changes', afterUndo.x !== snapBefore[0] || afterUndo.y !== snapBefore[1],
      JSON.stringify([snapBefore, [afterUndo.x, afterUndo.y]]));
    ok('redo-restores', afterRedo.x === snapBefore[0] && afterRedo.y === snapBefore[1], JSON.stringify([[afterRedo.x, afterRedo.y]]));

    // 9) 导出 / 导入弹层
    document.getElementById('btn-export').click();
    var modal = document.getElementById('io-modal');
    ok('export-modal', !!(modal && modal.classList.contains('show')), modal && modal.className);
    var ta = document.getElementById('io-text');
    ok('export-text', !!(ta && ta.value.length > 1000), ta ? ta.value.length : -1);
    T.closeIo();
    document.getElementById('btn-import').click();
    ok('import-modal', modal.classList.contains('show') && !document.getElementById('io-file').hidden, modal.className);
    T.closeIo();

    // 10) 自动保存
    T.markDirty();
    var saved = T.autosaveNow();
    var raw = null;
    try { raw = localStorage.getItem('select-layout-tool:auto:v1'); } catch (e) { raw = null; }
    ok('autosave-write', saved === true && !!raw, String(saved));
    var parsed = null;
    try { parsed = JSON.parse(raw); } catch (e) { parsed = null; }
    ok('autosave-payload', !!(parsed && parsed.xml && parsed.dirty === true && parsed.savedAt),
      parsed ? Object.keys(parsed).join(',') : 'null');

    // 11) 长按：选中 + 打开「格子」面板（先收面板，重算落点）
    T.closeSheet();
    await sleep(700);
    T.setZoomPct(100, { resetPan: true });
    await sleep(120);
    var f2 = firstVisibleItem();
    if (f2) {
      var lp = mkTouch(51, f2.sp.x, f2.sp.y);
      fire('touchstart', [lp], [lp]);
      await sleep(560);
      fire('touchend', [], [lp]);
      ok('longpress-opens-item',
        document.getElementById('seg-item').classList.contains('active') &&
        document.body.classList.contains('sheet-open'),
        document.getElementById('seg-item').className + ' / sheet=' + document.body.classList.contains('sheet-open'));
    } else {
      ok('longpress-opens-item', false, '找不到可见格子');
    }

    // 12) 格子面板：步长 / 选整行 / 清空此格（撤销恢复）
    document.getElementById('tab-seg-item').click();
    await sleep(80);
    document.getElementById('btn-step-10').click();
    T.selectItem(itemByGrid(gx, gy));
    var step0 = itemByGrid(gx, gy).offset;
    var stepBefore = [step0.x, step0.y];
    document.getElementById('btn-right').click();
    var step1 = itemByGrid(gx, gy).offset;
    ok('step-10', step1.x === stepBefore[0] + 10, stepBefore[0] + ' -> ' + step1.x);
    document.getElementById('btn-step-1').click();
    document.getElementById('btn-select-row').click();
    var stRow = T.getState();
    ok('select-row', stRow.selectedRow === gy && T.getSelectedItems().length >= 1,
      'row=' + stRow.selectedRow + ' n=' + T.getSelectedItems().length);
    T.selectItem(itemByGrid(gx, gy));
    window.confirm = function () { return true; };
    document.getElementById('btn-clear-id').click();
    var cleared = itemByGrid(gx, gy);
    ok('clear-id', !!(cleared && cleared.fighterID === null), cleared ? String(cleared.fighterID) : 'null');
    T.doUndo();
    var restored = itemByGrid(gx, gy);
    ok('clear-id-undo', !!(restored && !!restored.fighterID), restored ? String(restored.fighterID) : 'null');

    // 13) 列表点角色 → 跳到该格所在页（PC 与手机同一入口）
    document.getElementById('tab-seg-list').click();
    await sleep(80);
    var st2 = T.getState();
    var gap2 = T.calcGap(st2.charList);
    var rpp2 = gap2.rowsPerPage || 1;
    var far = null;
    for (var i3 = 0; i3 < st2.charList.length; i3++) {
      if (st2.charList[i3].gridY === rpp2 && st2.charList[i3].fighterID) { far = st2.charList[i3]; break; }
    }
    ok('list-far-item-found', !!far, far ? ('[' + far.gridX + ',' + far.gridY + ']') : 'none');
    if (far) {
      var prefix = '[' + far.gridX + ',' + far.gridY + ']';
      var cards = document.getElementById('cards').children;
      var card = null;
      for (var k2 = cards.length - 1; k2 >= 0; k2--) {
        if (String(cards[k2].title || '').indexOf(prefix) === 0) { card = cards[k2]; break; }
      }
      ok('list-card-found', !!card, prefix);
      T.gotoPage(0);
      await sleep(80);
      if (card) card.click();
      await sleep(120);
      var st3 = T.getState();
      ok('list-jump-page', st3.currentPage === 1, st3.currentPage);
      ok('list-jump-select', st3.selectedKey === far.listKey, st3.selectedKey);
      var fl = T.getFlash();
      ok('list-jump-flash', !!(fl && fl.active && fl.key === far.listKey), fl ? (fl.key + ' active=' + fl.active + ' left=' + fl.remaining + 'ms') : 'null');
      ok('list-jump-page-pill', document.getElementById('pill-page').textContent === '2/' + T.totalPages(),
        document.getElementById('pill-page').textContent);
    }
  }

  function finalRects() {
    var T = window.__layoutTool;
    var d = T.diag();
    R.final = {
      main: d.main, sidebar: d.sidebar, tabs: d.tabs, canvas: d.canvas,
      topbar: d.topbar, inputProbe: d.inputProbe, vw: d.vw, vh: d.vh,
    };
  }

  async function main() {
    var T = window.__layoutTool;
    ok('api-exposed', !!T);
    if (!T) { finish(); return; }
    var ui = T.getUIMode();
    R.mode = ui.touchUI ? 'touch' : 'desktop';
    ok('ui-mode', true, ui.pref + '/' + R.mode);

    await sleep(700);
    T.openSheet('seg-layout');
    T.setZoomPct(100, { resetPan: true });
    await sleep(700);

    var d1 = T.diag();
    R.diag = d1;
    ok('no-horizontal-overflow', d1.overflowX === 0, d1.overflowX);
    ok('canvas-inside-main',
      !!(d1.canvas && d1.main) &&
      d1.canvas.x >= d1.main.x - 2 && d1.canvas.y >= d1.main.y - 2 &&
      d1.canvas.x + d1.canvas.w <= d1.main.x + d1.main.w + 2 &&
      d1.canvas.y + d1.canvas.h <= d1.main.y + d1.main.h + 2,
      JSON.stringify({ canvas: d1.canvas, main: d1.main }));
    ok('canvas-visible-size', !!(d1.canvas && d1.canvas.w > 120 && d1.canvas.h > 90),
      d1.canvas ? (d1.canvas.w + 'x' + d1.canvas.h) : 'null');

    if (R.mode === 'touch') {
      ok('tap-targets-44', d1.smallTargets.length === 0, d1.smallTargets.join(' | '));
      ok('bitmap-not-downscaled', d1.backingQ >= 1 && d1.bitmap[0] >= 800, d1.backingQ + ' / ' + d1.bitmap.join('x'));
      await runTouch();
      await sleep(400);
      T.closeSheet();
      T.setZoomPct(100, { resetPan: true });
      await sleep(700);
      var d2 = T.diag();
      ok('sheet-collapsed-canvas', !!(d2.canvas && d2.main) && d2.canvas.h >= d1.canvas.h - 1, d2.canvas.h + ' vs ' + d1.canvas.h);
      ok('sheet-collapsed-overflow', d2.overflowX === 0, d2.overflowX);
    } else {
      ok('desktop-bitmap-800', d1.bitmap[0] === 800 && d1.bitmap[1] === 600, d1.bitmap.join('x'));
      ok('desktop-zoom-100', d1.zoom === 1, d1.zoom);
    }

    var h = document.getElementById('touch-help-close');
    if (h) h.click();
    if (R.mode === 'touch') { T.openSheet('seg-layout'); T.setZoomPct(100, { resetPan: true }); }
    await sleep(700);
    finalRects();
    finish();
  }

  window.addEventListener('load', function () {
    main().catch(function (e) { R.errors.push('main: ' + (e && (e.stack || e.message))); finish(); });
  });
})();

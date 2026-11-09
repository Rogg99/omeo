/* Helpers de composants + registre des écrans.
   Chaque écran : S(groupe, id, titre, description, html, options)
   options : { nav: "home"|"prog"|"hist"|"profile"|false, bg: classe, dark: bool (barre d'état claire), noIsland } */
(function () {
  const I = window.icon;
  const screens = [];
  const groups = [];

  function G(id, title, desc) { groups.push({ id, title, desc }); }
  function S(group, id, title, desc, html, opts) { screens.push({ group, id, title, desc, html, opts: opts || {} }); }

  const status = (dark) =>
    '<div class="status' + (dark ? " on-dark" : "") + '"><span>9:41</span><span class="st-r">' +
    '<i style="width:3px;height:5px"></i><i style="width:3px;height:7px"></i><i style="width:3px;height:9px"></i><i style="width:3px;height:11px"></i>' +
    '<svg width="16" height="12" viewBox="0 0 16 12" fill="currentColor"><path d="M8 2.5c2.3 0 4.4.9 6 2.4l1-1.1A10 10 0 0 0 8 1 10 10 0 0 0 1 3.8l1 1.1a8.6 8.6 0 0 1 6-2.4m0 3c1.5 0 2.8.6 3.9 1.5l1-1.1A7 7 0 0 0 8 4a7 7 0 0 0-4.9 1.9l1 1.1A5.6 5.6 0 0 1 8 5.5m0 3c.7 0 1.3.2 1.8.6L8 11 6.2 9.1c.5-.4 1.1-.6 1.8-.6"/></svg>' +
    '<span style="width:25px;height:12px;border:1.5px solid currentColor;border-radius:4px;padding:1.5px;display:inline-flex;opacity:.9"><b style="background:currentColor;width:75%;border-radius:1.5px"></b></span></span></div>';

  const appbar = (o) => {
    o = o || {};
    return '<div class="appbar"><div class="grow">' + window.logo(34) + "</div>" +
      '<button class="icon-btn" aria-label="Aide et contact">' + I("help") + "</button>" +
      '<button class="icon-btn" aria-label="Notifications, 3 non lues">' + I("bell") + (o.count === 0 ? "" : '<span class="count">' + (o.count || 3) + "</span>") + "</button></div>";
  };

  const topbar = (title, eyebrow, right, o) => {
    o = o || {};
    return '<div class="topbar"><button class="icon-btn" aria-label="Retour">' + I(o.close ? "x" : "chevL", o.close ? "" : "flip") + "</button>" +
      '<div class="t">' + (eyebrow ? '<span class="eyebrow">' + eyebrow + "</span>" : "") + "<h1>" + title + "</h1></div>" +
      (right ? right : "<span></span>") + "</div>";
  };
  const iconBtn = (name, label, cls) => '<button class="icon-btn ' + (cls || "") + '" aria-label="' + (label || name) + '">' + I(name) + "</button>";

  const tabbar = (active) => {
    const t = (k, ic, label) => '<div class="tab' + (active === k ? " on" : "") + '"><span class="pill">' + I(ic) + "</span>" + label + "</div>";
    return '<nav class="tabbar" aria-label="Navigation principale">' + t("home", "home", "Accueil") + t("prog", "chart", "Progression") +
      '<button class="fab" aria-label="Ajouter un repas">' + I("plus") + "</button>" + t("hist", "calendar", "Journal") + t("profile", "user", "Profil") + "</nav>";
  };

  function ring(size, stroke, pct, color, inner, track) {
    const r = (size - stroke) / 2, c = 2 * Math.PI * r, off = c * (1 - Math.min(pct, 1));
    return '<div class="ring" style="width:' + size + "px;height:" + size + 'px"><svg viewBox="0 0 ' + size + " " + size + '">' +
      '<circle cx="' + size / 2 + '" cy="' + size / 2 + '" r="' + r + '" fill="none" stroke="' + (track || "var(--surface-2)") + '" stroke-width="' + stroke + '"/>' +
      '<circle cx="' + size / 2 + '" cy="' + size / 2 + '" r="' + r + '" fill="none" stroke="' + (color || "var(--primary)") + '" stroke-width="' + stroke + '" stroke-linecap="round" stroke-dasharray="' + c + '" stroke-dashoffset="' + off + '"/></svg>' +
      '<div class="ring-in">' + (inner || "") + "</div></div>";
  }
  const bar = (pct, color, cls) => '<div class="bar ' + (cls || "") + '"><i style="width:' + Math.round(pct * 100) + "%;--c:" + (color || "var(--primary)") + '"></i></div>';

  function line(points, o) {
    o = o || {};
    const w = 320, h = o.h || 150, max = o.max || Math.max.apply(null, points) * 1.15, n = points.length;
    const xy = points.map((v, i) => [(i / (n - 1)) * w, h - (v / max) * h]);
    const d = xy.map((p, i) => (i ? "L" : "M") + p[0].toFixed(1) + " " + p[1].toFixed(1)).join(" ");
    const area = d + " L" + w + " " + h + " L0 " + h + " Z";
    const goal = o.goal ? '<line x1="0" x2="' + w + '" y1="' + (h - (o.goal / max) * h) + '" y2="' + (h - (o.goal / max) * h) + '" stroke="var(--accent)" stroke-width="1.5" stroke-dasharray="5 5"/>' : "";
    const col = o.color || "var(--primary)";
    return '<div class="chart" style="height:' + h + 'px"><svg viewBox="0 0 ' + w + " " + h + '" preserveAspectRatio="none">' +
      '<defs><linearGradient id="g' + (o.id || "x") + '" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="' + col + '" stop-opacity=".22"/><stop offset="1" stop-color="' + col + '" stop-opacity="0"/></linearGradient></defs>' +
      goal + '<path d="' + area + '" fill="url(#g' + (o.id || "x") + ')"/><path d="' + d + '" fill="none" stroke="' + col + '" stroke-width="2.5" stroke-linejoin="round" vector-effect="non-scaling-stroke"/>' +
      xy.map((p, i) => (i === n - 1 ? '<circle cx="' + p[0] + '" cy="' + p[1] + '" r="5" fill="var(--surface)" stroke="' + col + '" stroke-width="2.5" vector-effect="non-scaling-stroke"/>' : "")).join("") +
      "</svg></div>";
  }

  function bars(values, labels, o) {
    o = o || {};
    const max = o.max || Math.max.apply(null, values) * 1.1;
    return '<div class="bars" style="height:' + (o.h || 140) + 'px">' + values.map((v, i) =>
      '<div class="' + (i === (o.today == null ? values.length - 1 : o.today) ? "today" : "") + '"><i style="height:' + Math.max(3, (v / max) * 100) + "%;--c:" + (o.color || "var(--primary)") + '"></i><span>' + labels[i] + "</span></div>").join("") + "</div>";
  }

  const days = (sel, o) => {
    o = o || {};
    const names = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"], nums = o.nums || [3, 4, 5, 6, 7, 8, 9];
    return '<div class="days">' + names.map((n, i) => '<div class="day' + (i === sel ? " on" : "") + (i > sel && !o.past ? " future" : "") + '"><small>' + n + "</small><b>" + nums[i] + "</b>" + (i <= sel && (o.dots || []).includes(i) ? '<span class="d"></span>' : "") + "</div>").join("") + "</div>";
  };

  const sheet = (title, body, o) => {
    o = o || {};
    return '<div class="scrim"></div><div class="sheet" role="dialog" aria-label="' + title.replace(/<[^>]+>/g, "") + '"><div class="grab"></div>' +
      (o.noHead ? "" : '<div class="sheet-h"><h2>' + title + "</h2>" + iconBtn("x", "Fermer", "sm") + "</div>") + body + "</div>";
  };

  const li = (ic, title, sub, right, cls) =>
    '<div class="li ' + (cls || "") + '">' + (ic ? '<span class="badge-ico ' + (ic.c || "") + '">' + I(ic.i || ic) + "</span>" : "") +
    '<div class="grow"><b>' + title + "</b>" + (sub ? "<small>" + sub + "</small>" : "") + "</div>" + (right === undefined ? I("chevR", "flip") : right) + "</div>";

  const input = (ic, ph, o) => {
    o = o || {};
    return '<div class="field">' + (o.label ? '<label class="lbl">' + o.label + "</label>" : "") +
      '<div class="input ' + (o.state || "") + (o.big ? " big" : "") + (o.area ? " area" : "") + '">' + (ic ? I(ic) : "") +
      (o.value ? '<span class="val grow">' + o.value + (o.state === "focus" ? '<span class="caret"></span>' : "") + "</span>" : '<span class="ph grow">' + (o.state === "focus" ? '<span class="caret"></span>' : "") + ph + "</span>") +
      (o.unit ? '<span class="unit">' + o.unit + "</span>" : "") + (o.right || "") + "</div>" +
      (o.help ? '<div class="help ' + (o.helpCls || "") + '">' + o.help + "</div>" : "") + "</div>";
  };

  const photo = (cls, label, style) => '<div class="photo ' + cls + '" data-label="' + (label || "") + '" style="' + (style || "") + '"></div>';
  const macro = (label, v, max, color, unit) =>
    '<div><div class="row between small"><span class="bold">' + label + '</span><span class="faint num">' + v + "/" + max + (unit || " g") + "</span></div>" +
    '<div class="mt-8">' + bar(v / max, color, "thin") + "</div></div>";

  function frame(s, o) {
    o = o || {};
    const opt = s.opts;
    return '<div class="device"><div class="screen ' + (opt.bg || "") + '"' + (opt.dir ? ' dir="' + opt.dir + '"' : "") + (opt.theme ? ' data-theme="' + opt.theme + '"' : "") + ">" +
      (opt.noIsland ? "" : '<div class="island"></div>') + (opt.noStatus ? "" : status(opt.dark)) + s.html +
      (opt.nav ? tabbar(opt.nav) : "") + '<div class="home-ind"' + (opt.dark ? ' style="background:#fff"' : "") + "></div></div></div>";
  }

  window.M = { G, S, screens, groups, status, appbar, topbar, iconBtn, tabbar, ring, bar, line, bars, days, sheet, li, input, photo, macro, frame, I };
})();

(function () {
  const { G, S, I, appbar, days, ring, macro, bar, photo } = window.M;

  G("accueil", "Accueil", "Une information clé en haut (calories restantes), puis les actions rapides et ce qui est en cours. Tous les chiffres viennent de l'API.");

  const nutritionCard = (o) => {
    o = o || {};
    const rest = o.rest == null ? 890 : o.rest, pct = o.pct == null ? 0.62 : o.pct;
    return '<div class="card"><div class="card-h"><h3>Nutrition du jour</h3><span class="tag">' + (o.when || "Aujourd'hui") + "</span></div>" +
      '<div class="row" style="gap:20px">' + ring(128, 12, pct, "var(--primary)", '<div class="num" style="font-size:32px;font-weight:600">' + rest.toLocaleString("fr-FR") + '</div><div class="xs faint bold">kcal restantes</div>') +
      '<div class="grow stack" style="--gap:14px">' + macro("Protéines", o.p || 84, 128, "var(--prot)") + macro("Glucides", o.c || 180, 270, "var(--carb)") + macro("Lipides", o.f || 42, 72, "var(--fat)") + "</div></div>" +
      '<hr class="divider"><div class="grid2"><div class="row" style="gap:10px"><span class="badge-ico sm">' + I("flame") + '</span><div><div class="xs faint bold">CONSOMMÉ</div><div class="num bold">' + (o.cons || "1 450") + ' kcal</div></div></div>' +
      '<div class="row" style="gap:10px"><span class="badge-ico sm accent">' + I("target") + '</span><div><div class="xs faint bold">OBJECTIF</div><div class="num bold">2 340 kcal</div></div></div></div></div>';
  };

  const quick = '<div class="sec-title"><h3>Ajouter un repas</h3><span class="xs faint">2 analyses photo restantes</span></div><div class="pad"><div class="grid2" style="grid-template-columns:1.3fr 1fr">' +
    '<div class="card black" style="padding:16px;min-height:132px;display:flex;flex-direction:column;justify-content:space-between"><span class="badge-ico glass">' + I("camera") + '</span><div><b style="font:600 16px var(--font-display)">Photo du plat</b><div class="xs" style="opacity:.65">Analyse en 5 secondes</div></div></div>' +
    '<div class="stack" style="--gap:10px"><div class="card tight row" style="gap:10px"><span class="badge-ico sm">' + I("mic") + '</span><b class="small grow">Vocal</b><span class="tag plus">Plus</span></div>' +
    '<div class="card tight row" style="gap:10px"><span class="badge-ico sm">' + I("search") + '</span><b class="small grow">Catalogue</b></div></div></div></div>';

  const balance = '<div class="sec-title"><h3>Balance du jour</h3><a>Détails</a></div><div class="pad"><div class="card"><div class="grid3 center">' +
    '<div><div class="xs faint bold">MANGÉ</div><div class="num h-md mt-4">1 450</div></div><div><div class="xs faint bold">DÉPENSÉ</div><div class="num h-md mt-4">2 610</div></div><div><div class="xs faint bold">ÉCART</div><div class="num h-md mt-4" style="color:var(--primary-text)">−1 160</div></div></div>' +
    '<div class="row mt-16" style="gap:10px"><span class="badge-ico sm info">' + I("footprints") + '</span><div class="grow"><div class="row between small"><b>6 420 pas</b><span class="faint">/ 8 000</span></div><div class="mt-4">' + bar(0.8, "var(--info)", "thin") + "</div></div></div>" +
    '<p class="xs faint mt-12 row" style="gap:6px">' + I("sync") + " Health Connect · synchronisé il y a 4 min</p></div></div>";

  const inProgress = '<div class="sec-title"><h3>En cours</h3><a>Tout voir</a></div><div class="pad stack" style="--gap:10px">' +
    '<div class="card green row" style="gap:14px"><span class="badge-ico glass lg">' + I("flag") + '</span><div class="grow"><div class="xs" style="opacity:.7">PROGRAMME · JOUR 12/28</div><b style="font:600 16px var(--font-display)">Mincir sans frustration</b><div class="mt-8">' + bar(0.43, "", "thin on-color") + '</div><div class="xs mt-4" style="opacity:.75">2 tâches sur 3 aujourd\'hui</div></div>' + I("chevR", "flip") + "</div>" +
    '<div class="card row" style="gap:14px"><span class="badge-ico lg accent">' + I("drop") + '</span><div class="grow"><div class="xs faint bold">CHALLENGE · JOUR 5/14</div><b style="font:600 16px var(--font-display)">2 L d\'eau par jour</b><div class="small muted mt-4">1,25 L / 2 L aujourd\'hui · validé automatiquement</div></div>' + I("chevR", "flip") + "</div></div>";

  const rewards = '<div class="pad mt-24"><div class="card row" style="gap:14px"><span class="badge-ico lg black">' + I("award") + '</span><div class="grow"><div class="row between"><b style="font:600 15px var(--font-display)">Niveau 4 · Cuisinier</b><span class="tag accent">' + I("flame") + ' 12 jours</span></div><div class="mt-8">' + bar(0.64, "var(--accent)", "thin") + '</div><div class="xs faint mt-4">640 / 1 000 points vers le niveau 5</div></div></div></div>';

  const shortcuts = '<div class="sec-title"><h3>Explorer</h3></div><div class="pad grid2">' +
    [["utensils", "Nutrition", "Équilibre et objectifs", "var(--brown-700)"], ["dumbbell", "Sport", "Séances et activité", "var(--sage-700)"], ["book", "Recettes", "Les saveurs de chez nous", "var(--ink-950)"], ["leaf", "Plantes & nutrition", "Baobab, moringa…", "#6b6a2e"]]
      .map((x) => '<div class="card" style="background:' + x[3] + ';color:#fffdf9;border:0;min-height:120px;display:flex;flex-direction:column;justify-content:space-between;position:relative;overflow:hidden"><span class="glow" style="width:120px;height:120px;right:-40px;top:-40px"></span><span class="badge-ico glass sm">' + I(x[0]) + '</span><div><b style="font:600 15px var(--font-display)">' + x[1] + '</b><div class="xs" style="opacity:.7">' + x[2] + "</div></div></div>").join("") + "</div>";

  const insight = '<div class="pad mt-16"><div class="card accent row" style="align-items:flex-start;gap:12px"><span class="badge-ico sm accent" style="background:var(--surface)">' + I("lightbulb") + '</span><div class="grow"><div class="row between"><b class="small">Constat de la semaine</b><span class="tag plus">Plus</span></div><p class="small mt-4">Tu bouges plus le week-end, mais tu manges plus aussi : +420 kcal en moyenne le samedi.</p></div></div></div>';

  const hello = (name, sub) => '<div class="pad" style="padding-top:6px"><p class="eyebrow">' + (sub || "Lundi 9 novembre") + '</p><h1 class="h-lg mt-4">Bonjour, Franck</h1></div>';

  S("accueil", "HOM-01", "Accueil · journée en cours", "Calories restantes en héros, macros, ajout rapide (photo en premier), balance, programme/challenge, niveau et série, raccourcis.",
    '<div class="scroll">' + appbar() + hello() + '<div class="mt-16">' + days(0, { nums: [9, 10, 11, 12, 13, 14, 15], dots: [0] }) + '</div><div class="pad mt-16">' + nutritionCard() + "</div>" + quick + balance + inProgress + insight + rewards + shortcuts + "</div>", { nav: "home" });

  S("accueil", "HOM-02", "Accueil · premier jour", "Nouveau compte : aucune donnée. On guide vers la première photo, sans tableau vide décourageant.",
    '<div class="scroll">' + appbar({ count: 1 }) + hello("", "Jour 1 de ton essai") + '<div class="pad mt-16"><div class="card black" style="padding:22px;position:relative;overflow:hidden"><span class="glow" style="width:200px;height:200px;right:-60px;top:-60px"></span>' +
    '<span class="tag glass">' + I("sparkles") + ' Première étape</span><h2 class="h-lg mt-16">Photographie ton<br>prochain repas</h2><p class="small mt-8" style="opacity:.7">Omeo reconnaît le plat, estime les portions et calcule tes apports.</p>' +
    '<button class="btn white md mt-20">' + I("camera") + " Prendre une photo</button></div></div>" +
    '<div class="pad mt-16">' + nutritionCard({ rest: 2340, pct: 0, p: 0, c: 0, f: 0, cons: "0" }) + "</div>" +
    '<div class="sec-title"><h3>Pour bien démarrer</h3><span class="xs faint">1/4</span></div><div class="pad"><div class="list">' +
    [["check", "Créer ton profil", 1], ["camera", "Scanner un premier repas"], ["heart", "Connecter Health Connect"], ["drop", "Ajouter un verre d'eau"]].map((t) => '<div class="li"><span class="check' + (t[2] ? " on" : "") + '" style="border-radius:50%">' + (t[2] ? I("check") : "") + '</span><div class="grow"><b style="' + (t[2] ? "text-decoration:line-through;color:var(--text-3)" : "") + '">' + t[1] + "</b></div>" + (t[2] ? "" : I("chevR", "flip")) + "</div>").join("") + "</div></div></div>", { nav: "home" });

  S("accueil", "HOM-03", "Accueil · jour passé", "Un jour passé sélectionné dans le bandeau : la carte affiche le bilan figé et un raccourci vers le journal du jour.",
    '<div class="scroll">' + appbar() + hello("", "Jeudi 5 novembre") + '<div class="mt-16">' + days(3, { dots: [0, 1, 2, 3], past: true }) + '</div><div class="pad mt-16">' + nutritionCard({ when: "Jeu. 5 nov.", rest: 120, pct: 0.95, p: 131, c: 262, f: 70, cons: "2 220" }) +
    '<div class="banner ok mt-12">' + I("check") + '<span class="grow">Objectif respecté à 5 % près · <b>+20 points</b></span></div><button class="btn outline md mt-12">Voir le journal de ce jour ' + I("arrowR", "flip") + "</button></div>" + shortcuts + "</div>", { nav: "home" });

  S("accueil", "HOM-04", "Accueil · objectif dépassé", "Dépassement affiché sans culpabiliser : chiffre en orange, message bienveillant, suggestion utile.",
    '<div class="scroll">' + appbar() + hello() + '<div class="mt-16">' + days(0, { nums: [9, 10, 11, 12, 13, 14, 15], dots: [0] }) + '</div><div class="pad mt-16"><div class="card"><div class="card-h"><h3>Nutrition du jour</h3><span class="tag accent">+180 kcal</span></div>' +
    '<div class="row" style="gap:20px">' + ring(128, 12, 1, "var(--accent)", '<div class="num" style="font-size:32px;font-weight:600;color:var(--accent-text)">+180</div><div class="xs faint bold">kcal en plus</div>') +
    '<div class="grow stack" style="--gap:14px">' + macro("Protéines", 110, 128, "var(--prot)") + macro("Glucides", 301, 270, "var(--accent)") + macro("Lipides", 70, 72, "var(--fat)") + "</div></div>" +
    '<div class="banner neutral mt-16">' + I("smile") + '<span>Ça arrive ! Une marche de 30 minutes compense environ 150 kcal. Demain est un autre jour.</span></div></div></div>' + balance + "</div>", { nav: "home" });

  S("accueil", "HOM-05", "Accueil · calcul en attente", "Hors connexion : le repas photographié est en attente, les totaux ne bougent pas tant que l'API n'a pas répondu.",
    '<div class="scroll">' + appbar() + '<div class="pad"><div class="banner neutral">' + I("wifiOff") + '<span class="grow">Hors connexion. Tes repas seront envoyés au retour du réseau.</span></div></div>' + hello() +
    '<div class="pad mt-16">' + nutritionCard() + '<div class="card mt-12 row"><div class="photo ph-alloco thumb" style="opacity:.7"></div><div class="grow"><b class="small">Déjeuner · 12:40</b><div class="xs faint row mt-4" style="gap:6px">' + I("cloudUp") + ' En cours de calcul…</div><div class="skeleton mt-8" style="height:8px;width:70%"></div></div></div></div>' + quick + "</div>", { nav: "home" });
})();

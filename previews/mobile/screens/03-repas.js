(function () {
  const { G, S, I, topbar, iconBtn, sheet, input, bar, photo, ring, appbar, days } = window.M;

  G("repas", "Ajouter un repas", "Bouton central « + » → photo (principal), vocal/texte (Plus) ou catalogue. Les valeurs nutritionnelles viennent de la base Nyam, jamais de l'IA. L'utilisateur corrige, choisit le type de repas, valide, puis peut donner son avis sur l'analyse.");

  const homeBehind = '<div class="scroll">' + appbar() + '<div class="pad"><p class="eyebrow">Lundi 9 novembre</p><h1 class="h-lg mt-4">Bonjour, Franck</h1></div><div class="mt-16">' + days(0, { nums: [9, 10, 11, 12, 13, 14, 15] }) + '</div><div class="pad mt-16"><div class="card" style="height:260px"></div></div></div>';

  const ingr = (name, qty, kcal, on, o) => {
    o = o || {};
    return '<div class="li" style="gap:12px;' + (on ? "" : "opacity:.5") + '"><span class="check' + (on ? " on" : "") + '">' + (on ? I("check") : "") + '</span><div class="grow"><b>' + name + (o.low ? ' <span class="tag warn" style="height:20px;vertical-align:1px">À vérifier</span>' : "") + "</b><small>" + kcal + " kcal" + (o.match ? " · " + o.match : "") + "</small></div>" +
      '<div class="row" style="gap:4px;background:var(--surface-2);border-radius:999px;padding:3px"><button class="icon-btn sm" style="width:30px;height:30px;border:0" aria-label="Moins">' + I("minus") + '</button><span class="num bold small" style="min-width:52px;text-align:center">' + qty + '</span><button class="icon-btn sm" style="width:30px;height:30px;border:0" aria-label="Plus">' + I("plus") + "</button></div></div>";
  };
  const mealTypes = (sel) => '<div class="chips">' + [["cup", "Petit-déjeuner"], ["utensils", "Déjeuner"], ["apple", "Collation"], ["moon", "Dîner"]].map((m, i) => '<span class="chip' + (i === sel ? " on" : "") + '">' + I(m[1] ? m[0] : "") + m[1] + "</span>").join("") + "</div>";

  S("repas", "MEA-01", "Menu « + »", "Feuille d'action : la photo est l'option principale. Quotas visibles avant d'agir. Raccourci eau.",
    homeBehind + sheet("Ajouter", '<div class="card black row" style="gap:14px;padding:18px"><span class="badge-ico glass lg">' + I("camera") + '</span><div class="grow"><b style="font:600 17px var(--font-display)">Prendre en photo</b><div class="small" style="opacity:.7">2 analyses restantes aujourd\'hui</div></div>' + I("chevR", "flip") + "</div>" +
      '<div class="list mt-12">' + window.M.li("image", "Choisir dans la galerie", "Une photo déjà prise") + window.M.li("mic", "Dicter ou écrire", "« Un ndolé avec deux plantains »", '<span class="tag plus">Plus</span>') + window.M.li("search", "Chercher un plat", "Catalogue, récents et favoris") + "</div>" +
      '<div class="list mt-12">' + window.M.li({ i: "drop", c: "info" }, "Ajouter de l'eau", "1,25 L / 2,6 L aujourd'hui", '<span class="row" style="gap:6px"><span class="chip" style="height:32px">+25 cl</span><span class="chip" style="height:32px">+50 cl</span></span>') + "</div>"), { nav: "home" });

  S("repas", "MEA-02", "Viseur photo", "Plein écran, cadre de visée, conseil de cadrage, galerie, flash. Le quota restant est rappelé.",
    '<div style="position:absolute;inset:0" class="photo ph-thieb"></div><div style="position:absolute;inset:0;background:linear-gradient(180deg,rgba(0,0,0,.45),transparent 25%,transparent 65%,rgba(0,0,0,.7))"></div>' +
    '<div style="position:absolute;top:56px;left:16px;right:16px;display:flex;justify-content:space-between;align-items:center;color:#fff">' + '<button class="icon-btn" style="background:rgba(0,0,0,.35);border:0;color:#fff" aria-label="Fermer">' + I("x") + '</button><span class="tag glass" style="backdrop-filter:blur(10px)">' + I("camera") + ' 2 analyses restantes</span><button class="icon-btn" style="background:rgba(0,0,0,.35);border:0;color:#fff" aria-label="Flash">' + I("bolt") + "</button></div>" +
    '<div style="position:absolute;left:40px;right:40px;top:200px;height:330px;color:#fff">' + ["top:0;left:0;border-width:4px 0 0 4px;border-radius:22px 0 0 0", "top:0;right:0;border-width:4px 4px 0 0;border-radius:0 22px 0 0", "bottom:0;left:0;border-width:0 0 4px 4px;border-radius:0 0 0 22px", "bottom:0;right:0;border-width:0 4px 4px 0;border-radius:0 0 22px 0"].map((s) => '<i style="position:absolute;width:46px;height:46px;border:solid #fff;' + s + '"></i>').join("") + "</div>" +
    '<p style="position:absolute;top:556px;left:0;right:0;text-align:center;color:#fff;font-size:14px;font-weight:500">Cadre toute l\'assiette, vue de dessus, avec de la lumière</p>' +
    '<div style="position:absolute;bottom:56px;left:0;right:0;display:flex;align-items:center;justify-content:space-around;color:#fff">' +
    '<button class="icon-btn" style="width:52px;height:52px;border-radius:16px;background:rgba(255,255,255,.18);border:0;color:#fff" aria-label="Galerie">' + I("image") + '</button><button style="width:82px;height:82px;border-radius:50%;border:5px solid #fff;background:rgba(255,255,255,.25)" aria-label="Prendre la photo"></button>' +
    '<button class="icon-btn" style="width:52px;height:52px;border-radius:16px;background:rgba(255,255,255,.18);border:0;color:#fff" aria-label="Saisie vocale">' + I("mic") + "</button></div>", { dark: true, bg: "full-black" });

  S("repas", "MEA-03", "Analyse en cours", "Retour immédiat : la photo reste visible, étapes de l'analyse. ~5 s.",
    '<div class="scroll no-nav">' + topbar("Analyse", "", "", { close: true }) + '<div class="pad"><div style="position:relative;border-radius:28px;overflow:hidden;height:340px">' + photo("ph-thieb", "", "position:absolute;inset:0") + '<div class="scanline"></div></div>' +
    '<h2 class="h-lg mt-24">On regarde ton assiette…</h2><div class="stack mt-16" style="--gap:12px">' +
    [["Plat reconnu", 1], ["Ingrédients détectés", 1], ["Portions estimées", 0], ["Calcul des apports", 0]].map((x, i) => '<div class="row small" style="color:' + (x[1] ? "var(--text)" : "var(--text-3)") + '">' + (x[1] ? '<span class="check on" style="border-radius:50%;width:22px;height:22px">' + I("check") + "</span>" : i === 2 ? '<span class="spinner" style="width:22px;height:22px;border-width:3px"></span>' : '<span class="check" style="border-radius:50%;width:22px;height:22px"></span>') + x[0] + "</div>").join("") + "</div></div></div>");

  const result = (low) => '<div class="scroll no-nav" style="padding-bottom:120px">' + topbar("Vérifie ton repas", "Analyse photo", iconBtn("more", "Options")) +
    '<div class="pad"><div class="row" style="gap:14px">' + photo("ph-thieb", "", "width:84px;height:84px;border-radius:22px;flex:none") + '<div class="grow"><h2 class="h-md">Thiéboudienne</h2><div class="row mt-4" style="gap:6px">' +
    (low ? '<span class="tag warn">' + I("alert") + " Confiance moyenne</span>" : '<span class="tag">' + I("sparkles") + " Confiance élevée</span>") + '</div><a class="link small mt-4" style="display:inline-block">Ce n\'est pas ça ?</a></div></div>' +
    (low ? '<div class="banner warn mt-16">' + I("alert") + "<span>On n'est pas sûrs de tout. Vérifie les ingrédients marqués et ajuste les quantités.</span></div>" : "") +
    '<div class="card mt-16 black row" style="justify-content:space-around;padding:16px">' + [["640", "kcal"], ["32 g", "prot."], ["86 g", "gluc."], ["18 g", "lip."]].map((x) => '<div class="center"><div class="num" style="font-size:20px;font-weight:600">' + x[0] + '</div><div class="xs" style="opacity:.6">' + x[1] + "</div></div>").join("") + "</div>" +
    '<div class="row between mt-24"><h3 class="h-sm">Ingrédients détectés</h3><a class="link small row" style="gap:4px">' + I("plus") + " Ajouter</a></div>" +
    '<div class="list mt-12">' + ingr("Riz brisé", "180 g", 250, 1) + ingr("Poisson (mérou)", "150 g", 165, 1) + ingr("Huile d'arachide", "15 g", 133, 1, { low: low }) + ingr("Chou", "60 g", 15, 1) + ingr("Carotte", "50 g", 20, 1) + ingr("Manioc", "100 g", 160, low ? 1 : 0, { low: low }) + "</div>" +
    '<h3 class="h-sm mt-24">Type de repas</h3><div class="mt-12">' + mealTypes(1) + '</div><p class="xs faint mt-8">Proposé selon l\'heure (12:40). Modifiable.</p></div></div>' +
    '<div class="bottom-cta"><button class="btn black">' + I("check") + " Enregistrer · 640 kcal</button></div>";

  S("repas", "MEA-04", "Ingrédients présélectionnés", "Correction en place : décocher, ajuster la quantité (±), ajouter. Totaux recalculés par l'API à chaque modification.", result(false));
  S("repas", "MEA-05", "Confiance faible", "Bannière d'avertissement et ingrédients à vérifier mis en évidence.", result(true));

  S("repas", "MEA-06", "Ajouter un ingrédient", "Recherche dans la base d'aliments, noms locaux inclus. Les valeurs sont celles de la base.",
    '<div class="scroll no-nav">' + topbar("Vérifie ton repas", "Analyse photo", "") + "</div>" + sheet("Ajouter un ingrédient", input("search", "", { state: "focus", value: "plant" }) +
      '<div class="list mt-12">' + [["Plantain mûr frit", "Alloco · 100 g · 250 kcal"], ["Plantain vert bouilli", "100 g · 122 kcal"], ["Plantain mûr bouilli", "100 g · 116 kcal"], ["Chips de plantain", "Banane chips · 100 g · 520 kcal"]].map((x) => window.M.li("", x[0], x[1], '<span class="icon-btn sm" style="background:var(--primary-soft);border:0;color:var(--primary-text)">' + I("plus") + "</span>")).join("") + "</div>" +
      '<p class="small muted center mt-16">Tu ne trouves pas ? <a class="link">Signale-le</a>, on l\'ajoutera.</p>'));

  S("repas", "MEA-07", "Modifier une quantité", "Portions concrètes (assiette, louche, pièce) plutôt que des grammes seuls.",
    '<div class="scroll no-nav">' + topbar("Vérifie ton repas", "", "") + "</div>" + sheet("Riz brisé", '<p class="muted small" style="margin-top:-8px">139 kcal pour 100 g</p>' +
      '<div class="center mt-24"><span class="num" style="font-size:56px;font-weight:600">180</span><span class="faint h-md"> g</span><div class="small muted">≈ 250 kcal</div></div>' +
      '<div class="chips mt-24" style="justify-content:center">' + ["½ assiette", "1 assiette", "1 louche", "100 g"].map((c, i) => '<span class="chip' + (i === 1 ? " on" : "") + '">' + c + "</span>").join("") + "</div>" +
      '<div class="row mt-24" style="gap:10px"><button class="btn outline md">' + I("minus") + '</button><button class="btn outline md">' + I("plus") + '</button></div><button class="btn black mt-12">Valider</button>'));

  S("repas", "MEA-08", "Photo inexploitable", "Photo floue ou sans nourriture : message explicite, l'analyse n'est pas décomptée du quota.",
    '<div class="scroll no-nav">' + topbar("Analyse", "", "", { close: true }) + '<div class="pad center"><div style="position:relative;border-radius:28px;overflow:hidden;height:300px;filter:blur(3px)">' + photo("ph-thieb", "", "position:absolute;inset:0") + "</div>" +
      '<span class="badge-ico lg round warn" style="margin:-28px auto 0;position:relative;box-shadow:0 0 0 6px var(--bg)">' + I("camera") + '</span><h2 class="h-lg mt-16">On n\'a pas reconnu de plat</h2><p class="muted mt-8">La photo est floue ou trop sombre. Cette analyse n\'est pas décomptée.</p>' +
      '<div class="card sunk mt-20 stack small" style="text-align:start;--gap:8px">' + ["Vue de dessus, toute l'assiette", "Près d'une fenêtre ou avec le flash", "Téléphone immobile"].map((t) => '<div class="row">' + I("check") + t + "</div>").join("") + "</div></div></div>" +
      '<div class="bottom-cta"><button class="btn black">' + I("camera") + ' Reprendre la photo</button><button class="btn ghost mt-8">Chercher dans le catalogue</button></div>');

  S("repas", "MEA-09", "Repas enregistré", "Célébration courte, points gagnés, nouveaux totaux, et demande d'avis en un geste (👍/👎).",
    '<div class="scroll no-nav"><div class="pad center" style="padding-top:80px">' + ring(150, 12, 0.62, "var(--primary)", '<span class="badge-ico lg round" style="width:80px;height:80px;background:var(--primary);color:var(--on-primary)">' + I("check") + "</span>") +
      '<h1 class="h-lg mt-24">Déjeuner enregistré</h1><p class="muted mt-8">Il te reste <b style="color:var(--text)">890 kcal</b> pour aujourd\'hui.</p><span class="tag accent mt-16" style="height:32px;font-size:13px;padding:0 14px">' + I("star") + " +10 points</span>" +
      '<div class="card mt-32"><b class="h-sm">L\'analyse était-elle juste ?</b><p class="small muted mt-4">Ton avis améliore la reconnaissance des plats.</p><div class="row mt-16" style="gap:10px"><button class="btn outline md">' + I("thumbUp") + ' Oui</button><button class="btn outline md">' + I("thumbDown") + " Non</button></div></div>" +
      '<div class="card sunk mt-12 row small" style="text-align:start">' + I("book") + '<span class="grow">La recette du <b>thiéboudienne</b> est dans le catalogue.</span><a class="link">Voir</a></div></div></div>' +
      '<div class="bottom-cta"><button class="btn black">Terminé</button></div>');

  S("repas", "MEA-10", "Avis négatif", "Motif en un geste, commentaire facultatif. Les corrections faites sont jointes automatiquement.",
    '<div class="scroll no-nav"></div>' + sheet("Qu'est-ce qui n'allait pas ?", '<div class="stack" style="--gap:10px">' +
      [["Mauvais plat", 0], ["Ingrédient manquant", 1], ["Quantités fausses", 1], ["Autre", 0]].map((r) => '<div class="option' + (r[1] ? " on" : "") + '" style="padding:14px 16px"><div class="grow"><b style="font-size:15px">' + r[0] + '</b></div><span class="check' + (r[1] ? " on" : "") + '">' + (r[1] ? I("check") : "") + "</span></div>").join("") + "</div>" +
      '<div class="mt-16">' + input("", "", { area: true, value: "Il manquait le gombo, et la portion de riz était plus petite." }) + "</div>" +
      '<div class="banner neutral mt-12">' + I("info") + "<span>Tes corrections (2 quantités modifiées) seront jointes à l'avis.</span></div><button class=\"btn black mt-16\">Envoyer · +5 points</button>"));

  S("repas", "MEA-11", "Saisie vocale", "Plus : on dicte librement. Transcription en direct, puis même écran de correction que la photo.",
    '<div class="scroll no-nav">' + topbar("Dicter mon repas", "", "", { close: true }) + '<div class="pad"><div class="seg"><span class="on">' + I("mic") + ' Voix</span><span>' + I("keyboard") + " Texte</span></div>" +
      '<p class="h-lg mt-32" style="font-weight:500;line-height:1.35">« Une assiette de <span style="background:var(--primary-soft);border-radius:6px;padding:0 4px">ndolé</span> avec <span style="background:var(--primary-soft);border-radius:6px;padding:0 4px">deux plantains frits</span> et un <span class="faint">peu de…</span>»</p>' +
      '<p class="xs faint mt-16">7 saisies vocales restantes ce mois-ci</p></div></div>' +
      '<div style="position:absolute;bottom:60px;left:0;right:0;display:flex;flex-direction:column;align-items:center;gap:18px"><div class="row" style="gap:4px;height:40px">' + [10, 22, 34, 18, 40, 26, 14, 30, 38, 20, 12, 28, 16].map((h) => '<i style="width:4px;height:' + h + 'px;border-radius:2px;background:var(--primary)"></i>').join("") + "</div>" +
      '<button style="width:84px;height:84px;border-radius:50%;border:0;background:var(--accent);color:#fff;display:grid;place-items:center;box-shadow:0 0 0 10px var(--accent-soft)" aria-label="Arrêter">' + I("pause") + '</button><span class="small muted">Touche pour terminer</span></div>');

  S("repas", "MEA-12", "Saisie en texte", "Alternative à la voix (lieu bruyant, discrétion). Exemples cliquables.",
    '<div class="scroll no-nav">' + topbar("Décrire mon repas", "", "", { close: true }) + '<div class="pad"><div class="seg"><span>' + I("mic") + ' Voix</span><span class="on">' + I("keyboard") + " Texte</span></div>" +
      '<div class="mt-20">' + input("", "", { area: true, state: "focus", value: "Petit-déjeuner : bouillie de mil avec du lait et un beignet" }) + "</div>" +
      '<p class="eyebrow mt-20">Exemples</p><div class="chips mt-8">' + ["2 beignets haricots", "Garba au thon", "Yassa poulet, riz"].map((c) => '<span class="chip">' + c + "</span>").join("") + "</div></div></div>" +
      '<div class="bottom-cta"><button class="btn black">' + I("sparkles") + " Analyser</button></div>");

  S("repas", "MEA-13", "Catalogue de plats", "Recherche, filtre par pays, récents et favoris en tête pour aller vite.",
    '<div class="scroll no-nav">' + topbar("Chercher un plat", "", "", { close: true }) + '<div class="pad">' + input("search", "Ndolé, attiéké, yassa…") +
      '<div class="chips mt-12 scroll-x" style="flex-wrap:nowrap">' + ["Tous les pays", "🇨🇲 Cameroun", "🇸🇳 Sénégal", "🇨🇮 Côte d\'Ivoire", "🇹🇬 Togo"].map((c, i) => '<span class="chip' + (i === 0 ? " on" : "") + '">' + c + "</span>").join("") + "</div>" +
      '<p class="eyebrow mt-24">Récents</p><div class="list mt-8">' + [["ph-ndole", "Ndolé", "1 assiette · 520 kcal"], ["ph-alloco", "Alloco", "1 portion · 360 kcal"]].map((x) => '<div class="li"><div class="photo ' + x[0] + ' thumb" style="width:48px;height:48px;border-radius:14px"></div><div class="grow"><b>' + x[1] + "</b><small>" + x[2] + '</small></div><span class="icon-btn sm" style="background:var(--primary-soft);border:0;color:var(--primary-text)">' + I("plus") + "</span></div>").join("") + "</div>" +
      '<p class="eyebrow mt-24">Favoris</p><div class="list mt-8">' + [["ph-yassa", "Poulet yassa", "1 assiette · 610 kcal"], ["ph-fonio", "Fonio aux légumes", "1 bol · 340 kcal"], ["ph-gombo", "Sauce gombo", "1 louche · 180 kcal"]].map((x) => '<div class="li"><div class="photo ' + x[0] + ' thumb" style="width:48px;height:48px;border-radius:14px"></div><div class="grow"><b>' + x[1] + "</b><small>" + x[2] + '</small></div><span class="icon-btn sm" style="background:var(--primary-soft);border:0;color:var(--primary-text)">' + I("plus") + "</span></div>").join("") + "</div></div></div>");

  S("repas", "MEA-14", "Plat du catalogue · portion", "Portion standard modifiable, apports par portion, lien vers la recette.",
    '<div class="scroll no-nav bleed">' + photo("ph-ndole", "photo ndolé", "height:300px") + '<div style="position:absolute;top:56px;left:16px">' + iconBtn("x", "Fermer") + '</div><div class="pad" style="margin-top:-28px;position:relative"><div class="card"><div class="row between"><div><h2 class="h-lg">Ndolé</h2><p class="small muted">Cameroun · aussi appelé « ndolè »</p></div>' + iconBtn("heart", "Favori") + "</div>" +
      '<p class="eyebrow mt-20">Portion</p><div class="row mt-8" style="gap:10px"><div class="seg grow"><span>½</span><span class="on">1 assiette</span><span>1½</span><span>2</span></div></div><p class="xs faint mt-8">1 assiette ≈ 350 g</p>' +
      '<div class="grid2 mt-16" style="grid-template-columns:repeat(4,1fr);gap:8px">' + [["520", "kcal"], ["29 g", "prot."], ["18 g", "gluc."], ["38 g", "lip."]].map((x) => '<div class="stat center" style="padding:10px 4px"><div class="v" style="font-size:16px">' + x[0] + '</div><div class="l">' + x[1] + "</div></div>").join("") + '</div></div><h3 class="h-sm mt-24">Type de repas</h3><div class="mt-12">' + mealTypes(1) + "</div></div></div>" +
      '<div class="bottom-cta"><button class="btn black">Ajouter au déjeuner</button></div>');

  S("repas", "MEA-15", "Détail d'un repas", "Depuis le journal : photo, apports, ingrédients, et toutes les actions de gestion.",
    '<div class="scroll no-nav bleed">' + photo("ph-alloco", "photo du repas", "height:280px") + '<div style="position:absolute;top:56px;left:16px;right:16px;display:flex;justify-content:space-between">' + iconBtn("chevL", "Retour") + iconBtn("more", "Plus d'actions") + "</div>" +
      '<div class="pad" style="padding-top:20px"><span class="tag">' + I("utensils") + ' Déjeuner · 12:40</span><h1 class="h-lg mt-8">Alloco & poisson braisé</h1><p class="small muted">Analyse photo · modifiée par toi</p>' +
      '<div class="card black mt-16 row" style="justify-content:space-around">' + [["810", "kcal"], ["41 g", "prot."], ["92 g", "gluc."], ["31 g", "lip."]].map((x) => '<div class="center"><div class="num" style="font-size:19px;font-weight:600">' + x[0] + '</div><div class="xs" style="opacity:.6">' + x[1] + "</div></div>").join("") + "</div>" +
      '<div class="grid2 mt-12" style="grid-template-columns:repeat(4,1fr);gap:8px">' + [["edit", "Modifier"], ["move", "Déplacer"], ["duplicate", "Dupliquer"], ["trash", "Supprimer"]].map((a, i) => '<div class="center small" style="' + (i === 3 ? "color:var(--danger)" : "") + '"><span class="badge-ico round ' + (i === 3 ? "danger" : "neutral") + '" style="margin:auto">' + I(a[0]) + '</span><div class="mt-4 xs bold">' + a[1] + "</div></div>").join("") + "</div>" +
      '<h3 class="h-sm mt-24">Ingrédients</h3><div class="list mt-12">' + [["Banane plantain frite", "200 g · 500 kcal"], ["Poisson braisé (tilapia)", "180 g · 230 kcal"], ["Piment, oignon, tomate", "60 g · 25 kcal"], ["Attiéké", "50 g · 55 kcal"]].map((x) => window.M.li("", x[0], x[1], "")).join("") + "</div>" +
      '<div class="row mt-16 small muted" style="gap:8px">' + I("trash") + '<a class="link">Supprimer la photo seulement</a></div></div></div>');

  S("repas", "MEA-16", "Déplacer un repas", "Changer le type de repas et/ou le jour.",
    '<div class="scroll no-nav"></div>' + sheet("Déplacer le repas", '<p class="eyebrow">Vers</p><div class="mt-8">' + mealTypes(3) + '</div><p class="eyebrow mt-20">Jour</p><div class="mt-8" style="margin:0 -20px">' + days(5, { nums: [3, 4, 5, 6, 7, 8, 9], past: true }) + '</div><button class="btn black mt-24">Déplacer vers dîner · dim. 8</button>'));

  S("repas", "MEA-17", "Supprimer un repas", "Confirmation explicite, action destructive en rouge, annulation possible via snackbar ensuite.",
    '<div class="scroll no-nav bleed">' + photo("ph-alloco", "", "height:280px") + '</div><div class="scrim"></div><div class="dialog"><span class="badge-ico lg round danger" style="margin:auto">' + I("trash") + '</span><h2 class="h-md mt-16">Supprimer ce repas ?</h2><p class="small muted mt-8">Alloco & poisson braisé (810 kcal) sera retiré de ton journal et tes totaux seront recalculés.</p>' +
      '<button class="btn danger md mt-20">Supprimer</button><button class="btn ghost md mt-4">Annuler</button></div>');
})();

(function () {
  const { G, S, I, appbar, topbar, sheet, days, screens } = window.M;

  G("systeme", "États système & thèmes", "Chargement, hors connexion, erreurs, mise à jour exigée, nouveaux CGU, permissions, plus les déclinaisons sombre et arabe (RTL) d'écrans clés.");

  S("systeme", "SYS-01", "Chargement (squelette)", "Squelettes à la forme du contenu final plutôt qu'un spinner seul (cf. capture « Programmes » vide).",
    '<div class="scroll">' + appbar() + '<div class="pad"><div class="skeleton" style="height:12px;width:120px"></div><div class="skeleton mt-8" style="height:28px;width:200px"></div></div><div class="days mt-16">' + Array.from({ length: 7 }, () => '<div class="skeleton grow" style="height:64px;border-radius:20px"></div>').join("") + '</div><div class="pad mt-16"><div class="skeleton" style="height:230px;border-radius:24px"></div><div class="grid2 mt-16"><div class="skeleton" style="height:130px;border-radius:24px"></div><div class="skeleton" style="height:130px;border-radius:24px"></div></div></div></div>', { nav: "home" });

  S("systeme", "SYS-02", "Hors connexion", "Bandeau persistant mais discret ; l'app reste utilisable (saisies mises en attente).",
    '<div class="scroll">' + appbar() + '<div class="pad"><div class="banner neutral">' + I("wifiOff") + '<span class="grow">Hors connexion · 2 repas en attente d\'envoi</span></div><p class="eyebrow mt-20">Lundi 9 novembre</p><h1 class="h-lg mt-4">Bonjour, Franck</h1></div><div class="mt-16">' + days(0, { nums: [9, 10, 11, 12, 13, 14, 15] }) + '</div><div class="pad mt-16"><div class="card" style="opacity:.6"><div class="row between"><h3 class="h-sm">Nutrition du jour</h3><span class="tag neutral">Mis à jour à 11:02</span></div><div class="skeleton mt-16" style="height:120px"></div></div></div></div>' +
    '<div class="toast">' + I("cloudUp") + '<span class="grow">Repas enregistré. Il sera calculé au retour du réseau.</span></div>', { nav: "home" });

  S("systeme", "SYS-03", "Erreur de chargement", "Message humain, cause probable, action de reprise. Jamais de code d'erreur brut.",
    '<div class="scroll">' + topbar("Programmes", "", "") + '<div class="pad center" style="padding-top:140px"><span class="badge-ico round warn" style="margin:auto;width:88px;height:88px">' + I("alert").replace('class="ico ', 'style="width:36px;height:36px" class="ico ') + '</span><h2 class="h-md mt-20">Impossible de charger les programmes</h2><p class="small muted mt-8">Le réseau semble lent. Réessaie dans un instant.</p><button class="btn black md mt-20" style="width:auto">' + I("refresh") + " Réessayer</button></div></div>", { nav: "home" });

  S("systeme", "SYS-04", "Mise à jour exigée", "Version minimale fixée dans l'admin : écran bloquant, une seule action.",
    '<div class="scroll no-nav"><div class="pad center" style="padding-top:170px">' + window.logo(56, false) + '<h1 class="h-lg mt-24">Une mise à jour est nécessaire</h1><p class="muted mt-8">Cette version de Nyam n\'est plus prise en charge. Mets à jour pour continuer ; tes données sont conservées.</p></div></div><div class="bottom-cta"><button class="btn black">' + window.brandIcons.play + " Mettre à jour</button></div>");

  S("systeme", "SYS-05", "Nouvelles CGU à accepter", "Un document a changé : résumé des changements, lecture complète, acceptation obligatoire pour continuer.",
    '<div class="scroll">' + appbar() + '</div><div class="scrim"></div>' + sheet("", '<h2 class="h-md">Nos conditions évoluent</h2><p class="small muted mt-8">Version 4 de la politique de confidentialité, en vigueur le 1er décembre 2026.</p><div class="card sunk mt-16 stack small" style="--gap:8px">' + ["Nouvel hébergeur des photos de repas (UE)", "Durée de conservation des photos : 24 mois", "Précisions sur l'export de tes données"].map((t) => '<div class="row" style="align-items:flex-start;gap:8px">' + I("check") + t + "</div>").join("") + '</div><a class="link small mt-12" style="display:inline-block">Lire le document complet</a><button class="btn black mt-20">J\'accepte</button>', { noHead: false }), { nav: "home" });

  S("systeme", "SYS-06", "Caméra refusée", "Permission refusée : explication et lien vers les réglages, alternative sans caméra.",
    '<div class="scroll no-nav">' + topbar("", "", "", { close: true }) + '<div class="pad center" style="padding-top:100px"><span class="badge-ico round neutral" style="margin:auto;width:96px;height:96px">' + I("camera").replace('class="ico ', 'style="width:40px;height:40px" class="ico ') + '</span><h1 class="h-lg mt-20">Nyam a besoin de ta caméra</h1><p class="muted mt-8">Pour analyser tes plats. Les photos ne servent qu\'à ton suivi et tu peux les supprimer.</p></div></div>' +
    '<div class="bottom-cta"><button class="btn black">Ouvrir les réglages</button><button class="btn ghost mt-4">Choisir dans la galerie</button></div>');

  S("systeme", "SYS-07", "Annuler une action", "Snackbar d'annulation après une suppression (5 s).",
    '<div class="scroll">' + topbar("Journal", "", "") + '<div class="pad"><div class="card" style="height:120px"></div><div class="card mt-12" style="height:120px"></div></div></div><div class="toast">' + I("trash") + '<span class="grow">Repas supprimé</span><a class="link">Annuler</a></div>', { nav: "hist" });

  const home = screens.find((s) => s.id === "HOM-01");
  if (home) {
    S("systeme", "SYS-08", "Accueil · thème sombre", "Surfaces chaudes très foncées, vert éclairci pour le contraste (AA). Même hiérarchie qu'en clair.", home.html, Object.assign({}, home.opts, { theme: "dark", dark: true }));
    S("systeme", "SYS-09", "Accueil · arabe (RTL)", "Mise en page miroir, flèches retournées, chiffres et graphiques restent lisibles. Textes traduits dans l'app réelle.",
      home.html.replace("Bonjour, Franck", "مرحبًا، فرانك").replace("Lundi 9 novembre", "الإثنين 9 نوفمبر").replace("Nutrition du jour", "تغذية اليوم").replace("Ajouter un repas", "أضف وجبة").replace("Photo du plat", "صورة الطبق"),
      Object.assign({}, home.opts, { dir: "rtl" }));
  }
  const pls = screens.find((s) => s.id === "PLS-01");
  if (pls) S("systeme", "SYS-10", "Nyam Plus · thème sombre", "Vérification du thème sombre sur un écran à fort enjeu.", pls.html, Object.assign({}, pls.opts, { theme: "dark", dark: true }));
})();

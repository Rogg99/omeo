(function () {
  const { G, S, I, topbar, iconBtn, input, ring, sheet } = window.M;

  G("onboarding", "Démarrage & onboarding", "Écran de démarrage → langue → questionnaire en 9 étapes (réponses gardées sur le téléphone) → création du compte → plan calculé par l'API. Une question par écran, gros champ, bouton toujours accessible au pouce.");
  G("compte", "Connexion & compte", "Connexion pour les utilisateurs existants, mot de passe oublié, vérification de l'email.");

  const step = (n, ic, title, sub, body, o) => {
    o = o || {};
    const bars = Array.from({ length: 9 }, (_, i) => '<i class="' + (i < n - 1 ? "on" : i === n - 1 ? "cur" : "") + '"></i>').join("");
    return '<div class="scroll no-nav"><div class="row" style="padding:6px 16px 0">' + iconBtn("arrowL", "Étape précédente", "ghost") +
      '<div class="grow"><div class="steps-bar" role="progressbar" aria-valuemin="1" aria-valuemax="9" aria-valuenow="' + n + '">' + bars + "</div></div>" +
      '<span class="num bold" style="width:44px;text-align:center;color:var(--primary-text)">' + n + "/9</span></div>" +
      '<div class="pad" style="padding-top:28px"><span class="badge-ico lg round">' + I(ic) + "</span>" +
      '<h1 class="h-xl mt-20">' + title + '</h1><p class="muted mt-8">' + sub + "</p>" +
      '<div class="mt-32 stack" style="--gap:12px">' + body + "</div></div></div>" +
      '<div class="bottom-cta">' + (o.above || "") + '<button class="btn black"' + (o.disabled ? " disabled" : "") + ">" + (o.cta || "Continuer") + " " + I("arrowR", "flip") + "</button></div>";
  };

  // ---------- Démarrage ----------
  S("onboarding", "ONB-01", "Écran de démarrage", "Logo sur fond vert profond pendant le chargement (< 1,5 s). Pas d'interaction.",
    '<div style="position:absolute;inset:0;display:grid;place-items:center;--logo-color: #e2e8da;--logo-text:#f4efe6">' +
    '<div class="center">' + window.logo(64, false) + '<div style="font:700 44px/1 var(--font-display);letter-spacing:-.04em;margin-top:14px">Omeo</div>' +
    '<p style="margin-top:10px;opacity:.75;font-size:15px">Scanne. <span style="color:#f2a26b">Comprends.</span> Mange mieux.</p></div></div>' +
    '<div style="position:absolute;bottom:60px;left:0;right:0;display:grid;place-items:center"><div class="spinner" style="width:26px;height:26px;border-width:3px;border-color:rgba(255,255,255,.18);border-top-color:#fff"></div></div>',
    { bg: "full-green", dark: true });

  S("onboarding", "ONB-02", "Choix de la langue", "Langue détectée sur le téléphone et présélectionnée. 8 langues ; l'arabe bascule l'interface de droite à gauche.",
    '<div class="scroll no-nav"><div class="pad" style="padding-top:36px">' + window.logo(36) +
    '<h1 class="h-xl mt-32">Dans quelle langue<br>veux-tu utiliser Omeo ?</h1><p class="muted mt-8">Tu pourras la changer à tout moment dans les paramètres.</p>' +
    '<div class="list mt-24">' +
    [["Français", "Détectée sur ton téléphone", 1], ["English"], ["Español"], ["Português"], ["العربية", "De droite à gauche"], ["简体中文"], ["日本語"], ["Deutsch"]]
      .map((l) => '<div class="li"><div class="grow"><b>' + l[0] + "</b>" + (l[1] ? "<small>" + l[1] + "</small>" : "") + '</div><span class="radio' + (l[2] ? " on" : "") + '">' + (l[2] ? I("check") : "") + "</span></div>").join("") +
    '</div></div></div><div class="bottom-cta"><button class="btn black">Continuer ' + I("arrowR", "flip") + "</button></div>");

  S("onboarding", "ONB-03", "Bienvenue", "Promesse en une phrase + 3 bénéfices. Deux chemins clairs : nouveau compte ou connexion.",
    '<div class="scroll no-nav bleed"><div style="height:430px;position:relative;background:var(--sage-800);border-radius:0 0 40px 40px;overflow:hidden">' +
    '<div class="photo ph-thieb" data-label="photo plat" style="position:absolute;width:250px;height:250px;border-radius:50%;left:50%;top:92px;translate:-50% 0;box-shadow:0 30px 60px -20px rgba(0,0,0,.6)"></div>' +
    '<div style="position:absolute;left:50%;top:80px;translate:-50% 0;width:290px;height:290px;border:2px dashed rgba(255,255,255,.35);border-radius:50%"></div>' +
    '<span class="tag glass" style="position:absolute;left:26px;top:120px;backdrop-filter:blur(8px)">' + I("flame") + " 640 kcal</span>" +
    '<span class="tag glass" style="position:absolute;right:24px;top:250px;backdrop-filter:blur(8px)">' + I("beef") + " 32 g protéines</span>" +
    '<span class="tag" style="position:absolute;left:44px;bottom:38px;background:#fffdf9;color:#151411">' + I("sparkles") + " Thiéboudienne reconnu</span></div>" +
    '<div class="pad" style="padding-top:30px"><h1 class="h-xl">Mange mieux.<br><span class="serif" style="font-size:40px;color:var(--primary-text)">À ton rythme.</span></h1>' +
    '<p class="muted mt-12">Photographie ton assiette : Omeo reconnaît le plat, estime les portions et te dit où tu en es.</p></div></div>' +
    '<div class="bottom-cta"><button class="btn black">Commencer · 2 min</button><button class="btn ghost mt-8">J\'ai déjà un compte</button></div>');

  // ---------- Questionnaire ----------
  S("onboarding", "ONB-04", "Étape 1 · Nom", "Clavier ouvert directement, 2 à 60 caractères. Le bouton reste désactivé tant que le champ est vide.",
    step(1, "user", "Comment t'appelles-tu ?", "Pour personnaliser ton suivi.",
      input("user", "Prénom et nom", { state: "focus", value: "Franck Etape", help: "<span></span><span>12/60</span>" })));

  S("onboarding", "ONB-05", "Étape 2 · Âge", "Sélecteur de date de naissance en roues (pas de clavier). L'âge calculé est affiché pour rassurer.",
    step(2, "calendar", "Quelle est ta date de naissance ?", "Elle sert à calculer tes besoins caloriques.",
      '<div class="card" style="padding:8px 0;position:relative"><div style="position:absolute;left:12px;right:12px;top:50%;translate:0 -50%;height:52px;border-radius:14px;background:var(--primary-soft)"></div>' +
      '<div style="display:grid;grid-template-columns:1fr 1.6fr 1.2fr;position:relative;text-align:center;font:600 20px/52px var(--font-display)">' +
      ["<span class='faint' style='font-size:16px'>12<br>13</span>", "<span class='faint' style='font-size:16px'>Février<br>Mars</span>", "<span class='faint' style='font-size:16px'>1994<br>1995</span>"].join("") +
      "<span>14</span><span>Avril</span><span>1996</span>" +
      ["<span class='faint' style='font-size:16px'>15<br>16</span>", "<span class='faint' style='font-size:16px'>Mai<br>Juin</span>", "<span class='faint' style='font-size:16px'>1997<br>1998</span>"].join("") +
      '</div></div><div class="banner ok">' + I("info") + "<span>Tu as <b>30 ans</b>.</span></div>"));

  S("onboarding", "ONB-06", "Étape 3 · Genre", "Deux grandes cartes. On explique pourquoi la question est posée (calcul du métabolisme).",
    step(3, "users", "Quel est ton genre ?", "Il intervient dans le calcul de ton métabolisme de base.",
      '<div class="option on"><span class="badge-ico round">' + I("user") + '</span><div class="grow"><b>Homme</b></div><span class="radio on">' + I("check") + "</span></div>" +
      '<div class="option"><span class="badge-ico round neutral">' + I("user") + '</span><div class="grow"><b>Femme</b></div><span class="radio"></span></div>'));

  S("onboarding", "ONB-07", "Étape 4 · Ville", "Saisie avec suggestions locales. Les villes populaires sont proposées en un geste.",
    step(4, "pin", "Dans quelle ville vis-tu ?", "Pour te proposer des plats et des recettes de ta région.",
      input("search", "Rechercher une ville", { state: "focus", value: "Yao" }) +
      '<div class="list">' + [["Yaoundé", "Cameroun", 1], ["Yaoundé — Mvog-Ada", "Cameroun"]].map((c) => '<div class="li" style="min-height:56px">' + I("pin") + '<div class="grow"><b>' + c[0] + "</b><small>" + c[1] + "</small></div>" + (c[2] ? I("check") : "") + "</div>").join("") + "</div>" +
      '<p class="eyebrow mt-16">Populaires</p><div class="chips">' + ["Dakar", "Abidjan", "Lomé", "Douala", "Cotonou", "Bamako"].map((c) => '<span class="chip">' + c + "</span>").join("") + "</div>"));

  S("onboarding", "ONB-08", "Étape 5 · Taille", "Règle horizontale à faire glisser + saisie au clavier possible. Bascule cm / ft.",
    step(5, "ruler", "Quelle est ta taille ?", "Entre 100 et 250 cm.",
      '<div class="center"><span class="num" style="font-size:64px;font-weight:600">175</span><span class="faint" style="font-size:22px;font-weight:600"> cm</span></div>' +
      '<div style="position:relative;height:70px;overflow:hidden;margin:0 -20px"><div style="position:absolute;left:50%;top:0;bottom:0;width:3px;background:var(--accent);border-radius:2px;translate:-50% 0;z-index:1"></div>' +
      '<div style="display:flex;align-items:flex-end;gap:9px;height:56px;justify-content:center">' + Array.from({ length: 41 }, (_, i) => '<i style="width:2px;flex:none;background:var(--text-3);opacity:' + (i % 5 ? .45 : .9) + ";height:" + (i % 10 === 0 ? 48 : i % 5 ? 22 : 34) + 'px"></i>').join("") + "</div></div>" +
      '<div class="seg" style="width:160px;margin:8px auto 0"><span class="on">cm</span><span>ft</span></div>'));

  S("onboarding", "ONB-09", "Étape 6 · Poids", "Champ numérique géant avec décimale. Unité kg / lb.",
    step(6, "scale", "Quel est ton poids ?", "Ton poids actuel, même approximatif.",
      input("", "", { big: true, state: "focus", value: "80,5", unit: "kg" }) +
      '<div class="seg" style="width:160px;margin:4px auto 0"><span class="on">kg</span><span>lb</span></div>' +
      '<div class="banner neutral">' + I("lock") + "<span>Tes données de santé restent privées et ne sont jamais partagées.</span></div>"));

  S("onboarding", "ONB-10", "Étape 7 · Poids cible", "Écart affiché en direct. État normal.",
    step(7, "flag", "Quel poids veux-tu atteindre ?", "On t'aidera à y arriver de façon saine et durable.",
      input("", "", { big: true, state: "focus", value: "74", unit: "kg" }) +
      '<div class="card soft row">' + I("trend") + '<span class="grow small"><b>−6,5 kg</b> par rapport à aujourd\'hui. Un rythme sain : 0,5 kg par semaine environ.</span></div>'));

  S("onboarding", "ONB-11", "Étape 7 · Cible incohérente", "Avertissement non bloquant quand la cible contredit l'objectif (ex. perdre du poids avec une cible plus haute).",
    step(7, "flag", "Quel poids veux-tu atteindre ?", "On t'aidera à y arriver de façon saine et durable.",
      input("", "", { big: true, state: "focus", value: "90", unit: "kg" }) +
      '<div class="banner warn">' + I("alert") + "<span><b>+9,5 kg</b> par rapport à aujourd'hui. Si ton objectif est de perdre du poids, vérifie ce chiffre. Tu pourras préciser ton objectif à l'étape suivante.</span></div>"));

  S("onboarding", "ONB-12", "Étape 8 · Objectifs", "Choix multiple. Les objectifs incompatibles (perdre / prendre) s'excluent avec une explication.",
    step(8, "target", "Quels sont tes objectifs ?", "Choisis-en un ou plusieurs. Omeo adapte ses conseils.",
      [["scale", "Perdre du poids", "Atteindre et garder un poids santé.", 1], ["dumbbell", "Prendre de la masse", "Gagner du muscle avec une alimentation adaptée.", 0, 1], ["utensils", "Manger équilibré", "De meilleures habitudes au quotidien.", 1], ["drop", "Prévenir le diabète", "Mieux gérer sa glycémie.", 1], ["heart", "Prévenir l'hypertension", "Surveiller le sel et la tension.", 0]]
        .map((o) => '<div class="option' + (o[3] ? " on" : "") + '"' + (o[4] ? ' style="opacity:.45"' : "") + '><span class="badge-ico round' + (o[3] ? "" : " neutral") + '">' + I(o[0]) + '</span><div class="grow"><b>' + o[1] + "</b><small>" + (o[4] ? "Incompatible avec « Perdre du poids »" : o[2]) + '</small></div><span class="check' + (o[3] ? " on" : "") + '">' + (o[3] ? I("check") : "") + "</span></div>").join(""),
      { cta: "Continuer · 3 choisis" }));

  S("onboarding", "ONB-13", "Étape 9 · Créer le compte", "Google / Apple en premier (moins de saisie). Code d'invitation avant tout choix, y compris Google/Apple. Consentements séparés et explicites.",
    '<div class="scroll no-nav" style="padding-bottom:40px"><div class="row" style="padding:6px 16px 0">' + iconBtn("arrowL", "Étape précédente", "ghost") +
    '<div class="grow"><div class="steps-bar">' + '<i class="on"></i>'.repeat(8) + '<i class="cur"></i></div></div><span class="num bold" style="width:44px;text-align:center;color:var(--primary-text)">9/9</span></div>' +
    '<div class="pad" style="padding-top:20px"><h1 class="h-lg">Ton profil est prêt.<br>Crée ton compte.</h1><p class="muted mt-8 small">Pour sauvegarder tes réponses et calculer ton plan.</p>' +
    '<div class="mt-20">' + input("gift", "Code d'invitation (facultatif)", { value: "AWA2026", state: "ok", right: '<span class="tag">' + I("check") + " 7 jours offerts</span>", help: "<span>À saisir avant de choisir un mode de connexion.</span><span>7/10</span>", helpCls: "ok" }) + "</div>" +
    '<div class="stack mt-16" style="--gap:10px"><button class="btn social">' + window.brandIcons.google + " Continuer avec Google</button>" +
    '<button class="btn social">' + window.brandIcons.apple + " Continuer avec Apple</button></div>" +
    '<div class="row mt-16 faint xs"><hr class="grow" style="border:0;height:1px;background:var(--line)">ou avec ton email<hr class="grow" style="border:0;height:1px;background:var(--line)"></div>' +
    '<div class="stack mt-16" style="--gap:10px">' + input("mail", "Adresse email", { value: "franck@exemple.com" }) +
    input("lock", "Mot de passe", { state: "focus", value: "••••••••", right: I("eye") }) +
    '<div class="card sunk tight xs stack" style="--gap:6px">' + [["10 caractères minimum", 0], ["Une minuscule et une majuscule", 1], ["Un chiffre", 1], ["Un caractère spécial", 0]].map((r) => '<div class="row" style="gap:8px;color:' + (r[1] ? "var(--primary-text)" : "var(--text-3)") + '">' + I(r[1] ? "check" : "minus") + r[0] + "</div>").join("") + "</div>" +
    '</div><div class="stack mt-20" style="--gap:12px">' +
    [["J'accepte les <a class='link'>CGU</a> et la <a class='link'>politique de confidentialité</a>", 1, "Obligatoire"], ["J'accepte que Omeo traite mes données de santé (poids, repas, activité) pour calculer mon suivi", 1, "Obligatoire"], ["Je veux recevoir les nouveautés et offres d'Omeo", 0, "Facultatif"]]
      .map((c) => '<div class="row" style="align-items:flex-start"><span class="check' + (c[1] ? " on" : "") + '">' + (c[1] ? I("check") : "") + '</span><span class="small grow">' + c[0] + ' <span class="faint xs">· ' + c[2] + "</span></span></div>").join("") +
    '</div><button class="btn black mt-24">Créer mon compte</button></div></div>');

  S("onboarding", "ONB-14", "Code d'invitation invalide", "Erreur claire et non bloquante : on peut s'inscrire sans code.",
    '<div class="scroll no-nav"><div class="row" style="padding:6px 16px 0">' + iconBtn("arrowL", "Étape précédente", "ghost") + '<div class="grow"><div class="steps-bar">' + '<i class="on"></i>'.repeat(8) + '<i class="cur"></i></div></div><span class="num bold" style="width:44px;text-align:center;color:var(--primary-text)">9/9</span></div>' +
    '<div class="pad" style="padding-top:20px"><h1 class="h-lg">Ton profil est prêt.<br>Crée ton compte.</h1><div class="mt-20">' +
    input("gift", "", { value: "AWA20", state: "error", right: I("x"), help: "<span>Ce code n'existe pas ou a expiré. Tu peux continuer sans : ton essai sera de 3 jours.</span><span>5/10</span>", helpCls: "err" }) + "</div>" +
    '<div class="stack mt-16" style="--gap:10px"><button class="btn social">' + window.brandIcons.google + " Continuer avec Google</button><button class=\"btn social\">" + window.brandIcons.apple + " Continuer avec Apple</button></div></div></div>");

  S("onboarding", "ONB-15", "Calcul du plan", "Attente pendant que l'API calcule les objectifs. Étapes visibles pour rendre l'attente utile.",
    '<div class="scroll no-nav"><div class="pad center" style="padding-top:150px">' + ring(150, 10, 0.68, "var(--primary)", '<span class="num" style="font-size:34px;font-weight:600">68%</span>') +
    '<h1 class="h-lg mt-32">On prépare ton plan…</h1><div class="stack mt-24" style="--gap:12px;text-align:start;display:inline-block">' +
    [["Métabolisme de base calculé", 1], ["Objectif calorique ajusté", 1], ["Répartition des macros", 0], ["Plats de ta région", 0]].map((x) => '<div class="row small" style="color:' + (x[1] ? "var(--text)" : "var(--text-3)") + '"><span class="check' + (x[1] ? " on" : "") + '" style="width:22px;height:22px;border-radius:50%">' + (x[1] ? I("check") : "") + "</span>" + x[0] + "</div>").join("") + "</div></div></div>");

  S("onboarding", "ONB-16", "Ton plan est prêt", "Résumé des objectifs calculés par l'API, avec durée de l'essai. Rassurant et concret avant l'accueil.",
    '<div class="scroll no-nav"><div class="pad" style="padding-top:28px"><span class="tag">' + I("sparkles") + ' Essai Omeo Plus · 7 jours</span><h1 class="h-xl mt-16">Franck, voici<br>ton plan quotidien</h1>' +
    '<div class="card black mt-24 center" style="padding:26px"><p class="eyebrow" style="color:inherit;opacity:.6">Objectif calorique</p><div class="num mt-8" style="font-size:52px;font-weight:600">2 340<span style="font-size:18px;opacity:.6"> kcal</span></div><p class="small" style="opacity:.7">Pour perdre ~0,5 kg par semaine</p></div>' +
    '<div class="grid3 mt-12">' + [["Protéines", "128 g", "var(--prot)"], ["Glucides", "270 g", "var(--carb)"], ["Lipides", "72 g", "var(--fat)"]].map((m) => '<div class="stat center"><span style="display:block;width:8px;height:8px;border-radius:50%;background:' + m[2] + ';margin:0 auto 8px"></span><div class="v" style="font-size:19px">' + m[1] + '</div><div class="l">' + m[0] + "</div></div>").join("") + "</div>" +
    '<div class="list mt-12">' + [["drop", "Eau", "2,6 L par jour"], ["footprints", "Pas", "8 000 par jour"], ["flag", "Poids cible", "74 kg · vers fin mars"]].map((x) => '<div class="li" style="min-height:56px"><span class="badge-ico sm">' + I(x[0]) + '</span><div class="grow"><b>' + x[1] + '</b></div><span class="bold small">' + x[2] + "</span></div>").join("") + "</div>" +
    '<p class="xs faint mt-12 center">Repères indicatifs, pas un avis médical. Ils s\'ajustent à chaque pesée.</p></div></div>' +
    '<div class="bottom-cta"><button class="btn black">C\'est parti</button></div>');

  // ---------- Compte ----------
  S("compte", "ACC-01", "Connexion", "Google / Apple en premier, puis email. Lien vers mot de passe oublié bien visible.",
    '<div class="scroll no-nav">' + topbar("", "", "") + '<div class="pad">' + window.logo(40) + '<h1 class="h-xl mt-24">Content de te revoir</h1><p class="muted mt-8">Connecte-toi pour retrouver ton suivi.</p>' +
    '<div class="stack mt-24" style="--gap:10px"><button class="btn social">' + window.brandIcons.google + " Continuer avec Google</button><button class=\"btn social\">" + window.brandIcons.apple + " Continuer avec Apple</button></div>" +
    '<div class="row mt-20 faint xs"><hr class="grow" style="border:0;height:1px;background:var(--line)">ou<hr class="grow" style="border:0;height:1px;background:var(--line)"></div>' +
    '<div class="stack mt-20" style="--gap:10px">' + input("mail", "Adresse email", { value: "franck@exemple.com" }) + input("lock", "Mot de passe", { value: "••••••••••••", right: I("eye") }) +
    '</div><div style="text-align:end" class="mt-12"><a class="link small">Mot de passe oublié ?</a></div><button class="btn black mt-24">Se connecter</button>' +
    '<p class="center small muted mt-20">Pas encore de compte ? <a class="link">Commencer</a></p></div></div>');

  S("compte", "ACC-02", "Connexion · erreur", "Message d'erreur générique (ne révèle pas si l'email existe), champs conservés.",
    '<div class="scroll no-nav">' + topbar("", "", "") + '<div class="pad"><h1 class="h-xl">Content de te revoir</h1>' +
    '<div class="banner danger mt-24">' + I("alert") + "<span>Email ou mot de passe incorrect. Vérifie ta saisie ou réinitialise ton mot de passe.</span></div>" +
    '<div class="stack mt-16" style="--gap:10px">' + input("mail", "", { value: "franck@exemple.com", state: "error" }) + input("lock", "", { value: "••••••••", state: "error", right: I("eye") }) +
    '</div><div style="text-align:end" class="mt-12"><a class="link small">Mot de passe oublié ?</a></div><button class="btn black mt-24">Se connecter</button></div></div>');

  S("compte", "ACC-03", "Mot de passe oublié", "Un seul champ. L'email du dernier compte est prérempli quand il est connu.",
    '<div class="scroll no-nav">' + topbar("", "", "") + '<div class="pad"><span class="badge-ico lg round">' + I("key") + '</span><h1 class="h-xl mt-20">Mot de passe oublié ?</h1><p class="muted mt-8">Indique ton email : on t\'envoie un lien pour en choisir un nouveau.</p>' +
    '<div class="mt-24">' + input("mail", "Adresse email", { state: "focus", value: "franck@exemple.com" }) + "</div></div></div>" +
    '<div class="bottom-cta"><button class="btn black">Envoyer le lien</button></div>');

  S("compte", "ACC-04", "Lien envoyé", "Confirmation + ouverture directe de l'app mail + renvoi possible après délai.",
    '<div class="scroll no-nav"><div class="pad center" style="padding-top:150px"><span class="badge-ico lg round" style="margin:auto;width:84px;height:84px">' + I("mail") + '</span><h1 class="h-lg mt-24">Vérifie ta boîte mail</h1>' +
    '<p class="muted mt-8">Si un compte existe pour <b style="color:var(--text)">franck@exemple.com</b>, tu vas recevoir un lien valable 1 heure.</p></div></div>' +
    '<div class="bottom-cta"><button class="btn black">Ouvrir ma messagerie</button><button class="btn ghost mt-8" disabled>Renvoyer dans 0:42</button></div>');

  S("compte", "ACC-05", "Nouveau mot de passe", "Ouvert depuis le lien reçu. Règles vérifiées en direct.",
    '<div class="scroll no-nav">' + topbar("Nouveau mot de passe", "", "", { close: true }) + '<div class="pad stack" style="--gap:12px;padding-top:12px">' +
    input("lock", "Nouveau mot de passe", { value: "••••••••••••", state: "ok", right: I("eye") }) + input("shieldCheck", "Confirmer", { value: "••••••••••••", state: "ok" }) +
    '<div class="card sunk tight xs stack" style="--gap:6px">' + ["10 caractères minimum", "Une minuscule et une majuscule", "Un chiffre", "Un caractère spécial"].map((r) => '<div class="row" style="gap:8px;color:var(--primary-text)">' + I("check") + r + "</div>").join("") + "</div>" +
    '<div class="row"><span class="check on">' + I("check") + '</span><span class="small">Me déconnecter de tous les autres appareils</span></div></div></div>' +
    '<div class="bottom-cta"><button class="btn black">Enregistrer</button></div>');

  S("compte", "ACC-06", "Vérifier son email", "L'app reste utilisable : rappel discret en haut de l'accueil, avec renvoi en un geste.",
    '<div class="scroll">' + window.M.appbar() + '<div class="pad"><div class="banner info">' + I("mail") + '<span class="grow">Confirme ton email pour sécuriser ton compte et valider ton parrainage.<br><a class="link">Renvoyer l\'email</a> · <a class="link">Modifier</a></span>' + I("x") + "</div>" +
    '<p class="eyebrow mt-24">Bonjour,</p><h1 class="h-lg mt-4">Franck</h1></div><div class="mt-16">' + window.M.days(6, { dots: [] }) + "</div>" +
    '<div class="pad mt-16"><div class="card"><div class="skeleton" style="height:150px"></div></div></div></div>', { nav: "home" });
})();

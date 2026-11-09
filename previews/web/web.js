/* En-tête, pied de page et bandeau cookies communs à toutes les pages du site. */
(function () {
  const I = window.icon, B = window.brandIcons;
  const here = location.pathname.split("/").pop() || "index.html";
  const link = (href, t) => '<a href="' + href + '" class="' + (here === href ? "on" : "") + '">' + t + "</a>";

  const header = '<header class="nav" id="nav"><div class="wrap"><a href="index.html" aria-label="Nyam, accueil">' + window.logo(34) + '</a><nav class="links hide-m" aria-label="Navigation principale">' +
    link("fonctionnalites.html", "Fonctionnalités") + link("tarifs.html", "Tarifs") + link("faq.html", "FAQ") + link("contact.html", "Contact") + '</nav><span class="grow"></span>' +
    '<button class="lang" aria-label="Langue : français">' + I("globe") + ' FR</button><a class="btn sm hide-m" href="abonnement.html">Mon abonnement</a><a class="btn sm green" href="index.html#telecharger">Télécharger</a></div></header>';

  const footer = '<footer class="foot"><div class="wrap"><div class="grid" style="grid-template-columns:1.6fr 1fr 1fr 1fr;gap:40px">' +
    '<div>' + window.logo(36) + '<p class="mt16" style="max-width:300px;font-size:15px">Scanne. Comprends. Mange mieux. Le suivi nutritionnel pensé pour les plats d\'Afrique, puis du monde.</p><div class="row mt24 wrapf">' +
    '<a class="store" style="background:#2b2a26" href="#">' + B.play + '<span><small>Disponible sur</small><b>Google Play</b></span></a><a class="store" style="background:#2b2a26" href="#">' + B.apple + '<span><small>Télécharger dans</small><b>l\'App Store</b></span></a></div></div>' +
    '<div><h4>Produit</h4><ul><li><a href="fonctionnalites.html">Fonctionnalités</a></li><li><a href="tarifs.html">Tarifs</a></li><li><a href="abonnement.html">Mon abonnement</a></li><li><a href="faq.html">FAQ</a></li></ul></div>' +
    '<div><h4>Aide</h4><ul><li><a href="contact.html">Contact</a></li><li><a href="suppression-compte.html">Supprimer mon compte</a></li><li><a href="invitation.html">Invitation</a></li></ul></div>' +
    '<div><h4>Légal</h4><ul><li><a href="legal.html">CGU</a></li><li><a href="legal.html#confidentialite">Confidentialité</a></li><li><a href="legal.html#cookies">Cookies</a></li><li><a href="legal.html#mentions">Mentions légales</a></li></ul></div></div>' +
    '<div class="bottom"><span>© 2026 Nyam</span><span class="grow"></span><span>Français · English · Español · Português · العربية · 简体中文 · 日本語 · Deutsch</span></div>' +
    '<p class="xs mt16" style="opacity:.6">Nyam fournit des repères nutritionnels informatifs. L\'application ne remplace pas un avis médical.</p></div></footer>';

  const cookie = '<div class="cookie" role="dialog" aria-label="Cookies"><b style="font:600 17px var(--font-display)">Un cookie ?</b><p class="small muted mt8">On mesure l\'audience de façon anonyme et respectueuse de la vie privée. Rien n\'est déposé sans ton accord.</p><div class="row mt16"><button class="btn sm ghost">Refuser</button><button class="btn sm">Accepter</button></div><a class="xs faint" href="legal.html#cookies" style="display:inline-block;margin-top:10px">Personnaliser</a></div>';

  document.body.insertAdjacentHTML("afterbegin", header);
  document.body.insertAdjacentHTML("beforeend", footer + (document.body.dataset.cookie ? cookie : ""));
  addEventListener("scroll", () => document.getElementById("nav").classList.toggle("scrolled", scrollY > 8));
  document.querySelectorAll("[data-i]").forEach((el) => (el.innerHTML = I(el.dataset.i) + el.innerHTML));
})();

window.qr = function () {
  let s = "";
  for (let i = 0; i < 121; i++) {
    const x = i % 11, y = Math.floor(i / 11);
    const corner = (x < 3 && y < 3) || (x > 7 && y < 3) || (x < 3 && y > 7);
    s += "<i" + (corner ? "" : (x * 7 + y * 3 + x * y) % 3 === 0 ? ' class="o"' : "") + "></i>";
  }
  return '<div class="qr" aria-label="QR code de téléchargement">' + s + "</div>";
};

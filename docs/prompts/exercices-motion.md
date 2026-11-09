# Prompt : animations d'exercices (motion design)

> Coller d'abord le [socle commun](README.md#socle-commun-à-coller-en-tête-de-chaque-prompt).

```text
LIVRABLE : la chaîne de production des animations d'exercices d'Omeo, dans tools/motion/, ainsi que
le premier set de 18 exercices animés. Ce livrable répond à la question ouverte n° 7 de
docs/produit/99-decisions.md (« Production des vidéos d'exercices »).

PRINCIPE : on ne tourne pas de vidéos finales. On filme un geste réel, on en extrait le squelette
(pose estimation), on nettoie le mouvement, puis on le redessine dans le style Omeo.
Une même source (le fichier de pose) produit :
1. l'animation jouée en direct dans l'app : vectorielle, nette à toutes les tailles, légère ;
2. la vidéo HLS et la vignette attendues par le modèle Exercise : fallback, web, admin, partage.

DIRECTION ARTISTIQUE (identique au logo « la bouchée », voir docs/brand/) :
- Monochrome : personnage plein en encre (#111 en clair, #fff en sombre), sans visage, tête ronde,
  membres en capsules arrondies d'épaisseur constante, articulations invisibles.
- Un seul accent facultatif : les muscles travaillés, en surbrillance grise à 30 %, désactivable.
- Le sol est un trait fin. Pas de décor, pas d'ombre portée, pas de texte incrusté.
- Caméra fixe. Profil strict ou 3/4 selon l'exercice (voir le set), cadrage identique pour tous.
- Boucle parfaite : la dernière image rejoint la première sans saut. Durée de 2 à 4 s par répétition,
  au tempo indiqué.
- Les couleurs viennent des tokens (shared/tokens). Rien en dur dans le rendu de l'app.

OUTILS :
- Capture : vidéo au téléphone, 1080p, 60 fps, trépied, fond uni, corps entier dans le champ,
  vêtements près du corps. Trois répétitions par exercice : on garde la plus propre.
- Extraction : Python 3.12, MediaPipe Pose Landmarker (modèle « heavy », mode VIDEO, 33 points en
  coordonnées monde), OpenCV pour la lecture vidéo.
- Nettoyage : filtre One Euro (lissage sans latence), découpe d'une répétition, recalage de la boucle
  (fondu des 6 dernières images vers la première), normalisation (bassin centré, pieds au sol,
  taille de squelette fixe), symétrisation optionnelle pour les exercices bilatéraux.
- Réduction : on ne garde que les 17 points utiles (tête, épaules, coudes, poignets, hanches,
  genoux, chevilles, pointes de pied), en 2D dans le plan de la caméra, à 30 images/s.
- Rendu hors app : script Python qui dessine les images avec skia-python (même géométrie que le
  rendu Flutter), puis ffmpeg pour encoder en HLS (H.264, 720p et 360p) et produire la vignette WebP.
- Rendu dans l'app : un CustomPainter Flutter qui lit le fichier de pose et interpole entre les
  images. Le rendu web et admin lit le même fichier en Canvas 2D, dans un petit module TypeScript
  partagé.
- Dépendances figées (requirements.txt avec versions exactes), tout lancé par un Makefile ou un
  script unique. Aucun service en ligne : tout tourne en local.

FORMAT DU FICHIER DE POSE (omeo-pose v1, JSON, < 60 Ko par exercice) :
{
  "version": 1,
  "slug": "squat",
  "fps": 30,
  "view": "side" | "three_quarter",
  "loop": true,
  "joints": ["head", "l_shoulder", ...],   // ordre fixe, 17 entrées
  "frames": [[x0, y0, x1, y1, ...], ...],  // coordonnées normalisées 0..1, 4 décimales
  "muscles": ["quadriceps", "glutes"],     // pour la surbrillance
  "rep_marker": 0.5                        // position dans la boucle où la répétition « compte »
}
Le schéma JSON est écrit dans tools/motion/schema/pose.schema.json. Chaque fichier produit est
validé contre ce schéma en CI.

ARBORESCENCE :
tools/motion/
  README.md            capture (checklist de tournage), pipeline, ajout d'un exercice
  exercises.yaml       le set : métadonnées de chaque exercice (voir plus bas)
  capture/             vidéos sources (ignorées par git, conservées dans le stockage S3 privé)
  pipeline/            extract.py, clean.py, loop.py, render.py, encode.py (fonctions pures, testées)
  out/<slug>/          pose.json, preview.webp, hls/ (ignoré par git, publié via l'admin)
  schema/pose.schema.json
  tests/
mobile/lib/core/widgets/exercise_animation/   le widget Flutter (painter, contrôleur, golden tests)
shared/motion/                                le lecteur Canvas TypeScript pour le web et l'admin

LECTEUR (mobile, puis web et admin) :
- Lecture, pause, vitesse (0,5×, 1×), boucle infinie, vue en miroir.
- Synchronisation avec le minuteur de séance : en mode « reps », l'événement rep_marker fait avancer
  le compteur affiché (le compte officiel reste celui de l'API).
- Respecte les mouvements réduits : affiche l'image clé du milieu du mouvement, avec un bouton pour
  lancer l'animation.
- Libellé accessible : nom de l'exercice et consigne courte.
- 60 fps sur un appareil d'entrée de gamme (vérifié avec le profiler Flutter). Aucune allocation par
  image dans le painter.

CONTRAT ET DONNÉES (règle 3 du socle) :
- Le modèle Exercise a déjà video, thumbnail, muscles, level, equipment, met et is_free.
- Il manque le fichier de pose. Écris dans contracts/CHANGES.md la proposition d'un champ
  `animation` (URL signée vers pose.json, nullable) sur Exercise, côté public et côté admin, ainsi
  que l'upload correspondant dans l'admin. N'applique rien avant validation.
- En attendant, le mobile charge les fichiers de pose du set depuis ses fixtures mock.

PREMIER SET : 18 EXERCICES, tous sans matériel (sauf une chaise ou un mur), adaptés à un salon.
Remplis tools/motion/exercises.yaml avec ces données. Noms et consignes en fr ici, traduits ensuite
dans l'admin. Les valeurs MET viennent du Compendium of Physical Activities : fais-les valider par
l'API (activity/met.py), ne les recopie pas côté client.

| #  | slug                 | Nom                        | Vue    | Niveau        | Muscles                          | MET | Tempo        | Gratuit |
|----|----------------------|----------------------------|--------|---------------|----------------------------------|-----|--------------|---------|
| 1  | jumping-jacks        | Jumping jacks              | face   | débutant      | corps entier, mollets            | 8.0 | 1 s / rép.   | oui     |
| 2  | marche-sur-place     | Montées de genoux lentes   | profil | débutant      | quadriceps, abdominaux           | 4.0 | 1,2 s        | oui     |
| 3  | squat                | Squat                      | 3/4    | débutant      | quadriceps, fessiers             | 5.0 | 3 s (2-0-1)  | oui     |
| 4  | fentes-alternees     | Fentes alternées           | profil | débutant      | quadriceps, fessiers             | 4.0 | 3 s          | oui     |
| 5  | pompes-inclinees     | Pompes inclinées (chaise)  | profil | débutant      | pectoraux, triceps               | 3.8 | 3 s          | oui     |
| 6  | gainage              | Gainage (planche)          | profil | débutant      | abdominaux, dos                  | 3.8 | statique, respiration 4 s | oui |
| 7  | pont-fessier         | Pont fessier               | profil | débutant      | fessiers, ischios                | 3.5 | 3 s          | oui     |
| 8  | rotations-bras       | Cercles de bras            | face   | débutant      | épaules (échauffement)           | 2.8 | 2 s          | oui     |
| 9  | chaise-murale        | Chaise au mur              | profil | débutant      | quadriceps                       | 4.0 | statique     | non     |
| 10 | superman             | Superman                   | profil | débutant      | dos, fessiers                    | 3.5 | 3 s          | non     |
| 11 | crunch               | Crunch                     | profil | débutant      | abdominaux                       | 3.8 | 2 s          | non     |
| 12 | pompes               | Pompes                     | profil | intermédiaire | pectoraux, triceps, gainage      | 8.0 | 2,5 s        | non     |
| 13 | mountain-climbers    | Mountain climbers          | profil | intermédiaire | abdominaux, épaules, cardio      | 8.0 | 0,8 s        | non     |
| 14 | dips-chaise          | Dips sur chaise            | profil | intermédiaire | triceps                          | 3.8 | 2,5 s        | non     |
| 15 | gainage-lateral      | Gainage latéral            | face   | intermédiaire | obliques                         | 3.8 | statique     | non     |
| 16 | squat-saute          | Squat sauté                | 3/4    | intermédiaire | quadriceps, fessiers, cardio     | 8.0 | 1,5 s        | non     |
| 17 | talons-fesses        | Talons-fesses              | profil | intermédiaire | ischios, cardio                  | 8.0 | 0,6 s        | non     |
| 18 | burpees              | Burpees                    | profil | avancé        | corps entier                     | 8.0 | 3 s          | non     |

Pour chaque exercice, exercises.yaml contient aussi :
- 3 consignes courtes (placement, mouvement, respiration) et 2 erreurs fréquentes ;
- une variante plus facile et une plus difficile (slug, même si elle n'est pas encore animée) ;
- pour les exercices unilatéraux (fentes, gainage latéral), un paramètre `mirror: true`.
  On ne filme qu'un côté, le lecteur alterne.
Les 8 exercices gratuits correspondent à la « sélection » de l'offre Free (02-offres-quotas.md).

SÉANCES DE DÉMONSTRATION (fixtures mock et données de seed de l'API) :
- « Réveil mobilité » : 10 min, débutant, mobilité (8, 2, 3, 7, 10, 6).
- « Renfo du soir » : 15 min, débutant, renforcement (3, 5, 4, 7, 11, 6, 9).
- « Cardio express » : 12 min, intermédiaire, cardio (1, 13, 16, 17, 12, 18).
Ces noms reprennent ceux des maquettes de previews/.

ORDRE DE TRAVAIL :
1. Pipeline sur une vidéo de test libre de droits (ou filmée par toi), avec le squat comme pilote.
   Livrable : pose.json valide, rendu PNG des images clés, tests des fonctions de nettoyage.
2. Widget Flutter et golden tests, sur le squat.
3. Rendu hors app (HLS et vignette) et checklist de tournage dans tools/motion/README.md.
4. Proposition de contrat dans contracts/CHANGES.md.
5. Les 17 autres exercices : je fournis les vidéos sources en suivant la checklist.
   Tant qu'une vidéo manque, l'exercice est marqué `pending` dans exercises.yaml et n'est pas publié.
6. Lecteur TypeScript pour le web et l'admin.
Un commit par étape réussie.

CRITÈRES D'ACCEPTATION :
- Les 18 fichiers de pose sont valides, font moins de 60 Ko chacun et bouclent sans saut visible
  (écart entre la première et la dernière image < 0,5 % de la hauteur du squelette).
- Aucun tremblement visible : la vitesse angulaire des articulations est bornée, et c'est testé.
- Le rendu Flutter et le rendu skia sont identiques à ±1 px sur les images clés (golden partagées).
- Lisible à 48 px (vignette de liste) comme en plein écran.
- Thème clair et sombre, de droite à gauche (le personnage ne se retourne pas), mouvements réduits.
- Aucune vidéo source ni donnée biométrique de la personne filmée dans git.
```

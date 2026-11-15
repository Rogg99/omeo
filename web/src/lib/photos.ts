import type { StaticImageData } from "next/image";

import alloco from "../../public/images/alloco.jpg";
import baobab from "../../public/images/baobab.jpg";
import bissap from "../../public/images/bissap.jpg";
import fonio from "../../public/images/fonio.jpg";
import gombo from "../../public/images/gombo.jpg";
import moringa from "../../public/images/moringa.jpg";
import ndole from "../../public/images/ndole.jpg";
import poisson from "../../public/images/poisson.jpg";
import sport from "../../public/images/sport.jpg";
import sport2 from "../../public/images/sport2.jpg";
import thieb from "../../public/images/thieb.jpg";
import yassa from "../../public/images/yassa.jpg";

/** Photos du site (Wikimedia Commons), avec leur crédit : affichées sur la page Crédits photos. */
export type Photo = { image: StaticImageData; title: string; source: string; author: string; license: string };

export const PHOTOS = {
  ndole: { image: ndole, title: "Ndolé camerounais", source: "https://commons.wikimedia.org/wiki/File:Ndol%C3%A9_camerounais.JPG", author: "PRA", license: "CC BY 3.0" },
  thieb: { image: thieb, title: "Ceebu jen, Senegalese cuisine", source: "https://commons.wikimedia.org/wiki/File:Ceebu_jen,_Senegalese_cuisine.JPG", author: "Alweaver2", license: "CC BY-SA 4.0" },
  alloco: { image: alloco, title: "Aloko", source: "https://commons.wikimedia.org/wiki/File:Aloko.jpg", author: "Krista", license: "CC BY 2.0" },
  baobab: {
    image: baobab,
    title: "Baobab fruit, mature, split detail with dry pulp",
    source: "https://commons.wikimedia.org/wiki/File:Baobab_fruit,_mature,_split_detail_with_dry_pulp_-_Adansonia_digitata.jpg",
    author: "T.K. Naliaka",
    license: "CC BY-SA 4.0",
  },
  bissap: { image: bissap, title: "Sobolo", source: "https://commons.wikimedia.org/wiki/File:Sobolo.jpg", author: "Noahalorwu", license: "CC BY-SA 4.0" },
  moringa: { image: moringa, title: "Moringa leaves and flowers", source: "https://commons.wikimedia.org/wiki/File:Moringa_leaves_and_flowers.jpg", author: "Haseena13", license: "CC0" },
  yassa: { image: yassa, title: "Poulet yassa", source: "https://commons.wikimedia.org/wiki/File:Poulet_yassa_01.jpg", author: "Arnaud 25", license: "CC0" },
  fonio: {
    image: fonio,
    title: "Plat de fonio décoré avec des fromages",
    source: "https://commons.wikimedia.org/wiki/File:Plat_de_fonio_d%C3%A9cor%C3%A9_avec_des_fromages_02.jpg",
    author: "Fadila2",
    license: "CC BY-SA 4.0",
  },
  gombo: { image: gombo, title: "Sauce gombo aux crabes avec poisson", source: "https://commons.wikimedia.org/wiki/File:Sauce_gombo_aux_crabes_avec_poisson.jpg", author: "Estrella230", license: "CC BY 4.0" },
  poisson: {
    image: poisson,
    title: "Poisson braisé, accompagné d’aloco",
    source: "https://commons.wikimedia.org/wiki/File:Poisson_brais%C3%A9,_accompagn%C3%A9_d%E2%80%99aloco.jpg",
    author: "Ourytima",
    license: "CC BY-SA 4.0",
  },
  sport: {
    image: sport,
    title: "Woman performing strength training exercises in a fitness center",
    source: "https://commons.wikimedia.org/wiki/File:Woman_performing_strength_training_exercises_in_a_fitness_center.jpg",
    author: "Shixart1985",
    license: "CC BY 2.0",
  },
  sport2: {
    image: sport2,
    title: "Woman exercising with resistance band in a gym setting",
    source: "https://commons.wikimedia.org/wiki/File:Woman_exercising_with_resistance_band_in_a_gym_setting.jpg",
    author: "Shixart1985",
    license: "CC BY 2.0",
  },
} satisfies Record<string, Photo>;

export type PhotoName = keyof typeof PHOTOS;

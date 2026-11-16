import type { Applied, BodyOf, Locale, Page, QueryOf, ResponseOf, Result, Schemas, StaffContext } from "../types";

export type ContentType = Schemas["ContentTypeName"];
export type ContentStatus = Schemas["ContentStatus"];
export type ContentRow = Schemas["AdminContentRow"];
export type ContentItem = Schemas["AdminContentItem"];
export type ContentPayload = Schemas["AdminContentPayload"];
export type ContentQuery = QueryOf<"adminListContent">;
export type Revision = ResponseOf<"adminListRevisions", 200>[number];
export type TransitionInput = BodyOf<"adminTransitionContent">;
export type MachineTranslation = ResponseOf<"adminMachineTranslate", 200>;
export type TranslationCoverage = ResponseOf<"adminTranslationCoverage", 200>;
export type MediaUploadInput = BodyOf<"adminCreateMediaUpload">;
export type UploadTicket = Schemas["UploadTicket"];

export interface ContentRepository {
  list(type: ContentType, query: ContentQuery, ctx: StaffContext): Promise<Result<Page<ContentRow>>>;
  get(type: ContentType, id: string, ctx: StaffContext): Promise<Result<ContentItem>>;
  create(type: ContentType, payload: ContentPayload, ctx: StaffContext): Promise<Result<ContentItem>>;
  /** Verrou optimiste : `payload.version` obligatoire, 409 `conflict` si le contenu a changé entre-temps. */
  update(type: ContentType, id: string, payload: ContentPayload, ctx: StaffContext): Promise<Result<ContentItem>>;
  /** Uniquement un brouillon jamais publié (sinon : archiver). */
  remove(type: ContentType, id: string, ctx: StaffContext): Promise<Result<null>>;
  /** Vers `published` : 202 (validation par une autre personne), sauf `content.publish_own`. */
  transition(
    type: ContentType,
    id: string,
    input: TransitionInput,
    ctx: StaffContext,
  ): Promise<Result<Applied<ContentItem>>>;
  revisions(type: ContentType, id: string, ctx: StaffContext): Promise<Result<Revision[]>>;
  /** Traduction IA des champs manquants, à relire avant d'être enregistrée. */
  translate(type: ContentType, id: string, locales: Locale[], ctx: StaffContext): Promise<Result<MachineTranslation>>;
  coverage(ctx: StaffContext): Promise<Result<TranslationCoverage>>;
  /** URL présignée de téléversement direct (image, vidéo, sous-titres VTT). */
  createUpload(input: MediaUploadInput, ctx: StaffContext): Promise<Result<UploadTicket>>;
}

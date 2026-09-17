/**
 * O documento de `workspaces/{wid}/financial_coaching/{id}` — os slides que o
 * app mostra como "insight do Coach".
 *
 * Escrito EXCLUSIVAMENTE pelo servidor (`CoachingService`, via Admin SDK) e
 * lido pelo app. Até F1.11 ele atravessava o backend como `any`: o repositório
 * recebia e devolvia "qualquer coisa", de modo que um campo renomeado no
 * validador chegava ao Firestore sem que nada reclamasse, e o app só descobria
 * o sumiço na tela.
 *
 * O modelo mora na feature `coaching` (é dela a regra), mas a persistência vive
 * em `IFinanceRepository`, que já era dona da coleção antes deste pacote.
 */

/** Tom do insight. O app escolhe o ícone e a cor do cabeçalho a partir dele. */
export const COACHING_TYPES = ["insight", "warning", "tip"] as const;
export type CoachingType = typeof COACHING_TYPES[number];

export const DEFAULT_COACHING_TYPE: CoachingType = "insight";

/** Título do insight quando a IA não mandou um. */
export const DEFAULT_COACHING_MESSAGE = "Insights do seu Coach Financeiro";

export function isCoachingType(value: unknown): value is CoachingType {
    return typeof value === "string" && (COACHING_TYPES as readonly string[]).includes(value);
}

/** Animação de entrada do slide, entre as que o app sabe desenhar. */
export const COACHING_ANIMATION_TYPES = ["zoom", "slide", "bounce", "fade", "pulse"] as const;
export type CoachingAnimationType = typeof COACHING_ANIMATION_TYPES[number];

export const DEFAULT_COACHING_ANIMATION: CoachingAnimationType = "fade";

export function isCoachingAnimationType(value: unknown): value is CoachingAnimationType {
    return typeof value === "string" && (COACHING_ANIMATION_TYPES as readonly string[]).includes(value);
}

/**
 * Um slide do carrossel.
 *
 * `actionPath` e `actionLabel` andam JUNTOS e são os únicos campos realmente
 * opcionais: sem uma rota que sobreviva à allowlist (`sanitizeActionPath`) o
 * slide vai sem botão, e um rótulo sem destino não teria o que fazer. Os
 * demais campos têm padrão no validador e chegam sempre preenchidos.
 */
export interface CoachingSlide {
    title: string;
    message: string;
    icon: string;
    /** `#RRGGBB`. */
    color: string;
    /** `#RRGGBB`. Só quando a IA mandou um segundo tom válido. */
    secondaryColor?: string;
    /** Ícones decorativos do fundo. Lista vazia é o caso comum. */
    icons: string[];
    animationType: CoachingAnimationType;
    /** Rota interna já validada contra a allowlist. Ausente = slide sem botão. */
    actionPath?: string;
    /** Rótulo do botão. Só existe junto de `actionPath`. */
    actionLabel?: string;
}

/** O payload que o validador server-side entrega — e que vai para o documento. */
export interface CoachingAnalysisPayload {
    message: string;
    summary: string;
    type: CoachingType;
    slides: CoachingSlide[];
}

/**
 * O que é GRAVADO. `date` é o instante da geração (o repositório o converte em
 * `Timestamp`); `generatedBy` marca que o texto veio do servidor, e não de uma
 * escrita antiga do cliente.
 */
export interface CoachingAnalysisWrite extends CoachingAnalysisPayload {
    date: Date;
    generatedBy: "server";
}

/**
 * O que é LIDO. `id` vem do documento e `date` pode ser `null` num documento
 * legado gravado pelo cliente sem o campo.
 */
export interface CoachingAnalysisDocument extends CoachingAnalysisPayload {
    id: string;
    date: Date | null;
    generatedBy?: string;
}

/** A resposta da callable `generateCoaching` — o contrato com o app. */
export interface CoachingResponse extends CoachingAnalysisPayload {
    id: string;
    /** ISO-8601. */
    date: string;
}

/** Converte um valor cru de data (Timestamp, Date ou ISO) em `Date`. */
function toDateOrNull(value: unknown): Date | null {
    if (!value) return null;
    if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
    const timestamp = value as { toDate?: () => Date };
    if (typeof timestamp.toDate === "function") return timestamp.toDate();
    if (typeof value === "string") {
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }
    return null;
}

/**
 * Documento cru -> `CoachingAnalysisDocument`.
 *
 * A normalização acontece AQUI, na entrada, e não espalhada pelo serviço: um
 * insight legado gravado pelo cliente (antes de a escrita virar exclusiva do
 * servidor) pode não ter `summary`, `slides` ou `type` válido, e o resto do
 * processo não tem por que saber disso.
 *
 * `summary` cai no `message` quando está vazio — é o mesmo fallback que o
 * `formatResponse` do serviço aplicava.
 */
export function toCoachingAnalysisDocument(
    id: string,
    data: Record<string, unknown> | undefined
): CoachingAnalysisDocument {
    const message = typeof data?.message === "string" && data.message.trim().length > 0
        ? data.message
        : DEFAULT_COACHING_MESSAGE;
    const summary = typeof data?.summary === "string" && data.summary.length > 0
        ? data.summary
        : message;

    return {
        id,
        message,
        summary,
        type: isCoachingType(data?.type) ? data.type : DEFAULT_COACHING_TYPE,
        slides: Array.isArray(data?.slides) ? data.slides as CoachingSlide[] : [],
        date: toDateOrNull(data?.date),
        generatedBy: typeof data?.generatedBy === "string" ? data.generatedBy : undefined,
    };
}

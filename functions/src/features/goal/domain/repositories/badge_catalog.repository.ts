/**
 * Texto do catálogo por locale. A chave é o código de idioma (`pt`, `en`) e
 * `pt` é o fallback: um locale que o servidor não publicou cai nele em vez de
 * aparecer em branco.
 */
export type LocalizedText = Record<string, string>;

/** Documento publicado em `config/badges` e lido pelo app. */
export interface BadgeCatalogDocument {
    /** Muda quando qualquer badge ou limiar muda. Hash do conteúdo. */
    version: string;
    badges: {
        id: string;
        name: LocalizedText;
        icon: string;
        xpReward: number;
        category: string;
        description: LocalizedText;
    }[];
    /**
     * XP mínimo de cada nível, do nível 1 em diante: `levelThresholds[n - 1]`
     * é o XP que abre o nível `n`. Substitui a fórmula duplicada no app.
     */
    levelThresholds: number[];
    /**
     * F2.3 — a tabela "como ganhar XP" que o app exibe.
     *
     * Ela mora no catálogo, e não num documento por workspace, porque é
     * configuração do PRODUTO: os valores são os mesmos para todo mundo e
     * mudam por deploy, não por usuário. Não existe (nem vai existir)
     * `workspaces/{w}.xpSources`.
     */
    xpSources: {
        id: string;
        name: LocalizedText;
        xp: number;
        description: LocalizedText;
    }[];
}

export interface IBadgeCatalogRepository {
    /** Versão publicada hoje, ou `null` se o documento ainda não existe. */
    getPublishedVersion(): Promise<string | null>;
    publish(catalog: BadgeCatalogDocument): Promise<void>;
}

/** Documento publicado em `config/badges` e lido pelo app. */
export interface BadgeCatalogDocument {
    /** Muda quando qualquer badge ou limiar muda. Hash do conteúdo. */
    version: string;
    badges: {
        id: string;
        name: string;
        icon: string;
        xpReward: number;
        category: string;
        description: string;
    }[];
    /**
     * XP mínimo de cada nível, do nível 1 em diante: `levelThresholds[n - 1]`
     * é o XP que abre o nível `n`. Substitui a fórmula duplicada no app.
     */
    levelThresholds: number[];
}

export interface IBadgeCatalogRepository {
    /** Versão publicada hoje, ou `null` se o documento ainda não existe. */
    getPublishedVersion(): Promise<string | null>;
    publish(catalog: BadgeCatalogDocument): Promise<void>;
}

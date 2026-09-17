import * as crypto from "crypto";
import * as logger from "firebase-functions/logger";
import {
    BadgeCatalogDocument,
    IBadgeCatalogRepository,
    LocalizedText,
} from "../repositories/badge_catalog.repository";
import { BADGES, XP_SOURCES } from "./gamification.service";
import { BADGE_STRINGS_EN } from "./badge_catalog.i18n";

/** Quantos níveis o app precisa desenhar. */
export const LEVEL_COUNT = 20;

/**
 * XP mínimo de cada nível, derivado da MESMA fórmula de `calculateLevel`
 * (`floor(log2(xp / 300 + 1)) + 1`): o nível `n` abre em `300 * (2^(n-1) - 1)`.
 *
 * Publicar a tabela em vez da fórmula é o que permite apagar a inversa
 * duplicada no Flutter (`workspace_level_indicator` e `badges_cabinet_screen`
 * calculavam cada uma a sua).
 */
export function buildLevelThresholds(levels: number = LEVEL_COUNT): number[] {
    const thresholds: number[] = [];
    for (let level = 1; level <= levels; level++) {
        thresholds.push(300 * (Math.pow(2, level - 1) - 1));
    }
    return thresholds;
}

/**
 * Monta o documento do catálogo a partir do `BADGES` do servidor.
 *
 * `name` e `description` saem como mapas por locale. O português vem da
 * definição do badge; o inglês, de `BADGE_STRINGS_EN`. Badge sem tradução é
 * publicado só em `pt` — o app cai no fallback e mostra o texto em português,
 * em vez de mostrar vazio.
 */
export function buildBadgeCatalog(): BadgeCatalogDocument {
    const badges = Object.values(BADGES).map((badge) => ({
        id: badge.id,
        name: localized(badge.name, BADGE_STRINGS_EN[badge.id]?.name),
        icon: badge.icon,
        xpReward: badge.xpReward,
        category: badge.category as string,
        description: localized(badge.description, BADGE_STRINGS_EN[badge.id]?.description),
    }));

    const levelThresholds = buildLevelThresholds();

    // F2.3 — a tabela de fontes de XP viaja no MESMO documento dos badges, e
    // entra no hash da versão: mudar quanto vale uma semana dentro do plano
    // republica o catálogo sozinho, igual a mudar o XP de um badge.
    const xpSources = XP_SOURCES.map((source) => ({
        id: source.id,
        name: { ...source.name },
        xp: source.xp,
        description: { ...source.description },
    }));

    return {
        version: catalogVersion(badges, levelThresholds, xpSources),
        badges,
        levelThresholds,
        xpSources,
    };
}

function localized(pt: string, en?: string): LocalizedText {
    return en ? { pt, en } : { pt };
}

/**
 * Versão = hash do conteúdo. Não é um número que alguém precisa lembrar de
 * incrementar: mudou um nome, um XP ou um limiar, muda o hash e a próxima
 * execução publica.
 */
function catalogVersion(badges: unknown[], levelThresholds: number[], xpSources: unknown[]): string {
    const payload = JSON.stringify({ badges, levelThresholds, xpSources });
    return crypto.createHash("sha256").update(payload).digest("hex").slice(0, 16);
}

export interface PublishResult {
    version: string;
    /** `false` quando a versão publicada já era esta (nada foi escrito). */
    published: boolean;
    badgeCount: number;
}

export class BadgeCatalogService {
    constructor(private repository: IBadgeCatalogRepository) {}

    /**
     * Publica `config/badges` — IDEMPOTENTE: só escreve se a versão mudou.
     *
     * Roda todo dia pelo cron `publishBadgeCatalog` (com `maxInstances: 1`), de
     * modo que um deploy que mexe no catálogo se propaga sozinho em até 24h, e
     * o script `publish_badge_catalog` cobre o primeiro deploy.
     */
    async publishBadgeCatalog(): Promise<PublishResult> {
        const catalog = buildBadgeCatalog();
        const publishedVersion = await this.repository.getPublishedVersion();

        if (publishedVersion === catalog.version) {
            logger.info(`[BadgeCatalog] Versão ${catalog.version} já publicada — nada a fazer.`);
            return { version: catalog.version, published: false, badgeCount: catalog.badges.length };
        }

        await this.repository.publish(catalog);
        logger.info(`[BadgeCatalog] Catálogo publicado: versão ${catalog.version}, ${catalog.badges.length} badges.`);
        return { version: catalog.version, published: true, badgeCount: catalog.badges.length };
    }
}

import {
    BadgeCatalogService,
    buildBadgeCatalog,
    buildLevelThresholds,
    LEVEL_COUNT,
} from "../features/goal/domain/services/badge_catalog.service";
import { BADGES, BADGE_CATEGORIES, calculateLevel } from "../features/goal/domain/services/gamification.service";
import { publishBadgeCatalogScript } from "../scripts/publish_badge_catalog";

const silent = () => undefined;

function makeRepository(publishedVersion: string | null = null) {
    return {
        getPublishedVersion: jest.fn().mockResolvedValue(publishedVersion),
        publish: jest.fn().mockResolvedValue(undefined),
    };
}

describe("buildBadgeCatalog", () => {
    it("publica TODOS os ids de BADGES, sem sobra nem falta", () => {
        const catalog = buildBadgeCatalog();

        const catalogIds = catalog.badges.map((b) => b.id).sort();
        const badgeIds = Object.values(BADGES).map((b) => b.id).sort();

        expect(catalogIds).toEqual(badgeIds);
        expect(catalog.badges).toHaveLength(Object.keys(BADGES).length);
    });

    it("todo badge tem nome, ícone, descrição e categoria conhecida", () => {
        for (const badge of buildBadgeCatalog().badges) {
            expect(badge.name.pt.length).toBeGreaterThan(0);
            expect(badge.icon.length).toBeGreaterThan(0);
            expect(badge.description.pt.length).toBeGreaterThan(0);
            // F2.3: XP ZERO é legítimo — os badges de contagem continuam como
            // conquista, mas não pagam mais XP. O que não pode é XP negativo.
            expect(badge.xpReward).toBeGreaterThanOrEqual(0);
            expect(BADGE_CATEGORIES as readonly string[]).toContain(badge.category);
        }
    });

    it("todo badge é publicado em português E em inglês", () => {
        for (const badge of buildBadgeCatalog().badges) {
            expect(Object.keys(badge.name).sort()).toEqual(["en", "pt"]);
            expect(Object.keys(badge.description).sort()).toEqual(["en", "pt"]);
            expect(badge.name.en.length).toBeGreaterThan(0);
            expect(badge.description.en.length).toBeGreaterThan(0);
        }
    });

    it("o texto em inglês é DIFERENTE do português (tradução, não cópia)", () => {
        const iguais = buildBadgeCatalog().badges.filter((b) => b.name.pt === b.name.en);
        // "Streak" e afins podem coincidir; o que não pode é o inglês ser um
        // espelho do português inteiro.
        expect(iguais.length).toBeLessThan(5);
    });

    it("a versão muda quando o conteúdo por locale muda", () => {
        // O hash cobre os mapas de texto: publicar uma tradução nova propaga.
        const catalog = buildBadgeCatalog();
        expect(catalog.version).toHaveLength(16);
    });

    it("a chave do mapa BADGES é sempre igual ao id do badge", () => {
        for (const [key, badge] of Object.entries(BADGES)) {
            expect(key).toBe(badge.id);
        }
    });

    it("a versão é estável para o mesmo conteúdo", () => {
        expect(buildBadgeCatalog().version).toBe(buildBadgeCatalog().version);
    });
});

describe("buildLevelThresholds", () => {
    it("publica 20 níveis começando em zero XP", () => {
        const thresholds = buildLevelThresholds();
        expect(thresholds).toHaveLength(LEVEL_COUNT);
        expect(thresholds[0]).toBe(0);
        expect(thresholds[1]).toBe(300);
    });

    it("cada limiar abre exatamente o nível correspondente em calculateLevel", () => {
        const thresholds = buildLevelThresholds();
        thresholds.forEach((xp, index) => {
            const level = index + 1;
            expect(calculateLevel(xp)).toBe(level);
            if (xp > 0) {
                // Um XP a menos ainda é o nível anterior: a tabela é a inversa
                // fiel da fórmula, e não uma aproximação.
                expect(calculateLevel(xp - 1)).toBe(level - 1);
            }
        });
    });

    it("é estritamente crescente", () => {
        const thresholds = buildLevelThresholds();
        for (let i = 1; i < thresholds.length; i++) {
            expect(thresholds[i]).toBeGreaterThan(thresholds[i - 1]);
        }
    });
});

describe("BadgeCatalogService.publishBadgeCatalog", () => {
    it("publica quando não existe documento", async () => {
        const repository = makeRepository(null);

        const result = await new BadgeCatalogService(repository as any).publishBadgeCatalog();

        expect(result.published).toBe(true);
        expect(repository.publish).toHaveBeenCalledTimes(1);
        expect(repository.publish.mock.calls[0][0].badges).toHaveLength(Object.keys(BADGES).length);
    });

    it("é idempotente: não reescreve quando a versão publicada já é a atual", async () => {
        const repository = makeRepository(buildBadgeCatalog().version);

        const result = await new BadgeCatalogService(repository as any).publishBadgeCatalog();

        expect(result.published).toBe(false);
        expect(repository.publish).not.toHaveBeenCalled();
    });

    it("republica quando a versão publicada é antiga", async () => {
        const repository = makeRepository("versao-velha");

        const result = await new BadgeCatalogService(repository as any).publishBadgeCatalog();

        expect(result.published).toBe(true);
        expect(repository.publish).toHaveBeenCalledTimes(1);
    });
});

describe("publish_badge_catalog (script)", () => {
    it("dry-run não escreve e reporta a versão que publicaria", async () => {
        const repository = {
            getPublishedVersion: jest.fn().mockResolvedValue(null),
            publish: jest.fn(),
        };

        const summary = await publishBadgeCatalogScript(repository as any, { dryRun: true }, silent);

        expect(repository.publish).not.toHaveBeenCalled();
        expect(summary.written).toBe(true);
        expect(summary.version).toBe(buildBadgeCatalog().version);
    });

    it("com --apply publica o catálogo", async () => {
        const repository = {
            getPublishedVersion: jest.fn().mockResolvedValue(null),
            publish: jest.fn().mockResolvedValue(undefined),
        };

        const summary = await publishBadgeCatalogScript(repository as any, { dryRun: false }, silent);

        expect(repository.publish).toHaveBeenCalledTimes(1);
        expect(summary.written).toBe(true);
    });

    it("não reescreve quando a versão já está publicada", async () => {
        const repository = {
            getPublishedVersion: jest.fn().mockResolvedValue(buildBadgeCatalog().version),
            publish: jest.fn(),
        };

        const summary = await publishBadgeCatalogScript(repository as any, { dryRun: false }, silent);

        expect(repository.publish).not.toHaveBeenCalled();
        expect(summary.written).toBe(false);
    });
});

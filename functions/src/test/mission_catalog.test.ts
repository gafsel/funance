/**
 * Catálogo de missões por tipo de workspace: integridade, seleção
 * determinística e montagem do nome.
 */

import {
    AUDIENCE_FORBIDDEN_TERMS,
    MISSION_ACTION_PATHS,
    MISSION_CATALOG,
    MISSION_PROGRESS_RULES,
    WEEKLY_MISSION_TYPES,
    WORKSPACE_AUDIENCES,
    buildMissionName,
    findMissionTemplate,
    hashString,
    missionTemplatesFor,
    normalizeTerm,
    resolveAudience,
    selectMissionTemplate,
} from "../features/goal/domain/models/mission_catalog";
import { ALLOWED_ACTION_PATHS } from "../features/coaching/domain/models/coaching_action_path.model";
import { appliesToAudience } from "../features/goal/domain/models/audience.model";

describe("catálogo de missões — integridade", () => {
    it("cobre os três tipos de missão nas duas audiências", () => {
        for (const audience of WORKSPACE_AUDIENCES) {
            for (const type of WEEKLY_MISSION_TYPES) {
                expect(missionTemplatesFor(audience, type).length).toBeGreaterThan(0);
            }
        }
    });

    it("não tem chave repetida e toda chave é encontrável", () => {
        const keys = MISSION_CATALOG.map((t) => t.key);
        expect(new Set(keys).size).toBe(keys.length);
        for (const key of keys) {
            expect(findMissionTemplate(key)?.key).toBe(key);
        }
        expect(findMissionTemplate("nao_existe")).toBeNull();
        expect(findMissionTemplate(undefined)).toBeNull();
    });

    it("todo template declara regra conhecida, XP positivo e alvo válido", () => {
        for (const template of MISSION_CATALOG) {
            expect(MISSION_PROGRESS_RULES).toContain(template.progressRule);
            expect(template.rewardXp).toBeGreaterThan(0);
            expect(template.target).toBeGreaterThan(0);
            // O validador da IA recusa alvo acima de 100 (MAX_MISSION_TARGET).
            expect(template.target).toBeLessThanOrEqual(100);
            expect(template.aiRequiredTerms.length).toBeGreaterThan(0);
        }
    });

    it("todo actionPath está na allowlist de missão", () => {
        for (const template of MISSION_CATALOG) {
            expect(MISSION_ACTION_PATHS).toContain(template.actionPath);
        }
    });

    it("a allowlist de missão é a do coaching MAIS /reconciliation", () => {
        // Se alguém acrescentar uma rota aqui sem acertar o app, o CTA da
        // missão vira um botão que não navega. O teste existe para essa adição
        // ser deliberada — ver "Contratos com o app" no README.
        const extra = MISSION_ACTION_PATHS.filter(
            (path) => !ALLOWED_ACTION_PATHS.includes(path.split("?")[0])
        );
        expect(extra).toEqual(["/reconciliation"]);
    });

    it("o texto de cada template usa exatamente os placeholders que declara", () => {
        for (const template of MISSION_CATALOG) {
            for (const locale of ["pt", "en"] as const) {
                const found = [...template.name[locale].matchAll(/\{(category|target)\}/g)].map((m) => m[1]);
                expect(new Set(found)).toEqual(new Set(template.params));
            }
        }
    });

    it("todo placeholder {category} tem fallback nos dois idiomas", () => {
        for (const template of MISSION_CATALOG) {
            if (!template.params.includes("category")) continue;
            expect(template.fallbackParams?.category?.pt).toBeTruthy();
            expect(template.fallbackParams?.category?.en).toBeTruthy();
        }
    });

    it("nenhum texto de template usa o vocabulário proibido da sua audiência", () => {
        // É a regressão que este pacote existe para impedir: uma missão de
        // empresa falando de alimentação/lazer, ou uma pessoal falando de
        // margem e centro de custo.
        for (const template of MISSION_CATALOG) {
            const forbidden = AUDIENCE_FORBIDDEN_TERMS[template.audience];
            const text = normalizeTerm(`${template.name.pt} ${template.nameKey}`);
            for (const term of forbidden) {
                expect(text).not.toContain(term);
            }
        }
    });
});

describe("seleção determinística por semana", () => {
    it("a mesma semana devolve sempre o mesmo template", () => {
        for (const audience of WORKSPACE_AUDIENCES) {
            for (const type of WEEKLY_MISSION_TYPES) {
                const first = selectMissionTemplate(audience, type, "2026-W38");
                for (let i = 0; i < 5; i++) {
                    expect(selectMissionTemplate(audience, type, "2026-W38")?.key).toBe(first?.key);
                }
            }
        }
    });

    it("o template escolhido pertence à audiência e ao tipo pedidos", () => {
        for (let week = 1; week <= 53; week++) {
            const weekId = `2026-W${String(week).padStart(2, "0")}`;
            for (const audience of WORKSPACE_AUDIENCES) {
                for (const type of WEEKLY_MISSION_TYPES) {
                    const template = selectMissionTemplate(audience, type, weekId)!;
                    expect(template.audience).toBe(audience);
                    expect(template.type).toBe(type);
                }
            }
        }
    });

    it("varia entre as semanas do ano onde existe mais de um candidato", () => {
        for (const type of WEEKLY_MISSION_TYPES) {
            const candidates = missionTemplatesFor("business", type);
            if (candidates.length < 2) continue;
            const chosen = new Set<string>();
            for (let week = 1; week <= 53; week++) {
                const weekId = `2026-W${String(week).padStart(2, "0")}`;
                chosen.add(selectMissionTemplate("business", type, weekId)!.key);
            }
            // Não exigimos distribuição perfeita — exigimos que o hash de fato
            // alcance todos os candidatos ao longo de um ano. Um hash que
            // agrupasse tudo numa posição tornaria o catálogo inútil.
            expect(chosen.size).toBe(candidates.length);
        }
    });

    it("hashString é estável e distingue semanas vizinhas", () => {
        expect(hashString("2026-W31")).toBe(hashString("2026-W31"));
        expect(hashString("2026-W31")).not.toBe(hashString("2026-W32"));
    });
});

describe("audiência", () => {
    it("só `business` vira empresa; o resto (inclusive ausente) é pessoal", () => {
        expect(resolveAudience("business")).toBe("business");
        expect(resolveAudience("personal")).toBe("personal");
        expect(resolveAudience(undefined)).toBe("personal");
        expect(resolveAudience(null)).toBe("personal");
        expect(resolveAudience("Business")).toBe("personal");
    });

    it("conteúdo sem marcação (ou `both`) vale para os dois tipos", () => {
        expect(appliesToAudience(undefined, "business")).toBe(true);
        expect(appliesToAudience("both", "personal")).toBe(true);
        expect(appliesToAudience("personal", "business")).toBe(false);
        expect(appliesToAudience("personal", "personal")).toBe(true);
    });
});

describe("buildMissionName", () => {
    const discipline = findMissionTemplate("business_discipline_top_cost_center")!;

    it("preenche categoria e alvo", () => {
        expect(buildMissionName(discipline, "pt", { category: "Marketing", target: 5 }))
            .toBe("Manter o centro de custo Marketing dentro do plano por 5 dias.");
    });

    it("cai no fallback quando o workspace não tem nenhum limite", () => {
        expect(buildMissionName(discipline, "pt", { target: 5 }))
            .toBe("Manter o centro de custo de maior peso dentro do plano por 5 dias.");
        expect(buildMissionName(discipline, "en", { target: 5 }))
            .toBe("Keep the heaviest cost centre within plan for 5 days.");
    });

    it("monta o texto pessoal sem vocabulário de equipe", () => {
        const consistency = findMissionTemplate("personal_consistency_plan_limits")!;
        const name = buildMissionName(consistency, "pt", { target: 3 });
        expect(name).toBe("Planejar limites para pelo menos 3 categorias e organizar a semana.");
        expect(name.toLowerCase()).not.toContain("equipe");
    });
});

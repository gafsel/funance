/**
 * Renderização de templates de prompt.
 *
 * Por que isto existe: `String.prototype.replace(string, string)` substitui
 * apenas a PRIMEIRA ocorrência do token e interpreta os padrões especiais
 * `$&`, `$'`, "$`" e `$1` dentro do valor de substituição. Como boa parte dos
 * valores vem do usuário (descrição de notificação bancária, nome de
 * categoria, texto de documento), uma descrição como "PIX $& $&" conseguia
 * duplicar trechos do prompt — injeção real, não teórica.
 *
 * `renderTemplate` usa um replacer de FUNÇÃO (o retorno é literal, nenhum `$`
 * é interpretado) e uma regex global (todas as ocorrências do token são
 * substituídas). Os valores injetados não são re-escaneados, então um valor
 * que contenha `{{outroToken}}` continua sendo apenas texto.
 */

// Tokens no formato {{nome}} (espaços opcionais dentro das chaves).
const TOKEN_PATTERN = /\{\{\s*([a-zA-Z0-9_]+)\s*\}\}/g;

export type PromptVars = Record<string, string>;

/**
 * Substitui todos os `{{token}}` do template pelos valores de `vars`.
 * Tokens sem valor correspondente são mantidos como estão (fica visível no
 * log/prompt que faltou um dado, em vez de virar string vazia silenciosa).
 */
export function renderTemplate(template: string, vars: PromptVars): string {
    return template.replace(TOKEN_PATTERN, (match, token: string) => {
        if (!Object.prototype.hasOwnProperty.call(vars, token)) {
            return match;
        }
        const value = vars[token];
        return value === null || value === undefined ? "" : String(value);
    });
}

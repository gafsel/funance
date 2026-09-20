# Arte da Arena — procedência e licença

Tudo o que está nesta pasta é **arte placeholder de POC**. Nada aqui foi
desenhado para o produto: serve para o dono sentir a mecânica antes de a gente
encomendar arte de verdade.

## `kenney_tiny_dungeon.png`

- **Pacote**: Kenney — *Tiny Dungeon* (1.0), criado em 05-07-2022.
- **Origem**: <https://kenney.nl/assets/tiny-dungeon>
  (arquivo `kenney_tiny-dungeon.zip`, `Tilemap/tilemap_packed.png`).
- **Licença**: Creative Commons Zero (CC0 1.0 Universal) —
  <http://creativecommons.org/publicdomain/zero/1.0/>.
  Uso livre em projeto pessoal, educacional e **comercial**. Crédito ao Kenney
  é bem-vindo e **não é obrigatório**. O texto original veio junto e está em
  `kenney_tiny_dungeon_license.txt`.
- **O que é**: folha de 12 × 11 tiles de 16 × 16 px, **sem espaçamento** entre
  eles (por isso a variante "packed"). O índice de um tile é
  `linha * 12 + coluna`, e é assim que `ArenaSprites` o endereça.
- **O que a Arena usa da folha** (o resto vai no binário porque separar 12
  arquivos de 150 bytes custa mais do que os 5 KB da folha inteira):

  | Índice | O que é          | Onde aparece                       |
  |-------:|------------------|------------------------------------|
  |     96 | cavaleiro de elmo fechado | avatar `knight` (padrão)  |
  |     84 | mago de manto roxo        | avatar `mage`             |
  |    112 | batedor de faixa verde    | avatar `ranger`           |
  |    100 | guerreira de cabelo prateado | avatar `warrior`       |
  |     99 | curandeira de vestido roxo | avatar `healer`          |
  |     87 | bárbaro de elmo com pelos | avatar `barbarian`        |
  |     88 | monge de colete marrom    | avatar `monk`             |
  |     86 | ferreiro de avental       | avatar `smith`            |
  |    122 | aranha           | monstro da semana                  |
  |    110 | demônio vermelho | monstro da semana (enfurecido)     |
  |    120 | morcego          | monstro da semana                  |
  |    121 | fantasma         | monstro da semana                  |
  |    108 | gosma            | monstro da semana                  |
  |     82 | casulo           | casulo da fatura do cartão         |
  |     48 | chão de areia    | piso da arena                      |
  |     49 | chão salpicado   | piso da arena (variação)           |
  |     40 | parede de tijolo | fundo da arena                     |
  |     29 | braseiro         | tocha do fundo                     |

## O que **não** vem de pacote nenhum

Moedas, números flutuantes, barras de vida, hachura de comprometido e o filtro
de exaustão são desenhados em código (`arena_effects.dart`,
`arena_hud.dart`), com os tokens de `lib/core/theme/` — nenhum hexadecimal
solto e nenhuma imagem extra.

## Quando trocar

Esta pasta inteira é descartável. Quando a arte definitiva chegar, o contrato
que ela precisa cumprir é o de `ArenaSprites`: um sprite por `HeroSkin`, um por
`MonsterSkin`, mais chão/parede. Ver a seção "custo de arte" no relatório da
POC.

Os oito avatares são o contrato mais rígido dos três: o `name` de cada
`HeroSkin` está gravado em `users/{uid}.avatar` no Firestore de quem já
escolheu. A arte nova pode desenhar outro cavaleiro; ela não pode deixar de
ter um.

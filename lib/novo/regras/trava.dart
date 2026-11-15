/// Quanto tempo fora do app faz a trava voltar a pedir a biometria.
const tempoForaParaTravar = Duration(minutes: 5);

/// O app deve pedir a biometria de novo ao voltar? Só quando a trava está
/// ligada neste aparelho e a pessoa ficou fora tempo suficiente.
bool deveTravarAoVoltar({required bool travaLigada, required DateTime? saiuEm, required DateTime agora}) =>
    travaLigada && saiuEm != null && agora.difference(saiuEm) >= tempoForaParaTravar;

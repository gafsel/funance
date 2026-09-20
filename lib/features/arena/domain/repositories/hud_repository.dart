import 'package:funances/features/arena/domain/models/hud_state.dart';

/// O que o HUD mensal lê e mais ninguém lia.
///
/// Os dois documentos são **do servidor**: as rules negam a escrita ao
/// cliente, e é por isso que eles não moram no `WorkspaceModel` — um modelo
/// que o app serializa de volta no `toJson` não pode carregar campo que as
/// rules rejeitam. Aqui é só leitura, que é tudo o que o rodapé precisa.
abstract class IHudRepository {
  /// `workspaces/{w}.expectedIncome`.
  ///
  /// `null` quando o campo não existe — e ausência é como o servidor escreve
  /// "ainda não sei", nunca "a receita é zero".
  Stream<ExpectedIncome?> watchExpectedIncome(String workspaceId);

  /// `workspaces/{w}/monthly_reports`, os meses já fechados.
  ///
  /// [limit] existe porque a folha mostra os últimos meses, não a vida
  /// inteira do cofre: sem ele, um workspace de três anos traria trinta e
  /// seis documentos para desenhar seis linhas.
  Stream<List<HudMonthlyReport>> watchMonthlyReports(
    String workspaceId, {
    int limit,
  });
}

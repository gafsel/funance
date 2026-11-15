/// Os endereços do app. Cada seção e cada tela de detalhe tem o seu, para
/// que recarregar a página (ou guardar o link) volte ao mesmo lugar.
///
/// Este arquivo não importa tela nenhuma: é só o vocabulário dos caminhos,
/// usado por quem abre uma tela e por quem monta a tela a partir do endereço.
library;

String _id(String id) => Uri.encodeComponent(id);

const caminhoDoInicio = '/';
const caminhoDasCategorias = '/categorias';
const caminhoDaDistribuicao = '/distribuicao';
const caminhoDaRevisao = '/revisao';
const caminhoDaOrganizacao = '/organizar';

/// No celular, Empresa e Relatórios abrem a partir de "Mais".
const caminhoDaEmpresaNoCelular = '/mais/empresa';
const caminhoDosRelatoriosNoCelular = '/mais/relatorios';

String caminhoDaConta(String contaId) => '/conta/${_id(contaId)}';
String caminhoDoCartao(String cartaoId) => '/cartao/${_id(cartaoId)}';
String caminhoDaFatura(String cartaoId, String faturaId) => '/fatura/${_id(cartaoId)}/${_id(faturaId)}';
String caminhoDaMeta(String metaId) => '/meta/${_id(metaId)}';
String caminhoDoFechamento(String mes) => '/fechamento/${_id(mes)}';
String caminhoDoContato(String contraparteId) => '/contato/${_id(contraparteId)}';

/// As partes de um caminho, já decodificadas: `/fatura/a/b` → `[fatura, a, b]`.
List<String> partesDoCaminho(String caminho) {
  try {
    return Uri.parse(caminho).pathSegments.where((p) => p.isNotEmpty).toList();
  } catch (_) {
    return const [];
  }
}

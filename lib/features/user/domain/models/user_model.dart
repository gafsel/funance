import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,

    /// O herói que representa este usuário na Arena — o `name` de um
    /// `HeroSkin` (`knight`, `mage`, `ranger`, `warrior`, `healer`,
    /// `barbarian`, `monk`, `smith`).
    ///
    /// **Nulo é um valor legítimo**, e não um campo faltando por engano:
    /// todo mundo que entrou no app antes do seletor existir não escolheu
    /// nada, e a Arena continua desenhando para essa gente o boneco da
    /// ordem de entrada. Guardado como TEXTO, e não como índice de sprite,
    /// porque o índice é coordenada da folha de arte e a folha vai mudar.
    String? avatar,
    required DateTime createdAt,
    DateTime? lastLogin,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

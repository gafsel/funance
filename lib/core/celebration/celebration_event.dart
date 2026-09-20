import 'package:flutter/foundation.dart';

/// O que está sendo celebrado.
///
/// A ordem dos membros é a ordem de importância: quando dois eventos chegam
/// juntos (subir de nível normalmente vem com XP e às vezes com uma badge), o
/// maior manda na pilha.
enum CelebrationKind {
  /// XP creditado por um lançamento ou por uma ação do servidor.
  xp,

  /// Missão da semana concluída.
  mission,

  /// Badge desbloqueada.
  badge,

  /// Patente da Bússola subiu.
  tier,

  /// O cofre subiu de nível.
  level;

  /// `true` quando o evento merece o tratamento cheio — halo, háptica forte,
  /// confete. Ganhar XP não merece; desbloquear uma badge, sim.
  bool get isMajor => index >= CelebrationKind.badge.index;
}

/// Uma conquista a mostrar.
///
/// O evento carrega **dados**, não texto: a tradução acontece no widget, que é
/// quem tem `AppLocalizations`. Isso também é o que permite testar o serviço
/// sem montar uma árvore.
@immutable
class CelebrationEvent {
  const CelebrationEvent({
    required this.kind,
    required this.key,
    this.xp,
    this.badgeId,
    this.level,
    this.missionId,
    this.missionName,
    this.tierName,
  });

  /// XP ganho. `key` é sequencial porque o mesmo valor pode ser ganho duas
  /// vezes seguidas e as duas vezes contam.
  factory CelebrationEvent.xp(int amount, {required int sequence}) =>
      CelebrationEvent(
        kind: CelebrationKind.xp,
        key: 'xp:$sequence',
        xp: amount,
      );

  factory CelebrationEvent.mission({
    required String missionId,
    String? name,
    int? xp,
  }) => CelebrationEvent(
    kind: CelebrationKind.mission,
    key: 'mission:$missionId',
    missionId: missionId,
    missionName: name,
    xp: xp,
  );

  factory CelebrationEvent.badge(String badgeId) => CelebrationEvent(
    kind: CelebrationKind.badge,
    key: 'badge:$badgeId',
    badgeId: badgeId,
  );

  factory CelebrationEvent.level(int level) => CelebrationEvent(
    kind: CelebrationKind.level,
    key: 'level:$level',
    level: level,
  );

  factory CelebrationEvent.tier(String tierName) => CelebrationEvent(
    kind: CelebrationKind.tier,
    key: 'tier:$tierName',
    tierName: tierName,
  );

  final CelebrationKind kind;

  /// Identidade do evento. É o que impede a mesma conquista de ser celebrada
  /// duas vezes quando o Firestore reemite o documento — e o Firestore reemite
  /// o documento o tempo todo.
  final String key;

  final int? xp;
  final String? badgeId;
  final int? level;
  final String? missionId;
  final String? missionName;
  final String? tierName;

  @override
  bool operator ==(Object other) =>
      other is CelebrationEvent && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'CelebrationEvent($key)';
}

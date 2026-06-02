import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';

final missionProvider = StreamProvider.autoDispose<MissionModel>((ref) {
  final service = ref.watch(MissionDomainProviders.service);
  return service.watchMissions();
});

// Nota: O missionProvider anterior era um StreamProvider que continha toda a lógica.
// Agora ele apenas repassa o stream do MissionViewProviders.mission, mantendo compatibilidade
// com a MissionsTab se necessário, ou podemos atualizar a MissionsTab para usar MissionViewProviders.mission diretamente.
// Dado que o usuário pediu "notifiers devem funcionar apenas como controlador de telas", 
// e o missionProvider original era apenas um StreamProvider (não um StateNotifier), 
// a refatoração para MissionService + Provider cumpre a regra de separar lógica de negócio.

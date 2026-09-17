import 'package:funances/core/files/picked_document.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/platform/app_platform.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/services/user_service.dart';
import 'package:funances/features/user/presentation/model/user_view_models.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/form/form_notifier.dart';

class UserProfileNotifier extends FormNotifier<UserProfileFormState, void> {
  final UserService userService;
  final ImagePicker _picker = ImagePicker();

  UserProfileNotifier({
    required this.userService,
  }) : super(const UserProfileFormState(id: '', displayName: '', email: ''));

  void load(UserModel user) {
    state = UserProfileFormState.initial(user);
  }

  void updateDisplayName(String value) => state = state.copyWith(displayName: value);

  Future<void> pickImage(BuildContext context, ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    // O cropper na web recebe o context; se a tela saiu durante a escolha da
    // imagem, não há mais o que abrir.
    if (!context.mounted) return;

    if (pickedFile != null) {
      // O plugin image_cropper não suporta macOS.
      // Suporta Android, iOS e Web.
      final bool supportsCropping =
          AppPlatform.isWeb || AppPlatform.isAndroid || AppPlatform.isIOS;

      if (supportsCropping) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Ajustar Foto',
              toolbarColor: AppColors.deepTurquoise,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Ajustar Foto',
              aspectRatioLockEnabled: true,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
              size: const CropperSize(
                width: 520,
                height: 520,
              ),
            ),
          ],
        );

        if (croppedFile != null) {
          state = state.copyWith(
            newPhotoFile: PickedDocument(
              // O recorte devolve um nome temporário; o do arquivo escolhido
              // é o que preserva a extensão original.
              name: pickedFile.name,
              bytes: await croppedFile.readAsBytes(),
            ),
          );
        }
      } else {
        // Para plataformas sem suporte ao crop (como macOS), usamos a imagem direta
        state = state.copyWith(
          newPhotoFile: PickedDocument(
            name: pickedFile.name,
            bytes: await pickedFile.readAsBytes(),
          ),
        );
      }
    }
  }

  @override
  Future<void> submit() async {
    String? photoUrl = state.photoUrl;

    if (state.newPhotoFile != null) {
      photoUrl = await userService.uploadAvatar(state.id, state.newPhotoFile!);
    }

    await userService.updateProfile(
      id: state.id,
      displayName: state.displayName,
      photoUrl: photoUrl,
    );
  }
}

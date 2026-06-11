import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/user/presentation/controller/user_profile_notifier.dart';
import 'package:funances/features/user/presentation/model/user_view_models.dart';
import 'package:funances/features/user/presentation/providers/user_providers.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  void _showPhotoSourceDialog(BuildContext context, UserProfileNotifier notifier, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.profilePhotoCamera),
              onTap: () {
                Navigator.pop(context);
                notifier.pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.profilePhotoGallery),
              onTap: () {
                Navigator.pop(context);
                notifier.pickImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(AuthDomainProviders.currentUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveForm<UserProfileFormState, void, UserProfileNotifier>(
              UserViewProviders.profileForm,
              onSuccess: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.profileUpdateSuccess)),
                );
              },
              fieldsBuilder: (context, snapshot) {
                final state = snapshot.model;
                final notifier = snapshot.notifier;

                // Inicializa o estado se for a primeira vez
                if (state.id.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notifier.load(user);
                  });
                }

                return [
                  FullWidthItem(
                    Center(
                      child: UserAvatar(
                        displayName: state.displayName,
                        photoUrl: state.photoUrl,
                        imageFile: state.newPhotoFile,
                        radius: 50,
                        onEdit: () => _showPhotoSourceDialog(context, notifier, l10n),
                      ),
                    ),
                  ),
                  TextFormField(
                    key: ValueKey('name_${state.id}'),
                    initialValue: state.displayName,
                    decoration: InputDecoration(
                      labelText: l10n.profileNameLabel,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    onChanged: notifier.updateDisplayName,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    key: ValueKey('email_${state.id}'),
                    initialValue: state.email,
                    decoration: InputDecoration(
                      labelText: l10n.profileEmailLabel,
                      prefixIcon: const Icon(Icons.email),
                    ),
                    enabled: false,
                  ),
                ];
              },
            ),
    );
  }
}

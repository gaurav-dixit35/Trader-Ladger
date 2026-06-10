import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../core/providers/image_picker_provider.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../application/entry_image_providers.dart';
import '../../data/entry_image_repository_impl.dart';
import '../../domain/entry_image.dart';

class EntryImageSection extends ConsumerWidget {
  const EntryImageSection({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesState = ref.watch(entryImagesControllerProvider(entryId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Proof images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Camera',
                  onPressed: () => _addFromCamera(context, ref),
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
                IconButton(
                  tooltip: 'Gallery',
                  onPressed: () => _addFromGallery(context, ref),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spacingMd),
            imagesState.when(
              data: (images) {
                if (images.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.image_outlined,
                    title: 'No proof images',
                    message: 'Add bill, cheque, or payment proof images.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${images.length}/${AppConstants.maxEntryImages} images',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppLayout.spacingMd),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: AppLayout.spacingSm,
                        mainAxisSpacing: AppLayout.spacingSm,
                      ),
                      itemBuilder: (context, index) {
                        final image = images[index];
                        return _EntryImageTile(
                          image: image,
                          onDelete: () => _deleteImage(context, ref, image),
                        );
                      },
                    ),
                  ],
                );
              },
              error: (error, stackTrace) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load images',
                message: 'Please refresh this entry.',
                action: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(entryImagesControllerProvider(entryId).notifier)
                        .load();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFromCamera(BuildContext context, WidgetRef ref) async {
    await _handleImageAction(
      context,
      () {
        final picker = ref.read(imagePickerServiceProvider);
        return ref
            .read(entryImagesControllerProvider(entryId).notifier)
            .addFromPicker((picker) => picker.captureFromCamera(), picker);
      },
    );
  }

  Future<void> _addFromGallery(BuildContext context, WidgetRef ref) async {
    await _handleImageAction(
      context,
      () {
        final picker = ref.read(imagePickerServiceProvider);
        return ref
            .read(entryImagesControllerProvider(entryId).notifier)
            .addFromPicker((picker) => picker.pickFromGallery(), picker);
      },
    );
  }

  Future<void> _deleteImage(
    BuildContext context,
    WidgetRef ref,
    EntryImage image,
  ) async {
    await ref
        .read(entryImagesControllerProvider(entryId).notifier)
        .deleteImage(image.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Image moved to recycle bin'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(entryImagesControllerProvider(entryId).notifier)
                .restoreImage(image.id);
          },
        ),
      ),
    );
  }

  Future<void> _handleImageAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on EntryImageLimitException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _EntryImageTile extends StatelessWidget {
  const _EntryImageTile({
    required this.image,
    required this.onDelete,
  });

  final EntryImage image;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppLayout.radiusSm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(image.localPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
              );
            },
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton.filledTonal(
              tooltip: 'Delete image',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }
}

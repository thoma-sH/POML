import 'dart:io';

import 'package:first_flutter_app/features/post/data/repos/mock_post_repo.dart';
import 'package:first_flutter_app/features/post/data/repos/mock_post_storage_repo.dart';
import 'package:first_flutter_app/features/post/data/repos/supabase_post_repo.dart';
import 'package:first_flutter_app/features/post/data/repos/supabase_post_storage_repo.dart';
import 'package:first_flutter_app/features/post/domain/repos/post_repo.dart';
import 'package:first_flutter_app/features/post/domain/repos/post_storage_repo.dart';
import 'package:first_flutter_app/features/post/presentation/cubits/post_capture_cubit.dart';
import 'package:first_flutter_app/features/post/presentation/cubits/post_capture_states.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/grain_overlay.dart';
import 'package:first_flutter_app/shared/widgets/scalloped_avatar.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PostCapturePage extends StatelessWidget {
  const PostCapturePage({super.key});

  PostStorageRepo _storageRepo() =>
      kDebugMode ? MockPostStorageRepo() : SupabasePostStorageRepo();

  PostRepo _postRepo() => kDebugMode ? MockPostRepo() : SupabasePostRepo();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostCaptureCubit>(
      create: (_) => PostCaptureCubit(
        storageRepo: _storageRepo(),
        postRepo: _postRepo(),
      ),
      child: const _PostCaptureView(),
    );
  }
}

class _PostCaptureView extends StatefulWidget {
  const _PostCaptureView();

  @override
  State<_PostCaptureView> createState() => _PostCaptureViewState();
}

class _PostCaptureViewState extends State<_PostCaptureView> {
  int? _selectedAlbum;
  final _captionController = TextEditingController();
  bool _locationTagged = false;

  static const _albums = <_AlbumOption>[
    _AlbumOption(name: 'Beach', color: Color(0xFF4F6B8A)),
    _AlbumOption(name: 'Concerts', color: Color(0xFF7E5A8C)),
    _AlbumOption(name: 'Vibing', color: Color(0xFF4A5568)),
    _AlbumOption(name: 'School', color: Color(0xFF6B4F8A)),
    _AlbumOption(name: 'Sad', color: Color(0xFF3A3760)),
    _AlbumOption(name: 'Roadtrip', color: Color(0xFF5C7A56)),
    _AlbumOption(name: 'Coffee', color: Color(0xFF7A5C3A)),
    _AlbumOption(name: 'Sunsets', color: Color(0xFF8C4A3A)),
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _captionController.clear();
    setState(() {
      _selectedAlbum = null;
      _locationTagged = false;
    });
  }

  Future<void> _showPickerSheet() async {
    final cubit = context.read<PostCaptureCubit>();
    HapticFeedback.lightImpact();
    final source = await showModalBottomSheet<_PickerSource>(
      context: context,
      backgroundColor: AppColors.surface1,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIconsLight.camera, color: AppColors.textPrimary),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(sheetCtx, _PickerSource.camera),
            ),
            ListTile(
              leading: Icon(PhosphorIconsLight.image, color: AppColors.textPrimary),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(sheetCtx, _PickerSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == _PickerSource.camera) {
      await cubit.pickFromCamera();
    } else if (source == _PickerSource.gallery) {
      await cubit.pickFromGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        _selectedAlbum != null ? _albums[_selectedAlbum!].color : null;

    return BlocListener<PostCaptureCubit, PostCaptureState>(
      listener: (context, state) {
        if (state is PostCaptureSuccess) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Posted.')));
          _resetForm();
          context.read<PostCaptureCubit>().clearMedia();
        } else if (state is PostCaptureFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: GrainOverlay()),
            SafeArea(
              bottom: false,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _PageHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  _CameraBlock(
                    selectedColor: selectedColor,
                    onPick: _showPickerSheet,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(label: 'post to album'),
                  const SizedBox(height: AppSpacing.md),
                  _AlbumPicker(
                    albums: _albums,
                    selectedIndex: _selectedAlbum,
                    onSelect: (i) {
                      HapticFeedback.lightImpact();
                      setState(
                        () => _selectedAlbum = _selectedAlbum == i ? null : i,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(label: 'caption'),
                  const SizedBox(height: AppSpacing.md),
                  _CaptionField(controller: _captionController),
                  const SizedBox(height: AppSpacing.xl),
                  _LocationRow(
                    tagged: _locationTagged,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _locationTagged = !_locationTagged);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  BlocBuilder<PostCaptureCubit, PostCaptureState>(
                    builder: (context, state) {
                      final hasMedia = state is PostCaptureIdle && state.hasMedia ||
                          state is PostCaptureFailure && state.selectedFile != null;
                      final publishing = state is PostCapturePublishing;
                      return _PostButton(
                        enabled: hasMedia && _selectedAlbum != null && !publishing,
                        publishing: publishing,
                        selectedColor: selectedColor,
                        onPost: () {
                          HapticFeedback.mediumImpact();
                          context.read<PostCaptureCubit>().publish(
                            caption: _captionController.text.trim().isEmpty
                                ? null
                                : _captionController.text.trim(),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.huge + AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PickerSource { camera, gallery }

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          Text(
            'new post',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            PhosphorIconsLight.plus,
            color: AppColors.accent,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CameraBlock extends StatelessWidget {
  const _CameraBlock({required this.selectedColor, required this.onPick});

  final Color? selectedColor;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCaptureCubit, PostCaptureState>(
      builder: (context, state) {
        final File? file = switch (state) {
          PostCaptureIdle s => s.selectedFile,
          PostCaptureFailure s => s.selectedFile,
          _ => null,
        };
        final publishing = state is PostCapturePublishing;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: publishing ? null : onPick,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.xl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (file != null)
                      Image.file(file, fit: BoxFit.cover)
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.2, -0.3),
                            radius: 1.2,
                            colors: [
                              selectedColor != null
                                  ? Color.lerp(
                                        selectedColor,
                                        Colors.black,
                                        0.4,
                                      ) ??
                                      AppColors.surface2
                                  : AppColors.surface2,
                              AppColors.bgDeep,
                            ],
                          ),
                        ),
                      ),
                    if (file == null)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScallopedOutlineButton(
                              onTap: onPick,
                              size: 72,
                              borderColor: selectedColor ?? AppColors.accent,
                              child: Icon(
                                PhosphorIconsLight.camera,
                                color: selectedColor ?? AppColors.accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'tap to capture or choose',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                    letterSpacing: 0.3,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'photo only · up to 10 MB',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    if (file != null)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: TapBounce(
                          scaleTo: 0.85,
                          onTap: () =>
                              context.read<PostCaptureCubit>().clearMedia(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              PhosphorIconsLight.x,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (publishing)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _AlbumPicker extends StatelessWidget {
  const _AlbumPicker({
    required this.albums,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_AlbumOption> albums;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: albums.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final isSelected = selectedIndex == i;
          return _AlbumChip(
            album: albums[i],
            isSelected: isSelected,
            onTap: () => onSelect(i),
          );
        },
      ),
    );
  }
}

class _AlbumChip extends StatelessWidget {
  const _AlbumChip({
    required this.album,
    required this.isSelected,
    required this.onTap,
  });

  final _AlbumOption album;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? album.color.withValues(alpha: 0.25)
              : AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: isSelected
                ? album.color.withValues(alpha: 0.7)
                : AppColors.borderSubtle,
            width: isSelected ? 1.0 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: album.color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: album.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              album.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                fontWeight:
                    isSelected ? FontWeight.w500 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptionField extends StatelessWidget {
  const _CaptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        ),
        child: TextField(
          controller: controller,
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: 'optional caption…',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textDisabled,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.tagged, required this.onTap});

  final bool tagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tagged
                    ? AppColors.accentDeep.withValues(alpha: 0.4)
                    : AppColors.surface1,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tagged ? AppColors.accent : AppColors.borderSubtle,
                  width: 0.5,
                ),
              ),
              child: Icon(
                tagged
                    ? PhosphorIconsFill.mapPin
                    : PhosphorIconsLight.mapPin,
                color: tagged ? AppColors.accent : AppColors.textTertiary,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tagged ? 'location tagged' : 'tag location',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tagged
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (tagged)
                    Text(
                      'tap to remove',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  const _PostButton({
    required this.enabled,
    required this.selectedColor,
    required this.onPost,
    this.publishing = false,
  });

  final bool enabled;
  final Color? selectedColor;
  final VoidCallback onPost;
  final bool publishing;

  String _label(BuildContext context) {
    if (publishing) {
      final state = context.read<PostCaptureCubit>().state;
      if (state is PostCapturePublishing &&
          state.stage == PublishStage.uploading) {
        return 'uploading...';
      }
      return 'publishing...';
    }
    final cubit = context.read<PostCaptureCubit>();
    final hasMedia = switch (cubit.state) {
      PostCaptureIdle s => s.hasMedia,
      PostCaptureFailure s => s.selectedFile != null,
      _ => false,
    };
    if (!hasMedia) return 'add a photo first';
    if (!enabled) return 'pick an album first';
    return 'post';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? AppColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        onTap: enabled ? onPost : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          decoration: BoxDecoration(
            color: enabled || publishing ? activeColor : AppColors.surface1,
            borderRadius: BorderRadius.circular(AppSpacing.xl),
            border: Border.all(
              color: enabled || publishing
                  ? activeColor.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
              width: 0.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (publishing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  PhosphorIconsLight.paperPlaneTilt,
                  color: enabled ? Colors.white : AppColors.textDisabled,
                  size: 18,
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _label(context),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: enabled || publishing
                      ? Colors.white
                      : AppColors.textDisabled,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumOption {
  const _AlbumOption({required this.name, required this.color});

  final String name;
  final Color color;
}

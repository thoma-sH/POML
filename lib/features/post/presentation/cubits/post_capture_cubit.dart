import 'dart:io';

import 'package:first_flutter_app/features/post/domain/repos/post_repo.dart';
import 'package:first_flutter_app/features/post/domain/repos/post_storage_repo.dart';
import 'package:first_flutter_app/features/post/presentation/cubits/post_capture_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class PostCaptureCubit extends Cubit<PostCaptureState> {
  PostCaptureCubit({
    required this.storageRepo,
    required this.postRepo,
  }) : super(const PostCaptureIdle());

  final PostStorageRepo storageRepo;
  final PostRepo postRepo;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromCamera() => _pick(ImageSource.camera);

  Future<void> pickFromGallery() => _pick(ImageSource.gallery);

  void clearMedia() {
    emit(const PostCaptureIdle());
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 4096,
      );
      if (picked == null) return;
      emit(PostCaptureIdle(
        selectedFile: File(picked.path),
        mimeType: _mimeFromPath(picked.path),
      ));
    } catch (_) {
      emit(const PostCaptureFailure('Could not access photo. Check permissions.'));
    }
  }

  Future<void> publish({
    String? caption,
    String? albumId,
    double? latitude,
    double? longitude,
  }) async {
    final current = state;
    if (current is! PostCaptureIdle || !current.hasMedia) {
      emit(const PostCaptureFailure('Select a photo first.'));
      return;
    }
    final file = current.selectedFile!;
    final mime = current.mimeType ?? 'image/jpeg';

    try {
      emit(const PostCapturePublishing(PublishStage.uploading));
      final mediaUrl = await storageRepo.uploadPostMedia(
        file: file,
        mimeType: mime,
      );

      emit(const PostCapturePublishing(PublishStage.creating));
      final id = await postRepo.createPost(
        mediaUrl: mediaUrl,
        caption: caption,
        albumId: albumId,
        latitude: latitude,
        longitude: longitude,
      );

      emit(PostCaptureSuccess(id));
    } catch (e) {
      emit(PostCaptureFailure(
        e.toString().replaceFirst('Exception: ', ''),
        selectedFile: file,
        mimeType: mime,
      ));
    }
  }

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'image/jpeg';
  }
}

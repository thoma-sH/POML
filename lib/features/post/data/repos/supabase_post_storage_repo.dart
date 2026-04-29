import 'dart:io';

import 'package:first_flutter_app/features/post/domain/repos/post_storage_repo.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabasePostStorageRepo implements PostStorageRepo {
  static const _bucket = 'post-media';
  static const _maxLongEdge = 1600;
  static const _jpegQuality = 82;

  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  @override
  Future<String> uploadPostMedia({
    required File file,
    required String mimeType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in.');
    }

    final isImage = mimeType.startsWith('image/');
    final upload = isImage ? await _compressImage(file) : file;
    final ext = isImage ? 'jpg' : (p.extension(file.path).replaceFirst('.', ''));
    final outMime = isImage ? 'image/jpeg' : mimeType;

    final objectPath = '${user.id}/${_uuid.v4()}.$ext';

    await _client.storage.from(_bucket).upload(
      objectPath,
      upload,
      fileOptions: FileOptions(
        contentType: outMime,
        upsert: false,
      ),
    );

    return _client.storage.from(_bucket).getPublicUrl(objectPath);
  }

  // Re-encode large camera/gallery images to JPEG below ~1600px on the long
  // edge. Saves bandwidth + storage and removes EXIF (incl. GPS) by default.
  Future<File> _compressImage(File source) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      source.absolute.path,
      minWidth: _maxLongEdge,
      minHeight: _maxLongEdge,
      quality: _jpegQuality,
      keepExif: false,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) return source;

    final out = File(p.join(
      source.parent.path,
      'lacuna_compressed_${_uuid.v4()}.jpg',
    ));
    await out.writeAsBytes(compressed);
    return out;
  }
}

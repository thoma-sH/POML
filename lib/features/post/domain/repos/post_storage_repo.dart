import 'dart:io';

// Uploads post media to long-term storage and returns a public URL the
// feed renderer can use as-is. Implementations are responsible for path
// layout (must place objects under `<user_id>/...` to satisfy the bucket
// RLS) and for any client-side compression.
abstract class PostStorageRepo {
  Future<String> uploadPostMedia({
    required File file,
    required String mimeType,
  });
}

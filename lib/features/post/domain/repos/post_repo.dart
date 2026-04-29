// Creates a row in the `posts` table via the rate-limited `create_post` RPC.
// The RPC handles author_id (= auth.uid), rate limiting, and inserting
// the row in a single round-trip; the client only needs to supply the
// already-uploaded media URL plus optional metadata.
abstract class PostRepo {
  Future<String> createPost({
    required String mediaUrl,
    String mediaType = 'photo',
    String? caption,
    String? albumId,
    double? latitude,
    double? longitude,
  });
}

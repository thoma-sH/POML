import 'package:first_flutter_app/features/post/domain/repos/post_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePostRepo implements PostRepo {
  final _client = Supabase.instance.client;

  @override
  Future<String> createPost({
    required String mediaUrl,
    String mediaType = 'photo',
    String? caption,
    String? albumId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final id = await _client.rpc('create_post', params: {
        '_media_url': mediaUrl,
        '_media_type': mediaType,
        '_caption': caption,
        '_album_id': albumId,
        '_latitude': latitude,
        '_longitude': longitude,
      });
      return id as String;
    } on PostgrestException catch (e) {
      if (e.message.contains('rate_limited')) {
        throw Exception('Slow down — too many posts in the last hour.');
      }
      if (e.message.contains('not_authenticated')) {
        throw Exception('Sign in to post.');
      }
      throw Exception('Could not publish post. Please try again.');
    } catch (_) {
      throw Exception('Could not publish post. Please try again.');
    }
  }
}

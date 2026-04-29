import 'package:first_flutter_app/features/post/domain/repos/post_repo.dart';

class MockPostRepo implements PostRepo {
  @override
  Future<String> createPost({
    required String mediaUrl,
    String mediaType = 'photo',
    String? caption,
    String? albumId,
    double? latitude,
    double? longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'mock-post-${DateTime.now().millisecondsSinceEpoch}';
  }
}

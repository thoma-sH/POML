import 'dart:io';

import 'package:first_flutter_app/features/post/domain/repos/post_storage_repo.dart';

// Returns a stable picsum URL so debug builds can publish without a real
// upload. Picks a different seed each call so feed previews vary.
class MockPostStorageRepo implements PostStorageRepo {
  int _seed = 0;

  @override
  Future<String> uploadPostMedia({
    required File file,
    required String mimeType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _seed++;
    return 'https://picsum.photos/seed/lacuna-mock-$_seed/1200/1500';
  }
}

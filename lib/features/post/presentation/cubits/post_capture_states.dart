import 'dart:io';

sealed class PostCaptureState {
  const PostCaptureState();
}

class PostCaptureIdle extends PostCaptureState {
  const PostCaptureIdle({this.selectedFile, this.mimeType});

  final File? selectedFile;
  final String? mimeType;

  bool get hasMedia => selectedFile != null;
}

class PostCapturePublishing extends PostCaptureState {
  const PostCapturePublishing(this.stage);

  final PublishStage stage;
}

enum PublishStage { uploading, creating }

class PostCaptureSuccess extends PostCaptureState {
  const PostCaptureSuccess(this.postId);

  final String postId;
}

class PostCaptureFailure extends PostCaptureState {
  const PostCaptureFailure(this.message, {this.selectedFile, this.mimeType});

  final String message;
  final File? selectedFile;
  final String? mimeType;
}

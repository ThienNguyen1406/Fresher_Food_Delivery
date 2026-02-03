import 'package:fresher_food/models/Chat.dart';

/// State class quản lý trạng thái chat
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final bool isSending;
  final bool isUploadingFile;
  final bool isWaitingForBotResponse;
  final String? selectedFileId;
  final String? selectedImagePath;

  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.isSending = false,
    this.isUploadingFile = false,
    this.isWaitingForBotResponse = false,
    this.selectedFileId,
    this.selectedImagePath,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    bool? isSending,
    bool? isUploadingFile,
    bool? isWaitingForBotResponse,
    String? selectedFileId,
    String? selectedImagePath,
    bool clearSelectedFileId = false,
    bool clearSelectedImagePath = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isSending: isSending ?? this.isSending,
      isUploadingFile: isUploadingFile ?? this.isUploadingFile,
      isWaitingForBotResponse: isWaitingForBotResponse ?? this.isWaitingForBotResponse,
      selectedFileId: clearSelectedFileId ? null : (selectedFileId ?? this.selectedFileId),
      selectedImagePath: clearSelectedImagePath ? null : (selectedImagePath ?? this.selectedImagePath),
    );
  }

  /// Loading state
  ChatState loading() {
    return copyWith(isLoading: true);
  }

  /// Success state với messages
  ChatState success(List<Message> newMessages, {bool hasMore = true}) {
    return copyWith(
      messages: newMessages,
      isLoading: false,
      hasMoreMessages: hasMore,
    );
  }

  /// Error state
  ChatState error() {
    return copyWith(isLoading: false);
  }
}


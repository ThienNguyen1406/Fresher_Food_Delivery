import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/message_bubble.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/typing_indicator.dart';
import 'package:intl/intl.dart';

/// Widget hiển thị danh sách messages
class MessagesList extends StatelessWidget {
  final ScrollController scrollController;
  final ValueNotifier<List<Message>> messagesNotifier;
  final ValueNotifier<bool> isLoadingMoreNotifier;
  final ValueNotifier<bool> isWaitingForBotResponseNotifier;
  final double screenWidth;
  final DateFormat timeFormat;
  final Future<void> Function() onRefresh;

  const MessagesList({
    super.key,
    required this.scrollController,
    required this.messagesNotifier,
    required this.isLoadingMoreNotifier,
    required this.isWaitingForBotResponseNotifier,
    required this.screenWidth,
    required this.timeFormat,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.green.shade600,
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: isLoadingMoreNotifier,
            builder: (context, isLoadingMore, _) {
              if (!isLoadingMore) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                child: const CircularProgressIndicator(),
              );
            },
          ),
          Expanded(
            child: ValueListenableBuilder<List<Message>>(
              valueListenable: messagesNotifier,
              builder: (context, messages, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: isWaitingForBotResponseNotifier,
                  builder: (context, isWaiting, _) {
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      reverse: true,
                      itemCount: messages.length + (isWaiting ? 1 : 0),
                      cacheExtent: 2000,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        if (isWaiting && index == 0) {
                          return TypingIndicatorWidget(screenWidth: screenWidth);
                        }
                        final messageIndex = isWaiting ? index - 1 : index;
                        if (messageIndex < 0 || messageIndex >= messages.length) {
                          return const SizedBox.shrink();
                        }
                        final message = messages[messageIndex];
                        return MessageBubble(
                          key: ValueKey(message.maTinNhan),
                          message: message,
                          screenWidth: screenWidth,
                          timeFormat: timeFormat,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


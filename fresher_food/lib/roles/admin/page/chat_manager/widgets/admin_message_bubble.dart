import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:intl/intl.dart';
import 'admin_message_content.dart';

class AdminMessageBubble extends StatelessWidget {
  final Message message;
  final List<Message> allMessages;
  final ThemeData theme;

  const AdminMessageBubble({
    super.key,
    required this.message,
    required this.allMessages,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isFromAdmin = message.isFromAdmin;
    final isFromUser = message.isFromUser;
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final messageDate = message.ngayGui;
    final isToday = messageDate.year == now.year && 
                    messageDate.month == now.month && 
                    messageDate.day == now.day;
    
    // Tính thời gian phản hồi nếu đây là tin nhắn từ admin (phản hồi)
    String? responseTimeText;
    if (isFromAdmin && allMessages.isNotEmpty) {
      // Tìm tin nhắn user gần nhất trước tin nhắn này
      final messageIndex = allMessages.indexOf(message);
      if (messageIndex > 0) {
        for (int i = messageIndex - 1; i >= 0; i--) {
          if (allMessages[i].isFromUser) {
            final userMessageTime = allMessages[i].ngayGui;
            final responseTime = messageDate.difference(userMessageTime);
            if (responseTime.inSeconds < 60) {
              responseTimeText = '${responseTime.inSeconds}s';
            } else if (responseTime.inMinutes < 60) {
              responseTimeText = '${responseTime.inMinutes} phút';
            } else if (responseTime.inHours < 24) {
              responseTimeText = '${responseTime.inHours} giờ';
            } else {
              responseTimeText = '${responseTime.inDays} ngày';
            }
            break;
          }
        }
      }
    }

    return Align(
      alignment: isFromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisAlignment:
              isFromAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isFromAdmin) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFromAdmin
                      ? theme.primaryColor
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight: isFromAdmin ? const Radius.circular(4) : null,
                    bottomLeft: !isFromAdmin ? const Radius.circular(4) : null,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminMessageContent(
                      messageText: message.noiDung,
                      isFromAdmin: isFromAdmin,
                      isFromUser: isFromUser,
                      theme: theme,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isToday 
                              ? timeFormat.format(messageDate)
                              : '${dateFormat.format(messageDate)} ${timeFormat.format(messageDate)}',
                          style: TextStyle(
                            color: isFromAdmin
                                ? Colors.white70
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (responseTimeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFromAdmin 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⏱️ $responseTimeText',
                              style: TextStyle(
                                color: isFromAdmin
                                    ? Colors.white
                                    : Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isFromAdmin) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.support_agent,
                  size: 16,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


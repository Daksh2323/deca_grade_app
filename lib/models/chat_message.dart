import 'dart:typed_data';

enum MessageSender { user, aria }

enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;
  final String? subject;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.subject,
    this.imageBytes,
  });

  ChatMessage copyWith({String? text, MessageStatus? status}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      sender: sender,
      timestamp: timestamp,
      status: status ?? this.status,
      subject: subject,
      imageBytes: imageBytes,
    );
  }
}

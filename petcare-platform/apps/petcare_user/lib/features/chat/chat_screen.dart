import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';

class ChatMessageVm {
  final String senderId;
  final String text;
  final DateTime sentAt;
  ChatMessageVm({required this.senderId, required this.text, required this.sentAt});

  factory ChatMessageVm.fromJson(Map<String, dynamic> json) => ChatMessageVm(
        senderId: json['senderId'],
        text: json['text'],
        sentAt: DateTime.parse(json['sentAt']),
      );
}

class ChatScreen extends StatefulWidget {
  final Booking booking;
  const ChatScreen({super.key, required this.booking});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late BookingSocket _socket;
  final _messages = <ChatMessageVm>[];
  final _controller = TextEditingController();
  String? _myId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final me = await _api.post('/auth/me');
    _myId = me.data['id'];

    _socket = BookingSocket(baseUrl: ApiConfig.baseUrl, namespace: 'chat', bookingId: widget.booking.id);
    _socket.socket.on('message:new', (data) {
      setState(() => _messages.add(ChatMessageVm.fromJson(data)));
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _myId == null) return;
    _socket.socket.emit('message:send', {
      'bookingId': widget.booking.id,
      'senderId': _myId,
      'text': text,
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.booking.otherPartyName ?? 'Provider'}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isMe = m.senderId == _myId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

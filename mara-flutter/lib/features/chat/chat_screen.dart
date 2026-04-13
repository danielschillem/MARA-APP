import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

const _wsBase = 'ws://10.0.2.2:8081/api/ws'; // Android emulator → host

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();

  int? _convId;
  String? _sessionToken;
  bool _loading = true;
  bool _closed = false;
  List<_Msg> _messages = [];
  WebSocketChannel? _ws;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ws?.sink.close();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Init conversation ─────────────────────────────────────────────────────

  Future<void> _start() async {
    try {
      final data = await _api.startAnonymousChat();
      _convId = data['id'] as int?;
      _sessionToken =
          data['token'] as String? ?? data['session_token'] as String?;

      // Load existing messages
      if (_convId != null) {
        final msgs = await _api.getMessages(_convId!);
        setState(() {
          _messages = msgs.map((m) => _Msg.fromJson(m)).toList();
          _loading = false;
        });
        _connectWS();
        _scrollToBottom();
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  void _connectWS() {
    if (_convId == null) return;
    final uri = Uri.parse('$_wsBase?room=conv:$_convId');
    _ws = WebSocketChannel.connect(uri);

    _ws!.stream.listen(
      (raw) {
        try {
          final event = jsonDecode(raw as String) as Map<String, dynamic>;
          if (event['type'] == 'new_message') {
            final msg = _Msg.fromJson(event['payload'] as Map<String, dynamic>);
            // Deduplicate
            if (!_messages.any((m) => m.id == msg.id)) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          }
        } catch (_) {}
      },
      onDone: () {
        if (!_closed && mounted) {
          // Reconnect after delay
          Future.delayed(const Duration(seconds: 3), _connectWS);
        }
      },
    );
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _send() async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty || _convId == null) return;
    _msgCtrl.clear();

    final tempMsg = _Msg(
      id: -DateTime.now().millisecondsSinceEpoch,
      body: body,
      isFromVisitor: true,
      createdAt: DateTime.now(),
      pending: true,
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      await _api.sendMessage(_convId!, body, _sessionToken ?? '');
      // Real message arrives via WS; remove temp if it hasn't been deduped yet
      setState(() => _messages.removeWhere((m) => m.id == tempMsg.id));
    } catch (_) {
      setState(() {
        _messages.removeWhere((m) => m.id == tempMsg.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur d\'envoi, veuillez réessayer.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Discussion confidentielle',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(
              _closed ? 'Discussion fermée' : 'Conseiller disponible',
              style: TextStyle(
                fontSize: 11,
                color: _closed ? AppColors.muted : AppColors.green,
              ),
            ),
          ],
        ),
        actions: [
          if (!_closed)
            TextButton(
              onPressed: _endChat,
              child: const Text('Terminer',
                  style: TextStyle(color: AppColors.red, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green.withValues(alpha: .3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outlined,
                          color: AppColors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cette discussion est confidentielle et anonyme. '
                          'Un conseiller MARA vous répondra sous peu.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.green),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _BubbleWidget(msg: _messages[i]),
                  ),
                ),

                // Input
                if (!_closed)
                  _InputBar(
                    controller: _msgCtrl,
                    onSend: _send,
                  ),

                if (_closed)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.redLight,
                    child: Text(
                      'Discussion terminée. Merci de nous avoir contacté.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _endChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminer la discussion ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Terminer', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _ws?.sink.close();
      setState(() => _closed = true);
    }
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  const _BubbleWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isVisitor = msg.isFromVisitor;
    return Align(
      alignment: isVisitor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
        decoration: BoxDecoration(
          color: isVisitor ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isVisitor ? 16 : 4),
            bottomRight: Radius.circular(isVisitor ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isVisitor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.body,
              style: TextStyle(
                color: isVisitor ? Colors.white : AppColors.ink,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isVisitor ? Colors.white54 : AppColors.muted,
                  ),
                ),
                if (msg.pending) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Votre message…',
                hintStyle: TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _Msg {
  final int id;
  final String body;
  final bool isFromVisitor;
  final DateTime createdAt;
  final bool pending;

  _Msg({
    required this.id,
    required this.body,
    required this.isFromVisitor,
    required this.createdAt,
    this.pending = false,
  });

  factory _Msg.fromJson(Map<String, dynamic> j) => _Msg(
        id: j['id'] as int? ?? 0,
        body: j['body'] as String? ?? '',
        isFromVisitor: j['is_from_visitor'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

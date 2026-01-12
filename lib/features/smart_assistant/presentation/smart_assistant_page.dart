import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../smart_assistant/data/smart_assistant_service.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

class SmartAssistantPage extends ConsumerStatefulWidget {
  const SmartAssistantPage({super.key});

  @override
  ConsumerState<SmartAssistantPage> createState() => _SmartAssistantPageState();
}

class _SmartAssistantPageState extends ConsumerState<SmartAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  void _send(String text, {required Future<Stream<Candidates>> Function() apiCall}) async {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final stream = await apiCall();
      String fullResponse = "";

      // Add a placeholder for AI response
      setState(() {
        _messages.add(ChatMessage(text: "...", isUser: false));
      });
      final responseIndex = _messages.length - 1;

      stream.listen(
        (event) {
          final part =
              event.content?.parts?.fold("", (previous, current) {
                final text = (current as dynamic).text ?? "";
                return "$previous $text";
              }) ??
              "";
          fullResponse += part;

          setState(() {
            _messages[responseIndex] = ChatMessage(text: fullResponse, isUser: false);
          });
        },
        onDone: () {
          setState(() => _isLoading = false);
        },
        onError: (e) {
          setState(() {
            _messages[responseIndex] = ChatMessage(text: "Error: $e", isUser: false);
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error starting chat: $e", isUser: false));
        _isLoading = false;
      });
    }
  }

  void _handleInventoryAnalysis() {
    _send("Analisis Stok & Inventaris", apiCall: () => ref.read(smartAssistantServiceProvider).analyzeInventory(""));
  }

  void _handleHRAnalysis() {
    _send("Analisis Karyawan & Absensi", apiCall: () => ref.read(smartAssistantServiceProvider).analyzeHR(""));
  }

  void _handleCustomChat() {
    final text = _controller.text;
    if (text.isEmpty) return;
    _send(text, apiCall: () => ref.read(smartAssistantServiceProvider).chat(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Smart Assistant'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() => _messages.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.inventory_2, size: 16),
                  label: const Text('Analisis Stok'),
                  onPressed: _isLoading ? null : _handleInventoryAnalysis,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.people, size: 16),
                  label: const Text('Analisis HR & Absen'),
                  onPressed: _isLoading ? null : _handleHRAnalysis,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.deepPurple : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: !msg.isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: msg.isUser
                        ? Text(msg.text, style: const TextStyle(color: Colors.white, height: 1.4))
                        : MarkdownBody(data: msg.text),
                  ),
                );
              },
            ),
          ),

          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(minHeight: 2)),

          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Tanya AI...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _handleCustomChat(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _isLoading ? null : _handleCustomChat, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

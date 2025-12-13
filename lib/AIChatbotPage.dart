import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIChatbotPage extends StatefulWidget {
  const AIChatbotPage({super.key});

  @override
  State<AIChatbotPage> createState() => _AIChatbotPageState();
}

class _AIChatbotPageState extends State<AIChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  bool _greetingInitialized = false;
  bool _quickExpanded = false;

  final List<String> _questionsEn = const [
    "I have headache and blurry vision",
    "I feel strong abdominal pain",
    "I missed one dose of my medicine",
    "I feel reduced baby movements",
    "What can HEAL APP do for me?",
    "How do medication reminders work?",
    "Is HEAL APP replacing my doctor?",
    "When should I talk to a doctor online?",
  ];

  final List<String> _questionsAr = const [
    "أشعر بصداع وتشوش في الرؤية",
    "أشعر بألم قوي في البطن",
    "نسيت أخذ جرعة واحدة من الدواء",
    "أشعر بأن حركة الجنين أقل من المعتاد",
    "ما الذي يقدمه تطبيق HEAL لي؟",
    "كيف تعمل تذكيرات الأدوية؟",
    "هل تطبيق HEAL بديل عن الطبيب؟",
    "متى أحتاج استشارة طبيب أونلاين؟",
  ];

  bool get isArabic =>
      Localizations.localeOf(context).languageCode.startsWith('ar');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_greetingInitialized) {
      _addBotMessage(
        isArabic
            ? "🤖 مساعد HEAL\n\n"
            "مرحبًا بك! يمكنك كتابة سؤالك باللغة العربية أو الإنجليزية.\n"
            "أنا أساعد فقط في مواضيع الحمل، الصحة، والأدوية.\n\n"
            "⚠️ لا أقدّم تشخيصًا طبيًا."
            : "🤖 HEAL Assistant\n\n"
            "Welcome! You can ask in Arabic or English.\n"
            "I help with pregnancy, health, and medications only.\n\n"
            "⚠️ I do not provide medical diagnosis.",
      );

      _greetingInitialized = true;
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({"sender": "bot", "message": text});
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({"sender": "user", "message": text});
    });
  }

  Future<void> _sendMessage([String? preset]) async {
    final message = (preset ?? _controller.text).trim();
    if (message.isEmpty || _isSending) return;

    _controller.clear();
    _addUserMessage(message);
    setState(() => _isSending = true);

    try {
      final history = _messages
          .take(10)
          .map((m) => {
        "role": m["sender"] == "user" ? "user" : "assistant",
        "content": m["message"],
      })
          .toList();

      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/health-chat"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({
          "message": message,
          "language": isArabic ? "ar" : "en", // ✅ دعم اللغة
          "history": history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _addBotMessage(data["reply"] ?? "—");
      } else {
        _addBotMessage(isArabic
            ? "تعذر الاتصال بالخادم."
            : "Could not connect to server.");
      }
    } catch (_) {
      _addBotMessage(isArabic
          ? "حدث خطأ في الاتصال."
          : "Connection error.");
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _bubble({
    required String text,
    required bool isUser,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.purple : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = isArabic ? _questionsAr : _questionsEn;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1FF),
      appBar: AppBar(
        title: Text(isArabic ? "مساعد HEAL" : "HEAL Assistant"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return _bubble(
                  text: m["message"],
                  isUser: m["sender"] == "user",
                );
              },
            ),
          ),

          /// الأسئلة السريعة
          ExpansionTile(
            title: Text(isArabic ? "أسئلة سريعة" : "Quick Questions"),
            children: questions
                .map(
                  (q) => ListTile(
                title: Text(
                  q,
                  textAlign:
                  isArabic ? TextAlign.right : TextAlign.left,
                ),
                onTap: () => _sendMessage(q),
              ),
            )
                .toList(),
          ),

          /// الإدخال
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textDirection:
                    isArabic ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: isArabic
                          ? "اكتبي سؤالك هنا..."
                          : "Type your question...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
                  onPressed: _isSending ? null : _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

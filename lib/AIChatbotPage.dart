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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_greetingInitialized) {
      final isArabic = Localizations.localeOf(context)
          .languageCode
          .toLowerCase()
          .startsWith('ar');

      final greeting = isArabic
          ? "🤖 مساعد HEAL\n\n"
          "مرحبًا بك! أنا هنا لمساعدتك في مواضيع الحمل، الصحة، والأدوية فقط.\n"
          "يمكنك كتابة الأعراض أو اختيار أحد الأسئلة السريعة.\n\n"
          "⚠️ لا أقدّم تشخيصًا طبيًا أو وصفات علاجية. اتبعي نصائح طبيبك دائمًا."
          : "🤖 HEAL Assistant\n\n"
          "Welcome! I’m here to help you with pregnancy, health, and medications only.\n"
          "You can type your symptoms or choose one of the quick questions.\n\n"
          "⚠️ I cannot diagnose or prescribe. Always follow your doctor’s advice.";

      _addBotMessage(greeting);
      _greetingInitialized = true;
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({
        "sender": "bot",
        "message": text,
      });
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({
        "sender": "user",
        "message": text,
      });
    });
  }

  Future<void> _sendMessage([String? preset]) async {
    final isArabic = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('ar');

    final userMessage = (preset ?? _controller.text).trim();
    if (userMessage.isEmpty || _isSending) return;

    _controller.clear();
    _addUserMessage(userMessage);
    setState(() => _isSending = true);

    try {
      final history = _messages
          .take(10)
          .map((m) => {
        "role": m["sender"] == "user" ? "user" : "assistant",
        "content": m["message"],
      })
          .toList();

      final url = Uri.parse("http://10.0.2.2:8080/health-chat");

      const modeString = "faq";

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mode": modeString,
          "message": userMessage,
          "history": history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data["reply"] as String? ??
            (isArabic
                ? "عذرًا، لم أتمكن من توليد رد. حاول مرة أخرى."
                : "Sorry, I could not generate a response.");
        _addBotMessage(botReply);
      } else {
        _addBotMessage(isArabic
            ? "عذرًا، لا يمكن الوصول إلى خادم HEAL (خطأ ${response.statusCode})."
            : "Sorry, I could not reach the HEAL server (error ${response.statusCode}).");
      }
    } catch (e) {
      _addBotMessage(isArabic
          ? "حدثت مشكلة في الاتصال بخادم HEAL. الرجاء المحاولة لاحقًا."
          : "There was a problem connecting to the HEAL backend. Please try again.");
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _buildBotBubble(String text, bool isArabic) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple.shade100,
              child: const Icon(Icons.health_and_safety,
                  size: 18, color: Colors.purple),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.4),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text, bool isArabic) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('ar');

    final questions = isArabic ? _questionsAr : _questionsEn;
    final background = const Color(0xFFF7F1FF);

    final quickTitle = isArabic ? "أسئلة سريعة" : "Quick Questions";
    final hintText =
    isArabic ? "اكتبي الأعراض أو سؤالك هنا..." : "Type your symptoms or question...";
    final appBarTitle = isArabic ? "مساعد شات الشفاء" : "HEAL Chatbot";

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg['sender'] == "user";
                          return isUser
                              ? _buildUserBubble(msg['message'] as String, isArabic)
                              : _buildBotBubble(msg['message'] as String, isArabic);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    onExpansionChanged: (expanded) {
                      setState(() => _quickExpanded = expanded);
                    },
                    title: Text(
                      quickTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    trailing: Icon(
                      _quickExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.purple,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      Column(
                        crossAxisAlignment:
                        isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: questions.map((q) {
                          return InkWell(
                            onTap: () => _sendMessage(q),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  if (!isArabic)
                                    Text(
                                      "• ",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.purple.shade600,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      q,
                                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  if (isArabic)
                                    Text(
                                      " •",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.purple.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: hintText,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.purple,
                        shape: const CircleBorder(),
                        elevation: 3,
                      ),
                      onPressed: _isSending ? null : _sendMessage,
                      child: _isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.send, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

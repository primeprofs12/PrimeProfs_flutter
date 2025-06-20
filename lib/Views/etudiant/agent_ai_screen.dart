import 'package:flutter/material.dart';
import 'package:primeprof/models/ai_agent_message.dart';
import 'package:primeprof/view_models/ai_agent_view_model.dart';
import 'package:primeprof/view_models/login_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AgentAIScreen extends StatelessWidget {
  final String email;
  final String password;

  const AgentAIScreen({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('AgentAIScreen: Email: $email, Password: $password');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => AiAgentViewModel()),
      ],
      child: _AgentAIChat(email: email, password: password),
    );
  }
}

class _AgentAIChat extends StatefulWidget {
  final String email;
  final String password;

  const _AgentAIChat({required this.email, required this.password});

  @override
  State<_AgentAIChat> createState() => _AgentAIChatState();
}

class _AgentAIChatState extends State<_AgentAIChat> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, String> _summary = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Initialize login and AI agent session
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
    loginViewModel.login(widget.email, widget.password).then((authResponse) async {
      if (authResponse != null) {
        final sessionId = await loginViewModel.getSessionId();
        debugPrint('AgentAIScreen: Retrieved Session ID: $sessionId');
        if (sessionId != null) {
          final aiAgentViewModel = Provider.of<AiAgentViewModel>(context, listen: false);
          aiAgentViewModel.startConversation(sessionId);
        } else {
          debugPrint('AgentAIScreen: Session ID not found after login.');
        }
      } else {
        debugPrint('AgentAIScreen: Login failed.');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(AiAgentMessage message) {
    debugPrint('AgentAIScreen: Rendering message - Sender: ${message.sender}, Message: ${message.message}, Time: ${message.time}');
    final theme = Theme.of(context);
    bool isUserMessage = message.sender == 'You';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Align(
          alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isUserMessage
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateSummary(AiAgentMessage userMessage) {
    final messageText = userMessage.message.toLowerCase();
    if (messageText.contains('lancer')) {
      _summary['Statut'] = 'Démarré';
    } else if (messageText.contains('mathématiques') ||
        messageText.contains('physique') ||
        messageText.contains('anglais') ||
        messageText.contains('français') ||
        messageText.contains('autre')) {
      _summary['Matière'] = userMessage.message;
    } else if (messageText.contains('primaire') ||
        messageText.contains('collège') ||
        messageText.contains('lycée') ||
        messageText.contains('université')) {
      _summary['Classe'] = userMessage.message;
    } else if (messageText.contains('structuré') ||
        messageText.contains('ludique') ||
        messageText.contains('interactif') ||
        messageText.contains('aucune')) {
      _summary['Style d’enseignement'] = userMessage.message;
    } else if (messageText.contains('intensif') ||
        messageText.contains('hebdomadaire') ||
        messageText.contains('aucune préférence')) {
      _summary['Rythme'] = userMessage.message;
    }
  }

  Widget _buildConfirmationButtons(AiAgentViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  debugPrint('AgentAIScreen: Sending selected option: Oui');
                  viewModel.sendMessage('Oui');
                  setState(() {}); // Refresh to show the next message
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 2),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Oui',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  debugPrint('AgentAIScreen: Sending selected option: Non');
                  viewModel.sendMessage('Non');
                  setState(() {}); // Refresh to show the next message
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 2),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Non',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AiAgentViewModel viewModel) {
    // Check if the last message is a summary
    final lastMessage = viewModel.messages.isNotEmpty ? viewModel.messages.last : null;
    bool isSummaryStep = lastMessage != null && lastMessage.sender == 'Agent AI' &&
        lastMessage.message.toLowerCase().contains('résumé');

    if (isSummaryStep) {
      return _buildConfirmationButtons(viewModel);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message',
                        hintStyle: TextStyle(
                          color: Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                      onSubmitted: (_) => _handleSendMessage(viewModel),
                    ),
                  ),
                  if (viewModel.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () => _handleSendMessage(viewModel),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendMessage(AiAgentViewModel viewModel) {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      debugPrint('AgentAIScreen: Sending message: $message');
      final userMessage = AiAgentMessage(
        sender: 'You',
        message: message,
        time: DateFormat('HH:mm').format(DateTime.now()),
      );
      _updateSummary(userMessage);
      viewModel.sendMessage(message);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiAgentViewModel>(
      builder: (context, viewModel, child) {
        debugPrint('AgentAIScreen: Messages count: ${viewModel.messages.length}');
        if (viewModel.messages.isEmpty) {
          debugPrint('AgentAIScreen: No messages to display.');
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Assistant Pédagogique",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Aucun message pour l'instant.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                _buildInputArea(viewModel),
              ],
            ),
          );
        }

        for (var message in viewModel.messages) {
          debugPrint('AgentAIScreen: Message in list - Sender: ${message.sender}, Content: ${message.message}');
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Assistant Pédagogique",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    key: ValueKey(viewModel.messages.length),
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.messages.length,
                    itemBuilder: (context, index) {
                      final message = viewModel.messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
              ),
              _buildInputArea(viewModel),
            ],
          ),
        );
      },
    );
  }
}
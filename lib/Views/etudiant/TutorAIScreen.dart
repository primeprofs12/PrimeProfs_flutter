import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:primeprof/Views/etudiant/student_drawer.dart';
import 'package:primeprof/services/apii_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import '../UserManagement/login_screen.dart';
import 'List_chat.dart';
import 'PaymentScreen.dart';
import 'ResourceScreen.dart';
import 'StudentScreen.dart';

class TutorAIScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const TutorAIScreen({super.key, required this.cameras});

  @override
  _TutorAIScreenState createState() => _TutorAIScreenState();
}

class _TutorAIScreenState extends State<TutorAIScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ApiiService _apiService = ApiiService();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isLoading = false;

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

    _messages.add({
      'time': 'Assistant ${_formatTime(DateTime.now())}',
      'message':
          'Bienvenue sur TutoIA. Je suis ici pour vous aider avec vos cours. Choisissez un sujet ou posez une question !',
    });

    if (widget.cameras.isNotEmpty) {
      _cameraController =
          CameraController(widget.cameras[0], ResolutionPreset.high);
      _initCamera();
    } else {
      _messages.add({
        'time': 'Système ${_formatTime(DateTime.now())}',
        'message': 'Aucune caméra disponible sur cet appareil.',
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _cameraController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de la caméra : $e');
      if (mounted) {
        _messages.add({
          'time': 'Système ${_formatTime(DateTime.now())}',
          'message': 'Erreur lors de l\'initialisation de la caméra : $e',
        });
      }
    }
  }

  Future<void> _checkCameraPermissionAndScan(BuildContext context) async {
    if (_cameraController == null &&
        !(await Permission.storage.request().isGranted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Aucune caméra disponible et accès à la galerie refusé.')),
      );
      return;
    }
    if (await Permission.camera.request().isGranted ||
        await Permission.storage.request().isGranted) {
      await _showImageSourceDialog(context);
    } else {
      _showPermissionDialog(context);
    }
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Autorisation requise'),
        content: Text(
          'Voulez-vous autoriser l\'accès à la caméra et à la galerie pour scanner un exercice ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Non, passer au chat'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool cameraGranted = await Permission.camera.request().isGranted;
              bool storageGranted =
                  await Permission.storage.request().isGranted;
              if (cameraGranted || storageGranted) {
                await _showImageSourceDialog(context);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Autorisation refusée.')),
                  );
                }
              }
            },
            child: Text('Oui, autoriser'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cameraController != null)
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choisir une image depuis la galerie'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (result == 'camera' && mounted) {
      _takePhoto(context);
    } else if (result == 'gallery' && mounted) {
      _pickImage();
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    if (_cameraController == null || !_isCameraInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Caméra non initialisée ou non disponible.')),
        );
      }
      return;
    }
    _showCameraPreview(context);
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        await _scanAndSendExerciseFromImage(XFile(image.path));
      } else if (image == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aucune image sélectionnée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la sélection de l\'image : $e')),
        );
      }
    }
  }

  void _showCameraPreview(BuildContext context) {
    if (_cameraController == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: double.infinity,
          height: 400,
          child: _isCameraInitialized
              ? Column(
                  children: [
                    Expanded(child: CameraPreview(_cameraController!)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Assurez-vous que l\'image est nette pour un meilleur scan.',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (mounted) await _scanAndSendExercise();
                      },
                      child: Text('Capturer'),
                    ),
                  ],
                )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _scanAndSendExerciseFromImage(XFile image) async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
      _messages.add({
        'time': 'Vous ${_formatTime(DateTime.now())}',
        'message': 'Scan en cours...',
      });
      _scrollToBottom();
    });

    String extractedText = await _processTextInIsolate(image.path);
    if (mounted) {
      if (extractedText.isEmpty) {
        setState(() {
          _messages.last['message'] = 'Aucun texte détecté dans l\'image.';
        });
      } else {
        setState(() {
          _messages.last['message'] = 'Exercice scanné : $extractedText';
        });
        await _sendToApi('Résous l\'exercice suivant : $extractedText');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAndSendExercise() async {
    if (_isLoading || !mounted || _cameraController == null) return;

    setState(() {
      _isLoading = true;
      _messages.add({
        'time': 'Vous ${_formatTime(DateTime.now())}',
        'message': 'Scan en cours...',
      });
      _scrollToBottom();
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      String extractedText = await _processTextInIsolate(image.path);
      if (mounted) {
        if (extractedText.isEmpty) {
          setState(() {
            _messages.last['message'] = 'Aucun texte détecté dans l\'image.';
          });
        } else {
          setState(() {
            _messages.last['message'] = 'Exercice scanné : $extractedText';
          });
          await _sendToApi('Résous l\'exercice suivant : $extractedText');
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'time': 'IA ${_formatTime(DateTime.now())}',
            'message': 'Erreur : $e',
            'retry': true,
          });
          _isLoading = false;
          _scrollToBottom();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du traitement de l\'exercice.')),
        );
      }
    }
  }

  Future<String> _processTextInIsolate(String imagePath) async {
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(
      _textRecognitionIsolate,
      [receivePort.sendPort, imagePath, RootIsolateToken.instance!],
    );
    return await receivePort.first as String;
  }

  static void _textRecognitionIsolate(List<dynamic> args) async {
    final SendPort sendPort = args[0] as SendPort;
    final String imagePath = args[1] as String;
    final RootIsolateToken rootIsolateToken = args[2] as RootIsolateToken;

    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      Isolate.exit(sendPort, recognizedText.text);
    } catch (e) {
      Isolate.exit(sendPort, 'Erreur lors de la reconnaissance : $e');
    }
  }

  Future<void> _sendToApi(String prompt) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.sendPrompt(prompt);
      if (mounted) {
        setState(() {
          _messages.add({
            'time': 'IA ${_formatTime(DateTime.now())}',
            'message': response,
            'retry': false,
          });
          _isLoading = false;
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'time': 'IA ${_formatTime(DateTime.now())}',
            'message': 'Erreur : $e',
            'retry': true,
            'prompt': prompt,
          });
          _isLoading = false;
          _scrollToBottom();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la requête à l\'IA.')),
        );
      }
    }
  }

  void _addMessage(String message) async {
    if (_isLoading || !mounted || message.isEmpty) return;

    setState(() {
      _messages.add({
        'time': 'Vous ${_formatTime(DateTime.now())}',
        'message': 'Question saisie : $message',
        'retry': false,
      });
      _isLoading = true;
      _scrollToBottom();
    });

    await _sendToApi(message);
    _textController.clear();
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  int _selectedIndex = 3;

  void _onItemTapped(int index, BuildContext context) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    if (index == 5) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MessagesScreenE(name: '')),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResourceScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => TutorAIScreen(cameras: widget.cameras)),
      );
    } else if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EtudiantScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'Tuteur IA',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            if (_scaffoldKey.currentState != null) {
              _scaffoldKey.currentState!.openDrawer();
            }
          },
        ),
      ),
      drawer: StudentDrawer(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => _onItemTapped(index, context),
      ),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.grey[100],
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(
                      _messages[index]['time']!,
                      _messages[index]['message']!,
                      _messages[index]['retry'] ?? false,
                      _messages[index]['prompt'],
                    );
                  },
                ),
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      String time, String message, bool retry, String? prompt) {
    bool isUserMessage = time.startsWith('Vous');
    bool isError = message.startsWith('Erreur :');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage)
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
          if (!isUserMessage) SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? Colors.blueAccent
                    : isError
                        ? Colors.red[100]
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: isUserMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUserMessage ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  isError
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red[900],
                              ),
                            ),
                            if (retry)
                              TextButton(
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = true;
                                      _messages.removeAt(_messages.length - 1);
                                    });
                                    _sendToApi(prompt!);
                                  }
                                },
                                child: Text(
                                  'Réessayer',
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                              ),
                          ],
                        )
                      : MarkdownBody(
                          data: message,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 16,
                              color:
                                  isUserMessage ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          if (isUserMessage) SizedBox(width: 8),
          if (isUserMessage)
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Posez votre question ici...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.document_scanner, color: Colors.blueAccent),
                    onPressed: _isLoading
                        ? null
                        : () => _checkCameraPermissionAndScan(context),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          Material(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(30),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_textController.text.isNotEmpty && mounted) {
                        _addMessage(_textController.text);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

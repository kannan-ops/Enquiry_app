import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enquiry_app/utils/api_debug_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AttachmentStatus { pending, uploading, success, failed }

class AttachmentItem {
  final String id;
  final String name;
  final String path;
  final String type; // 'image', 'video', 'audio', 'document', 'contact', 'location', 'url'
  final String size;
  double progress;
  AttachmentStatus status;
  Timer? timer;

  AttachmentItem({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.progress = 0.0,
    this.status = AttachmentStatus.pending,
    this.timer,
  });
}

class ChatScreen extends StatefulWidget {
  final String module; // "product", "enquiry", "bulk_order"
  final int referenceId;
  final String userName;
  final String? userPhone;
  final String? initialMessage;
  final List<String>? initialSharedFiles;
  final String? initialSharedText;
  final int? userId;

  const ChatScreen({
    super.key,
    required this.module,
    required this.referenceId,
    required this.userName,
    this.userPhone,
    this.initialMessage,
    this.initialSharedFiles,
    this.initialSharedText,
    this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  final List<AttachmentItem> _attachments = [];

  @override
  void initState() {
    super.initState();
    _saveLastChat();

    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    }
    
    _fetchMessages();

    // Attach shared files if passed from share intent
    if (widget.initialSharedFiles != null && widget.initialSharedFiles!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (var path in widget.initialSharedFiles!) {
          _attachFileFromPath(path);
        }
      });
    }

    // Attach shared text/url if passed from share intent
    if (widget.initialSharedText != null && widget.initialSharedText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final text = widget.initialSharedText!;
        if (text.startsWith("http://") || text.startsWith("https://")) {
          _attachUrlShare(text);
        } else {
          _messageController.text = text;
        }
      });
    }
  }

  Future<void> _saveLastChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_chat_module', widget.module);
      await prefs.setInt('last_chat_reference_id', widget.referenceId);
      await prefs.setString('last_chat_user_name', widget.userName);
      if (widget.userPhone != null) {
        await prefs.setString('last_chat_user_phone', widget.userPhone!);
      }
    } catch (_) {}
  }

  String _getFileSizeString(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes).toString().length - 1;
    var index = (i / 3).floor();
    var num = bytes / (1 << (10 * index));
    return "${num.toStringAsFixed(1)} ${suffixes[index]}";
  }

  String _getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'mkv', 'avi', '3gp'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(ext)) return 'audio';
    if (['pdf'].contains(ext)) return 'pdf';
    if (['vcf'].contains(ext)) return 'contact';
    return 'document';
  }

  void _attachFileFromPath(String path) {
    final file = File(path);
    if (!file.existsSync()) return;

    final name = path.split('/').last;
    final size = _getFileSizeString(file.lengthSync());
    final type = _getFileType(path);
    final id = DateTime.now().millisecondsSinceEpoch.toString() + "_" + name;

    final item = AttachmentItem(
      id: id,
      name: name,
      path: path,
      type: type,
      size: size,
      status: AttachmentStatus.uploading,
      progress: 0.0,
    );

    setState(() {
      _attachments.add(item);
    });

    _startUpload(item);
  }

  void _startUpload(AttachmentItem item) {
    item.timer?.cancel();
    item.status = AttachmentStatus.uploading;
    item.timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        item.progress += 0.1;
        if (item.progress >= 1.0) {
          item.progress = 1.0;
          item.status = AttachmentStatus.success;
          timer.cancel();
        }
      });
    });
  }

  void _attachUrlShare(String url) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = AttachmentItem(
      id: id,
      name: url,
      path: url,
      type: 'url',
      size: 'Link',
      status: AttachmentStatus.success,
      progress: 1.0,
    );
    setState(() {
      _attachments.add(item);
    });
  }

  Future<void> _shareLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final mapsUrl = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final item = AttachmentItem(
        id: id,
        name: "Shared Location",
        path: mapsUrl,
        type: 'location',
        size: "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
        status: AttachmentStatus.success,
        progress: 1.0,
      );
      setState(() {
        _attachments.add(item);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share location: $e")),
      );
    }
  }

  void _shareContact() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        return AlertDialog(
          title: const Text("Share Contact"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Contact Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  Navigator.pop(context);
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  final item = AttachmentItem(
                    id: id,
                    name: name,
                    path: phone,
                    type: 'contact',
                    size: 'Contact Card',
                    status: AttachmentStatus.success,
                    progress: 1.0,
                  );
                  setState(() {
                    _attachments.add(item);
                  });
                }
              },
              child: const Text("Share"),
            ),
          ],
        );
      },
    );
  }

  void _shareVoiceRecording() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            var isRecording = false;
            var duration = 0;
            Timer? recTimer;

            void startRec() {
              setModalState(() {
                isRecording = true;
              });
              recTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setModalState(() {
                  duration++;
                });
              });
            }

            void stopRec() {
              recTimer?.cancel();
              Navigator.pop(context);
              if (duration > 0) {
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                final item = AttachmentItem(
                  id: id,
                  name: "Voice Record ${duration}s.mp3",
                  path: "simulated_voice_record",
                  type: 'audio',
                  size: "${(duration * 16).toStringAsFixed(0)} KB",
                  status: AttachmentStatus.success,
                  progress: 1.0,
                );
                setState(() {
                  _attachments.add(item);
                });
              }
            }

            return Container(
              padding: const EdgeInsets.all(24),
              height: 250,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRecording ? "Recording Voice Message..." : "Voice Recorder",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (isRecording) ...[
                    Text("${duration}s", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: 20 + (index % 2 == 0 ? 15 : 5) * (duration % 2 == 0 ? 1.5 : 0.5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                  ] else ...[
                    const Icon(Icons.mic, size: 48, color: Colors.blue),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isRecording ? stopRec : startRec,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecording ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(isRecording ? "Stop & Attach" : "Start Recording"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Attachment Type",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildAttachmentMenuTile(
                    icon: Icons.image,
                    label: "Gallery",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildAttachmentMenuTile(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildAttachmentMenuTile(
                    icon: Icons.videocam,
                    label: "Video",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                  _buildAttachmentMenuTile(
                    icon: Icons.audiotrack,
                    label: "Audio",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAudio();
                    },
                  ),
                  _buildAttachmentMenuTile(
                    icon: Icons.mic,
                    label: "Voice",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _shareVoiceRecording();
                    },
                  ),
                  _buildAttachmentMenuTile(
                    icon: Icons.description,
                    label: "Document",
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
                    },
                  ),
                  _buildAttachmentMenuTile(
                    icon: Icons.person,
                    label: "Contact",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      _shareContact();
                    },
                  ),
                  _buildAttachmentMenuTile(
                    icon: Icons.location_on,
                    label: "Location",
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      _shareLocation();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentMenuTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source);
      if (file != null) {
        _attachFileFromPath(file.path);
      }
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        _attachFileFromPath(file.path);
      }
    } catch (_) {}
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        _attachFileFromPath(result.files.single.path!);
      }
    } catch (_) {}
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        _attachFileFromPath(result.files.single.path!);
      }
    } catch (_) {}
  }

  void _showEmojiPicker() {
    final emojis = ["😊", "😂", "❤️", "👍", "🔥", "🎉", "🚀", "💻", "👋", "👀", "🙌", "🎂", "🌟", "😎", "😜", "🙏"];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Emoji", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _messageController.text += emojis[index];
                        _messageController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _messageController.text.length),
                        );
                      },
                      child: Center(
                        child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<dynamic> _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map) {
      if (json.containsKey('data')) {
        final d = json['data'];
        if (d is List) return d;
        if (d is Map) {
          if (d.containsKey('data')) {
            final dd = d['data'];
            if (dd is List) return dd;
          }
          if (d.containsKey('messages')) {
            final dm = d['messages'];
            if (dm is List) return dm;
          }
        }
      }
      if (json.containsKey('messages')) {
        final m = json['messages'];
        if (m is List) return m;
      }
      for (var val in json.values) {
        if (val is List) return val;
        if (val is Map) {
          final sub = _extractList(val);
          if (sub.isNotEmpty) return sub;
        }
      }
    }
    return [];
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.userId != null && widget.userId! > 0) {
        var omnichannelUrl = "https://receivedchat.srivagroups.in/api/conversations/${widget.userId}";
        try {
          print("================== OMNICHANNEL API ==================");
          print("URL: $omnichannelUrl");
          final res = await ApiDebugLogger.httpClient.get(Uri.parse(omnichannelUrl)).timeout(const Duration(seconds: 6));
          print("STATUS CODE: ${res.statusCode}");
          print("RESPONSE: ${res.body}");
          print("====================================================");
          
          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            final dataObj = decoded['data'];
            List<dynamic> loadedMessages = [];
            if (dataObj != null && dataObj['messages'] != null) {
               loadedMessages = dataObj['messages'];
            }
            loadedMessages.sort((a, b) {
              final timeA = DateTime.tryParse((a["timestamp"] ?? a["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              final timeB = DateTime.tryParse((b["timestamp"] ?? b["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              return timeA.compareTo(timeB);
            });
            setState(() {
              _messages = loadedMessages;
            });
            _scrollToBottom();
            return;
          }
        } catch (e) {
          print("OMNICHANNEL API ERROR: $e");
        }
      }

      var url = "https://whatsapp.srivagroups.in/conversation.php?module=${widget.module}&reference_id=${widget.referenceId}";
      try {
        print("================== PHP API ==================");
        print("URL: $url");
        final res = await ApiDebugLogger.httpClient.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
        print("STATUS CODE: ${res.statusCode}");
        print("RESPONSE: ${res.body}");
        print("=============================================");
        
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final loadedMessages = _extractList(decoded);
          loadedMessages.sort((a, b) {
            final timeA = DateTime.tryParse((a["timestamp"] ?? a["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB = DateTime.tryParse((b["timestamp"] ?? b["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeA.compareTo(timeB);
          });
          setState(() {
            _messages = loadedMessages;
          });
          _scrollToBottom();
          return;
        }
      } catch (e) {
        print("PHP API ERROR: $e");
      }

      // Fallback URL
      url = "https://bulk.srivagroups.in/api/messages/${widget.module}/${widget.referenceId}";
      try {
        print("================== BULK API ==================");
        print("URL: $url");
        final res = await ApiDebugLogger.httpClient.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
        print("STATUS CODE: ${res.statusCode}");
        print("RESPONSE: ${res.body}");
        print("==============================================");
        
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final loadedMessages = _extractList(decoded);
          loadedMessages.sort((a, b) {
            final timeA = DateTime.tryParse((a["timestamp"] ?? a["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB = DateTime.tryParse((b["timestamp"] ?? b["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeA.compareTo(timeB);
          });
          setState(() {
            _messages = loadedMessages;
          });
          _scrollToBottom();
        }
      } catch (e) {
        print("BULK API ERROR: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    // Wait if any files are still uploading
    final hasUploading = _attachments.any((a) => a.status == AttachmentStatus.uploading);
    if (hasUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait for all attachments to finish uploading")),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    // Format attachments in the text
    String finalMessage = text;
    for (var att in _attachments) {
      if (att.status == AttachmentStatus.success) {
        finalMessage += "\n[Attachment: ${att.name}|${att.type}|${att.size}|${att.path}]";
      }
    }

    final url = "https://whatsapp.srivagroups.in/send.php";
    final body = {
      "module": widget.module,
      "reference_id": widget.referenceId,
      "sender": "admin",
      "message": finalMessage,
      "phone": widget.userPhone ?? "",
    };

    try {
      final res = await ApiDebugLogger.httpClient.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _messageController.clear();
        setState(() {
          _attachments.clear();
        });
        await _fetchMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: ${res.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error sending message. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _previewImage(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: path.startsWith("http")
                  ? Image.network(path)
                  : Image.file(File(path)),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playVideo(String name, String path) {
    showDialog(
      context: context,
      builder: (context) {
        var isPlaying = true;
        var playProgress = 0.3;
        return StatefulBuilder(
          builder: (context, setVideoState) {
            return AlertDialog(
              title: Text("Video: $name"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 200,
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.videocam : Icons.videocam_off,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: playProgress,
                    onChanged: (val) {
                      setVideoState(() {
                        playProgress = val;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setVideoState(() {
                            isPlaying = !isPlaying;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDocument(String path) async {
    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Document Link"),
            content: SelectableText(path),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  void _openLocation(String mapsUrl) async {
    final uri = Uri.parse(mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _viewContact(String name, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contact Card"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 40, color: Colors.teal),
                const SizedBox(width: 12),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text("Phone Number: $phone", style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final telUri = Uri.parse("tel:$phone");
              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri);
              }
            },
            child: const Text("Call"),
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleAttachmentTap(String name, String type, String path) {
    if (type == 'image') {
      _previewImage(path);
    } else if (type == 'video') {
      _playVideo(name, path);
    } else if (type == 'contact') {
      _viewContact(name, path);
    } else if (type == 'location') {
      _openLocation(path);
    } else if (type == 'url') {
      _openUrl(path);
    } else {
      _openDocument(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.userPhone != null && widget.userPhone!.isNotEmpty)
              Text(
                widget.userPhone!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            Text(
              "${widget.module.toUpperCase()} #${widget.referenceId}",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3B5BDB),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                "No messages yet",
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Type below and send a reply.",
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg["sender"] == "admin";
                            return _buildMessageBubble(msg["message"] ?? "", isMe, msg["created_at"]);
                          },
                        ),
            ),
            _buildAttachmentsPreviewBar(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _parseMessage(String rawMessage) {
    final regExp = RegExp(r'\n\n\[via:(.*?)\]$');
    final match = regExp.firstMatch(rawMessage);
    if (match != null) {
      final channelsStr = match.group(1) ?? "";
      final channels = channelsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final cleanMessage = rawMessage.substring(0, match.start);
      return {
        "message": cleanMessage,
        "channels": channels,
      };
    }
    return {
      "message": rawMessage,
      "channels": <String>[],
    };
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "";
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      int hour = dt.hour;
      final String period = hour >= 12 ? "PM" : "AM";
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final String hourStr = hour.toString().padLeft(2, '0');
      final String minuteStr = dt.minute.toString().padLeft(2, '0');
      return "$hourStr:$minuteStr $period";
    } catch (_) {
      return "";
    }
  }

  Widget _buildMessageBubble(String rawText, bool isMe, String? timeStr) {
    final parsed = _parseMessage(rawText);
    final String text = parsed["message"];
    final List<dynamic> channels = parsed["channels"];

    final attachmentRegExp = RegExp(r'\[Attachment:\s*(.*?)\s*\]');
    final matches = attachmentRegExp.allMatches(text);
    
    String displayText = text.replaceAll(attachmentRegExp, '').trim();
    if (displayText.isEmpty && matches.isNotEmpty) {
      displayText = "Sent attachment";
    }

    final attachmentWidgets = <Widget>[];
    for (var match in matches) {
      final partsStr = match.group(1) ?? "";
      final parts = partsStr.split('|');
      if (parts.length >= 4) {
        final name = parts[0];
        final type = parts[1];
        final size = parts[2];
        final path = parts[3];
        attachmentWidgets.add(_buildAttachmentCard(name, type, size, path, isMe));
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3B5BDB) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (displayText.isNotEmpty)
              Text(
                displayText,
                style: TextStyle(
                  color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            if (attachmentWidgets.isNotEmpty) ...attachmentWidgets,
            if (isMe && channels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: channels.map<Widget>((channel) {
                  IconData icon;
                  Color bgColor;
                  Color textColor;
                  final c = channel.toString().toLowerCase();
                  if (c == 'whatsapp') {
                    icon = Icons.chat_bubble_rounded;
                    bgColor = Colors.white.withOpacity(0.2);
                    textColor = Colors.white;
                  } else if (c == 'email') {
                    icon = Icons.email_rounded;
                    bgColor = Colors.white.withOpacity(0.2);
                    textColor = Colors.white;
                  } else if (c == 'sms') {
                    icon = Icons.sms_rounded;
                    bgColor = Colors.white.withOpacity(0.2);
                    textColor = Colors.white;
                  } else {
                    icon = Icons.send_rounded;
                    bgColor = Colors.white.withOpacity(0.2);
                    textColor = Colors.white;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 10, color: textColor),
                        const SizedBox(width: 4),
                        Text(
                          channel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMe && channels.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text(
                        "App Chat",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Text(
                    _formatTime(timeStr),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade500,
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

  Widget _buildAttachmentCard(String name, String type, String size, String path, bool isMe) {
    IconData icon;
    Color color;
    if (type == 'image') {
      icon = Icons.image;
      color = Colors.purple;
    } else if (type == 'video') {
      icon = Icons.videocam;
      color = Colors.orange;
    } else if (type == 'audio') {
      icon = Icons.audiotrack;
      color = Colors.blue;
    } else if (type == 'contact') {
      icon = Icons.person;
      color = Colors.teal;
    } else if (type == 'location') {
      icon = Icons.location_on;
      color = Colors.indigo;
    } else if (type == 'url') {
      icon = Icons.link;
      color = Colors.blueGrey;
    } else {
      icon = Icons.description;
      color = Colors.green;
    }

    final cardBgColor = isMe 
        ? Colors.white.withOpacity(0.12)
        : Theme.of(context).colorScheme.surface;

    final cardTextColor = isMe ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () => _handleAttachmentTap(name, type, path),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isMe ? Colors.white : color, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cardTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        size,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isMe ? Colors.white70 : Colors.grey.shade400,
                ),
              ],
            ),
            if (type == 'audio' && path != "simulated_voice_record" && File(path).existsSync()) ...[
              const SizedBox(height: 8),
              _AudioPlayerControlBar(filePath: path, isMe: isMe),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsPreviewBar() {
    if (_attachments.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final item = _attachments[index];
          IconData icon;
          Color color;
          if (item.type == 'image') {
            icon = Icons.image;
            color = Colors.purple;
          } else if (item.type == 'video') {
            icon = Icons.videocam;
            color = Colors.orange;
          } else if (item.type == 'audio') {
            icon = Icons.audiotrack;
            color = Colors.blue;
          } else if (item.type == 'contact') {
            icon = Icons.person;
            color = Colors.teal;
          } else if (item.type == 'location') {
            icon = Icons.location_on;
            color = Colors.indigo;
          } else if (item.type == 'url') {
            icon = Icons.link;
            color = Colors.blueGrey;
          } else {
            icon = Icons.description;
            color = Colors.green;
          }

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.size,
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          if (item.status == AttachmentStatus.uploading)
                            LinearProgressIndicator(
                              value: item.progress,
                              minHeight: 2,
                              color: color,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                            )
                          else
                            Text(
                              item.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: item.status == AttachmentStatus.success ? Colors.green : Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        item.timer?.cancel();
                        _attachments.removeAt(index);
                      });
                    },
                    child: const CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 8, color: Colors.white),
                    ),
                  ),
                ),
                if (item.status == AttachmentStatus.failed)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _startUpload(item),
                      child: const Icon(Icons.refresh, size: 14, color: Colors.blue),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF3B5BDB)),
              onPressed: _showAttachmentMenu,
            ),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
              onPressed: _showEmojiPicker,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B5BDB),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerControlBar extends StatefulWidget {
  final String filePath;
  final bool isMe;

  const _AudioPlayerControlBar({
    required this.filePath,
    required this.isMe,
  });

  @override
  State<_AudioPlayerControlBar> createState() => _AudioPlayerControlBarState();
}

class _AudioPlayerControlBarState extends State<_AudioPlayerControlBar> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });
    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });
    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.filePath));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isMe ? Colors.white : const Color(0xFF3B5BDB);
    final inactiveColor = widget.isMe ? Colors.white38 : Colors.grey.shade300;
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: activeColor,
            size: 28,
          ),
          onPressed: _togglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: activeColor,
              inactiveTrackColor: inactiveColor,
              thumbColor: activeColor,
            ),
            child: Slider(
              min: 0,
              max: _duration.inMilliseconds.toDouble() > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
              value: _position.inMilliseconds.toDouble() <= _duration.inMilliseconds.toDouble()
                  ? _position.inMilliseconds.toDouble()
                  : 0.0,
              onChanged: (val) {
                _audioPlayer.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),
        ),
      ],
    );
  }
}

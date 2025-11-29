import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../constants/colors.dart';
import '../services/mysql_service.dart';
import '../services/auth_service.dart';

class ProviderProfileEditScreen extends StatefulWidget {
  const ProviderProfileEditScreen({super.key});

  @override
  State<ProviderProfileEditScreen> createState() => _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends State<ProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String? _providerId;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    // Load provider ID
    _providerId = AuthService.currentUserProviderId ?? 'test_provider_001';

    // Load provider data from MySQL
    final provider = await MySQLService.instance.getProviderById(_providerId!);
    if (provider != null) {
      setState(() {
        _nameController.text = provider['name']?.toString() ?? '';
        _titleController.text = provider['title']?.toString() ?? '';
        _emailController.text = provider['email']?.toString() ?? '';
        _phoneController.text = provider['phone']?.toString() ?? '';
        _bioController.text = provider['bio']?.toString() ?? '';
        _profileImageUrl = provider['profile_image']?.toString();
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      print('=== Starting image pick ===');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      print('Picked file: ${pickedFile?.name}');
      if (pickedFile == null) {
        print('No file picked');
        return;
      }

      setState(() => _isLoading = true);
      print('Starting upload...');

      // Upload image to server
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://celesmile-demo.duckdns.org';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/profile-image'),
      );

      print('Reading file bytes...');
      final bytes = await pickedFile.readAsBytes();
      print('File size: ${bytes.length} bytes');

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: pickedFile.name,
      ));

      print('Sending request to /api/upload/profile-image');
      final response = await request.send();
      print('Response status code: ${response.statusCode}');

      final responseData = await response.stream.bytesToString();
      print('Response data: $responseData');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final imageUrl = jsonResponse['imageUrl'] as String;
        print('Image URL received: $imageUrl');

        setState(() {
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('プロフィール画像をアップロードしました'),
              backgroundColor: AppColors.primaryOrange,
            ),
          );
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('=== Upload error ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像アップロードに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('Saving profile for provider: $_providerId');
      print('Name: ${_nameController.text}');
      print('Title: ${_titleController.text}');
      print('Email: ${_emailController.text}');
      print('Phone: ${_phoneController.text}');
      print('Bio: ${_bioController.text}');
      print('Profile Image: $_profileImageUrl');

      // Save to database via API
      final success = await MySQLService.instance.updateProviderPublicProfile(
        _providerId!,
        {
          'name': _nameController.text,
          'title': _titleController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'bio': _bioController.text,
          'profile_image': _profileImageUrl,
        },
      );

      print('Save result: $success');

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールの更新に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'プロフィール編集',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              '保存',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.secondaryOrange.withOpacity(0.3),
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!) as ImageProvider
                                : null,
                            child: _profileImageUrl == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: AppColors.primaryOrange,
                                    size: 40,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickAndUploadImage,
                      child: const Text(
                        '画像を選択',
                        style: TextStyle(color: AppColors.primaryOrange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Information
              const Text(
                '基本情報',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名前',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '名前を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '肩書き',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '肩書きを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Contact Information
              const Text(
                '連絡先情報',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'メールアドレスを入力してください';
                  }
                  if (!value.contains('@')) {
                    return '正しいメールアドレスを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '電話番号',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '電話番号を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bio Section
              const Text(
                '自己紹介',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '自己紹介文',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
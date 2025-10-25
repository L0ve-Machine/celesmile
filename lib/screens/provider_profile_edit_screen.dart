import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';
import '../services/auth_service.dart';

class ProviderProfileEditScreen extends StatefulWidget {
  const ProviderProfileEditScreen({super.key});

  @override
  State<ProviderProfileEditScreen> createState() => _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends State<ProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final providerDb = ProviderDatabaseService();

  // Controllers
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _providerId;
  File? _imageFile;
  String? _profileImagePath;
  bool _isLoading = false;
  bool _showPasswordChange = false;

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    // Load provider ID
    _providerId = AuthService.currentUserProviderId ?? 'test_provider_001';

    // Load provider data
    final provider = providerDb.getProvider(_providerId!);
    if (provider != null) {
      setState(() {
        _nameController.text = provider.name;
        _titleController.text = provider.title;
        _emailController.text = provider.email ?? '';
        _phoneController.text = provider.phone ?? '';
        _bioController.text = provider.bio ?? '';
      });
    }

    // Load saved profile image path
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('provider_profile_image_$_providerId');
      if (_profileImagePath != null) {
        _imageFile = File(_profileImagePath!);
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profileImagePath = pickedFile.path;
      });

      // Save image path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('provider_profile_image_$_providerId', pickedFile.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('プロフィール画像を更新しました'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      _profileImagePath = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('provider_profile_image_$_providerId');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('プロフィール画像を削除しました'),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save to SharedPreferences (simulating database update)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('provider_name_$_providerId', _nameController.text);
      await prefs.setString('provider_title_$_providerId', _titleController.text);
      await prefs.setString('provider_email_$_providerId', _emailController.text);
      await prefs.setString('provider_phone_$_providerId', _phoneController.text);
      await prefs.setString('provider_bio_$_providerId', _bioController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('新しいパスワードが一致しません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードは8文字以上で入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate password change
      await Future.delayed(const Duration(seconds: 1));

      // Save new password to SharedPreferences (for demo)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('provider_password_$_providerId', _newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('パスワードを変更しました'),
            backgroundColor: AppColors.primaryOrange,
          ),
        );

        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _showPasswordChange = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('パスワード変更に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.secondaryOrange.withOpacity(0.3),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : null,
                            child: _imageFile == null
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text(
                            '画像を選択',
                            style: TextStyle(color: AppColors.primaryOrange),
                          ),
                        ),
                        if (_imageFile != null) ...[
                          const Text(' | '),
                          TextButton(
                            onPressed: _removeImage,
                            child: const Text(
                              '削除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ],
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
              const SizedBox(height: 32),

              // Password Change Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'パスワード変更',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showPasswordChange ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() => _showPasswordChange = !_showPasswordChange);
                    },
                  ),
                ],
              ),

              if (_showPasswordChange) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: '現在のパスワード',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: '新しいパスワード',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    helperText: '8文字以上で入力してください',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: '新しいパスワード（確認）',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'パスワードを変更',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
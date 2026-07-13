import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class AdminAppSettingsScreen extends StatefulWidget {
  const AdminAppSettingsScreen({super.key});

  @override
  State<AdminAppSettingsScreen> createState() => _AdminAppSettingsScreenState();
}

class _AdminAppSettingsScreenState extends State<AdminAppSettingsScreen> {
  final _firestore = FirestoreService();
  bool _isLoading = true;
  
  final _formKey = GlobalKey<FormState>();
  final _contactEmailCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _maintenanceMode = false;

  // Banner settings
  final _bannerTitleCtrl = TextEditingController(text: 'BEST SOUVENIRS,\nONE TAP AWAY!');
  final _bannerButtonTextCtrl = TextEditingController(text: 'Explore');
  final _bannerImageUrlCtrl = TextEditingController();
  bool _bannerEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await _firestore.getAppSettings();
    if (data != null && mounted) {
      setState(() {
        _contactEmailCtrl.text = data['contactEmail'] ?? '';
        _contactPhoneCtrl.text = data['contactPhone'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _maintenanceMode = data['maintenanceMode'] ?? false;
      });
    }
    final bannerData = await _firestore.getBannerSettings();
    if (bannerData != null && mounted) {
      setState(() {
        _bannerTitleCtrl.text = bannerData['title'] ?? 'BEST SOUVENIRS,\nONE TAP AWAY!';
        _bannerButtonTextCtrl.text = bannerData['buttonText'] ?? 'Explore';
        _bannerImageUrlCtrl.text = bannerData['imageUrl'] ?? '';
        _bannerEnabled = bannerData['enabled'] ?? true;
      });
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    await _firestore.updateAppSettings({
      'contactEmail': _contactEmailCtrl.text.trim(),
      'contactPhone': _contactPhoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'maintenanceMode': _maintenanceMode,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _firestore.updateBannerSettings({
      'title': _bannerTitleCtrl.text.trim(),
      'buttonText': _bannerButtonTextCtrl.text.trim(),
      'imageUrl': _bannerImageUrlCtrl.text.trim(),
      'enabled': _bannerEnabled,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _bannerTitleCtrl.dispose();
    _bannerButtonTextCtrl.dispose();
    _bannerImageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionHeader('Contact Information'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactEmailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Support Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactPhoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Support Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Store Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('System Settings'),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Maintenance Mode'),
                    subtitle: const Text('Disable user access during updates'),
                    value: _maintenanceMode,
                    activeThumbColor: AppColors.error,
                    onChanged: (v) => setState(() => _maintenanceMode = v),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Home Banner'),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Show Banner'),
                    value: _bannerEnabled,
                    onChanged: (v) => setState(() => _bannerEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bannerTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Banner Title',
                      prefixIcon: Icon(Icons.title),
                      hintText: 'BEST SOUVENIRS,\\nONE TAP AWAY!',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bannerButtonTextCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Button Text',
                      prefixIcon: Icon(Icons.smart_button),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bannerImageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Banner Image URL (optional)',
                      prefixIcon: Icon(Icons.image),
                      hintText: 'https://example.com/banner.png',
                    ),
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const Divider(),
      ],
    );
  }
}

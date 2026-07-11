import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/payment_method_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class AdminPaymentManagementScreen extends StatefulWidget {
  const AdminPaymentManagementScreen({super.key});

  @override
  State<AdminPaymentManagementScreen> createState() =>
      _AdminPaymentManagementScreenState();
}

class _AdminPaymentManagementScreenState
    extends State<AdminPaymentManagementScreen> {
  final _firestore = FirestoreService();

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
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPaymentDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<PaymentMethodModel>>(
        stream: _firestore.getAllPaymentMethods(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final methods = snapshot.data!;
          if (methods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 64, color: AppColors.grey),
                  const SizedBox(height: 16),
                  Text('No payment methods yet', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                  ),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final method = methods.removeAt(oldIndex);
              methods.insert(newIndex, method);
              
              // Update all sortOrders
              for (int i = 0; i < methods.length; i++) {
                if (methods[i].sortOrder != i) {
                  _firestore.updatePaymentMethod(methods[i].id, {'sortOrder': i});
                }
              }
            },
            itemBuilder: (context, index) {
              final method = methods[index];
              return Card(
                key: ValueKey(method.id),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _buildIcon(method.iconUrl),
                  title: Text(method.name, style: AppTextStyles.bodyLarge),
                  subtitle: Text(
                    method.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: method.isActive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showPaymentDialog(method: method),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                        onPressed: () => _confirmDelete(method),
                      ),
                      const Icon(Icons.drag_handle, color: AppColors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIcon(String url) {
    if (url.isEmpty) {
      return const CircleAvatar(
        backgroundColor: AppColors.lightGrey,
        child: Icon(Icons.payment, color: AppColors.grey),
      );
    }
    return CircleAvatar(
      backgroundColor: AppColors.lightGrey,
      backgroundImage: CachedNetworkImageProvider(url),
    );
  }

  void _showPaymentDialog({PaymentMethodModel? method}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PaymentForm(
        method: method,
        onSave: (data) async {
          if (method != null) {
            await _firestore.updatePaymentMethod(method.id, data);
          } else {
            await _firestore.addPaymentMethod(PaymentMethodModel.fromMap(data));
          }
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _confirmDelete(PaymentMethodModel method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete "${method.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.deletePaymentMethod(method.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PaymentForm extends StatefulWidget {
  final PaymentMethodModel? method;
  final Function(Map<String, dynamic>) onSave;

  const _PaymentForm({this.method, required this.onSave});

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _iconUrlCtrl;
  late bool _isActive;
  late bool _requiresCard;

  @override
  void initState() {
    super.initState();
    final m = widget.method;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _iconUrlCtrl = TextEditingController(text: m?.iconUrl ?? '');
    _isActive = m?.isActive ?? true;
    _requiresCard = m?.requiresCard ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.method != null ? 'Edit Payment Method' : 'Add Payment Method',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Method Name (e.g., ABA Payway)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _iconUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Icon URL',
                  hintText: 'https://example.com/icon.png',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Is Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Requires Card Info'),
                subtitle: const Text('Show card number fields in checkout'),
                value: _requiresCard,
                onChanged: (v) => setState(() => _requiresCard = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Payment Method'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.method?.id ?? 'pm_${DateTime.now().millisecondsSinceEpoch}';

    final data = <String, dynamic>{
      'id': id,
      'name': _nameCtrl.text.trim(),
      'iconUrl': _iconUrlCtrl.text.trim(),
      'isActive': _isActive,
      'requiresCard': _requiresCard,
      'sortOrder': widget.method?.sortOrder ?? 99,
      'createdAt': widget.method?.createdAt.toIso8601String() ?? DateTime.now().toIso8601String(),
    };

    widget.onSave(data);
  }
}

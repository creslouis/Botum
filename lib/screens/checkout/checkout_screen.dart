import 'dart:math';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../models/order_model.dart';
import '../../models/payment_method_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/payment_option_tile.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Lim Navy');
  final _streetController = TextEditingController(
    text: '271 Chip Mong, Mean Chey',
  );
  final _cityController = TextEditingController(text: 'Phnom Penh');
  final _phoneController = TextEditingController(text: '+855 98 987 987');
  final _cardNameController = TextEditingController(text: 'Lim Navy');
  String _selectedPaymentName = 'Mastercard';
  bool _isSubmitting = false;

  final FirestoreService _firestoreService = FirestoreService();

  bool _requiresCardInfo(List<PaymentMethodModel> methods) {
    try {
      final method = methods.firstWhere((m) => m.name == _selectedPaymentName);
      return method.requiresCard;
    } catch (_) {
      // Fallback logic for backward compatibility
      return _selectedPaymentName.toLowerCase().contains('card') || 
             _selectedPaymentName.toLowerCase().contains('paypal');
    }
  }

  String get _checkoutModeLabel {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.isGuest) {
      return 'Guest checkout';
    }
    return 'Logged in as ${auth.userModel?.displayName ?? auth.userModel?.email ?? 'User'}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
            children: [
              Text(
                'Payment',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              
              // Dynamic Payment Methods from Firestore
              StreamBuilder<List<PaymentMethodModel>>(
                stream: _firestoreService.getPaymentMethods(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final methods = snapshot.data ?? [];
                  
                  // Ensure selected payment is valid, or fallback to first
                  if (methods.isNotEmpty && 
                      !methods.any((m) => m.name == _selectedPaymentName)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedPaymentName = methods.first.name;
                        });
                      }
                    });
                  }
                  
                  if (methods.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No payment methods available.'),
                    );
                  }

                  return Column(
                    children: [
                      for (final method in methods) ...[
                        PaymentOptionTile(
                          title: method.name,
                          leading: _PaymentBrandDynamic(method: method),
                          isSelected: _selectedPaymentName == method.name,
                          onTap: () {
                            setState(() {
                              _selectedPaymentName = method.name;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_requiresCardInfo(methods)) ...[
                        const SizedBox(height: 8),
                        _CardPreview(cardNameController: _cardNameController),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _cardNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Name on the card').copyWith(
                            filled: true,
                            fillColor: const Color(0xFF2A292C),
                            labelStyle: const TextStyle(color: Colors.white70),
                          ),
                          validator: (value) {
                            if (!_requiresCardInfo(methods)) {
                              return null;
                            }
                            if ((value ?? '').trim().isEmpty) {
                              return 'Enter the cardholder name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipping Information',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration('Full name'),
                      validator: _requiredValidator('Enter your full name'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _streetController,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration('Street address'),
                      validator: _requiredValidator('Enter your street address'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cityController,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration('City'),
                      validator: _requiredValidator('Enter your city'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration('Phone number'),
                      validator: (value) {
                        final trimmed = (value ?? '').trim();
                        if (trimmed.isEmpty) {
                          return 'Enter your phone number';
                        }
                        if (trimmed.length < 8) {
                          return 'Phone number looks too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _checkoutModeLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Total',
                      value: '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
                      emphasize: true,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 160,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: cartProvider.items.isEmpty || _isSubmitting
                            ? null
                            : _submitOrder,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Pay'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (cartProvider.shippingFee == 0)
                      Text(
                        'Free shipping unlocked',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      labelStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE9D7E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE9D7E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE91E8C), width: 1.4),
      ),
    );
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) {
      if ((value ?? '').trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Use firebase auth UID if available, else a generated guest ID
    final auth = context.read<AuthProvider>();
    final userId = auth.firebaseUser?.uid ?? 'guest-${DateTime.now().millisecondsSinceEpoch}';

    final order = OrderModel(
      orderId: _generateOrderId(),
      userId: userId,
      items: cartProvider.items,
      totalPrice: cartProvider.totalPrice,
      paymentMethod: _selectedPaymentName,
      shippingInfo: ShippingInfo(
        fullName: _nameController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    var firestoreSaved = false;

    try {
      await _firestoreService.createOrder(order);
      firestoreSaved = true;
    } catch (_) {
      firestoreSaved = false;
    }

    await cartProvider.clearCart();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!firestoreSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order created locally, but failed to sync to server.',
          ),
        ),
      );
    }

    Navigator.pushReplacementNamed(
      context,
      OrderSuccessScreen.routeName,
      arguments: order.orderId,
    );
  }

  String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = Random().nextInt(9000) + 1000;
    return 'BTM-$timestamp-$suffix';
  }
}

class _PaymentBrandDynamic extends StatelessWidget {
  const _PaymentBrandDynamic({required this.method});

  final PaymentMethodModel method;

  @override
  Widget build(BuildContext context) {
    if (method.iconUrl.isNotEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.hardEdge,
        child: CachedNetworkImage(
          imageUrl: method.iconUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Icon(Icons.payment, size: 20),
          errorWidget: (context, url, error) => const Icon(Icons.payment, size: 20),
        ),
      );
    }

    // Fallback logic if no image URL is provided
    switch (method.name.toLowerCase()) {
      case 'aba payway':
        return _Badge(label: 'ABA', backgroundColor: const Color(0xFF2F6B81));
      case 'acleda bank':
        return _Badge(label: 'ACLEDA', backgroundColor: const Color(0xFF232A68));
      case 'mastercard':
        return const SizedBox(
          width: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 8,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: Color(0xFFD94141),
                ),
              ),
              Positioned(
                right: 8,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: Color(0xFFF4A640),
                ),
              ),
            ],
          ),
        );
      case 'paypal':
        return _PaypalBadge();
      default:
        return const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFF5DDE8),
          child: Icon(Icons.payments_outlined, color: Color(0xFFE91E8C)),
        );
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.cardNameController});

  final TextEditingController cardNameController;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      backgroundColor: const Color(0xFF2A292C),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Name on the card',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: cardNameController,
                  builder: (context, value, child) {
                    return Text(
                      value.text.trim().isEmpty
                          ? 'Cardholder'
                          : value.text.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '••••• 8979',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: 40,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFD94141),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFF4A640),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(
          alpha: backgroundColor == Colors.white ? 0.96 : 1,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1DCE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          )
        : Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _PaypalBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'P',
          style: TextStyle(
            color: Color(0xFF003087),
            fontWeight: FontWeight.w900,
            fontSize: 22,
            height: 0.9,
          ),
        ),
        Text(
          'PayPal',
          style: TextStyle(
            color: Color(0xFF009CDE),
            fontWeight: FontWeight.w800,
            fontSize: 9,
            height: 0.9,
          ),
        ),
      ],
    );
  }
}

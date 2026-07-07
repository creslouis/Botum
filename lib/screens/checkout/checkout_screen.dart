import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/payment_option_tile.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _guestUserId = 'guest-checkout';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Lim Navy');
  final _streetController = TextEditingController(
    text: '271 Chip Mong, Mean Chey',
  );
  final _cityController = TextEditingController(text: 'Phnom Penh');
  final _phoneController = TextEditingController(text: '+855 98 987 987');
  final _cardNameController = TextEditingController(text: 'Lim Navy');
  String _selectedPayment = 'Mastercard';
  bool _isSubmitting = false;

  static const _paymentMethods = <String>[
    'ABA Payway',
    'Acleda Bank',
    'Mastercard',
    'Paypal',
    'Cash On Delivery',
  ];

  bool get _requiresCardInfo =>
      _selectedPayment == 'Mastercard' || _selectedPayment == 'Paypal';

  String get _checkoutModeLabel => 'Guest checkout';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBFD), Color(0xFFF8EEF4)],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_checkoutModeLabel is enabled. We only require your shipping and payment details to place the order.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                for (final method in _paymentMethods) ...[
                  PaymentOptionTile(
                    title: method,
                    leading: _PaymentBrand(method: method),
                    isSelected: _selectedPayment == method,
                    onTap: () {
                      setState(() {
                        _selectedPayment = method;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                if (_requiresCardInfo) ...[
                  const SizedBox(height: 8),
                  _CardPreview(cardNameController: _cardNameController),
                  const SizedBox(height: 10),
                  _SectionCard(
                    child: TextFormField(
                      controller: _cardNameController,
                      decoration: _inputDecoration('Name on the card'),
                      validator: (value) {
                        if (!_requiresCardInfo) {
                          return null;
                        }
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter the cardholder name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shipping Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Edit')),
                  ],
                ),
                _SectionCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Full name'),
                        validator: _requiredValidator('Enter your full name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _streetController,
                        decoration: _inputDecoration('Street address'),
                        validator: _requiredValidator(
                          'Enter your street address',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cityController,
                        decoration: _inputDecoration('City'),
                        validator: _requiredValidator('Enter your city'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
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
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionCard(
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Items',
                        value: '${cartProvider.totalQuantity}',
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Subtotal',
                        value: '\$${cartProvider.subtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Shipping Fee',
                        value: cartProvider.shippingFee == 0
                            ? 'Free'
                            : '\$${cartProvider.shippingFee.toStringAsFixed(2)}',
                      ),
                      if (cartProvider.shippingFee == 0) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Orders over \$${CartProvider.freeShippingThreshold.toStringAsFixed(0)} get free shipping.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black45),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Total',
                        value:
                            '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
                        emphasize: true,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFFFBFD),
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

    final order = OrderModel(
      orderId: _generateOrderId(),
      userId: _guestUserId,
      items: cartProvider.items,
      totalPrice: cartProvider.totalPrice,
      paymentMethod: _selectedPayment,
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
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.orderId)
          .set(order.toMap());
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
            'Order flow completed, but Firestore is not configured yet in this repo.',
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

class _PaymentBrand extends StatelessWidget {
  const _PaymentBrand({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    switch (method) {
      case 'ABA Payway':
        return _Badge(label: 'ABA', backgroundColor: const Color(0xFF2F6B81));
      case 'Acleda Bank':
        return _Badge(
          label: 'ACLEDA',
          backgroundColor: const Color(0xFF232A68),
        );
      case 'Mastercard':
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
      case 'Paypal':
        return _Badge(label: 'PP', backgroundColor: const Color(0xFF1E63C5));
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
                        fontSize: 18,
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
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
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

import 'package:app/core/router.dart';
import 'package:app/core/theme.dart';
import 'package:app/providers/providers.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateProductScreen extends ConsumerStatefulWidget {
  const CreateProductScreen({super.key});

  @override
  ConsumerState<CreateProductScreen> createState() =>
      _CreateProductScreenState();
}

class _CreateProductScreenState extends ConsumerState<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _origin = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'kg');

  String _type = 'Plant';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _origin.dispose();
    _description.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.parse(_quantity.text.trim().replaceAll(',', '.'));

    try {
      setState(() {
        _saving = true;
        _error = null;
      });
      final batch = await ref.read(batchServiceProvider).createProduct(
            name: _name.text,
            category: _category.text,
            type: _type,
            description: _description.text,
            origin: _origin.text,
            initialQuantity: quantity,
            unit: _unit.text,
          );
      ref.invalidate(batchListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo lô mới.')),
      );
      Navigator.pushReplacementNamed(
        context,
        '${AppRouter.timeline}?batchId=${batch.batchId}',
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm lô mới')),
      body: GlassPageBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            children: [
              GlassPanel(
                colors: [
                  const Color(0xFFEAF8EF).withValues(alpha: 0.78),
                  Colors.white.withValues(alpha: 0.52),
                ],
                child: Row(
                  children: [
                    const GlassIconCapsule(
                      icon: Icons.add_box_outlined,
                      color: AppColors.pine,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tạo lô nông sản',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nhập thông tin ban đầu để hệ thống sinh mã QR và hồ sơ truy xuất.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassPanel(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Tên lô / sản phẩm',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        hintText: 'Ví dụ: Xoài, Lúa, Rau thủy canh...',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Loại sản phẩm',
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Plant',
                          child: Text('Cây trồng'),
                        ),
                        DropdownMenuItem(
                          value: 'Animal',
                          child: Text('Vật nuôi'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _type = value ?? 'Plant'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _origin,
                      decoration: const InputDecoration(
                        labelText: 'Xuất xứ',
                        hintText: 'Ví dụ: Cái Bè, Tiền Giang',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantity,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Số lượng ban đầu',
                              prefixIcon: Icon(Icons.scale_outlined),
                            ),
                            validator: _quantityValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _unit,
                            decoration: const InputDecoration(
                              labelText: 'Đơn vị',
                              hintText: 'kg',
                            ),
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: _required,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_rounded),
                        label: Text(_saving ? 'Đang tạo...' : 'Tạo lô mới'),
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

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập thông tin' : null;

  String? _quantityValidator(String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Số lượng không hợp lệ';
    return null;
  }
}

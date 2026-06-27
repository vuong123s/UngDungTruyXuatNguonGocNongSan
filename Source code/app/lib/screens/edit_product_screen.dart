import 'package:app/core/theme.dart';
import 'package:app/models/batch.dart';
import 'package:app/providers/providers.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.batch});
  final Batch batch;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _origin;
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.batch.productName);
    _category = TextEditingController(text: widget.batch.productType);
    _description = TextEditingController(text: widget.batch.description);
    _origin = TextEditingController(text: widget.batch.origin);
    _status = widget.batch.status;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _origin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() {
        _saving = true;
        _error = null;
      });
      await ref
          .read(batchServiceProvider)
          .updateProduct(
            productId: widget.batch.batchId,
            name: _name.text,
            category: _category.text,
            description: _description.text,
            origin: _origin.text,
            status: _status,
          );
      ref.invalidate(batchListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin lô.')),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa lô')),
      body: GlassPageBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassIconCapsule(
                      icon: Icons.edit_note_rounded,
                      color: AppColors.pine,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Thông tin lô',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text('Mã lô: ${widget.batch.batchId}'),
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
                        labelText: 'Tên sản phẩm',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _origin,
                      decoration: const InputDecoration(labelText: 'Xuất xứ'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'draft',
                          child: Text('Bản nháp'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Đang theo dõi'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Hoàn tất'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
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
}

import 'package:app/core/router.dart';
import 'package:app/core/theme.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, this.initialBatchId});

  final String? initialBatchId;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TextEditingController _manualBatchIdController =
      TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initialBatchId = widget.initialBatchId?.trim();
    if (initialBatchId != null && initialBatchId.isNotEmpty) {
      _manualBatchIdController.text = initialBatchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openTrace(initialBatchId);
        }
      });
    }
  }

  @override
  void dispose() {
    _manualBatchIdController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _manualBatchIdController.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Vui long nhap ma lo hoac quet QR.');
      return;
    }

    setState(() => _errorText = null);
    _openTrace(value);
  }

  void _openTrace(String productId) {
    Navigator.pushReplacementNamed(
      context,
      '${AppRouter.trace}?productId=$productId',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tra cuu truy xuat')),
      body: GlassPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(22),
              colors: [
                Colors.white.withValues(alpha: 0.58),
                const Color(0xB8DCE8FF),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thong tin truy xuat lo nong san',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nhap ma lo hoac quet QR de mo timeline moi.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Man hinh chi tiet se hien theo dang timeline doc gon, co node va cham de mo rong tung su kien.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tim lo nong san',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _manualBatchIdController,
                    decoration: InputDecoration(
                      labelText: 'Ma lo',
                      hintText: 'Nhap ma lo hoac ma doc tu QR',
                      prefixIcon: const Icon(Icons.search_rounded),
                      errorText: _errorText,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.timeline_rounded),
                          label: const Text('Xem truy xuat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.scanner),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Quet QR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Neu chua tai duoc du lieu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const _HintLine(
                    icon: Icons.wifi_tethering_rounded,
                    text: 'Kiem tra backend Node dang chay o cong 5000.',
                  ),
                  const SizedBox(height: 10),
                  const _HintLine(
                    icon: Icons.phone_android_rounded,
                    text:
                        'Neu dung dien thoai that, hay build voi --dart-define=API_BASE_URL=http://IP_MAY_TINH:5000/api/v1.',
                  ),
                  const SizedBox(height: 10),
                  const _HintLine(
                    icon: Icons.adb_rounded,
                    text:
                        'Neu dung Android emulator, 10.0.2.2 se tro ve may tinh cua ban.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassIconCapsule(icon: icon, size: 40, color: AppColors.pine),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.ink, height: 1.5),
          ),
        ),
      ],
    );
  }
}

import 'package:app/core/router.dart';
import 'package:app/core/theme.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GlassPageBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Row(
                children: [
                  const GlassIconCapsule(
                    icon: Icons.eco_rounded,
                    color: AppColors.pine,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AgriTrace', style: textTheme.titleLarge),
                        const SizedBox(height: 2),
                        const Text(
                          'Nền tảng truy xuất nông sản',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassPanel(
                    radius: 999,
                    blur: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    colors: [
                      Colors.white.withValues(alpha: 0.54),
                      Colors.white.withValues(alpha: 0.22),
                    ],
                    child: const Text(
                      'Demo 2026',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              GlassPanel(
                padding: const EdgeInsets.all(0),
                colors: [
                  Colors.white.withValues(alpha: 0.65),
                  const Color(0xBDE4F2D8),
                ],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A7F45), Color(0xFF5AA265)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Truy xuất nguồn gốc nông sản',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Theo dõi toàn bộ hành trình của từng lô nông sản.',
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Quét QR, tra cứu nhật ký canh tác, theo dõi xác nhận blockchain trong một trải nghiệm trực quan.',
                            style: TextStyle(
                              color: Color(0xFFEFF8F0),
                              height: 1.52,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Expanded(
                                child: _HeroMetric(
                                  value: '24/7',
                                  label: 'Sẵn sàng tra cứu',
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _HeroMetric(
                                  value: 'QR',
                                  label: 'Mở truy xuất tức thì',
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _HeroMetric(
                                  value: 'Chain',
                                  label: 'Dữ liệu đối chiếu',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text('Bắt đầu nhanh', style: textTheme.titleLarge),
                  ),
                  const _GlassChip(label: '3 bước thao tác'),
                ],
              ),
              const SizedBox(height: 12),
              _GlassActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Quét QR',
                subtitle: 'Mở nhanh thông tin lô nông sản và lịch sử cập nhật.',
                accentColor: const Color(0xFF2F8F4D),
                tag: 'Cho người tra cứu',
                onTap: () => Navigator.pushNamed(context, AppRouter.scanner),
              ),
              const SizedBox(height: 14),
              _GlassActionCard(
                icon: Icons.person_rounded,
                title: 'Đăng nhập quản lý',
                subtitle:
                    'Cập nhật nhật ký sản xuất, đóng gói và vận chuyển cho từng lô.',
                accentColor: const Color(0xFF406CBE),
                tag: 'Cho người vận hành',
                onTap: () => Navigator.pushNamed(context, AppRouter.login),
              ),
              const SizedBox(height: 14),
              _GlassActionCard(
                icon: Icons.person_add_rounded,
                title: 'Đăng ký tài khoản',
                subtitle: 'Tạo tài khoản mới để quản lý lô nông sản của bạn.',
                accentColor: const Color(0xFFB27A2D),
                tag: 'Bắt đầu sử dụng',
                onTap: () => Navigator.pushNamed(context, AppRouter.register),
              ),
              const SizedBox(height: 18),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vì sao chọn cách làm này',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    const _FeatureLine(
                      icon: Icons.touch_app_rounded,
                      title: 'Bám đúng nghiệp vụ',
                      subtitle:
                          'Chọn luồng quét mã, tra cứu và cập nhật nhật ký vì đây là các bước sát với truy xuất nông sản thực tế.',
                    ),
                    const SizedBox(height: 12),
                    const _FeatureLine(
                      icon: Icons.agriculture_rounded,
                      title: 'Dễ dùng cho người vận hành',
                      subtitle:
                          'Các chức năng được giữ ngắn gọn để người quản lý lô, nông dân hoặc người xem đều thao tác nhanh.',
                    ),
                    const SizedBox(height: 12),
                    const _FeatureLine(
                      icon: Icons.verified_rounded,
                      title: 'Thông tin dễ đối chiếu',
                      subtitle:
                          'Mốc thời gian, ảnh minh chứng và trạng thái xác nhận được đặt cùng nhau để tiện kiểm tra và trình bày.',
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
}

class _GlassActionCard extends StatelessWidget {
  const _GlassActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.16),
                border: Border.all(color: accentColor.withValues(alpha: 0.32)),
              ),
              child: Icon(icon, color: accentColor, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.14),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE7F6EA),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassIconCapsule(icon: icon, size: 42, color: AppColors.pine),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 999,
      blur: 16,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

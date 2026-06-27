import React, { useEffect, useMemo, useState } from 'react';
import {
  BrowserRouter,
  Link,
  Navigate,
  Outlet,
  Route,
  Routes,
  useLocation,
  useSearchParams,
} from 'react-router-dom';
import LoginPage from './pages/Login/LoginPage';
import DashboardPage from './pages/Dashboard/DashboardPage';
import TraceDetailPage from './pages/TraceDetail/TraceDetailPage';
import FarmingAreaPage from './pages/FarmingArea/FarmingAreaPage';
import CertificationPage from './pages/Certification/CertificationPage';
import AdminPage from './pages/Admin/AdminPage';
import ExportPage from './pages/Export/ExportPage';
import QualityInspectionPage from './pages/QualityInspection/QualityInspectionPage';
import DiseaseDetectionPage from './pages/DiseaseDetection/DiseaseDetectionPage';
import SupplyChainPage from './pages/SupplyChain/SupplyChainPage';
import { AuthProvider } from './core/context/AuthContext';
import { useAuth } from './core/hooks/useAuth';
import { productApi } from './core/api/product.api';
import { traceEventApi } from './core/api/traceEvent.api';
import { colors, spacing, borderRadius, shadows, typography } from './core/theme';
import type { EventType, Product, TraceEvent } from './core/types';

const eventTypeOptions: EventType[] = [
  'SEEDING',
  'FERTILIZING',
  'WATERING',
  'PEST_CONTROL',
  'HARVESTING',
  'PACKAGING',
  'SHIPPING',
];

const eventTypeLabels: Record<EventType, string> = {
  SEEDING: '🌱 Gieo hạt',
  FERTILIZING: '🧪 Bón phân',
  WATERING: '💧 Tưới nước',
  PEST_CONTROL: '🐛 Phòng trừ sâu bệnh',
  HARVESTING: '🌾 Thu hoạch',
  PACKAGING: '📦 Đóng gói',
  SHIPPING: '🚚 Vận chuyển',
};

// Global styles
const globalStyles = `
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { 
    font-family: ${typography.fontFamily}; 
    background: ${colors.background}; 
    color: ${colors.textPrimary};
    line-height: ${typography.lineHeights.normal};
  }
  ::selection { background: ${colors.primary[200]}; }
`;

const ProtectedRoute: React.FC = () => {
  const { loading, isAuthenticated } = useAuth();

  if (loading) {
    return (
      <div style={{ 
        minHeight: '100vh', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center',
        background: colors.background 
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ 
            width: 48, 
            height: 48, 
            border: `3px solid ${colors.neutral[200]}`,
            borderTopColor: colors.primary[600],
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            margin: '0 auto 16px'
          }} />
          <p style={{ color: colors.textSecondary }}>Đang tải...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
};

const AppShell: React.FC = () => {
  const { logout, user } = useAuth();
  const location = useLocation();

  const navItems = useMemo(
    () => [
      { to: '/', label: 'Lô nông sản', icon: '📦' },
      { to: '/add-event', label: 'Ghi nhật ký', icon: '📝' },
      { to: '/farming-areas', label: 'Vùng trồng', icon: '🌾' },
      { to: '/supply-chain', label: 'Chuỗi cung ứng', icon: '🚚' },
      { to: '/certifications', label: 'Chứng nhận', icon: '📜' },
      { to: '/disease-detection', label: 'Nhận diện bệnh', icon: '🔎' },
      ...(user?.role === 'admin' || user?.role === 'manager'
        ? [{ to: '/quality-inspections', label: 'Kiểm nghiệm', icon: '🧪' }]
        : []),
      { to: '/export', label: 'Xuất báo cáo', icon: '📊' },
      ...(user?.role === 'admin' ? [{ to: '/admin', label: 'Quản trị', icon: '⚙️' }] : []),
    ],
    [user?.role]
  );

  const isActive = (to: string) => {
    if (to === '/') return location.pathname === '/' || location.pathname === '/products';
    return location.pathname.startsWith(to);
  };

  return (
    <div style={{ minHeight: '100vh', background: colors.background }}>
      {/* Header */}
      <header style={{
        position: 'sticky',
        top: 0,
        zIndex: 50,
        background: colors.surface,
        borderBottom: `1px solid ${colors.neutral[200]}`,
        boxShadow: shadows.sm,
      }}>
        <div style={{
          maxWidth: 1280,
          margin: '0 auto',
          padding: `0 ${spacing[6]}`,
          height: 72,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: spacing[6],
        }}>
          {/* Logo */}
          <Link to="/" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: spacing[3] }}>
            <div style={{
              width: 40,
              height: 40,
              background: `linear-gradient(135deg, ${colors.primary[500]}, ${colors.primary[700]})`,
              borderRadius: borderRadius.lg,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: 20,
            }}>🌿</div>
            <div>
              <div style={{ fontWeight: typography.weights.bold, fontSize: typography.sizes.lg, color: colors.textPrimary }}>
                AgriTrace
              </div>
              <div style={{ fontSize: typography.sizes.xs, color: colors.textMuted }}>
                Truy xuất nguồn gốc
              </div>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <nav style={{ 
            display: 'flex', 
            alignItems: 'center', 
            gap: spacing[1],
            flex: 1,
            justifyContent: 'center',
          }}>
            {navItems.map((item) => {
              const active = isActive(item.to);
              return (
                <Link
                  key={item.to}
                  to={item.to}
                  style={{
                    textDecoration: 'none',
                    padding: `${spacing[2]} ${spacing[4]}`,
                    borderRadius: borderRadius.lg,
                    fontSize: typography.sizes.sm,
                    fontWeight: active ? typography.weights.semibold : typography.weights.medium,
                    color: active ? colors.primary[700] : colors.textSecondary,
                    background: active ? colors.primary[50] : 'transparent',
                    transition: 'all 0.2s ease',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>

          {/* User Menu */}
          <div style={{ display: 'flex', alignItems: 'center', gap: spacing[4] }}>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: typography.sizes.sm, fontWeight: typography.weights.semibold, color: colors.textPrimary }}>
                {user?.name || 'Người dùng'}
              </div>
              <div style={{ fontSize: typography.sizes.xs, color: colors.textMuted }}>
                {user?.email}
              </div>
            </div>
            <button
              onClick={logout}
              style={{
                background: colors.neutral[100],
                border: 'none',
                borderRadius: borderRadius.lg,
                padding: `${spacing[2]} ${spacing[4]}`,
                fontSize: typography.sizes.sm,
                fontWeight: typography.weights.medium,
                color: colors.textSecondary,
                cursor: 'pointer',
                transition: 'all 0.2s ease',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = colors.neutral[200];
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = colors.neutral[100];
              }}
            >
              Đăng xuất
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main style={{
        maxWidth: 1280,
        margin: '0 auto',
        padding: `${spacing[8]} ${spacing[6]} ${spacing[16]}`,
        minHeight: 'calc(100vh - 72px)',
      }}>
        <Outlet />
      </main>
    </div>
  );
};

const QuickAddEventPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<TraceEvent | null>(null);
  const [productId, setProductId] = useState(searchParams.get('productId') || '');
  const [eventType, setEventType] = useState<EventType>('SEEDING');
  const [description, setDescription] = useState('');
  const editableProducts = useMemo(
    () => products.filter((product) => product.status !== 'completed'),
    [products]
  );
  const selectedProduct = products.find((product) => product._id === productId);

  useEffect(() => {
    let mounted = true;

    productApi
      .getAll()
      .then((res) => {
        if (!mounted) return;
        const list = res.data.products;
        const editableList = list.filter((product) => product.status !== 'completed');
        setProducts(list);
        if ((!productId || list.find((product) => product._id === productId)?.status === 'completed') && editableList.length > 0) {
          setProductId(editableList[0]._id);
        }
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err.message || 'Không tải được danh sách lô');
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });

    return () => { mounted = false; };
  }, [productId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setResult(null);

    if (!productId || !description.trim()) {
      setError('Vui lòng chọn lô và nhập mô tả sự kiện');
      return;
    }
    if (selectedProduct?.status === 'completed') {
      setError('Lô đã hoàn thành, không thể thêm nhật ký mới.');
      return;
    }

    setSubmitting(true);
    try {
      const { data } = await traceEventApi.create({
        product: productId,
        eventType,
        description: description.trim(),
      });
      setResult(data.traceEvent);
      setDescription('');
    } catch (err: any) {
      setError(err.message || 'Không tạo được sự kiện');
    } finally {
      setSubmitting(false);
    }
  };

  const inputStyle: React.CSSProperties = {
    width: '100%',
    padding: `${spacing[3]} ${spacing[4]}`,
    border: `1px solid ${colors.neutral[300]}`,
    borderRadius: borderRadius.lg,
    fontSize: typography.sizes.base,
    transition: 'border-color 0.2s ease, box-shadow 0.2s ease',
    outline: 'none',
  };

  return (
    <div style={{ maxWidth: 640, margin: '0 auto' }}>
      {/* Page Header */}
      <div style={{ marginBottom: spacing[8] }}>
        <h1 style={{ 
          fontSize: typography.sizes['3xl'], 
          fontWeight: typography.weights.bold,
          color: colors.textPrimary,
          marginBottom: spacing[2],
        }}>
          Ghi nhật ký canh tác
        </h1>
        <p style={{ fontSize: typography.sizes.base, color: colors.textSecondary }}>
          Ghi lại các hoạt động sản xuất và đồng bộ lên blockchain
        </p>
      </div>

      {/* Form Card */}
      <div style={{
        background: colors.surface,
        borderRadius: borderRadius.xl,
        boxShadow: shadows.md,
        border: `1px solid ${colors.neutral[200]}`,
        padding: spacing[8],
      }}>
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: spacing[6] }}>
            {/* Product Select */}
            <div>
              <label style={{ 
                display: 'block', 
                marginBottom: spacing[2], 
                fontWeight: typography.weights.medium,
                fontSize: typography.sizes.sm,
                color: colors.textPrimary,
              }}>
                Lô nông sản
              </label>
              <select
                value={productId}
                onChange={(e) => setProductId(e.target.value)}
                disabled={loading || editableProducts.length === 0}
                style={{ ...inputStyle, cursor: 'pointer' }}
              >
                {editableProducts.length === 0 ? (
                  <option value="">Không có lô đang theo dõi</option>
                ) : (
                  editableProducts.map((product) => (
                    <option key={product._id} value={product._id}>
                      {product.name} - {product.origin}
                    </option>
                  ))
                )}
              </select>
            </div>

            {/* Event Type Select */}
            <div>
              <label style={{ 
                display: 'block', 
                marginBottom: spacing[2], 
                fontWeight: typography.weights.medium,
                fontSize: typography.sizes.sm,
                color: colors.textPrimary,
              }}>
                Loại hoạt động
              </label>
              <select
                value={eventType}
                onChange={(e) => setEventType(e.target.value as EventType)}
                style={{ ...inputStyle, cursor: 'pointer' }}
              >
                {eventTypeOptions.map((item) => (
                  <option key={item} value={item}>
                    {eventTypeLabels[item]}
                  </option>
                ))}
              </select>
            </div>

            {/* Description Textarea */}
            <div>
              <label style={{ 
                display: 'block', 
                marginBottom: spacing[2], 
                fontWeight: typography.weights.medium,
                fontSize: typography.sizes.sm,
                color: colors.textPrimary,
              }}>
                Mô tả chi tiết
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                rows={4}
                placeholder="Ví dụ: Bón phân NPK đợt 1, tưới nước sáng sớm, thu hoạch ngày 11/03..."
                style={{ ...inputStyle, resize: 'vertical', minHeight: 120 }}
              />
            </div>

            {/* Error Message */}
            {error && (
              <div style={{
                background: '#fef2f2',
                color: colors.error,
                padding: spacing[4],
                borderRadius: borderRadius.lg,
                fontSize: typography.sizes.sm,
              }}>
                {error}
              </div>
            )}

            {products.length > 0 && editableProducts.length === 0 && (
              <div style={{
                background: '#fffbeb',
                color: '#92400e',
                padding: spacing[4],
                borderRadius: borderRadius.lg,
                fontSize: typography.sizes.sm,
              }}>
                Tất cả lô hiện đã hoàn thành. Muốn bổ sung nhật ký, hãy chuyển trạng thái lô về “Đang theo dõi”.
              </div>
            )}

            {/* Success Message */}
            {result && (
              <div style={{
                background: colors.primary[50],
                color: colors.primary[700],
                padding: spacing[4],
                borderRadius: borderRadius.lg,
              }}>
                <div style={{ fontWeight: typography.weights.semibold, marginBottom: spacing[2] }}>
                  ✓ Tạo sự kiện thành công
                </div>
                <div style={{ fontSize: typography.sizes.sm }}>
                  Trạng thái blockchain: {result.onChainStatus}
                </div>
                {result.txHash && (
                  <div style={{ 
                    fontFamily: typography.fontFamilyMono, 
                    fontSize: typography.sizes.xs, 
                    marginTop: spacing[2],
                    wordBreak: 'break-all',
                    opacity: 0.8,
                  }}>
                    Tx: {result.txHash}
                  </div>
                )}
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={submitting || loading || editableProducts.length === 0}
              style={{
                width: '100%',
                padding: `${spacing[4]} ${spacing[6]}`,
                background: submitting ? colors.neutral[400] : colors.primary[600],
                color: 'white',
                border: 'none',
                borderRadius: borderRadius.lg,
                fontSize: typography.sizes.base,
                fontWeight: typography.weights.semibold,
                cursor: submitting ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s ease',
              }}
            >
              {submitting ? 'Đang ghi lên blockchain...' : 'Ghi nhật ký'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/trace/:productId" element={<TraceDetailPage />} />

      <Route element={<ProtectedRoute />}>
        <Route element={<AppShell />}>
          <Route index element={<DashboardPage />} />
          <Route path="/products" element={<DashboardPage />} />
          <Route path="/add-event" element={<QuickAddEventPage />} />
          <Route path="/farming-areas" element={<FarmingAreaPage />} />
          <Route path="/supply-chain" element={<SupplyChainPage />} />
          <Route path="/certifications" element={<CertificationPage />} />
          <Route path="/disease-detection" element={<DiseaseDetectionPage />} />
          <Route path="/quality-inspections" element={<QualityInspectionPage />} />
          <Route path="/export" element={<ExportPage />} />
          <Route path="/admin" element={<AdminPage />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

const App: React.FC = () => {
  return (
    <AuthProvider>
      <style>{globalStyles}</style>
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  );
};

export default App;

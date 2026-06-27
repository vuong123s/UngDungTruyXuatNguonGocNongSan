import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { productApi } from '../../core/api/product.api';
import { farmingAreaApi, FarmingArea as FarmingAreaType } from '../../core/api/farmingArea.api';
import { colors, spacing, borderRadius, shadows, typography } from '../../core/theme';
import type { Product } from '../../core/types';
import ProductCameraModal from '../../components/LiveStream/ProductCameraModal';
import { useAuth } from '../../core/hooks/useAuth';

// SVG Icons for modern premium UI
const CubeIcon = ({ color = 'currentColor' }: { color?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke={color} style={{ width: 24, height: 24 }}>
    <path strokeLinecap="round" strokeLinejoin="round" d="m21 7.5-9-5.25L3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9" />
  </svg>
);

const ActivityIcon = ({ color = 'currentColor' }: { color?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke={color} style={{ width: 24, height: 24 }}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v5.625C7.5 19.376 6.996 19.875 6.375 19.875h-2.25A1.125 1.125 0 0 1 3 18.75v-5.625ZM18 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v10.125c0 .621-.504 1.125-1.125 1.125h-2.25A1.125 1.125 0 0 1 18 18.75V8.625ZM10.5 13.125c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v5.625c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125v-5.625Z" />
    <path strokeLinecap="round" strokeLinejoin="round" d="M9 10.5V9.75a3 3 0 0 0-3-3h-.75M21 3v2.25m0 0H18.75M21 5.25 16.5 9.75" />
  </svg>
);

const CheckBadgeIcon = ({ color = 'currentColor' }: { color?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke={color} style={{ width: 24, height: 24 }}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 0 1-1.043 3.296 3.745 3.745 0 0 1-3.296 1.043A3.745 3.745 0 0 1 12 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 0 1-3.296-1.043 3.745 3.745 0 0 1-1.043-3.296A3.745 3.745 0 0 1 3 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 0 1 1.043-3.296 3.746 3.746 0 0 1 3.296-1.043A3.746 3.746 0 0 1 12 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 0 1 3.296 1.043 3.746 3.746 0 0 1 1.043 3.296A3.745 3.745 0 0 1 21 12Z" />
  </svg>
);

const EyeIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2.2} stroke="currentColor" style={{ width: 14, height: 14 }}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
    <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
  </svg>
);

const PlusCircleIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2.2} stroke="currentColor" style={{ width: 14, height: 14 }}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
  </svg>
);

const CameraIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2.2} stroke="currentColor" style={{ width: 14, height: 14 }}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 0 1 5.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 0 0-1.134-.175 2.31 2.31 0 0 1-1.64-1.055l-.822-1.316a2.192 2.192 0 0 0-1.736-1.039 48.774 48.774 0 0 0-5.232 0 2.192 2.192 0 0 0-1.736 1.039l-.821 1.316Z" />
    <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0ZM18.75 10.5h.008v.008h-.008V10.5Z" />
  </svg>
);

type ProductionType = 'Plant' | 'Animal';
type CategoryStore = Record<ProductionType, string[]>;

const CATEGORY_STORAGE_KEY = 'agri-trace-category-options-v1';

const statusLabel: Record<string, string> = {
  draft: 'Nháp',
  active: 'Đang theo dõi',
  completed: 'Hoàn tất',
  recalled: 'Đã thu hồi',
};

const statusColors: Record<string, { bg: string; text: string }> = {
  draft: { bg: colors.neutral[100], text: colors.neutral[600] },
  active: { bg: colors.primary[100], text: colors.primary[700] },
  completed: { bg: '#dbeafe', text: '#1d4ed8' },
  recalled: { bg: '#fee2e2', text: '#b91c1c' },
};

const productionTypeMeta: Record<
  ProductionType,
  { label: string; subtitle: string; startLabel: string; placeholder: string; icon: string }
> = {
  Plant: {
    label: 'Trồng trọt',
    subtitle: 'Dùng cho rau, củ, quả, nấm, ngũ cốc...',
    startLabel: 'Ngày bắt đầu gieo trồng',
    placeholder: 'Ví dụ: Xà lách lứa tháng 3',
    icon: '🌱',
  },
  Animal: {
    label: 'Chăn nuôi',
    subtitle: 'Dùng cho gia súc, gia cầm, thủy sản...',
    startLabel: 'Ngày bắt đầu nuôi / nhập đàn',
    placeholder: 'Ví dụ: Gà ta lứa tháng 3',
    icon: '🐔',
  },
};

const defaultCategoryOptions: CategoryStore = {
  Plant: ['Rau ăn lá', 'Rau củ', 'Trái cây', 'Ngũ cốc', 'Nấm', 'Khác'],
  Animal: ['Gia cầm', 'Gia súc', 'Thủy sản', 'Sữa / Trứng', 'Mật ong', 'Khác'],
};

const StatCard: React.FC<{
  label: string;
  value: string | number;
  color?: string;
  icon: React.ReactNode;
  borderAccent?: string;
}> = ({ label, value, color = colors.textPrimary, icon, borderAccent }) => {
  const [hovered, setHovered] = useState(false);
  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: colors.surface,
        borderRadius: borderRadius.xl,
        padding: `${spacing[5]} ${spacing[6]}`,
        boxShadow: hovered ? shadows.md : shadows.sm,
        border: `1px solid ${colors.neutral[200]}`,
        borderLeft: borderAccent ? `4px solid ${borderAccent}` : `1px solid ${colors.neutral[200]}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        transform: hovered ? 'translateY(-4px)' : 'translateY(0)',
      }}
    >
      <div>
        <p style={{ margin: 0, fontSize: typography.sizes.xs, fontWeight: typography.weights.semibold, color: colors.textSecondary, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: spacing[1] }}>{label}</p>
        <p style={{ margin: 0, fontSize: typography.sizes['3xl'], fontWeight: typography.weights.bold, color }}>{value}</p>
      </div>
      <div style={{
        padding: spacing[3],
        borderRadius: borderRadius.lg,
        background: borderAccent ? `${borderAccent}10` : `${colors.neutral[100]}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}>
        {icon}
      </div>
    </div>
  );
};

const fieldStyle: React.CSSProperties = {
  padding: `${spacing[3]} ${spacing[4]}`,
  borderRadius: borderRadius.lg,
  border: `1px solid ${colors.neutral[300]}`,
  fontSize: typography.sizes.base,
  width: '100%',
  boxSizing: 'border-box',
  outline: 'none',
  transition: 'border-color 0.2s ease',
};

const secondaryButtonStyle: React.CSSProperties = {
  border: `1px solid ${colors.neutral[300]}`,
  background: colors.surface,
  color: colors.textSecondary,
  borderRadius: borderRadius.lg,
  padding: `${spacing[3]} ${spacing[4]}`,
  cursor: 'pointer',
  fontWeight: typography.weights.medium,
  fontSize: typography.sizes.sm,
  transition: 'all 0.2s ease',
};

const ghostButtonStyle: React.CSSProperties = {
  border: 'none',
  background: 'transparent',
  color: colors.primary[600],
  borderRadius: borderRadius.md,
  padding: `${spacing[2]} ${spacing[3]}`,
  cursor: 'pointer',
  fontWeight: typography.weights.medium,
  fontSize: typography.sizes.sm,
};

const thStyle: React.CSSProperties = {
  padding: `${spacing[3]} ${spacing[4]}`,
  textAlign: 'left',
  fontWeight: typography.weights.semibold,
  color: colors.textSecondary,
  fontSize: typography.sizes.sm,
  borderBottom: `1px solid ${colors.neutral[200]}`,
};

const tdStyle: React.CSSProperties = {
  padding: `${spacing[4]} ${spacing[4]}`,
  borderBottom: `1px solid ${colors.neutral[100]}`,
  fontSize: typography.sizes.sm,
};

const normalizeGroupName = (value: string) => value.trim().replace(/\s+/g, ' ');

const loadCategoryOptions = (): CategoryStore => {
  if (typeof window === 'undefined') {
    return defaultCategoryOptions;
  }

  try {
    const raw = window.localStorage.getItem(CATEGORY_STORAGE_KEY);
    if (!raw) return defaultCategoryOptions;

    const parsed = JSON.parse(raw) as Partial<CategoryStore>;

    return {
      Plant:
        parsed.Plant?.map(normalizeGroupName).filter(Boolean) ?? defaultCategoryOptions.Plant,
      Animal:
        parsed.Animal?.map(normalizeGroupName).filter(Boolean) ?? defaultCategoryOptions.Animal,
    };
  } catch {
    return defaultCategoryOptions;
  }
};

const formatDate = (value?: string) => {
  if (!value) return 'Chưa cập nhật';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString('vi-VN');
};

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const [products, setProducts] = useState<Product[]>([]);
  const [trashProducts, setTrashProducts] = useState<Product[]>([]);
  const [farmingAreas, setFarmingAreas] = useState<FarmingAreaType[]>([]);
  const [loading, setLoading] = useState(true);
  const [trashLoading, setTrashLoading] = useState(false);
  const [error, setError] = useState('');
  const [trashError, setTrashError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState('');
  const [submitSuccess, setSubmitSuccess] = useState('');
  const [cameraProduct, setCameraProduct] = useState<Product | null>(null);
  const [groupError, setGroupError] = useState('');
  const [groupSuccess, setGroupSuccess] = useState('');
  const [categoryOptions, setCategoryOptions] =
    useState<CategoryStore>(loadCategoryOptions);
  const [newGroupName, setNewGroupName] = useState('');
  const [editingGroup, setEditingGroup] = useState<string | null>(null);
  const [editingGroupName, setEditingGroupName] = useState('');
  const [isGroupMenuOpen, setIsGroupMenuOpen] = useState(false);
  const [isTrashOpen, setIsTrashOpen] = useState(false);
  const groupMenuRef = useRef<HTMLDivElement | null>(null);
  const [formData, setFormData] = useState({
    type: 'Plant' as ProductionType,
    category: loadCategoryOptions().Plant[0] ?? '',
    name: '',
    farmingAreaId: '',
    origin: '',
    cultivationTime: '',
    note: '',
  });

  useEffect(() => {
    let mounted = true;

    Promise.all([
      productApi.getAll(),
      farmingAreaApi.getAll(),
    ])
      .then(([productRes, farmingAreaRes]) => {
        if (!mounted) return;
        setProducts(productRes.data.products);
        setFarmingAreas(farmingAreaRes.data.farmingAreas || []);
      })
      .catch((err) => {
        if (!mounted) return;
        setError(err.message || 'Lỗi tải dữ liệu');
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });

    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    window.localStorage.setItem(CATEGORY_STORAGE_KEY, JSON.stringify(categoryOptions));
  }, [categoryOptions]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (!groupMenuRef.current) return;
      if (!groupMenuRef.current.contains(event.target as Node)) {
        setIsGroupMenuOpen(false);
        setEditingGroup(null);
        setEditingGroupName('');
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    const options = categoryOptions[formData.type];
    if (!options.includes(formData.category)) {
      setFormData((prev) => ({
        ...prev,
        category: options[0] ?? '',
      }));
    }
  }, [categoryOptions, formData.category, formData.type]);

  const active = useMemo(
    () => products.filter((p) => p.status === 'active').length,
    [products]
  );
  const completed = useMemo(
    () => products.filter((p) => p.status === 'completed').length,
    [products]
  );
  const canManageTrash = user?.role === 'admin' || user?.role === 'manager';
  const canArchiveProduct = user?.role === 'admin';

  const productionMeta = productionTypeMeta[formData.type];
  const currentGroupOptions = categoryOptions[formData.type];

  const handleChange =
    (field: keyof typeof formData) =>
    (
      e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
    ) => {
      setFormData((prev) => ({ ...prev, [field]: e.target.value }));
    };

  const handleFarmingAreaChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const areaId = e.target.value;
    const selectedArea = farmingAreas.find((area) => area._id === areaId);
    setFormData((prev) => ({
      ...prev,
      farmingAreaId: areaId,
      origin: selectedArea?.address || prev.origin,
    }));
  };

  const handleTypeChange = (type: ProductionType) => {
    setGroupError('');
    setGroupSuccess('');
    setEditingGroup(null);
    setEditingGroupName('');
    setIsGroupMenuOpen(false);
    setFormData((prev) => ({
      ...prev,
      type,
      category: categoryOptions[type][0] ?? '',
    }));
  };

  const buildDescription = () => {
    if (formData.note.trim()) return formData.note.trim();

    const prefix =
      formData.type === 'Plant'
        ? `Lô trồng ${formData.name.trim()}`
        : `Lô nuôi ${formData.name.trim()}`;
    const group = formData.category ? `thuộc nhóm ${formData.category}` : '';
    const location = formData.origin.trim() ? `tại ${formData.origin.trim()}` : '';
    const date = formData.cultivationTime
      ? `bắt đầu ${formatDate(formData.cultivationTime)}`
      : '';

    return [prefix, group, location, date].filter(Boolean).join(', ');
  };

  const handleAddGroup = () => {
    const normalizedName = normalizeGroupName(newGroupName);
    setGroupError('');
    setGroupSuccess('');

    if (!normalizedName) {
      setGroupError('Nhập tên nhóm sản phẩm trước khi thêm.');
      return;
    }

    const duplicated = currentGroupOptions.some(
      (item) => item.toLowerCase() === normalizedName.toLowerCase()
    );
    if (duplicated) {
      setGroupError('Nhóm sản phẩm này đã tồn tại.');
      return;
    }

    const nextOptions = [...currentGroupOptions, normalizedName];
    setCategoryOptions((prev) => ({
      ...prev,
      [formData.type]: nextOptions,
    }));
    setFormData((prev) => ({
      ...prev,
      category: normalizedName,
    }));
    setNewGroupName('');
    setGroupSuccess(`Đã thêm nhóm "${normalizedName}".`);
  };

  const handleStartEditGroup = (groupName: string) => {
    setGroupError('');
    setGroupSuccess('');
    setEditingGroup(groupName);
    setEditingGroupName(groupName);
  };

  const handleSaveGroup = (groupName: string) => {
    const normalizedName = normalizeGroupName(editingGroupName);
    setGroupError('');
    setGroupSuccess('');

    if (!normalizedName) {
      setGroupError('Tên nhóm sản phẩm không được để trống.');
      return;
    }

    const duplicated = currentGroupOptions.some(
      (item) =>
        item.toLowerCase() === normalizedName.toLowerCase() &&
        item.toLowerCase() !== groupName.toLowerCase()
    );
    if (duplicated) {
      setGroupError('Tên nhóm mới đang trùng với một nhóm đã có.');
      return;
    }

    const nextOptions = currentGroupOptions.map((item) =>
      item === groupName ? normalizedName : item
    );
    setCategoryOptions((prev) => ({
      ...prev,
      [formData.type]: nextOptions,
    }));
    setFormData((prev) => ({
      ...prev,
      category: prev.category === groupName ? normalizedName : prev.category,
    }));
    setEditingGroup(null);
    setEditingGroupName('');
    setGroupSuccess(`Đã cập nhật nhóm thành "${normalizedName}".`);
  };

  const handleSelectGroup = (groupName: string) => {
    setGroupError('');
    setGroupSuccess('');
    setFormData((prev) => ({
      ...prev,
      category: groupName,
    }));
    setIsGroupMenuOpen(false);
    setEditingGroup(null);
    setEditingGroupName('');
  };

  const handleDeleteGroup = (groupName: string) => {
    setGroupError('');
    setGroupSuccess('');

    const nextOptions = currentGroupOptions.filter((item) => item !== groupName);
    setCategoryOptions((prev) => ({
      ...prev,
      [formData.type]: nextOptions,
    }));
    setFormData((prev) => ({
      ...prev,
      category: prev.category === groupName ? nextOptions[0] ?? '' : prev.category,
    }));
    setEditingGroup((prev) => (prev === groupName ? null : prev));
    setEditingGroupName('');
    setGroupSuccess(`Đã xóa nhóm "${groupName}".`);
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError('');
    setSubmitSuccess('');

    if (!formData.category.trim()) {
      setSubmitError('Vui lòng tạo hoặc chọn một nhóm sản phẩm.');
      return;
    }

    if (!formData.name.trim() || !formData.origin.trim()) {
      setSubmitError('Vui lòng nhập tên lô và nơi sản xuất.');
      return;
    }

    setSubmitting(true);
    try {
      const { data } = await productApi.create({
        name: formData.name.trim(),
        category: formData.category,
        type: formData.type,
        description: buildDescription(),
        origin: formData.origin.trim(),
        cultivation_time: formData.cultivationTime || undefined,
        farming_area: formData.farmingAreaId || undefined,
      });

      setProducts((prev) => [data.product, ...prev]);
      setFormData((prev) => ({
        ...prev,
        category: categoryOptions[prev.type][0] ?? '',
        name: '',
        farmingAreaId: '',
        origin: '',
        cultivationTime: '',
        note: '',
      }));
      setSubmitSuccess('Tạo lô nông sản thành công.');
    } catch (err: any) {
      setSubmitError(err.message || 'Không tạo được lô hàng.');
    } finally {
      setSubmitting(false);
    }
  };

  const loadTrash = async () => {
    setIsTrashOpen(true);
    setTrashLoading(true);
    setTrashError('');
    try {
      const { data } = await productApi.getTrash();
      setTrashProducts(data.products);
    } catch (err: any) {
      setTrashError(err.message || 'Không tải được thùng rác');
    } finally {
      setTrashLoading(false);
    }
  };

  const handleArchiveProduct = async (product: Product) => {
    if (!window.confirm(`Lưu trữ lô "${product.name}"? Lô sẽ được đưa vào thùng rác và có thể khôi phục sau.`)) {
      return;
    }
    try {
      await productApi.delete(product._id);
      setProducts((prev) => prev.filter((item) => item._id !== product._id));
      setSubmitSuccess(`Đã đưa "${product.name}" vào thùng rác.`);
    } catch (err: any) {
      setSubmitError(err.message || 'Không thể lưu trữ lô.');
    }
  };

  const handleRestoreProduct = async (product: Product) => {
    try {
      const { data } = await productApi.restore(product._id);
      setTrashProducts((prev) => prev.filter((item) => item._id !== product._id));
      setProducts((prev) => [data.product, ...prev]);
      setTrashError('');
    } catch (err: any) {
      setTrashError(err.message || 'Không thể khôi phục lô.');
    }
  };

  const handlePermanentDelete = async (product: Product) => {
    if (!window.confirm(`Xóa vĩnh viễn lô "${product.name}"? Chỉ lô chưa có lịch sử liên quan mới được xóa.`)) {
      return;
    }
    try {
      await productApi.permanentDelete(product._id);
      setTrashProducts((prev) => prev.filter((item) => item._id !== product._id));
      setTrashError('');
    } catch (err: any) {
      setTrashError(err.message || 'Không thể xóa vĩnh viễn lô.');
    }
  };

  if (loading) return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
      <p style={{ color: colors.textSecondary }}>Đang tải...</p>
    </div>
  );
  if (error) return (
    <div style={{ padding: spacing[6], background: '#fef2f2', borderRadius: borderRadius.lg, color: colors.error }}>
      Lỗi: {error}
    </div>
  );

  return (
    <div>
      {cameraProduct && (
        <ProductCameraModal
          product={cameraProduct}
          onClose={() => setCameraProduct(null)}
          onSaved={(updatedProduct) => {
            setProducts((prev) =>
              prev.map((item) =>
                item._id === updatedProduct._id ? updatedProduct : item
              )
            );
          }}
        />
      )}

      {isTrashOpen && (
        <div
          onMouseDown={(event) => event.target === event.currentTarget && setIsTrashOpen(false)}
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 1000,
            background: 'rgba(15, 23, 42, 0.45)',
            display: 'grid',
            placeItems: 'center',
            padding: spacing[5],
          }}
        >
          <div
            style={{
              width: 'min(860px, 100%)',
              maxHeight: '86vh',
              overflow: 'auto',
              background: colors.surface,
              borderRadius: borderRadius.xl,
              boxShadow: shadows.lg,
              border: `1px solid ${colors.neutral[200]}`,
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-start',
                gap: spacing[4],
                padding: spacing[6],
                borderBottom: `1px solid ${colors.neutral[200]}`,
              }}
            >
              <div>
                <h2 style={{ margin: 0, fontSize: typography.sizes.xl }}>
                  Thùng rác lô nông sản
                </h2>
                <p style={{ margin: `${spacing[1]} 0 0`, color: colors.textSecondary }}>
                  Khôi phục lô đã lưu trữ hoặc xóa vĩnh viễn khi không còn dữ liệu liên quan.
                </p>
              </div>
              <button type="button" onClick={() => setIsTrashOpen(false)} style={secondaryButtonStyle}>
                Đóng
              </button>
            </div>

            <div style={{ padding: spacing[6] }}>
              {trashError && (
                <div
                  style={{
                    marginBottom: spacing[4],
                    padding: spacing[3],
                    borderRadius: borderRadius.lg,
                    border: '1px solid #fecaca',
                    background: '#fff5f5',
                    color: '#b91c1c',
                  }}
                >
                  {trashError}
                </div>
              )}

              {trashLoading ? (
                <div style={{ padding: spacing[8], textAlign: 'center', color: colors.textSecondary }}>
                  Đang tải thùng rác...
                </div>
              ) : trashProducts.length === 0 ? (
                <div style={{ padding: spacing[8], textAlign: 'center', color: colors.textSecondary }}>
                  Thùng rác đang trống.
                </div>
              ) : (
                <div style={{ display: 'grid', gap: spacing[3] }}>
                  {trashProducts.map((product) => {
                    const deletedBy = product.deleted_by as any;
                    return (
                      <div
                        key={product._id}
                        style={{
                          display: 'grid',
                          gridTemplateColumns: '1fr auto',
                          gap: spacing[4],
                          padding: spacing[4],
                          border: `1px solid ${colors.neutral[200]}`,
                          borderRadius: borderRadius.lg,
                          background: colors.neutral[50],
                        }}
                      >
                        <div>
                          <strong>{product.name}</strong>
                          <div style={{ marginTop: spacing[1], color: colors.textSecondary, fontSize: typography.sizes.sm }}>
                            {product.category} • {product.origin}
                          </div>
                          <div style={{ marginTop: spacing[1], color: colors.textMuted, fontSize: typography.sizes.xs }}>
                            Lưu trữ: {formatDate(product.deletedAt)}{deletedBy ? ` bởi ${deletedBy.first_name || ''} ${deletedBy.last_name || ''}` : ''}
                          </div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: spacing[2], flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                          <button
                            type="button"
                            onClick={() => handleRestoreProduct(product)}
                            style={{
                              ...secondaryButtonStyle,
                              borderColor: '#86efac',
                              background: '#f0fdf4',
                              color: '#166534',
                            }}
                          >
                            Khôi phục
                          </button>
                          {user?.role === 'admin' && (
                            <button
                              type="button"
                              onClick={() => handlePermanentDelete(product)}
                              style={{
                                ...secondaryButtonStyle,
                                borderColor: '#fecaca',
                                background: '#fff5f5',
                                color: '#b91c1c',
                              }}
                            >
                              Xóa vĩnh viễn
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Page Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        marginBottom: spacing[8],
        gap: spacing[4],
        flexWrap: 'wrap',
      }}>
        <div>
          <h1 style={{ 
            margin: 0, 
            fontSize: typography.sizes['3xl'], 
            fontWeight: typography.weights.bold,
            color: colors.textPrimary,
          }}>
            Lô nông sản
          </h1>
          <p style={{ margin: `${spacing[2]} 0 0`, color: colors.textSecondary, fontSize: typography.sizes.base }}>
            Tạo lô mới và quản lý truy xuất nguồn gốc
          </p>
        </div>
        <div style={{ display: 'flex', gap: spacing[3], flexWrap: 'wrap' }}>
          {canManageTrash && (
            <button type="button" onClick={loadTrash} style={secondaryButtonStyle}>
              Thùng rác
            </button>
          )}
          <Link
            to="/add-event"
            style={{
              padding: `${spacing[3]} ${spacing[5]}`,
              borderRadius: borderRadius.lg,
              background: colors.primary[600],
              color: 'white',
              textDecoration: 'none',
              fontWeight: typography.weights.semibold,
              fontSize: typography.sizes.sm,
              display: 'inline-flex',
              alignItems: 'center',
              gap: spacing[2],
            }}
          >
            <span>+</span> Ghi sự kiện
          </Link>
        </div>
      </div>

      {/* Stats Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: spacing[5], marginBottom: spacing[8] }}>
        <StatCard
          label="Tổng lô hàng"
          value={products.length}
          icon={<CubeIcon color={colors.neutral[600]} />}
          borderAccent={colors.neutral[400]}
        />
        <StatCard
          label="Đang theo dõi"
          value={active}
          color={colors.primary[700]}
          icon={<ActivityIcon color={colors.primary[600]} />}
          borderAccent={colors.primary[500]}
        />
        <StatCard
          label="Hoàn tất"
          value={completed}
          color="#1d4ed8"
          icon={<CheckBadgeIcon color="#2563eb" />}
          borderAccent="#2563eb"
        />
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'minmax(360px, 480px) minmax(0, 1fr)',
        gap: spacing[6],
        alignItems: 'start',
      }}>
        {/* Create Form */}
        <form
          onSubmit={handleCreate}
          style={{
            background: colors.surface,
            borderRadius: borderRadius.xl,
            padding: spacing[6],
            boxShadow: shadows.md,
            border: `1px solid ${colors.neutral[200]}`,
            display: 'grid',
            gap: spacing[5],
          }}
        >
          <div>
            <h2 style={{ margin: 0, fontSize: typography.sizes.xl, fontWeight: typography.weights.semibold }}>
              Tạo lô hàng mới
            </h2>
            <p style={{ margin: `${spacing[2]} 0 0`, color: colors.textSecondary, fontSize: typography.sizes.sm }}>
              Chọn mô hình sản xuất và nhập thông tin lô
            </p>
          </div>

          {/* Production Type Tabs */}
          <div style={{ display: 'grid', gap: spacing[2] }}>
            <span style={{ fontWeight: typography.weights.medium, fontSize: typography.sizes.sm }}>Mô hình sản xuất</span>
            <div style={{ display: 'flex', gap: spacing[3] }}>
              {(Object.keys(productionTypeMeta) as ProductionType[]).map((type) => {
                const activeTab = formData.type === type;
                const meta = productionTypeMeta[type];
                return (
                  <button
                    key={type}
                    type="button"
                    onClick={() => handleTypeChange(type)}
                    style={{
                      flex: 1,
                      padding: `${spacing[3]} ${spacing[4]}`,
                      borderRadius: borderRadius.lg,
                      border: activeTab ? `2px solid ${colors.primary[600]}` : `1px solid ${colors.neutral[200]}`,
                      background: activeTab ? `linear-gradient(135deg, ${colors.primary[50]}, #f0fdf4)` : colors.surface,
                      color: activeTab ? colors.primary[800] : colors.textSecondary,
                      cursor: 'pointer',
                      textAlign: 'left',
                      transition: 'all 0.2s ease',
                      boxShadow: activeTab ? '0 4px 12px rgba(34, 197, 94, 0.12)' : 'none',
                      display: 'flex',
                      alignItems: 'center',
                      gap: spacing[3],
                    }}
                  >
                    <span style={{ fontSize: 24 }}>{meta.icon}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 700, fontSize: typography.sizes.sm }}>{meta.label}</div>
                      <div style={{ fontSize: 11, marginTop: 2, opacity: 0.8, lineHeight: 1.2 }}>
                        {meta.subtitle}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          <div style={{ display: 'grid', gap: 10 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
              <span style={{ fontWeight: 700 }}>Nhóm sản phẩm</span>
              <span style={{ color: '#6b7280', fontSize: 12 }}>
                Quản lý gọn ngay trong combobox
              </span>
            </div>

            <div
              ref={groupMenuRef}
              style={{
                position: 'relative',
              }}
            >
              <button
                type="button"
                onClick={() => setIsGroupMenuOpen((prev) => !prev)}
                style={{
                  ...fieldStyle,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  background: '#fff',
                  cursor: 'pointer',
                  textAlign: 'left',
                  border: isGroupMenuOpen ? `1px solid ${colors.primary[500]}` : `1px solid ${colors.neutral[300]}`,
                  boxShadow: isGroupMenuOpen ? `0 0 0 3px ${colors.primary[100]}` : 'none',
                }}
              >
                <span style={{ color: formData.category ? colors.textPrimary : colors.textMuted, fontWeight: formData.category ? 600 : 400 }}>
                  {formData.category || 'Chưa có nhóm. Bấm để thêm nhóm mới'}
                </span>
                <span style={{ display: 'flex', alignItems: 'center', color: colors.textSecondary }}>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor" style={{ width: 14, height: 14, transform: isGroupMenuOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s ease' }}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                  </svg>
                </span>
              </button>

              {isGroupMenuOpen && (
                <div
                  style={{
                    position: 'absolute',
                    zIndex: 10,
                    top: 'calc(100% + 8px)',
                    left: 0,
                    right: 0,
                    background: '#fff',
                    border: '1px solid #d1d5db',
                    borderRadius: 14,
                    boxShadow: '0 18px 40px rgba(15, 23, 42, 0.14)',
                    padding: 14,
                    display: 'grid',
                    gap: 10,
                  }}
                >
                  <div style={{ display: 'flex', gap: 8 }}>
                    <input
                      value={newGroupName}
                      onChange={(e) => setNewGroupName(e.target.value)}
                      placeholder={
                        formData.type === 'Plant'
                          ? 'Ví dụ: Rau ăn lá hữu cơ'
                          : 'Ví dụ: Gà thả vườn'
                      }
                      style={{ ...fieldStyle, flex: 1 }}
                    />
                    <button
                      type="button"
                      onClick={handleAddGroup}
                      style={{
                        padding: '10px 16px',
                        borderRadius: 10,
                        border: 'none',
                        background: '#166534',
                        color: '#fff',
                        fontWeight: 700,
                        cursor: 'pointer',
                        whiteSpace: 'nowrap',
                      }}
                    >
                      Thêm
                    </button>
                  </div>

                  <div
                    style={{
                      maxHeight: 260,
                      overflowY: 'auto',
                      display: 'grid',
                      gap: 8,
                    }}
                  >
                    {currentGroupOptions.length === 0 ? (
                      <div
                        style={{
                          border: '1px dashed #cbd5e1',
                          borderRadius: 10,
                          padding: 12,
                          color: '#64748b',
                          fontSize: 14,
                        }}
                      >
                        Chưa có nhóm nào cho mô hình này. Thêm nhóm đầu tiên để tạo lô.
                      </div>
                    ) : (
                      currentGroupOptions.map((item) => (
                        <div
                          key={item}
                          style={{
                            display: 'flex',
                            gap: 10,
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            border: '1px solid #e5e7eb',
                            borderRadius: 10,
                            padding: 10,
                            background: formData.category === item ? '#f0fdf4' : '#fff',
                          }}
                        >
                          {editingGroup === item ? (
                            <>
                              <input
                                value={editingGroupName}
                                onChange={(e) => setEditingGroupName(e.target.value)}
                                style={{ ...fieldStyle, flex: 1, padding: 10 }}
                                autoFocus
                              />
                              <div style={{ display: 'flex', gap: 6 }}>
                                <button
                                  type="button"
                                  onClick={() => handleSaveGroup(item)}
                                  style={{
                                    ...ghostButtonStyle,
                                    color: '#166534',
                                    background: '#dcfce7',
                                  }}
                                >
                                  Lưu
                                </button>
                                <button
                                  type="button"
                                  onClick={() => {
                                    setEditingGroup(null);
                                    setEditingGroupName('');
                                  }}
                                  style={ghostButtonStyle}
                                >
                                  Hủy
                                </button>
                              </div>
                            </>
                          ) : (
                            <>
                              <button
                                type="button"
                                onClick={() => handleSelectGroup(item)}
                                style={{
                                  border: 'none',
                                  background: 'transparent',
                                  cursor: 'pointer',
                                  textAlign: 'left',
                                  flex: 1,
                                  padding: 0,
                                  color: '#111827',
                                  fontWeight: formData.category === item ? 700 : 500,
                                }}
                              >
                                {item}
                              </button>
                              <div style={{ display: 'flex', gap: 4 }}>
                                <button
                                  type="button"
                                  onClick={() => handleStartEditGroup(item)}
                                  style={ghostButtonStyle}
                                >
                                  Sửa
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleDeleteGroup(item)}
                                  style={{
                                    ...ghostButtonStyle,
                                    color: '#b91c1c',
                                  }}
                                >
                                  Xóa
                                </button>
                              </div>
                            </>
                          )}
                        </div>
                      ))
                    )}
                  </div>

                  {groupError && (
                    <div
                      style={{
                        background: '#fef2f2',
                        color: '#b91c1c',
                        border: '1px solid #fecaca',
                        borderRadius: 10,
                        padding: 12,
                      }}
                    >
                      {groupError}
                    </div>
                  )}

                  {groupSuccess && (
                    <div
                      style={{
                        background: '#f0fdf4',
                        color: '#166534',
                        border: '1px solid #bbf7d0',
                        borderRadius: 10,
                        padding: 12,
                      }}
                    >
                      {groupSuccess}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Vùng trồng dropdown */}
          <label style={{ display: 'grid', gap: 8 }}>
            <span style={{ fontWeight: 700 }}>Vùng trồng / Trang trại</span>
            <select
              value={formData.farmingAreaId}
              onChange={handleFarmingAreaChange}
              style={{ ...fieldStyle, background: colors.surface }}
            >
              <option value="">-- Chọn vùng trồng (tùy chọn) --</option>
              {farmingAreas.map((area) => (
                <option key={area._id} value={area._id}>
                  {area.name} - {area.address}
                </option>
              ))}
            </select>
            <span style={{ fontSize: typography.sizes.xs, color: colors.textSecondary }}>
              Chọn vùng trồng sẽ tự động điền nơi sản xuất
            </span>
          </label>

          <label style={{ display: 'grid', gap: 8 }}>
            <span style={{ fontWeight: 700 }}>Tên lô / sản phẩm chính</span>
            <input
              value={formData.name}
              onChange={handleChange('name')}
              placeholder={productionMeta.placeholder}
              style={fieldStyle}
            />
          </label>

          <label style={{ display: 'grid', gap: 8 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 700 }}>Nơi sản xuất</span>
              {formData.farmingAreaId && (
                <span style={{ fontSize: typography.sizes.xs, color: colors.primary[600] }}>
                  ✓ Từ vùng trồng
                </span>
              )}
            </div>
            <input
              value={formData.origin}
              onChange={handleChange('origin')}
              placeholder="Ví dụ: Đà Lạt, Lâm Đồng"
              style={{
                ...fieldStyle,
                background: formData.farmingAreaId ? colors.neutral[50] : colors.surface,
              }}
            />
          </label>

          <label style={{ display: 'grid', gap: 8 }}>
            <span style={{ fontWeight: 700 }}>{productionMeta.startLabel}</span>
            <input
              type="date"
              value={formData.cultivationTime}
              onChange={handleChange('cultivationTime')}
              style={fieldStyle}
            />
          </label>

          <label style={{ display: 'grid', gap: 8 }}>
            <span style={{ fontWeight: 700 }}>Ghi chú lô</span>
            <textarea
              value={formData.note}
              onChange={handleChange('note')}
              rows={4}
              placeholder="Ví dụ: Lô demo cho tiểu luận, sản xuất theo quy trình VietGAP."
              style={{ ...fieldStyle, resize: 'vertical' }}
            />
          </label>

          <div
            style={{
              background: '#f8fafc',
              border: '1px solid #e5e7eb',
              borderRadius: 12,
              padding: 14,
            }}
          >
            <div style={{ fontWeight: 700, marginBottom: 6 }}>Tóm tắt sẽ lưu</div>
            <div style={{ color: '#475569', fontSize: 14, lineHeight: 1.5 }}>
              {formData.name.trim()
                ? buildDescription()
                : 'Nhập tên lô để xem mô tả tóm tắt.'}
            </div>
          </div>

          {submitError && (
            <div
              style={{
                background: '#fef2f2',
                color: '#b91c1c',
                border: '1px solid #fecaca',
                borderRadius: 10,
                padding: 12,
              }}
            >
              {submitError}
            </div>
          )}

          {submitSuccess && (
            <div
              style={{
                background: '#f0fdf4',
                color: '#166534',
                border: '1px solid #bbf7d0',
                borderRadius: 10,
                padding: 12,
              }}
            >
              {submitSuccess}
            </div>
          )}

          <button
            type="submit"
            disabled={submitting}
            style={{
              padding: '14px 20px',
              cursor: submitting ? 'not-allowed' : 'pointer',
              borderRadius: borderRadius.lg,
              border: 'none',
              background: submitting ? colors.neutral[400] : `linear-gradient(135deg, ${colors.primary[600]}, ${colors.primary[800]})`,
              color: '#fff',
              fontWeight: 700,
              fontSize: typography.sizes.base,
              boxShadow: submitting ? 'none' : '0 4px 14px rgba(22, 101, 52, 0.25)',
              transition: 'all 0.2s ease',
            }}
            onMouseEnter={(e) => {
              if (!submitting) {
                e.currentTarget.style.boxShadow = '0 6px 20px rgba(22, 101, 52, 0.35)';
                e.currentTarget.style.transform = 'translateY(-1px)';
              }
            }}
            onMouseLeave={(e) => {
              if (!submitting) {
                e.currentTarget.style.boxShadow = '0 4px 14px rgba(22, 101, 52, 0.25)';
                e.currentTarget.style.transform = 'translateY(0)';
              }
            }}
          >
            {submitting ? 'Đang tạo lô...' : 'Tạo lô hàng mới'}
          </button>
        </form>

        {products.length === 0 ? (
          <div
            style={{
              textAlign: 'center',
              padding: '48px 24px',
              color: '#6b7280',
              border: '2px dashed #e5e7eb',
              borderRadius: 12,
              background: '#fff',
            }}
          >
            <p style={{ fontSize: 18, marginTop: 0 }}>Chưa có lô hàng nào</p>
            <p style={{ marginBottom: 0 }}>Tạo lô đầu tiên bằng form bên trái.</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto', borderRadius: borderRadius.xl, border: `1px solid ${colors.neutral[200]}`, boxShadow: shadows.sm }}>
            <table
              style={{
                width: '100%',
                borderCollapse: 'collapse',
                backgroundColor: '#fff',
                overflow: 'hidden',
              }}
            >
              <thead>
                <tr style={{ backgroundColor: '#f9fafb' }}>
                  <th style={thStyle}>Tên lô / sản phẩm</th>
                  <th style={thStyle}>Nhóm</th>
                  <th style={thStyle}>Mô hình</th>
                  <th style={thStyle}>Nơi sản xuất</th>
                  <th style={thStyle}>Ngày bắt đầu</th>
                  <th style={thStyle}>Trạng thái</th>
                  <th style={{ ...thStyle, textAlign: 'center' }}>Hành động</th>
                </tr>
              </thead>
              <tbody>
                {products.map((p, i) => (
                  <tr
                    key={p._id}
                    style={{
                      borderTop: i > 0 ? `1px solid ${colors.neutral[200]}` : undefined,
                      backgroundColor: i % 2 === 1 ? '#fafafa' : '#fff',
                      transition: 'background-color 0.2s ease',
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.backgroundColor = '#f0fdf480';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.backgroundColor = i % 2 === 1 ? '#fafafa' : '#fff';
                    }}
                  >
                    <td style={{ padding: '16px 16px', fontWeight: 600, color: colors.textPrimary }}>{p.name}</td>
                    <td style={{ padding: '16px 16px', color: colors.textSecondary }}>{p.category}</td>
                    <td style={{ padding: '16px 16px', color: colors.textSecondary }}>
                      {p.type === 'Plant' ? '🌱 Trồng trọt' : '🐔 Chăn nuôi'}
                    </td>
                    <td style={{ padding: '16px 16px', color: colors.textSecondary }}>{p.origin}</td>
                    <td style={{ padding: '16px 16px', color: colors.textSecondary }}>
                      {formatDate(p.cultivation_time)}
                    </td>
                    <td style={{ padding: '16px 16px' }}>
                      <span
                        style={{
                          fontSize: typography.sizes.xs,
                          fontWeight: typography.weights.semibold,
                          color: statusColors[p.status]?.text || colors.textSecondary,
                          background: statusColors[p.status]?.bg || colors.neutral[100],
                          padding: `${spacing[1]} ${spacing[3]}`,
                          borderRadius: borderRadius.full,
                          display: 'inline-block',
                          boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
                        }}
                      >
                        {statusLabel[p.status] || p.status}
                      </span>
                    </td>
                    <td style={{ padding: '16px 16px', textAlign: 'center', whiteSpace: 'nowrap' }}>
                      <div style={{ display: 'inline-flex', gap: spacing[2], alignItems: 'center', justifyContent: 'center' }}>
                        <Link
                          to={`/trace/${p._id}`}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                            padding: '6px 12px',
                            borderRadius: borderRadius.full,
                            border: '1px solid #3b82f6',
                            background: '#eff6ff',
                            color: '#1d4ed8',
                            fontSize: 12,
                            textDecoration: 'none',
                            fontWeight: 600,
                            transition: 'all 0.2s ease',
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.background = '#dbeafe';
                            e.currentTarget.style.transform = 'translateY(-1px)';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.background = '#eff6ff';
                            e.currentTarget.style.transform = 'translateY(0)';
                          }}
                        >
                          <EyeIcon />
                          Xem trace
                        </Link>
                        <Link
                          to={`/add-event?productId=${p._id}`}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                            padding: '6px 12px',
                            borderRadius: borderRadius.full,
                            border: '1px solid #22c55e',
                            background: '#f0fdf4',
                            color: '#15803d',
                            fontSize: 12,
                            textDecoration: 'none',
                            fontWeight: 600,
                            transition: 'all 0.2s ease',
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.background = '#dcfce7';
                            e.currentTarget.style.transform = 'translateY(-1px)';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.background = '#f0fdf4';
                            e.currentTarget.style.transform = 'translateY(0)';
                          }}
                        >
                          <PlusCircleIcon />
                          Ghi sự kiện
                        </Link>
                        <button
                          type="button"
                          onClick={() => setCameraProduct(p)}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                            padding: '6px 12px',
                            borderRadius: borderRadius.full,
                            border: '1px solid #f87171',
                            background: '#fef2f2',
                            color: '#b91c1c',
                            fontSize: 12,
                            fontWeight: 600,
                            cursor: 'pointer',
                            transition: 'all 0.2s ease',
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.background = '#fee2e2';
                            e.currentTarget.style.transform = 'translateY(-1px)';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.background = '#fef2f2';
                            e.currentTarget.style.transform = 'translateY(0)';
                          }}
                        >
                          <CameraIcon />
                          Camera
                          <span style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            background: '#dc2626',
                            color: '#fff',
                            fontSize: 10,
                            fontWeight: 800,
                            height: 18,
                            minWidth: 18,
                            padding: '0 4px',
                            borderRadius: 99,
                            marginLeft: 2,
                          }}>
                            {p.live_cameras?.length ?? 0}
                          </span>
                        </button>
                        {canArchiveProduct && (
                          <button
                            type="button"
                            onClick={() => handleArchiveProduct(p)}
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: 6,
                              padding: '6px 12px',
                              borderRadius: borderRadius.full,
                              border: '1px solid #d1d5db',
                              background: '#f9fafb',
                              color: '#4b5563',
                              fontSize: 12,
                              fontWeight: 600,
                              cursor: 'pointer',
                              transition: 'all 0.2s ease',
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.background = '#f3f4f6';
                              e.currentTarget.style.transform = 'translateY(-1px)';
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.background = '#f9fafb';
                              e.currentTarget.style.transform = 'translateY(0)';
                            }}
                          >
                            Lưu trữ
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default DashboardPage;

import React, { useEffect, useState } from 'react';
import { farmingAreaApi, FarmingArea, CreateFarmingAreaData } from '../../core/api/farmingArea.api';
import { colors, spacing, borderRadius, shadows, typography } from '../../core/theme';

interface CertificationBadge {
  _id: string;
  name: string;
  type: string;
  status: string;
  expiry_date?: string;
}

interface FarmingAreaWithCerts extends FarmingArea {
  certifications?: CertificationBadge[];
}

const certTypeColors: Record<string, { bg: string; text: string }> = {
  VietGAP: { bg: '#dcfce7', text: '#166534' },
  GlobalGAP: { bg: '#dbeafe', text: '#1d4ed8' },
  Organic: { bg: '#fef3c7', text: '#92400e' },
  HACCP: { bg: '#fce7f3', text: '#be185d' },
  ISO22000: { bg: '#e0e7ff', text: '#4338ca' },
  Other: { bg: '#f3f4f6', text: '#374151' },
};

const fieldStyle: React.CSSProperties = {
  padding: `${spacing[3]} ${spacing[4]}`,
  borderRadius: borderRadius.lg,
  border: `1px solid ${colors.neutral[300]}`,
  fontSize: typography.sizes.base,
  width: '100%',
  boxSizing: 'border-box',
};

const FarmingAreaPage: React.FC = () => {
  const [areas, setAreas] = useState<FarmingAreaWithCerts[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState<CreateFarmingAreaData>({
    name: '',
    address: '',
    area_size: undefined,
    description: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  const fetchAreas = async () => {
    try {
      setLoading(true);
      const { data } = await farmingAreaApi.getAll();
      setAreas(data.farmingAreas as FarmingAreaWithCerts[]);
    } catch (err: any) {
      setError(err.message || 'Không tải được danh sách vùng trồng');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAreas();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name || !formData.address) {
      setError('Vui lòng nhập tên và địa chỉ');
      return;
    }
    setSubmitting(true);
    setError('');
    try {
      if (editingId) {
        await farmingAreaApi.update(editingId, formData);
      } else {
        await farmingAreaApi.create(formData);
      }
      setShowForm(false);
      setFormData({ name: '', address: '', area_size: undefined, description: '' });
      setEditingId(null);
      fetchAreas();
    } catch (err: any) {
      setError(err.message || 'Không thể lưu vùng trồng');
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (area: FarmingAreaWithCerts) => {
    setFormData({
      name: area.name,
      address: area.address,
      area_size: area.area_size,
      description: area.description,
    });
    setEditingId(area._id);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Bạn có chắc muốn xóa vùng trồng này?')) return;
    try {
      await farmingAreaApi.delete(id);
      fetchAreas();
    } catch (err: any) {
      setError(err.message || 'Không thể xóa');
    }
  };

  return (
    <div className="feature-page farming-page">
      <div className="feature-page-heading" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing[6] }}>
        <div>
          <h1 style={{ margin: 0, fontSize: typography.sizes['2xl'], fontWeight: typography.weights.bold }}>
            Quản lý Vùng trồng
          </h1>
          <p style={{ color: colors.textSecondary, margin: `${spacing[2]} 0 0`, fontSize: typography.sizes.sm }}>
            Thêm, sửa, xóa thông tin các vùng trồng / trang trại
          </p>
        </div>
        <button 
          style={{ 
            background: colors.primary[600], color: 'white', border: 'none', 
            borderRadius: borderRadius.lg, padding: `${spacing[3]} ${spacing[5]}`, 
            fontWeight: typography.weights.semibold, cursor: 'pointer' 
          }}
          onClick={() => { setShowForm(true); setEditingId(null); setFormData({ name: '', address: '', area_size: undefined, description: '' }); }}
        >
          + Thêm vùng trồng
        </button>
      </div>

      {error && (
        <div style={{ background: '#fef2f2', color: '#b91c1c', padding: spacing[4], borderRadius: borderRadius.lg, marginBottom: spacing[4] }}>
          {error}
        </div>
      )}

      {showForm && (
        <div className="feature-form-card" style={{
          background: colors.surface, border: `1px solid ${colors.neutral[200]}`, 
          borderRadius: borderRadius.xl, padding: spacing[6], marginBottom: spacing[6], boxShadow: shadows.sm 
        }}>
          <h3 style={{ marginTop: 0, fontSize: typography.sizes.lg, fontWeight: typography.weights.semibold }}>
            {editingId ? 'Sửa vùng trồng' : 'Thêm vùng trồng mới'}
          </h3>
          <form onSubmit={handleSubmit}>
            <div style={{ display: 'grid', gap: spacing[4], maxWidth: 500 }}>
              <div>
                <label style={{ display: 'block', marginBottom: spacing[2], fontWeight: typography.weights.medium, fontSize: typography.sizes.sm }}>
                  Tên vùng trồng *
                </label>
                <input 
                  style={fieldStyle} 
                  placeholder="Ví dụ: Trang trại rau sạch Đà Lạt" 
                  value={formData.name} 
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })} 
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: spacing[2], fontWeight: typography.weights.medium, fontSize: typography.sizes.sm }}>
                  Địa chỉ *
                </label>
                <input 
                  style={fieldStyle} 
                  placeholder="Ví dụ: Xã Xuân Thọ, TP. Đà Lạt, Lâm Đồng" 
                  value={formData.address} 
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })} 
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: spacing[2], fontWeight: typography.weights.medium, fontSize: typography.sizes.sm }}>
                  Diện tích (ha)
                </label>
                <input 
                  style={fieldStyle} 
                  type="number" 
                  placeholder="Ví dụ: 5.5" 
                  value={formData.area_size || ''} 
                  onChange={(e) => setFormData({ ...formData, area_size: e.target.value ? Number(e.target.value) : undefined })} 
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: spacing[2], fontWeight: typography.weights.medium, fontSize: typography.sizes.sm }}>
                  Mô tả
                </label>
                <textarea 
                  style={{ ...fieldStyle, minHeight: 80, resize: 'vertical' }} 
                  placeholder="Mô tả về vùng trồng..." 
                  value={formData.description || ''} 
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })} 
                />
              </div>
              <div style={{ display: 'flex', gap: spacing[3] }}>
                <button 
                  type="submit" 
                  style={{ 
                    background: colors.primary[600], color: 'white', border: 'none', 
                    borderRadius: borderRadius.lg, padding: `${spacing[3]} ${spacing[5]}`, 
                    fontWeight: typography.weights.semibold, cursor: submitting ? 'not-allowed' : 'pointer' 
                  }} 
                  disabled={submitting}
                >
                  {submitting ? 'Đang lưu...' : editingId ? 'Cập nhật' : 'Thêm mới'}
                </button>
                <button 
                  type="button" 
                  style={{ 
                    background: colors.neutral[200], color: colors.textSecondary, border: 'none', 
                    borderRadius: borderRadius.lg, padding: `${spacing[3]} ${spacing[5]}`, 
                    fontWeight: typography.weights.medium, cursor: 'pointer' 
                  }} 
                  onClick={() => setShowForm(false)}
                >
                  Hủy
                </button>
              </div>
            </div>
          </form>
        </div>
      )}

      {loading ? (
        <p style={{ color: colors.textSecondary }}>Đang tải...</p>
      ) : areas.length === 0 ? (
        <div style={{ 
          background: colors.surface, border: `1px solid ${colors.neutral[200]}`, 
          borderRadius: borderRadius.xl, padding: spacing[8], textAlign: 'center' 
        }}>
          <p style={{ color: colors.textSecondary, margin: 0 }}>Chưa có vùng trồng nào</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: spacing[5], gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))' }}>
          {areas.map((area) => (
            <div 
              key={area._id} 
              style={{ 
                background: colors.surface, border: `1px solid ${colors.neutral[200]}`, 
                borderRadius: borderRadius.xl, padding: spacing[5], boxShadow: shadows.sm 
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: spacing[3] }}>
                <h3 style={{ margin: 0, fontSize: typography.sizes.lg, fontWeight: typography.weights.semibold }}>
                  {area.name}
                </h3>
                <span style={{ 
                  background: area.status === 'active' ? colors.primary[100] : colors.neutral[100], 
                  color: area.status === 'active' ? colors.primary[700] : colors.textSecondary, 
                  padding: `${spacing[1]} ${spacing[3]}`, borderRadius: borderRadius.full, 
                  fontSize: typography.sizes.xs, fontWeight: typography.weights.semibold 
                }}>
                  {area.status === 'active' ? 'Hoạt động' : 'Ngừng'}
                </span>
              </div>

              <p style={{ color: colors.textSecondary, margin: `0 0 ${spacing[2]}`, fontSize: typography.sizes.sm }}>
                📍 {area.address}
              </p>
              
              {area.area_size && (
                <p style={{ margin: `0 0 ${spacing[2]}`, fontSize: typography.sizes.sm }}>
                  📐 Diện tích: <strong>{area.area_size} ha</strong>
                </p>
              )}
              
              {area.description && (
                <p style={{ margin: `0 0 ${spacing[3]}`, fontSize: typography.sizes.sm, color: colors.textSecondary }}>
                  {area.description}
                </p>
              )}

              {/* Certification Badges */}
              {area.certifications && area.certifications.length > 0 && (
                <div style={{ marginBottom: spacing[4] }}>
                  <p style={{ margin: `0 0 ${spacing[2]}`, fontSize: typography.sizes.xs, color: colors.textSecondary, fontWeight: typography.weights.medium }}>
                    🏆 CHỨNG NHẬN
                  </p>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: spacing[2] }}>
                    {area.certifications.map((cert) => {
                      const certColor = certTypeColors[cert.type] || certTypeColors.Other;
                      const isExpired = cert.status === 'expired';
                      return (
                        <span
                          key={cert._id}
                          title={`${cert.name}${isExpired ? ' (Hết hạn)' : ''}`}
                          style={{
                            background: isExpired ? colors.neutral[100] : certColor.bg,
                            color: isExpired ? colors.neutral[500] : certColor.text,
                            padding: `${spacing[1]} ${spacing[3]}`,
                            borderRadius: borderRadius.full,
                            fontSize: typography.sizes.xs,
                            fontWeight: typography.weights.semibold,
                            textDecoration: isExpired ? 'line-through' : 'none',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: spacing[1],
                          }}
                        >
                          {cert.type}
                          {isExpired && <span style={{ fontSize: 10 }}>⚠️</span>}
                        </span>
                      );
                    })}
                  </div>
                </div>
              )}

              <p style={{ fontSize: typography.sizes.xs, color: colors.neutral[400], margin: `0 0 ${spacing[3]}` }}>
                👤 Chủ sở hữu: {area.owner?.first_name} {area.owner?.last_name}
              </p>

              <div style={{ display: 'flex', gap: spacing[3] }}>
                <button 
                  onClick={() => handleEdit(area)} 
                  style={{ 
                    background: '#2563eb', color: 'white', border: 'none', 
                    borderRadius: borderRadius.md, padding: `${spacing[2]} ${spacing[4]}`, 
                    fontSize: typography.sizes.sm, fontWeight: typography.weights.medium, 
                    cursor: 'pointer' 
                  }}
                >
                  Sửa
                </button>
                <button 
                  onClick={() => handleDelete(area._id)} 
                  style={{ 
                    background: '#dc2626', color: 'white', border: 'none', 
                    borderRadius: borderRadius.md, padding: `${spacing[2]} ${spacing[4]}`, 
                    fontSize: typography.sizes.sm, fontWeight: typography.weights.medium, 
                    cursor: 'pointer' 
                  }}
                >
                  Xóa
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default FarmingAreaPage;

import React, { FormEvent, useEffect, useMemo, useState } from 'react';
import { diseaseDetectionApi } from '../../core/api/diseaseDetection.api';
import { productApi } from '../../core/api/product.api';
import { useAuth } from '../../core/hooks/useAuth';
import type { DiseaseDetection, DiseaseRiskLevel, Product } from '../../core/types';
import './DiseaseDetectionPage.css';

const symptomOptions = [
  'Vàng lá',
  'Đốm nâu',
  'Cháy lá',
  'Héo rũ',
  'Thối rễ',
  'Phấn trắng',
  'Lỗ thủng trên lá',
  'Rệp hoặc côn trùng',
  'Xoăn lá',
  'Chậm lớn',
];

const riskLabels: Record<DiseaseRiskLevel, string> = {
  low: 'Rủi ro thấp',
  medium: 'Cần theo dõi',
  high: 'Nguy cơ cao',
};

const DiseaseDetectionPage: React.FC = () => {
  const { user } = useAuth();
  const [products, setProducts] = useState<Product[]>([]);
  const [detections, setDetections] = useState<DiseaseDetection[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [productId, setProductId] = useState('');
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>([]);
  const [notes, setNotes] = useState('');
  const [images, setImages] = useState<File[]>([]);
  const [filterRisk, setFilterRisk] = useState('');
  const canAnalyze = user?.role === 'admin' || user?.role === 'manager' || user?.role === 'farmer';

  const load = async () => {
    try {
      setLoading(true);
      setError('');
      const [productRes, detectionRes] = await Promise.all([
        productApi.getAll(),
        diseaseDetectionApi.getAll(),
      ]);
      setProducts(productRes.data.products);
      setDetections(detectionRes.data.detections);
      setProductId((current) => current || productRes.data.products[0]?._id || '');
    } catch (err: any) {
      setError(err.message || 'Không thể tải dữ liệu nhận diện bệnh');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const visible = useMemo(
    () =>
      detections.filter(
        (item) => !filterRisk || item.overall_risk === filterRisk
      ),
    [detections, filterRisk]
  );

  const totals = useMemo(
    () => ({
      high: detections.filter((item) => item.overall_risk === 'high').length,
      medium: detections.filter((item) => item.overall_risk === 'medium').length,
      low: detections.filter((item) => item.overall_risk === 'low').length,
    }),
    [detections]
  );

  const toggleSymptom = (symptom: string) => {
    setSelectedSymptoms((current) =>
      current.includes(symptom)
        ? current.filter((item) => item !== symptom)
        : [...current, symptom]
    );
  };

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (!productId) {
      setError('Vui lòng chọn lô cần nhận diện');
      return;
    }
    if (selectedSymptoms.length === 0 && !notes.trim() && images.length === 0) {
      setError('Vui lòng chọn triệu chứng, nhập ghi chú hoặc tải ảnh cây trồng');
      return;
    }

    try {
      setSaving(true);
      setError('');
      const { data } = await diseaseDetectionApi.create({
        product: productId,
        symptoms: selectedSymptoms,
        notes: notes.trim() || undefined,
        images,
      });
      setDetections((current) => [data.detection, ...current]);
      setSelectedSymptoms([]);
      setNotes('');
      setImages([]);
    } catch (err: any) {
      setError(err.message || 'Không thể nhận diện bệnh');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (id: string) => {
    if (!window.confirm('Bạn có chắc muốn xóa kết quả nhận diện này?')) return;
    try {
      await diseaseDetectionApi.delete(id);
      setDetections((current) => current.filter((item) => item._id !== id));
    } catch (err: any) {
      setError(err.message || 'Không thể xóa kết quả nhận diện');
    }
  };

  return (
    <div className="disease-page">
      <header className="disease-heading">
        <div>
          <span>GIÁM SÁT SÂU BỆNH</span>
          <h1>Nhận diện bệnh cây</h1>
          <p>Ghi nhận ảnh và triệu chứng để sàng lọc rủi ro bệnh trên từng lô.</p>
        </div>
      </header>

      {error && <div className="disease-alert">{error}<button onClick={() => setError('')}>×</button></div>}

      <section className="disease-stats">
        <article><small>TỔNG LƯỢT</small><strong>{detections.length}</strong><p>Kết quả đã lưu</p></article>
        <article className="is-high"><small>NGUY CƠ CAO</small><strong>{totals.high}</strong><p>Cần xử lý sớm</p></article>
        <article className="is-medium"><small>CẦN THEO DÕI</small><strong>{totals.medium}</strong><p>Kiểm tra lại vườn</p></article>
        <article className="is-low"><small>RỦI RO THẤP</small><strong>{totals.low}</strong><p>Tiếp tục quan sát</p></article>
      </section>

      {canAnalyze && (
        <section className="disease-analyzer">
          <form onSubmit={submit}>
            <div className="disease-form-head">
              <div><span>PHÂN TÍCH MỚI</span><h2>Thông tin cây nghi bệnh</h2></div>
              <button type="submit" disabled={saving}>{saving ? 'Đang phân tích...' : 'Nhận diện'}</button>
            </div>
            <div className="disease-form-grid">
              <label>Lô nông sản<select value={productId} onChange={(event) => setProductId(event.target.value)} required><option value="">Chọn lô</option>{products.map((product) => <option key={product._id} value={product._id}>{product.name} - {product.origin}</option>)}</select></label>
              <label>Ảnh cây trồng<input type="file" accept="image/*" multiple onChange={(event) => setImages(Array.from(event.target.files || []).slice(0, 5))} /></label>
              <div className="disease-symptoms">
                <span>Triệu chứng quan sát</span>
                <div>
                  {symptomOptions.map((symptom) => (
                    <button className={selectedSymptoms.includes(symptom) ? 'is-selected' : ''} key={symptom} type="button" onClick={() => toggleSymptom(symptom)}>{symptom}</button>
                  ))}
                </div>
              </div>
              <label className="is-wide">Ghi chú thực địa<textarea rows={4} value={notes} onChange={(event) => setNotes(event.target.value)} placeholder="Ví dụ: Lá xuất hiện đốm nâu lan nhanh sau mưa, cây hơi héo vào buổi trưa..." /></label>
            </div>
          </form>
        </section>
      )}

      <section className="disease-list">
        <div className="disease-toolbar">
          <div><span>LỊCH SỬ</span><h2>Kết quả nhận diện</h2></div>
          <select value={filterRisk} onChange={(event) => setFilterRisk(event.target.value)}>
            <option value="">Tất cả mức rủi ro</option>
            <option value="high">Nguy cơ cao</option>
            <option value="medium">Cần theo dõi</option>
            <option value="low">Rủi ro thấp</option>
          </select>
        </div>

        {loading ? <div className="disease-empty">Đang tải dữ liệu...</div> :
          visible.length === 0 ? (
            <div className="disease-empty"><strong>Chưa có kết quả nhận diện</strong><p>Thêm ảnh và triệu chứng để tạo bản ghi đầu tiên.</p></div>
          ) : (
            <div className="disease-grid">
              {visible.map((item) => {
                const product = item.product as Product;
                const top = item.top_disease;
                return (
                  <article className={`disease-card risk-${item.overall_risk}`} key={item._id}>
                    <div className="disease-card-top"><span>{riskLabels[item.overall_risk]}</span><small>{new Date(item.createdAt).toLocaleDateString('vi-VN')}</small></div>
                    <h3>{top.disease_name}</h3>
                    <p>{top.description}</p>
                    <dl><div><dt>Lô</dt><dd>{product?.name || 'Lô nông sản'}</dd></div><div><dt>Độ tin cậy</dt><dd>{Math.round(top.confidence * 100)}%</dd></div><div><dt>Ảnh</dt><dd>{item.images?.length || 0}</dd></div></dl>
                    <div className="disease-recommendations">
                      {top.recommendations.slice(0, 3).map((recommendation) => <p key={recommendation}>{recommendation}</p>)}
                    </div>
                    <footer><span>{item.model_version}</span><button onClick={() => remove(item._id)}>Xóa</button></footer>
                  </article>
                );
              })}
            </div>
          )}
      </section>
    </div>
  );
};

export default DiseaseDetectionPage;

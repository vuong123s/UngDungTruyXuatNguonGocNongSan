import Product from '../models/Product';
import DiseaseDetection, {
  DiseaseRiskLevel,
  IDiseaseCandidate,
} from '../models/DiseaseDetection';
import { BadRequestError, NotFoundError, UnauthorizedError } from '../utils/errors';

const MODEL_VERSION = 'ruleset-v1';

interface DiseaseRule {
  disease_code: string;
  disease_name: string;
  risk_level: DiseaseRiskLevel;
  keywords: string[];
  description: string;
  recommendations: string[];
}

const diseaseRules: DiseaseRule[] = [
  {
    disease_code: 'leaf_spot',
    disease_name: 'Đốm lá do nấm',
    risk_level: 'medium',
    keywords: ['đốm', 'dom', 'nâu', 'nau', 'cháy lá', 'chay la', 'vàng lá', 'vang la'],
    description:
      'Lá xuất hiện đốm nâu/vàng hoặc vùng cháy mép, thường liên quan đến nấm bệnh và ẩm độ cao.',
    recommendations: [
      'Tỉa bỏ lá bệnh và gom ra khỏi khu vực canh tác.',
      'Giảm tưới phun lên tán lá, tăng thông thoáng luống trồng.',
      'Theo dõi 2-3 ngày và tham khảo cán bộ kỹ thuật nếu vết bệnh lan nhanh.',
    ],
  },
  {
    disease_code: 'powdery_mildew',
    disease_name: 'Phấn trắng',
    risk_level: 'medium',
    keywords: ['phấn trắng', 'phan trang', 'mốc trắng', 'moc trang', 'bột trắng', 'bot trang'],
    description:
      'Bề mặt lá có lớp bột trắng hoặc mốc trắng, dễ gặp khi vườn ẩm và thiếu thông thoáng.',
    recommendations: [
      'Cách ly khu vực có cây bệnh để hạn chế lây lan.',
      'Tăng ánh sáng và luồng gió trong tán cây.',
      'Sử dụng chế phẩm sinh học hoặc thuốc được phép theo hướng dẫn kỹ thuật.',
    ],
  },
  {
    disease_code: 'bacterial_wilt',
    disease_name: 'Héo xanh/héo rũ',
    risk_level: 'high',
    keywords: ['héo', 'heo', 'rũ', 'ru', 'héo rũ', 'heo ru', 'thối rễ', 'thoi re'],
    description:
      'Cây héo nhanh, rũ lá hoặc thối rễ có thể là dấu hiệu bệnh hệ thống, nguy cơ ảnh hưởng cả luống.',
    recommendations: [
      'Đánh dấu và cách ly cây nghi nhiễm ngay.',
      'Kiểm tra độ ẩm đất, rễ và lịch tưới gần nhất.',
      'Không dùng cây bệnh làm giống; báo kỹ thuật viên để xác nhận trước khi xử lý diện rộng.',
    ],
  },
  {
    disease_code: 'pest_damage',
    disease_name: 'Sâu hại/côn trùng gây hại',
    risk_level: 'medium',
    keywords: ['sâu', 'sau', 'bọ', 'bo', 'rệp', 'rep', 'lỗ thủng', 'lo thung', 'ăn lá', 'an la'],
    description:
      'Lá bị thủng, biến dạng hoặc có côn trùng/rệp bám là dấu hiệu sâu hại đang hoạt động.',
    recommendations: [
      'Kiểm tra mặt dưới lá và mật độ sâu hại theo từng điểm trong vườn.',
      'Ưu tiên bẫy sinh học hoặc thiên địch khi mật độ còn thấp.',
      'Ghi nhật ký xử lý nếu dùng thuốc bảo vệ thực vật.',
    ],
  },
  {
    disease_code: 'nutrient_stress',
    disease_name: 'Thiếu dinh dưỡng hoặc stress môi trường',
    risk_level: 'low',
    keywords: ['vàng', 'vang', 'nhạt màu', 'nhat mau', 'chậm lớn', 'cham lon', 'xoăn lá', 'xoan la'],
    description:
      'Cây sinh trưởng chậm, lá nhạt màu hoặc xoăn nhẹ có thể do dinh dưỡng, nước tưới hoặc thời tiết.',
    recommendations: [
      'Kiểm tra lịch bón phân, pH đất/nước và độ ẩm đất.',
      'Bổ sung dinh dưỡng cân đối, tránh bón đạm quá mức.',
      'Theo dõi lô trong 5-7 ngày sau điều chỉnh chăm sóc.',
    ],
  },
];

const healthyCandidate: IDiseaseCandidate = {
  disease_code: 'healthy',
  disease_name: 'Chưa phát hiện dấu hiệu bệnh rõ ràng',
  confidence: 0.58,
  risk_level: 'low',
  description:
    'Thông tin triệu chứng chưa đủ để xác định bệnh cụ thể. Kết quả này chỉ mang tính hỗ trợ sàng lọc ban đầu.',
  recommendations: [
    'Chụp ảnh rõ mặt trên và mặt dưới lá để kiểm tra lại khi có dấu hiệu mới.',
    'Tiếp tục theo dõi sinh trưởng, độ ẩm và lịch chăm sóc của lô.',
  ],
};

const normalizeText = (value: string) =>
  value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

const riskWeight = (risk: DiseaseRiskLevel) =>
  risk === 'high' ? 3 : risk === 'medium' ? 2 : 1;

const inferRisk = (candidates: IDiseaseCandidate[]): DiseaseRiskLevel => {
  const max = Math.max(...candidates.map((candidate) => riskWeight(candidate.risk_level)));
  return max >= 3 ? 'high' : max === 2 ? 'medium' : 'low';
};

const analyzeSymptoms = (
  symptoms: string[],
  notes?: string
): IDiseaseCandidate[] => {
  const source = normalizeText([...symptoms, notes || ''].join(' '));
  const candidates = diseaseRules
    .map((rule) => {
      const matches = rule.keywords.filter((keyword) =>
        source.includes(normalizeText(keyword))
      ).length;
      if (matches === 0) return null;

      return {
        disease_code: rule.disease_code,
        disease_name: rule.disease_name,
        confidence: Math.min(0.92, 0.45 + matches * 0.12),
        risk_level: rule.risk_level,
        description: rule.description,
        recommendations: rule.recommendations,
      };
    })
    .filter((candidate): candidate is IDiseaseCandidate => Boolean(candidate))
    .sort((left, right) => right.confidence - left.confidence);

  if (candidates.length === 0) return [healthyCandidate];
  return candidates.slice(0, 3);
};

export const getDetections = async (filters: {
  product?: string;
  risk?: DiseaseRiskLevel;
}) => {
  const query: Record<string, string> = {};
  if (filters.product) query.product = filters.product;
  if (filters.risk) query.overall_risk = filters.risk;

  return DiseaseDetection.find(query)
    .populate('product', 'name category origin status created_by')
    .populate('detected_by', 'first_name last_name email')
    .sort({ createdAt: -1 });
};

export const getDetectionsByProduct = async (productId: string) => {
  const product = await Product.exists({
    _id: productId,
    isDeleted: { $ne: true },
  });
  if (!product) throw new NotFoundError(`Không tìm thấy lô ${productId}`);

  return DiseaseDetection.find({ product: productId })
    .populate('detected_by', 'first_name last_name email')
    .sort({ createdAt: -1 });
};

export const createDetection = async (
  data: {
    product: string;
    crop_name?: string;
    symptoms?: string[];
    notes?: string;
    images?: { path: string; filename: string }[];
  },
  userId: string,
  userRole: string
) => {
  const product = await Product.findOne({
    _id: data.product,
    isDeleted: { $ne: true },
  }).select(
    'name category created_by'
  );
  if (!product) throw new NotFoundError(`Không tìm thấy lô ${data.product}`);

  if (userRole === 'farmer' && product.created_by.toString() !== userId) {
    throw new UnauthorizedError('Bạn chỉ được nhận diện bệnh cho lô của mình');
  }

  const symptoms = (data.symptoms || [])
    .map((symptom) => symptom.trim())
    .filter(Boolean);
  const notes = data.notes?.trim();
  if (symptoms.length === 0 && !notes && (!data.images || data.images.length === 0)) {
    throw new BadRequestError('Vui lòng nhập triệu chứng hoặc tải ảnh cây trồng');
  }

  const candidates = analyzeSymptoms(symptoms, notes);
  const topDisease = candidates[0];
  const detection = await DiseaseDetection.create({
    product: data.product,
    crop_name: data.crop_name?.trim() || product.name,
    symptoms,
    notes,
    images: data.images || [],
    candidates,
    top_disease: topDisease,
    overall_risk: inferRisk(candidates),
    model_version: MODEL_VERSION,
    detected_by: userId,
  });

  return DiseaseDetection.findById(detection._id)
    .populate('product', 'name category origin status')
    .populate('detected_by', 'first_name last_name email');
};

export const removeDetection = async (
  id: string,
  userId: string,
  userRole: string
) => {
  const detection = await DiseaseDetection.findById(id).populate(
    'product',
    'created_by'
  );
  if (!detection) throw new NotFoundError(`Không tìm thấy kết quả ${id}`);

  const product = detection.product as any;
  if (
    userRole === 'farmer' &&
    product?.created_by?.toString &&
    product.created_by.toString() !== userId
  ) {
    throw new UnauthorizedError('Bạn chỉ được xóa kết quả của lô mình quản lý');
  }

  await DiseaseDetection.findByIdAndDelete(id);
  return detection;
};

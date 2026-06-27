import 'dotenv/config';
import mongoose, { Types } from 'mongoose';
import connectDB from '../config/db';
import env from '../config/env';
import User from '../models/User';
import FarmingArea from '../models/FarmingArea';
import Product from '../models/Product';
import TraceEvent from '../models/TraceEvent';
import Certification from '../models/Certification';
import QualityInspection from '../models/QualityInspection';
import DiseaseDetection from '../models/DiseaseDetection';
import SupplyChainOrganization from '../models/SupplyChainOrganization';
import SupplyChainRecord from '../models/SupplyChainRecord';
import InventoryTransaction from '../models/InventoryTransaction';

const oid = (value: string) => new Types.ObjectId(value);

const PRODUCT_NAMES: Record<string, { name: string; category: string; origin: string }> = {
  '6a0fdaad7ecb33512b9d4c7a': { name: 'Xoài Cát Chu', category: 'Trái cây', origin: 'Cái Bè, Tiền Giang' },
  '6a0fdaad7ecb33512b9d4c7b': { name: 'Bưởi Da Xanh', category: 'Trái cây', origin: 'Chợ Lách, Bến Tre' },
  '6a0fdaad7ecb33512b9d4c7c': { name: 'Cà Chua Bi Đà Lạt', category: 'Rau quả', origin: 'Đà Lạt, Lâm Đồng' },
  '6a0fdaae7ecb33512b9d4c7d': { name: 'Xà Lách Thủy Canh', category: 'Rau ăn lá', origin: 'Đà Lạt, Lâm Đồng' },
  '6a0fdaae7ecb33512b9d4c7e': { name: 'Dưa Lưới', category: 'Trái cây', origin: 'Cái Bè, Tiền Giang' },
  '6a0fdaae7ecb33512b9d4c7f': { name: 'Ớt Chuông', category: 'Rau quả', origin: 'Đà Lạt, Lâm Đồng' },
  '6a0fdaae7ecb33512b9d4c80': { name: 'Trứng Gà Thả Vườn', category: 'Chăn nuôi', origin: 'Chợ Lách, Bến Tre' },
  '6a0fdb11559c052f3e2b7bbc': { name: 'Khoai Lang', category: 'Rau củ', origin: 'Phường 8, Đà Lạt, Lâm Đồng' },
  '6a0fdb89559c052f3e2b7c94': { name: 'Rau Mùi', category: 'Rau ăn lá', origin: 'Chợ Lách, Bến Tre' },
  '6a0fdccc559c052f3e2b7e15': { name: 'Rau Dền', category: 'Rau ăn lá', origin: 'Phường 8, Đà Lạt, Lâm Đồng' },
};

const PRODUCT_INVENTORY: Record<
  string,
  { initial_quantity: number; current_quantity: number; unit: string; note: string }
> = {
  '6a0fdaad7ecb33512b9d4c7a': {
    initial_quantity: 1200,
    current_quantity: 800,
    unit: 'kg',
    note: 'Lô xoài đã phân phối một phần theo hồ sơ chuỗi cung ứng mẫu.',
  },
  '6a0fdaad7ecb33512b9d4c7b': {
    initial_quantity: 900,
    current_quantity: 500,
    unit: 'kg',
    note: 'Lô bưởi còn tồn sau đóng gói và giao cùng chuyến mẫu.',
  },
  '6a0fdaad7ecb33512b9d4c7c': {
    initial_quantity: 650,
    current_quantity: 420,
    unit: 'kg',
    note: 'Lô cà chua còn tồn sau vận chuyển thử nghiệm.',
  },
  '6a0fdaae7ecb33512b9d4c7d': {
    initial_quantity: 300,
    current_quantity: 300,
    unit: 'kg',
    note: 'Lô xà lách thủy canh đang theo dõi sản xuất.',
  },
  '6a0fdaae7ecb33512b9d4c7e': {
    initial_quantity: 780,
    current_quantity: 780,
    unit: 'kg',
    note: 'Lô dưa lưới đầu vụ.',
  },
  '6a0fdaae7ecb33512b9d4c7f': {
    initial_quantity: 260,
    current_quantity: 260,
    unit: 'kg',
    note: 'Lô ớt chuông đang chăm sóc.',
  },
  '6a0fdaae7ecb33512b9d4c80': {
    initial_quantity: 2400,
    current_quantity: 1800,
    unit: 'quả',
    note: 'Lô trứng gà đã đóng hộp và xuất một phần.',
  },
  '6a0fdb11559c052f3e2b7bbc': {
    initial_quantity: 520,
    current_quantity: 520,
    unit: 'kg',
    note: 'Lô khoai lang mới gieo trồng/theo dõi.',
  },
  '6a0fdb89559c052f3e2b7c94': {
    initial_quantity: 90,
    current_quantity: 90,
    unit: 'kg',
    note: 'Lô rau mùi quy mô nhỏ.',
  },
  '6a0fdccc559c052f3e2b7e15': {
    initial_quantity: 140,
    current_quantity: 140,
    unit: 'kg',
    note: 'Lô rau dền đang theo dõi.',
  },
};

const AREA_DATA: Record<string, { name: string; address: string }> = {
  '6a0fdaac7ecb33512b9d4c77': { name: 'Vườn trái cây Cái Bè', address: 'Cái Bè, Tiền Giang' },
  '6a0fdaac7ecb33512b9d4c78': { name: 'Nhà kính Đà Lạt', address: 'Phường 8, Đà Lạt, Lâm Đồng' },
  '6a0fdaad7ecb33512b9d4c79': { name: 'Trang trại Chợ Lách', address: 'Chợ Lách, Bến Tre' },
};

const EVENT_DESCRIPTIONS: Record<string, string> = {
  '6a0fda8090c8a58380d6d8d9': 'Thu hoạch lô xoài đợt đầu, tuyển chọn quả đạt tiêu chuẩn.',
  '6a0fda8090c8a58380d6d8da': 'Phân loại và đóng gói bưởi da xanh theo quy cách.',
  '6a0fda8090c8a58380d6d8db': 'Chuyển cà chua đến điểm bán lẻ bằng xe lạnh.',
  '6a0fda8090c8a58380d6d8dc': 'Cấp dung dịch dinh dưỡng cho lô xà lách thủy canh.',
  '6a0fda8090c8a58380d6d8dd': 'Ghi nhận cây giống dưa lưới đầu vụ.',
  '6a0fda8090c8a58380d6d8de': 'Kiểm tra và phòng trừ sâu bệnh cho khu ớt chuông.',
  '6a0fda8090c8a58380d6d8df': 'Đóng hộp trứng gà trong ngày thu gom.',
  '6a0fdb21559c052f3e2b7bca': 'Gieo hạt giống F1 đã qua kiểm định.',
  '6a0fdb52559c052f3e2b7c54': 'Bón 12 kg phân NPK theo định mức canh tác.',
  '6a0fdb93559c052f3e2b7ca2': 'Gieo hạt giống F1 đã qua kiểm định.',
  '6a0fdbaf559c052f3e2b7cdd': 'Bón 12 kg phân NPK theo định mức canh tác.',
  '6a0fdc41559c052f3e2b7d9e': 'Tưới nước theo lịch canh tác, độ ẩm đất đạt yêu cầu.',
  '6a0fdc91559c052f3e2b7de8': 'Kiểm tra sâu bệnh định kỳ, không phát hiện dấu hiệu bất thường.',
  '6a0fdcd5559c052f3e2b7e23': 'Gieo hạt giống F1 đã qua kiểm định.',
  '6a33b296e364d09b32f991ae': 'Bàn giao lô hàng cho kho trung chuyển; xe lạnh duy trì nhiệt độ ổn định.',
};

async function repairReferences(fallbackUserId: Types.ObjectId) {
  const userIds = await User.distinct('_id');
  const productIds = await Product.distinct('_id');
  const areaIds = await FarmingArea.distinct('_id');
  const validProductIds = new Set(productIds.map(String));
  const invalidCertificationProductIds = (await Certification.distinct('products')).filter(
    (id) => id && !validProductIds.has(String(id))
  );
  const invalidRelatedProductIds = (await SupplyChainRecord.distinct('related_products')).filter(
    (id) => id && !validProductIds.has(String(id))
  );
  const invalidDiseaseDetectionProductIds = (await DiseaseDetection.distinct('product')).filter(
    (id) => id && !validProductIds.has(String(id))
  );

  const labels = [
    'farmingAreaOwner',
    'productCreator',
    'traceEventRecorder',
    'certificationHolder',
    'inspectionCreator',
    'organizationCreator',
    'supplyChainRecordCreator',
    'invalidFarmingArea',
    'invalidCertificationProducts',
    'invalidRelatedProducts',
    'diseaseDetectionActor',
    'invalidDiseaseDetections',
  ] as const;
  const results = await Promise.all([
    FarmingArea.updateMany({ owner: { $nin: userIds } }, { $set: { owner: fallbackUserId } }),
    Product.updateMany({ created_by: { $nin: userIds } }, { $set: { created_by: fallbackUserId } }),
    TraceEvent.updateMany({ recorded_by: { $nin: userIds } }, { $set: { recorded_by: fallbackUserId } }),
    Certification.updateMany({ holder: { $nin: userIds } }, { $set: { holder: fallbackUserId } }),
    QualityInspection.updateMany({ created_by: { $nin: userIds } }, { $set: { created_by: fallbackUserId } }),
    SupplyChainOrganization.updateMany({ created_by: { $nin: userIds } }, { $set: { created_by: fallbackUserId } }),
    SupplyChainRecord.updateMany({ created_by: { $nin: userIds } }, { $set: { created_by: fallbackUserId } }),
    Product.updateMany({ farming_area: { $exists: true, $nin: areaIds } }, { $unset: { farming_area: 1 } }),
    invalidCertificationProductIds.length
      ? Certification.updateMany(
          {},
          { $pull: { products: { $in: invalidCertificationProductIds } } }
        )
      : Promise.resolve({ modifiedCount: 0 }),
    invalidRelatedProductIds.length
      ? SupplyChainRecord.updateMany(
          {},
          { $pull: { related_products: { $in: invalidRelatedProductIds } } }
        )
      : Promise.resolve({ modifiedCount: 0 }),
    DiseaseDetection.updateMany({ detected_by: { $nin: userIds } }, { $set: { detected_by: fallbackUserId } }),
    invalidDiseaseDetectionProductIds.length
      ? DiseaseDetection.deleteMany({ product: { $in: invalidDiseaseDetectionProductIds } })
      : Promise.resolve({ modifiedCount: 0 }),
  ]);

  return Object.fromEntries(
    labels.map((label, index) => {
      const result = results[index] as { modifiedCount?: number; deletedCount?: number };
      return [label, result.modifiedCount ?? result.deletedCount ?? 0];
    })
  );
}

async function normalizeBaseData(fallbackUserId: Types.ObjectId) {
  for (const [id, data] of Object.entries(AREA_DATA)) {
    await FarmingArea.updateOne({ _id: oid(id) }, { $set: data });
  }
  for (const [id, data] of Object.entries(PRODUCT_NAMES)) {
    await Product.updateOne({ _id: oid(id) }, { $set: data });
  }
  for (const [id, description] of Object.entries(EVENT_DESCRIPTIONS)) {
    await TraceEvent.updateOne({ _id: oid(id) }, { $set: { description } });
  }

  await User.updateOne(
    { email: 'admin@gmail.com' },
    { $set: { first_name: 'Quản trị', last_name: 'AgriTrace', isActive: true } }
  );
  await User.updateOne(
    { email: 'farmer@gmail.com' },
    { $set: { first_name: 'Trần', last_name: 'Thị Nông', isActive: true } }
  );
  await User.updateOne(
    { email: 'farmerb@gmail.com' },
    { $set: { first_name: 'Nguyễn', last_name: 'Văn Vườn', isActive: true } }
  );

  await Certification.updateOne(
    { certificate_number: 'VIETGAP-2026-07' },
    {
      $set: {
        name: 'Chứng nhận VietGAP',
        type: 'VietGAP',
        issuing_authority: 'Sở Nông nghiệp và Môi trường Tiền Giang',
        status: 'valid',
        products: [oid('6a0fdaad7ecb33512b9d4c7a'), oid('6a0fdaae7ecb33512b9d4c7e')],
      },
    }
  );

  await TraceEvent.updateMany(
    { product: { $in: await Product.distinct('_id') } },
    [{ $set: { batchId: { $toString: '$product' } } }]
  );

  await Product.updateMany(
    { isDeleted: { $exists: false } },
    { $set: { isDeleted: false } }
  );

  await SupplyChainOrganization.updateMany(
    { tax_code: '' },
    { $unset: { tax_code: 1 } }
  );

  return repairReferences(fallbackUserId);
}

async function seedOrganizations(createdBy: Types.ObjectId) {
  const organizations = [
    { key: 'cooperative', name: 'Hợp tác xã Nông nghiệp Cái Bè', type: 'COOPERATIVE', tax_code: '1201680001', address: 'Cái Bè, Tiền Giang', contact_name: 'Trần Thị Nông', phone: '0901000001', email: 'caibe@agritrace.vn' },
    { key: 'processor', name: 'Nhà máy Sơ chế AgriFresh', type: 'PROCESSOR', tax_code: '0318000002', address: 'Tân An, Long An', contact_name: 'Lê Minh Khang', phone: '0901000002', email: 'soche@agritrace.vn' },
    { key: 'warehouse', name: 'Kho lạnh Mekong', type: 'WAREHOUSE', tax_code: '1801800003', address: 'Cái Răng, Cần Thơ', contact_name: 'Phạm Hoài Nam', phone: '0901000003', email: 'kho@agritrace.vn' },
    { key: 'carrier', name: 'Vận tải Lạnh Đồng Bằng', type: 'CARRIER', tax_code: '0318000004', address: 'Bình Chánh, TP. Hồ Chí Minh', contact_name: 'Võ Thành Công', phone: '0901000004', email: 'vantai@agritrace.vn' },
    { key: 'distributor', name: 'Phân phối Nông sản Việt', type: 'DISTRIBUTOR', tax_code: '0318000005', address: 'Thủ Đức, TP. Hồ Chí Minh', contact_name: 'Nguyễn Minh Anh', phone: '0901000005', email: 'phanphoi@agritrace.vn' },
    { key: 'retailer', name: 'Siêu thị Nông sản Xanh', type: 'RETAILER', tax_code: '0318000006', address: 'Quận 7, TP. Hồ Chí Minh', contact_name: 'Đặng Thu Hà', phone: '0901000006', email: 'banle@agritrace.vn' },
    { key: 'supplier', name: 'Công ty Vật tư Nông nghiệp Miền Tây', type: 'SUPPLIER', tax_code: '1801800007', address: 'Ninh Kiều, Cần Thơ', contact_name: 'Bùi Quốc Huy', phone: '0901000007', email: 'vattu@agritrace.vn' },
  ] as const;

  const ids: Record<string, Types.ObjectId> = {};
  for (const organization of organizations) {
    const { key, ...data } = organization;
    const document = await SupplyChainOrganization.findOneAndUpdate(
      { tax_code: data.tax_code },
      { $set: { ...data, active: true, created_by: createdBy } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    ids[key] = document._id;
  }
  return ids;
}

async function seedSupplyChain(createdBy: Types.ObjectId, org: Record<string, Types.ObjectId>) {
  const products = await Product.find({}).sort({ createdAt: 1 }).limit(4).select('_id name');
  if (products.length < 2) throw new Error('Cần ít nhất 2 sản phẩm để tạo dữ liệu chuỗi cung ứng.');

  const primary = products[0]._id;
  const secondary = products[1]._id;
  const records = [
    { key: 'demo-transfer', product: primary, operation_type: 'TRANSFER', title: 'Bàn giao nông sản từ hợp tác xã', description: 'Kiểm đếm, niêm phong và bàn giao lô hàng cho đơn vị sơ chế.', from_organization: org.cooperative, to_organization: org.processor, status: 'COMPLETED', quantity: 1200, unit: 'kg', occurred_at: new Date('2026-05-15T03:00:00.000Z'), location: 'Cái Bè, Tiền Giang' },
    { key: 'demo-processing', product: primary, operation_type: 'PROCESSING', title: 'Sơ chế và phân loại', description: 'Rửa, làm sạch, phân cỡ và đóng thùng theo tiêu chuẩn.', from_organization: org.processor, to_organization: org.processor, status: 'COMPLETED', quantity: 1165, unit: 'kg', occurred_at: new Date('2026-05-15T08:00:00.000Z'), location: 'Tân An, Long An' },
    { key: 'demo-split', product: primary, related_products: [secondary], operation_type: 'SPLIT', title: 'Tách lô theo quy cách đóng gói', description: 'Tách một phần sản lượng sang lô đóng gói bán lẻ.', from_organization: org.processor, to_organization: org.processor, status: 'COMPLETED', quantity: 350, unit: 'kg', occurred_at: new Date('2026-05-15T09:30:00.000Z'), location: 'Tân An, Long An' },
    { key: 'demo-warehouse-in', product: primary, operation_type: 'WAREHOUSE_IN', title: 'Nhập kho lạnh', description: 'Tiếp nhận lô hàng, kiểm tra niêm phong và điều kiện bảo quản.', from_organization: org.processor, to_organization: org.warehouse, status: 'COMPLETED', quantity: 815, unit: 'kg', occurred_at: new Date('2026-05-15T12:00:00.000Z'), location: 'Cái Răng, Cần Thơ', temperature: 8, humidity: 75 },
    { key: 'demo-warehouse-out', product: primary, operation_type: 'WAREHOUSE_OUT', title: 'Xuất kho giao nhà phân phối', description: 'Xuất kho theo nguyên tắc nhập trước, xuất trước.', from_organization: org.warehouse, to_organization: org.carrier, status: 'COMPLETED', quantity: 815, unit: 'kg', occurred_at: new Date('2026-05-16T00:30:00.000Z'), location: 'Cái Răng, Cần Thơ', temperature: 8.4, humidity: 73 },
    { key: 'demo-transport', product: primary, operation_type: 'TRANSPORT', title: 'Vận chuyển bằng xe lạnh', description: 'Theo dõi điều kiện vận chuyển xuyên suốt hành trình.', from_organization: org.carrier, to_organization: org.distributor, status: 'COMPLETED', quantity: 815, unit: 'kg', occurred_at: new Date('2026-05-16T02:00:00.000Z'), location: 'Cần Thơ – TP. Hồ Chí Minh', temperature: 9.1, humidity: 72, vehicle: '51D-123.45', driver: 'Nguyễn Văn Bình' },
    { key: 'demo-retail-transfer', product: primary, operation_type: 'TRANSFER', title: 'Phân phối đến điểm bán lẻ', description: 'Bàn giao đủ số lượng, bao bì nguyên vẹn.', from_organization: org.distributor, to_organization: org.retailer, status: 'COMPLETED', quantity: 800, unit: 'kg', occurred_at: new Date('2026-05-16T08:00:00.000Z'), location: 'Quận 7, TP. Hồ Chí Minh' },
    { key: 'demo-merge', product: secondary, related_products: [primary], operation_type: 'MERGE', title: 'Gộp lô giao cùng chuyến', description: 'Gộp các lô cùng tiêu chuẩn để tối ưu chuyến giao hàng.', from_organization: org.distributor, to_organization: org.retailer, status: 'COMPLETED', quantity: 500, unit: 'kg', occurred_at: new Date('2026-05-17T02:00:00.000Z'), location: 'Thủ Đức, TP. Hồ Chí Minh' },
  ] as const;

  for (const record of records) {
    const { key, ...data } = record;
    await SupplyChainRecord.findOneAndUpdate(
      { 'metadata.seed_key': key },
      { $set: { ...data, metadata: { seed_key: key, source: 'normalized-demo-data' }, created_by: createdBy } },
      { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true }
    );
  }
}

async function seedQualityInspections(createdBy: Types.ObjectId) {
  const products = await Product.find({}).sort({ createdAt: 1 }).limit(3).select('_id');
  const reports = [
    { report_number: 'KN-2026-001', product: products[0]?._id, inspection_type: 'PESTICIDE_RESIDUE', laboratory: 'Trung tâm Kỹ thuật Tiêu chuẩn Đo lường Chất lượng 3', sample_date: new Date('2026-05-14T00:00:00.000Z'), result_date: new Date('2026-05-15T00:00:00.000Z'), result: 'passed', summary: 'Không phát hiện dư lượng thuốc bảo vệ thực vật vượt ngưỡng.', metrics: [{ name: 'Carbendazim', value: '< 0.01', unit: 'mg/kg', limit: '0.1 mg/kg', passed: true }] },
    { report_number: 'KN-2026-002', product: products[1]?._id, inspection_type: 'MICROBIOLOGY', laboratory: 'Viện Pasteur TP. Hồ Chí Minh', sample_date: new Date('2026-05-15T00:00:00.000Z'), result_date: new Date('2026-05-16T00:00:00.000Z'), result: 'passed', summary: 'Các chỉ tiêu vi sinh nằm trong giới hạn cho phép.', metrics: [{ name: 'E. coli', value: 'Không phát hiện', unit: 'CFU/g', limit: '10 CFU/g', passed: true }] },
    { report_number: 'KN-2026-003', product: products[2]?._id, inspection_type: 'HEAVY_METAL', laboratory: 'Trung tâm Phân tích và Chứng nhận Chất lượng', sample_date: new Date('2026-05-16T00:00:00.000Z'), result_date: new Date('2026-05-17T00:00:00.000Z'), result: 'passed', summary: 'Hàm lượng kim loại nặng đạt quy chuẩn an toàn thực phẩm.', metrics: [{ name: 'Chì (Pb)', value: '0.018', unit: 'mg/kg', limit: '0.1 mg/kg', passed: true }] },
  ] as const;

  for (const report of reports) {
    if (!report.product) continue;
    await QualityInspection.findOneAndUpdate(
      { report_number: report.report_number },
      { $set: { ...report, created_by: createdBy } },
      { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true }
    );
  }
}

async function seedDiseaseDetections(createdBy: Types.ObjectId) {
  const products = await Product.find({}).sort({ createdAt: 1 }).limit(4).select('_id name');
  const detections = [
    {
      key: 'disease-mango-leaf-spot',
      product: products[0]?._id,
      crop_name: products[0]?.name || 'Xoài Cát Chu',
      symptoms: ['Đốm nâu', 'Cháy lá', 'Vàng lá'],
      notes: 'Một số lá già có đốm nâu lan từ mép sau đợt mưa lớn.',
      top_disease: {
        disease_code: 'leaf_spot',
        disease_name: 'Đốm lá do nấm',
        confidence: 0.81,
        risk_level: 'medium',
        description: 'Lá xuất hiện đốm nâu/vàng hoặc vùng cháy mép, thường liên quan đến nấm bệnh và ẩm độ cao.',
        recommendations: [
          'Tỉa bỏ lá bệnh và gom ra khỏi khu vực canh tác.',
          'Giảm tưới phun lên tán lá, tăng thông thoáng luống trồng.',
          'Theo dõi 2-3 ngày và tham khảo cán bộ kỹ thuật nếu vết bệnh lan nhanh.',
        ],
      },
    },
    {
      key: 'disease-tomato-wilt',
      product: products[2]?._id,
      crop_name: products[2]?.name || 'Cà Chua Bi Đà Lạt',
      symptoms: ['Héo rũ', 'Thối rễ'],
      notes: 'Cây héo nhanh vào buổi trưa, một số gốc có dấu hiệu thối rễ.',
      top_disease: {
        disease_code: 'bacterial_wilt',
        disease_name: 'Héo xanh/héo rũ',
        confidence: 0.86,
        risk_level: 'high',
        description: 'Cây héo nhanh, rũ lá hoặc thối rễ có thể là dấu hiệu bệnh hệ thống, nguy cơ ảnh hưởng cả luống.',
        recommendations: [
          'Đánh dấu và cách ly cây nghi nhiễm ngay.',
          'Kiểm tra độ ẩm đất, rễ và lịch tưới gần nhất.',
          'Báo kỹ thuật viên để xác nhận trước khi xử lý diện rộng.',
        ],
      },
    },
    {
      key: 'disease-lettuce-healthy',
      product: products[3]?._id,
      crop_name: products[3]?.name || 'Xà Lách Thủy Canh',
      symptoms: ['Chậm lớn'],
      notes: 'Không có vết bệnh rõ, chỉ ghi nhận sinh trưởng chậm nhẹ.',
      top_disease: {
        disease_code: 'nutrient_stress',
        disease_name: 'Thiếu dinh dưỡng hoặc stress môi trường',
        confidence: 0.62,
        risk_level: 'low',
        description: 'Cây sinh trưởng chậm hoặc lá nhạt màu có thể do dinh dưỡng, nước tưới hoặc thời tiết.',
        recommendations: [
          'Kiểm tra nồng độ dinh dưỡng và pH dung dịch.',
          'Theo dõi lô trong 5-7 ngày sau điều chỉnh chăm sóc.',
        ],
      },
    },
  ] as const;

  let upserted = 0;
  for (const detection of detections) {
    if (!detection.product) continue;
    const candidates = [detection.top_disease];
    const result = await DiseaseDetection.findOneAndUpdate(
      { 'notes': detection.notes, product: detection.product },
      {
        $set: {
          product: detection.product,
          crop_name: detection.crop_name,
          symptoms: detection.symptoms,
          notes: detection.notes,
          images: [],
          candidates,
          top_disease: detection.top_disease,
          overall_risk: detection.top_disease.risk_level,
          model_version: 'ruleset-v1',
          detected_by: createdBy,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true }
    );
    if (result) upserted += 1;
  }

  return { diseaseDetectionsUpserted: upserted };
}

async function normalizeInventory(createdBy: Types.ObjectId) {
  let productsUpdated = 0;
  let transactionsUpserted = 0;

  for (const [id, inventory] of Object.entries(PRODUCT_INVENTORY)) {
    const productId = oid(id);
    const product = await Product.findById(productId).select('_id name');
    if (!product) continue;

    const updateResult = await Product.updateOne(
      { _id: productId },
      {
        $set: {
          initial_quantity: inventory.initial_quantity,
          current_quantity: inventory.current_quantity,
          unit: inventory.unit,
        },
      },
      { runValidators: true }
    );
    productsUpdated += updateResult.modifiedCount;

    const initialKey = `inventory-${id}-initial`;
    const initialTx = await InventoryTransaction.findOneAndUpdate(
      { 'metadata.seed_key': initialKey },
      {
        $set: {
          product: productId,
          type: 'INITIAL',
          quantity: inventory.initial_quantity,
          unit: inventory.unit,
          balance_before: 0,
          balance_after: inventory.initial_quantity,
          related_products: [],
          note: `Khởi tạo tồn kho mẫu: ${inventory.note}`,
          occurred_at: new Date('2026-05-14T00:00:00.000Z'),
          metadata: {
            seed_key: initialKey,
            source: 'normalized-demo-data',
          },
          created_by: createdBy,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true }
    );
    if (initialTx) transactionsUpserted += 1;

    const adjustedQuantity = inventory.initial_quantity - inventory.current_quantity;
    const adjustKey = `inventory-${id}-adjust-out`;
    if (adjustedQuantity > 0) {
      const adjustTx = await InventoryTransaction.findOneAndUpdate(
        { 'metadata.seed_key': adjustKey },
        {
          $set: {
            product: productId,
            type: 'ADJUST_OUT',
            quantity: adjustedQuantity,
            unit: inventory.unit,
            balance_before: inventory.initial_quantity,
            balance_after: inventory.current_quantity,
            related_products: [],
            note: `Điều chỉnh tồn kho theo dữ liệu chuỗi cung ứng mẫu: ${inventory.note}`,
            occurred_at: new Date('2026-05-16T09:00:00.000Z'),
            metadata: {
              seed_key: adjustKey,
              source: 'normalized-demo-data',
            },
            created_by: createdBy,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true }
      );
      if (adjustTx) transactionsUpserted += 1;
    } else {
      await InventoryTransaction.deleteMany({ 'metadata.seed_key': adjustKey });
    }
  }

  return { productsUpdated, transactionsUpserted };
}

async function main() {
  await connectDB(env.DB_URI);
  const fallbackUser = await User.findOne({ role: 'admin', isActive: true }).sort({ createdAt: 1 });
  if (!fallbackUser) throw new Error('Không tìm thấy tài khoản quản trị đang hoạt động.');

  const repairedReferences = await normalizeBaseData(fallbackUser._id);
  const organizations = await seedOrganizations(fallbackUser._id);
  await seedSupplyChain(fallbackUser._id, organizations);
  await seedQualityInspections(fallbackUser._id);
  const disease = await seedDiseaseDetections(fallbackUser._id);
  const inventory = await normalizeInventory(fallbackUser._id);

  const counts = {
    users: await User.countDocuments(),
    farmingAreas: await FarmingArea.countDocuments(),
    products: await Product.countDocuments(),
    traceEvents: await TraceEvent.countDocuments(),
    certifications: await Certification.countDocuments(),
    qualityInspections: await QualityInspection.countDocuments(),
    diseaseDetections: await DiseaseDetection.countDocuments(),
    supplyChainOrganizations: await SupplyChainOrganization.countDocuments(),
    supplyChainRecords: await SupplyChainRecord.countDocuments(),
    inventoryTransactions: await InventoryTransaction.countDocuments(),
  };

  console.log(JSON.stringify({ success: true, repairedReferences, disease, inventory, counts }, null, 2));
}

main()
  .catch((error) => {
    console.error('Chuẩn hóa dữ liệu thất bại:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });

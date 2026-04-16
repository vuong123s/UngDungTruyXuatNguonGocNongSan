import Product from '../models/Product';
import FarmingArea from '../models/FarmingArea';
import env from '../config/env';
import { BadRequestError, NotFoundError } from '../utils/errors';
import generateQR from '../utils/qrcode';
import { createBatchOnChain } from './blockchain';
import { notifyProductStatusChanged } from './notification.service';

const isBlockchainConfigured = () =>
  !!(env.CONTRACT_ADDRESS && env.BLOCKCHAIN_PRIVATE_KEY);

export const getAllProducts = async () => {
  return Product.find({})
    .populate('created_by', 'first_name last_name email')
    .populate({
      path: 'farming_area',
      select: 'name address area_size coordinates',
      populate: {
        path: 'certifications',
        select: 'name type certificate_number status expiry_date issuing_authority'
      }
    });
};

export const getProductById = async (productId: string) => {
  const product = await Product.findById(productId)
    .populate('created_by', 'first_name last_name email')
    .populate({
      path: 'farming_area',
      select: 'name address area_size coordinates owner',
      populate: [
        {
          path: 'certifications',
          select: 'name type certificate_number status expiry_date issuing_authority scope'
        },
        {
          path: 'owner',
          select: 'first_name last_name email'
        }
      ]
    });

  if (!product) {
    throw new NotFoundError(`Không tìm thấy sản phẩm ${productId}`);
  }

  return product;
};

export const createProduct = async (
  data: {
    name: string;
    category: string;
    type: 'Plant' | 'Animal';
    description: string;
    origin?: string;
    cultivation_time?: string;
    images?: { path: string; filename: string }[];
    farming_area?: string;
  },
  userId: string
) => {
  if (!data.name || !data.category || !data.type || !data.description) {
    throw new BadRequestError('Vui lòng điền đầy đủ thông tin sản phẩm');
  }

  // Auto-fill origin from farming area if not provided
  let origin = data.origin;
  if (data.farming_area && !origin) {
    const farmingArea = await FarmingArea.findById(data.farming_area);
    if (farmingArea) {
      origin = farmingArea.address;
    }
  }

  const product = await Product.create({ 
    ...data, 
    origin: origin || 'Việt Nam',
    created_by: userId 
  });
  const batchId = product._id.toString();
  let batchTxHash = '';

  if (isBlockchainConfigured()) {
    try {
      const result = await createBatchOnChain(batchId);
      batchTxHash = result.txHash;
      product.onChainBatchId = batchId;
      product.batchTxHash = result.txHash;
      product.status = 'active';
    } catch (error: any) {
      console.error('Blockchain createBatch failed:', error.message);
    }
  }

  const traceUrl = `${env.FRONTEND_URL || 'http://localhost:3000'}/trace/${batchId}`;
  const qrcode = await generateQR(traceUrl);

  product.qrcode = qrcode;
  await product.save();

  // Populate farming_area for response
  await product.populate({
    path: 'farming_area',
    select: 'name address area_size',
    populate: {
      path: 'certifications',
      select: 'name type certificate_number status'
    }
  });

  return { product, batchId, batchTxHash };
};

export const updateProduct = async (
  productId: string,
  data: Partial<{
    name: string;
    category: string;
    description: string;
    origin: string;
    cultivation_time: string;
    status: string;
    farming_area: string;
  }>
) => {
  // Get the current product to check for status change
  const currentProduct = await Product.findById(productId);
  if (!currentProduct) {
    throw new NotFoundError(`Không tìm thấy sản phẩm ${productId}`);
  }

  const oldStatus = currentProduct.status;
  
  const product = await Product.findByIdAndUpdate(productId, data, {
    new: true,
    runValidators: true,
  });

  if (!product) {
    throw new NotFoundError(`Không tìm thấy sản phẩm ${productId}`);
  }

  // Notify if status has changed
  if (data.status && data.status !== oldStatus) {
    notifyProductStatusChanged(
      product.created_by.toString(),
      product.name,
      oldStatus,
      data.status,
      productId
    ).catch((err) => {
      console.error('Failed to send product status notification:', err.message);
    });
  }

  return product;
};

export const deleteProduct = async (productId: string) => {
  const product = await Product.findByIdAndDelete(productId);

  if (!product) {
    throw new NotFoundError(`Kh?ng t?m th?y s?n ph?m ${productId}`);
  }

  return product;
};

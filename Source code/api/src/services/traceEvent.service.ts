import TraceEvent, { ActionType } from '../models/TraceEvent';
import Product from '../models/Product';
import { NotFoundError } from '../utils/errors';
import {
  getBatchHistoryFromChain,
  recordActionOnChain,
  verifyActionOnChain,
  hashEventData,
  createBatchOnChain,
  batchExistsOnChain,
} from './blockchain';
import { notifyTraceEventAdded } from './notification.service';
import env from '../config/env';

const isBlockchainConfigured = () =>
  !!(env.CONTRACT_ADDRESS && env.BLOCKCHAIN_PRIVATE_KEY);

const BLOCKCHAIN_READ_TIMEOUT_MS = 2500;

const withTimeout = async <T>(promise: Promise<T>, timeoutMs: number) =>
  Promise.race<T>([
    promise,
    new Promise<T>((_, reject) => {
      setTimeout(() => reject(new Error(`Timeout after ${timeoutMs}ms`)), timeoutMs);
    }),
  ]);

const normalizeImages = (
  images?: Array<string | { path?: string; filename?: string }>
) => {
  if (!Array.isArray(images)) return [];

  return images
    .map((image) => {
      if (typeof image === 'string') {
        const normalizedPath = image.trim();
        if (!normalizedPath) return null;

        const parts = normalizedPath.split(/[\/]/);
        return {
          path: normalizedPath,
          filename: parts[parts.length - 1] || 'image',
        };
      }

      if (image && typeof image === 'object') {
        const normalizedPath = image.path?.trim();
        if (!normalizedPath) return null;

        return {
          path: normalizedPath,
          filename: image.filename?.trim() || normalizedPath.split(/[\/]/).pop() || 'image',
        };
      }

      return null;
    })
    .filter((image): image is { path: string; filename: string } => Boolean(image));
};

export const createTraceEvent = async (
  data: {
    product: string;
    eventType: ActionType;
    description: string;
    details?: Record<string, unknown>;
    images?: { path: string; filename: string }[];
  },
  userId: string
) => {
  const { product: productId, eventType, description, details, images } = data;
  const product = await Product.findById(productId);

  if (!product) {
    throw new NotFoundError(`Kh?ng t?m th?y s?n ph?m ${productId}`);
  }

  const batchId = product._id.toString();
  const normalizedImages = normalizeImages(images);

  // Hash only core fields. Images stay off-chain.
  const coreData: Record<string, unknown> = {
    batchId,
    eventType,
    description,
    details: details || {},
    recordedBy: userId,
  };

  const traceEvent = await TraceEvent.create({
    product: productId,
    batchId,
    eventType,
    description,
    details: details || {},
    images: normalizedImages,
    recorded_by: userId,
    onChainStatus: 'pending',
  });

  // Notify product owner about the new trace event (if different from current user)
  const productOwnerId = product.created_by.toString();
  if (productOwnerId !== userId) {
    notifyTraceEventAdded(productOwnerId, product.name, eventType, productId).catch((err) => {
      console.error('Failed to send trace event notification:', err.message);
    });
  }

  if (!isBlockchainConfigured()) {
    traceEvent.onChainStatus = 'skipped';
    traceEvent.dataHash = hashEventData(coreData);
    await traceEvent.save();

    return {
      traceEvent,
      blockchain: null,
      warning: 'Blockchain ch?a ???c c?u h?nh. D? li?u ?? l?u off-chain v?i hash c?c b?.',
    };
  }

  try {
    const existsOnChain = await batchExistsOnChain(batchId);
    if (!existsOnChain) {
      await createBatchOnChain(batchId);
    }

    const chainResult = await recordActionOnChain(batchId, coreData, eventType);

    traceEvent.dataHash = chainResult.dataHash;
    traceEvent.txHash = chainResult.txHash;
    traceEvent.blockNumber = chainResult.blockNumber;
    traceEvent.actionIndex = chainResult.actionIndex;
    traceEvent.onChainStatus = 'confirmed';
    await traceEvent.save();

    return {
      traceEvent,
      blockchain: {
        txHash: chainResult.txHash,
        blockNumber: chainResult.blockNumber,
        dataHash: chainResult.dataHash,
        actionIndex: chainResult.actionIndex,
      },
    };
  } catch (error: any) {
    traceEvent.onChainStatus = 'failed';
    traceEvent.dataHash = hashEventData(coreData);
    await traceEvent.save();

    console.error('Blockchain recordAction failed:', error.message);

    return {
      traceEvent,
      blockchain: null,
      warning: 'Ghi blockchain th?t b?i, d? li?u ?? l?u off-chain.',
    };
  }
};

export const getEventsByProduct = async (productId: string) => {
  const product = await Product.findById(productId);
  if (!product) {
    throw new NotFoundError(`Kh?ng t?m th?y s?n ph?m ${productId}`);
  }

  return TraceEvent.find({ product: productId })
    .populate('recorded_by', 'first_name last_name email')
    .sort({ createdAt: 1 });
};

export const getFullTrace = async (productId: string) => {
  const product = await Product.findById(productId)
    .populate('created_by', 'first_name last_name')
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

  const events = await TraceEvent.find({ product: productId })
    .populate('recorded_by', 'first_name last_name')
    .sort({ createdAt: 1 });

  let onChain = null;
  try {
    onChain = await withTimeout(
      getBatchHistoryFromChain(product._id.toString()),
      BLOCKCHAIN_READ_TIMEOUT_MS
    );
  } catch (error: any) {
    console.error('Blockchain getHistory failed:', error.message);
  }

  return { product, events, onChain };
};

export const verifyTraceEvent = async (eventId: string) => {
  const event = await TraceEvent.findById(eventId);
  if (!event) {
    throw new NotFoundError(`Kh?ng t?m th?y s? ki?n ${eventId}`);
  }

  if (event.onChainStatus !== 'confirmed' || event.actionIndex === undefined) {
    return {
      verified: false,
      reason: 'S? ki?n ch?a ???c ghi l?n blockchain',
      event,
    };
  }

  const coreData: Record<string, unknown> = {
    batchId: event.batchId,
    eventType: event.eventType,
    description: event.description,
    details: event.details || {},
    recordedBy: event.recorded_by.toString(),
  };

  try {
    const { verified, dataHash } = await verifyActionOnChain(
      event.batchId,
      event.actionIndex,
      coreData
    );

    return {
      verified,
      dataHash,
      txHash: event.txHash,
      blockNumber: event.blockNumber,
      event,
    };
  } catch (error: any) {
    return {
      verified: false,
      reason: `L?i khi ki?m tra blockchain: ${error.message}`,
      event,
    };
  }
};

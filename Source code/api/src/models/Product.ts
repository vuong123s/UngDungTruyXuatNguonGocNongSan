import { Schema, model, Types } from 'mongoose';

export interface IProduct {
  name: string;
  category: string;
  type: 'Plant' | 'Animal';
  description: string;
  origin: string;
  cultivation_time?: string;
  images: { path: string; filename: string }[];
  farming_area?: Types.ObjectId;
  qrcode?: string;
  status: 'draft' | 'active' | 'completed';
  onChainBatchId?: string;
  batchTxHash?: string;
  created_by: Types.ObjectId;
  createdAt?: Date;
  updatedAt?: Date;
}

const productSchema = new Schema<IProduct>(
  {
    name: {
      type: String,
      required: [true, 'Vui l?ng nh?p t?n s?n ph?m'],
      trim: true,
      maxlength: 200,
    },
    category: {
      type: String,
      required: [true, 'Vui l?ng nh?p danh m?c'],
      trim: true,
    },
    type: {
      type: String,
      required: [true, 'Vui l?ng ch?n lo?i s?n ph?m'],
      enum: {
        values: ['Plant', 'Animal'],
        message: '{VALUE} kh?ng h?p l?',
      },
    },
    description: {
      type: String,
      required: [true, 'Vui l?ng nh?p m? t?'],
    },
    origin: {
      type: String,
      default: 'Vi?t Nam',
    },
    cultivation_time: {
      type: String,
    },
    images: {
      type: [{ path: String, filename: String }],
      default: [],
    },
    farming_area: {
      type: Schema.Types.ObjectId,
      ref: 'FarmingArea',
    },
    qrcode: {
      type: String,
    },
    status: {
      type: String,
      enum: ['draft', 'active', 'completed'],
      default: 'draft',
    },
    onChainBatchId: {
      type: String,
    },
    batchTxHash: {
      type: String,
    },
    created_by: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  { timestamps: true }
);

export default model<IProduct>('Product', productSchema);

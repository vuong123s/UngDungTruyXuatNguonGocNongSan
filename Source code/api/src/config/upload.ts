import multer from 'multer';
import path from 'path';
import { BadRequestError } from '../utils/errors';

const UPLOAD_DIR = 'uploads';
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
const MAX_MEDIA_FILE_SIZE = 50 * 1024 * 1024; // 50MB
const ALLOWED_MIMETYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const ALLOWED_MEDIA_MIMETYPES = [
  ...ALLOWED_MIMETYPES,
  'video/mp4',
  'video/quicktime',
  'video/x-msvideo',
  'video/x-matroska',
  'video/webm',
];

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (_req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueSuffix}${ext}`);
  },
});

const fileFilter: multer.Options['fileFilter'] = (_req, file, cb) => {
  if (ALLOWED_MIMETYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new BadRequestError('Chỉ chấp nhận file ảnh (jpeg, png, gif, webp)'));
  }
};

const mediaFileFilter: multer.Options['fileFilter'] = (_req, file, cb) => {
  if (ALLOWED_MEDIA_MIMETYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new BadRequestError('Chỉ chấp nhận ảnh hoặc video (mp4, mov, avi, mkv, webm)'));
  }
};

export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: MAX_FILE_SIZE,
  },
});

export const uploadMedia = multer({
  storage,
  fileFilter: mediaFileFilter,
  limits: {
    fileSize: MAX_MEDIA_FILE_SIZE,
  },
});

export const UPLOAD_PATH = UPLOAD_DIR;

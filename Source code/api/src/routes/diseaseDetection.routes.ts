import { Router } from 'express';
import { upload } from '../config/upload';
import * as controller from '../controllers/diseaseDetection.controller';
import { authenticate, authorize } from '../middlewares/auth.middleware';
import { auditCreate, auditDelete } from '../middlewares/audit.middleware';

const router = Router();

router.use(authenticate);
router.get('/', controller.getAll);
router.get('/product/:productId', controller.getByProduct);
router.post(
  '/',
  authorize('admin', 'manager', 'farmer'),
  upload.array('images', 5),
  auditCreate('DiseaseDetection', (_req, body: any) => body?.detection?._id),
  controller.create
);
router.delete(
  '/:id',
  authorize('admin', 'manager', 'farmer'),
  auditDelete('DiseaseDetection'),
  controller.remove
);

export default router;

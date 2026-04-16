# TỔNG HỢP CHI TIẾT PROJECT

Ngày cập nhật: 2026-04-16

## 1) Tổng quan nhanh

Đây là hệ sinh thái truy xuất nguồn gốc nông sản đa nền tảng gồm 4 khối chính:

- Backend API: Node.js + TypeScript + Express + MongoDB + Ethers.
- Smart contract: Hardhat + Solidity (hợp đồng Traceability).
- Web quản trị/vận hành: React + TypeScript.
- Mobile client: Flutter + Riverpod + Dio.

Hệ thống dùng mô hình lưu trữ lai:

- Off-chain (MongoDB): lưu dữ liệu chi tiết nghiệp vụ, truy vấn nhanh.
- On-chain (EVM): lưu bằng chứng hash và lịch sử hành động không thể chỉnh sửa.

## 2) Mục tiêu nghiệp vụ

- Quản lý vòng đời lô nông sản (batch/product).
- Ghi nhận các sự kiện canh tác/vận hành theo timeline.
- Tạo QR cho từng lô để truy xuất từ web/mobile.
- Xác thực tính toàn vẹn dữ liệu bằng blockchain.
- Xuất báo cáo PDF/Excel/QR phục vụ quản lý và kiểm toán.

## 3) Kiến trúc tổng thể

```text
[Web React] ----\
                 \         +---------------------+
[Mobile Flutter] ---> API  |  Express + MongoDB  |
                 /         |  (off-chain data)   |
[Other Clients]-/          +----------+----------+
                                      |
                                      | ethers
                                      v
                           +----------------------+
                           | Traceability.sol     |
                           | (on-chain evidence)  |
                           +----------------------+
```

Luồng dữ liệu chính:

1. Client gửi yêu cầu tạo sản phẩm/sự kiện tới API.
2. API lưu bản ghi nghiệp vụ vào MongoDB.
3. API hash dữ liệu lõi và ghi hash + metadata lên contract.
4. API trả trạng thái on-chain/off-chain cho client.
5. Client có thể verify lại sự kiện bằng endpoint xác thực.

## 4) Vai trò từng thư mục/module

### 4.1 Backend API (`api/`)

- Entry point: `api/src/index.ts`.
- Route tổng: `api/src/routes/index.ts`, base path `/api/v1`.
- Kết nối DB: `api/src/config/db.ts`.
- Cấu hình môi trường: `api/src/config/env.ts`.
- Tích hợp blockchain (provider/signer/contract): `api/src/config/blockchain.ts`.
- Upload ảnh: `api/src/config/upload.ts` (Multer, tối đa 5MB/file).

Các nhóm nghiệp vụ chính:

- Auth & phân quyền.
- Quản lý người dùng.
- Quản lý sản phẩm/lô nông sản.
- Nhật ký truy xuất (trace events).
- Vùng trồng/chứng nhận.
- Thông báo, audit log, tìm kiếm.
- Xuất PDF/Excel/QR.

### 4.2 Smart Contract (`blockchain/`)

- Contract chính API đang dùng: `blockchain/contracts/Traceability.sol`.
- Contract phụ/legacy thử nghiệm: `blockchain/contracts/AgriTraceability.sol`.
- Deploy script: `blockchain/scripts/deploy.ts`.
- Test: `blockchain/test/Traceability.test.ts`.
- Hardhat config mạng local/sepolia/amoy: `blockchain/hardhat.config.ts`.

### 4.3 Web App (`web/`)

- Entry: `web/src/App.tsx`.
- API client: `web/src/core/api/axiosClient.ts`.
- Domain API wrappers: `web/src/core/api/*.api.ts`.
- Auth context: `web/src/core/context/AuthContext.tsx`.

Web có dashboard, ghi nhật ký nhanh, vùng trồng, chứng nhận, xuất báo cáo, admin.

### 4.4 Mobile App (`app/`)

- Entry: `app/lib/main.dart`.
- Router: `app/lib/core/router.dart`.
- API client: `app/lib/core/api_client.dart`.
- Service chính: `app/lib/services/auth_service.dart`, `batch_service.dart`, `trace_service.dart`.

Mobile hỗ trợ quét/nhập batch ID, xem timeline, đăng nhập, ghi sự kiện, thông báo.

### 4.5 Script tài liệu (`create_traceability_doc.py`, `make_docx.py`)

- Dùng để sinh báo cáo DOCX phục vụ học phần/đồ án.

## 5) Công nghệ và thư viện chính

### API

- Express, TypeScript, Mongoose.
- Xác thực: JWT + bcrypt.
- Blockchain SDK: ethers.
- Upload: multer.
- Export tài liệu: pdfkit, exceljs, qrcode.

### Blockchain

- Hardhat, Solidity 0.8.24, hardhat-toolbox.

### Web

- React 18, TypeScript, react-router-dom, axios.

### Mobile

- Flutter 3.11 SDK, Riverpod, Dio.
- QR: mobile_scanner, qr_flutter.

## 6) Cơ chế on-chain/off-chain

### 6.1 Tạo sản phẩm/lô

Trong `api/src/services/product.service.ts`:

- Tạo Product trong MongoDB.
- Dùng `product._id` làm `batchId`.
- Nếu blockchain được cấu hình:
  - gọi `createBatchOnChain(batchId)`;
  - cập nhật `onChainBatchId`, `status = active`.
- Sinh QR chứa URL truy xuất: `{FRONTEND_URL}/trace/{batchId}`.

### 6.2 Tạo trace event

Trong `api/src/services/traceEvent.service.ts`:

- Lưu TraceEvent trước với trạng thái `pending`.
- Build `coreData` rồi hash bằng keccak256.
- Nếu chưa cấu hình blockchain:
  - gán `onChainStatus = skipped`;
  - vẫn lưu `dataHash` off-chain.
- Nếu đã cấu hình:
  - kiểm tra batch tồn tại chưa (`batchExistsOnChain`);
  - nếu chưa có thì tạo batch;
  - gọi `addAction` lên contract;
  - cập nhật `txHash`, `blockNumber`, `actionIndex`, `onChainStatus = confirmed`.
- Nếu gọi chain thất bại:
  - chuyển `onChainStatus = failed`;
  - vẫn lưu hash off-chain để phục vụ đối soát.

### 6.3 Verify dữ liệu

- Endpoint verify lấy event theo `eventId`.
- Rebuild hash từ dữ liệu lõi.
- Gọi `verifyAction(batchId, actionIndex, dataHash)` trên chain.
- Trả về kết quả `verified` cùng hash/tx metadata.

## 7) Smart contract Traceability (đang dùng)

File: `blockchain/contracts/Traceability.sol`.

### Kiểu dữ liệu

- `ActionType`: SEEDING, FERTILIZING, WATERING, PEST_CONTROL, HARVESTING, PACKAGING, SHIPPING.
- `Action`: `dataHash`, `actionType`, `timestamp`, `recorder`.
- `Batch`: `owner`, `exists`, `actions[]`.

### Hàm chính

- `createBatch(batchId)`.
- `addAction(batchId, dataHash, actionType)` (chỉ owner của batch).
- `getHistory(batchId)`.
- `verifyAction(batchId, index, dataHash)`.
- `getActionCount(batchId)`.
- `batchExists(batchId)`.
- `getBatchOwner(batchId)`.

## 8) API REST hiện tại (base `/api/v1`)

### 8.1 Auth

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/logout`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `POST /auth/change-password` (cần auth)

### 8.2 Users

- `GET /users` (admin)
- `GET /users/:id` (auth)
- `PATCH /users/update` (auth)

### 8.3 Products

- `GET /products`
- `GET /products/:id`
- `POST /products` (admin/manager/farmer)
- `PATCH /products/:id` (admin/manager)
- `DELETE /products/:id` (admin)

### 8.4 Trace

- `GET /trace/verify/:eventId`
- `GET /trace/:productId`
- `GET /trace/events/product/:productId` (auth)
- `POST /trace/events` (admin/manager/farmer)

### 8.5 Farming areas

- `GET /farming-areas`
- `GET /farming-areas/my/areas` (auth)
- `GET /farming-areas/:id`
- `POST /farming-areas` (admin/manager/farmer)
- `PATCH /farming-areas/:id` (admin/manager/farmer)
- `DELETE /farming-areas/:id` (admin)

### 8.6 Certifications

- `GET /certifications`
- `GET /certifications/holder/:userId`
- `GET /certifications/farming-area/:areaId`
- `GET /certifications/:id`
- `POST /certifications` (admin/manager)
- `POST /certifications/check-expired` (admin)
- `PATCH /certifications/:id` (admin/manager)
- `DELETE /certifications/:id` (admin)

### 8.7 Export

Tất cả endpoint export yêu cầu auth:

- `GET /export/product/:id/pdf`
- `GET /export/product/:id/timeline`
- `GET /export/products/excel`
- `GET /export/product/:id/qr`
- `POST /export/qr/batch`

### 8.8 Upload

- `POST /upload/single` (auth)
- `POST /upload/multiple` (auth)
- `DELETE /upload/:filename` (auth)

### 8.9 Notifications

- `GET /notifications` (auth)
- `GET /notifications/unread-count` (auth)
- `PATCH /notifications/read-all` (auth)
- `PATCH /notifications/:id/read` (auth)
- `DELETE /notifications/:id` (auth)
- `POST /notifications/check-expiring-certifications` (admin)

### 8.10 Admin

- `GET /admin/dashboard` (admin)
- `GET /admin/users` (admin)
- `PATCH /admin/users/:id/role` (admin)
- `PATCH /admin/users/:id/status` (admin)
- `DELETE /admin/users/:id` (admin)
- `GET /admin/health` (admin)

### 8.11 Search

- `GET /search/products`
- `GET /search/products/stats`
- `GET /search/events`
- `GET /search/events/stats`

### 8.12 Audit logs

- `GET /audit-logs` (admin)
- `GET /audit-logs/entity/:entity/:entityId` (admin/manager)
- `GET /audit-logs/user/:userId` (admin)

## 9) Mô hình dữ liệu chính

### Product

- Trường quan trọng: `name`, `category`, `type`, `origin`, `status`, `farming_area`, `qrcode`, `onChainBatchId`, `created_by`.
- `status`: draft | active | completed.

### TraceEvent

- Trường quan trọng: `product`, `batchId`, `eventType`, `description`, `details`, `images`, `recorded_by`.
- Metadata blockchain: `dataHash`, `txHash`, `blockNumber`, `actionIndex`, `onChainStatus`.
- `onChainStatus`: pending | confirmed | failed | skipped.

### User

- Trường quan trọng: `first_name`, `last_name`, `email`, `role`, `isActive`.
- `role`: admin | manager | farmer | consumer.

## 10) Cấu hình môi trường cần có

### 10.1 API (`api/.env`)

- `PORT` (mặc định 5000)
- `DB_URI`
- `JWT_SECRET`
- `JWT_LIFETIME`
- `BLOCKCHAIN_RPC_URL` (mặc định `http://127.0.0.1:8545`)
- `BLOCKCHAIN_PRIVATE_KEY`
- `CONTRACT_ADDRESS`
- `FRONTEND_URL` (mặc định `http://localhost:3000`)
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` (nếu dùng cloud media)

### 10.2 Blockchain (`blockchain/.env`)

- `PRIVATE_KEY`
- `SEPOLIA_RPC_URL`
- `AMOY_RPC_URL`
- `ETHERSCAN_API_KEY`
- `POLYGONSCAN_API_KEY`
- `CONTRACT_NAME` (tuỳ chọn, mặc định Traceability khi deploy script)

### 10.3 Web

- `REACT_APP_API_URL` (dev thường để `/api/v1` hoặc URL API đầy đủ)

### 10.4 Mobile

- Có thể truyền lúc build/chạy bằng:
  - `--dart-define=API_BASE_URL=http://<host>:5000/api/v1`

## 11) Hướng dẫn chạy local (khuyến nghị)

### 11.1 Blockchain

```bash
cd blockchain
npm install
npm run node
```

Terminal khác:

```bash
cd blockchain
npm run deploy:local
```

Lấy `CONTRACT_ADDRESS` và cấu hình cho API.

### 11.2 API

```bash
cd api
npm install
npm run dev
```

API mặc định tại: `http://localhost:5000`.

### 11.3 Web

```bash
cd web
npm install
npm start
```

Web dev mặc định tại: `http://localhost:3000`.

### 11.4 Mobile

```bash
cd app
flutter pub get
flutter run
```

Android emulator dùng host API: `10.0.2.2` theo logic trong `api_client.dart`.

## 12) Triển khai Docker hiện có

- `api/Dockerfile`: build TS -> dist, runtime Node 20 slim.
- `blockchain/Dockerfile`: chạy hardhat node + deploy local qua script `start-node-and-deploy.sh`.
- `web/Dockerfile`: build React, serve qua nginx.
- `web/nginx.conf`: proxy `/api/` sang service `api:5000`.

Lưu ý:

- Chưa có file docker-compose trong repo hiện tại.
- `Dockerfile` ở thư mục gốc đang để trống.

## 13) Test và chất lượng mã

- Có test smart contract: `blockchain/test/Traceability.test.ts`.
- Chưa thấy test tự động rõ ràng cho API/Web/Mobile trong trạng thái hiện tại.

## 14) Điểm cần lưu ý kỹ thuật

- Có dấu hiệu tồn tại code legacy JS trong `api/controllers/traceController.js` và `api/models/Batch.js`.
  - API thực tế đang chạy từ `api/src/index.ts` (TypeScript), nên cần tránh nhầm lẫn khi bảo trì.
- `package.json` ở thư mục gốc chỉ chứa dependency `mongodb`, không phải orchestrator chính của toàn hệ.
- Một số chuỗi tiếng Việt trong source bị lỗi encoding ký tự; nên chuẩn hóa UTF-8 khi bảo trì lâu dài.

## 15) Đề xuất cải tiến ngắn hạn

1. Thêm `docker-compose.yml` để chạy đồng bộ blockchain + api + web + db.
2. Tạo bộ `.env.example` cho từng module.
3. Bổ sung test integration cho API trace/product.
4. Chuẩn hóa module legacy (xoá hoặc migrate rõ ràng).
5. Bổ sung tài liệu sequence diagram cho các luồng create product/create trace/verify.

---

Nếu cần, có thể tách tài liệu này thành:

- `ARCHITECTURE.md` (kiến trúc)
- `API_REFERENCE.md` (endpoint)
- `RUNBOOK.md` (vận hành)
- `SECURITY_NOTES.md` (bảo mật)

để đội dự án dễ bảo trì hơn.
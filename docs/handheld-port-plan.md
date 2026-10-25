# Kế hoạch đưa Commander Wars lên máy cầm tay

Ngày chốt: 2026-10-25. Nhánh: `handheld` trên fork `son01490517/Commander_Wars`
(`origin` = fork, `upstream` = `Robosturm/Commander_Wars`).

## 1. Mục tiêu và phạm vi

- **Thiết bị:** Anbernic RG35XX Pro: chip Allwinner H700 (4 nhân A53), **1 GB RAM dùng chung CPU/GPU**,
  Mali-G31, màn 3.5" **640x480** (4:3), 2 cần analog, L1/L2/R1/R2.
- **Hệ điều hành:** ROCKNIX (bản H700 + DTB `sun50i-h700-anbernic-rg35xx-pro.dtb`) trên **thẻ nhớ riêng**.
  Thẻ muOS đi kèm máy giữ nguyên. Driver Panfrost (GLES 3.1), Sway (Wayland).
- **Chế độ chơi:** chơi đơn đấu AI (AI chạy local). Map vẽ trên Mac rồi copy sang máy
  (xem `docs/handheld-map-making.md`).
- **Đã loại:** GBA (quá yếu), PS Vita (không có Qt6, port quá lớn), máy đắt hơn (chủ dự án thà chơi trên PC).
- **Điều kiện mua máy:** chỉ mua khi bản build Linux arm64 trong Docker đạt **RAM đỉnh ≤ 700 MB**
  trong trận 2 người (xem mục 4).

## 2. Hiện trạng đo được (baseline)

| Đo | Kết quả |
|---|---|
| Linux arm64, menu chính | 1.43–1.45 GB |
| Linux arm64, trận 2 người (Agitated 24x22) | đỉnh ≈ 1.54 GB |
| Linux arm64, trận 4 AI (Axle Roads) | đỉnh 1.68 GB |
| Mac (footprint) | 1.4 → 1.8 GB, tăng ≈ 1 MB/s. Do driver OpenGL của macOS, **không** xảy ra trên Linux |

Nguyên nhân chính (đã xác định trong code):
1. **Mỗi texture giữ thêm một bản ảnh trong RAM** (`Texture::m_image`, `3rd_party/oxygine-framework/oxygine/core/opengl/texture.h:60`).
   Ảnh giải nén khoảng 530 MB, nên tổng thành khoảng 1.06 GB (một bản ở CPU, một bản ở GPU).
2. **65 ảnh nền JPG 1536x864** (43 cho menu, 22 cho trong trận) bị nạp hết lúc khởi động
   (`oxygine/core/renderer.cpp:85`). Giải nén ra 345 MB, trong khi mỗi lúc chỉ hiển thị 1 ảnh.
3. **Toàn bộ sprite** (4,763 PNG, giải nén 185 MB) được nạp lúc khởi động, kể cả battle animation đã bị tắt.
4. **Nhạc được giải nén cả bài** thành float (khoảng 90 MB cho 4 phút, `coreengine/audiodecoder.cpp:134-170`).

## 3. Các quyết định kỹ thuật

| Chủ đề | Quyết định |
|---|---|
| Build | Cờ CMake `HANDHELD_BUILD`. Mọi thay đổi cho máy cầm tay nằm sau cờ này hoặc sau một setting có mặc định giữ nguyên hành vi desktop |
| Qt | Thiết bị: Qt 6.10.3 tự build tối giản, đóng gói kèm game. Đo đạc ở 1A: Qt 6.9 của Ubuntu là đủ |
| AI | Chạy trong cùng process (`DEFAULTAIPIPE=OFF`). AI online để giai đoạn sau (Mac host trận multiplayer có slot AI) |
| Asset | `DEPLOY_RESOURCES_AS_FOLDER=ON` |
| Mạng | Giữ nguyên code, chỉ ẩn nút Multiplayer trên máy cầm tay |
| Ảnh nền | Nạp 1 ảnh mỗi lần. Gói cho máy cầm tay dùng bản cắt 4:3, thu nhỏ còn 640x480 |
| Texture | Giải phóng bản ảnh trong RAM sau khi đẩy lên GPU. Không dùng nén mất dữ liệu (ETC2/ASTC) vì game là pixel art |
| Sprite | Chỉ nạp những gì các phe trong trận cần. Battle animation và capture animation mặc định tắt và không được nạp |
| Dự phòng | RGBA5551 (26% số ảnh không mất màu), sau đó là texture bảng màu 8-bit. Chỉ làm nếu vẫn chưa đạt mốc |
| Hiển thị | Zoom mặc định 1x (ô 32 px, thấy 20x15 ô), không thu nhỏ sprite, tắt MSAA |
| Nhạc | Chuyển sang streaming bằng pull API của stb_vorbis/opusfile có sẵn |
| Giao diện | Kiểu GBA: bỏ thanh bên phải. Góc trên có ô CO/tiền/power tự né con trỏ. Minimap xem qua menu Start. Ô địa hình nhỏ mặc định tắt |
| Nút | Start = menu; d-pad = con trỏ; L1 = unit kế tiếp; R1 = panel thông tin nhỏ; Select = `FieldInfo` đầy đủ; cần phải + L2/R2 = chuột ảo; Select+Start = thoát |
| Chạy trên máy | ROCKNIX Ports (`roms/ports/CommanderWars/`), Qt platform `wayland`, deploy bằng rsync/SSH, zram làm lưới an toàn |
| Save/setting | Lưu trong thư mục game (`USEAPPCONFIGPATH=OFF`) |

## 4. Tiêu chí "chơi được" (hết giai đoạn 1)

- RAM đỉnh **≤ 700 MB** trong trận 2 người, map ≤ 30x30. zram không được tính vào mốc này.
- Chơi liên tục **≥ 60 phút** không bị kill.
- Mỗi lượt AI **≤ 30 giây** trên map 2 người cỡ vừa.
- **≥ 30 FPS** khi cuộn map.

## 5. Các giai đoạn

- **1A – Tối ưu trên Mac + Docker** (chưa có máy): các card `1A-*`. Kết thúc bằng card `1A-90` (xác nhận đạt mốc), sau đó **mua máy**.
- **1B – Trên máy:** cross-build Qt 6.10.3, đóng gói Ports, gamepad, bố cục GBA, đo thật. Card `1B-*` (dạng khung).
- **2 – Mở rộng:** editor trên máy, AI online qua multiplayer, bật lại battle animation nếu còn RAM.

Danh sách card và trạng thái: `docs/tasks/README.md`.

## 6. Quy trình làm card

1. Làm các card **theo thứ tự** trên nhánh `handheld`. Mỗi card kết thúc bằng **một commit** có tiêu đề `[<mã card>] ...`.
2. AI làm card chỉ đọc những gì card liệt kê (mỗi card nằm trong khoảng 100k context, tối đa 200k).
3. Cuối card: chạy các lệnh trong mục *Verification* rồi chạy `tools/jev-review.sh <mã card>`.
   Nếu RESULT là `FIX NEEDED` thì sửa và chạy lại, **tối đa 3 vòng**.
4. Sau 3 vòng vẫn lỗi: **không commit code lỗi**. Lưu `git diff > docs/tasks/<mã card>.wip.patch`, đưa
   cây làm việc về trạng thái sạch, đổi trạng thái card thành `Blocked – Opus` và ghi mục *Handoff notes*
   (đã thử gì, lỗi gì, nghi ngờ ở đâu). Commit riêng phần card, patch và README với tiêu đề `[<mã card>] blocked`.
5. Opus nhận card bị block chỉ cần mã card: đọc card, phần handoff notes và file patch là làm tiếp được.

## 7. Jev trong dự án

Jev (gọi qua OpenRouter, không cần duyệt từng lần) dùng ở các chỗ sau:
- **Review mỗi card:** `tools/jev-review.sh` hỏi bộ câu chung (`tools/handheld/jev/common-questions.json`) cộng với câu riêng của card.
- **Xác nhận "đã xong":** script tự tách mỗi tiêu chí trong *Acceptance criteria* thành một câu `criterion_N`, cộng thêm câu `receipts_valid`, để đối chiếu khẳng định với receipt. Phép so sánh số do script làm (`threshold_checks`).
- **Phân loại tài nguyên mơ hồ** (`jev-triage`) ở các card nạp sprite theo trận.
- **Chọn danh sách file cần đọc** (`jev-find-code`) khi viết hoặc chia nhỏ card.
- **Phát hiện đi lệch hoặc lặp lỗi** giữa các vòng sửa, và **tư vấn nén context** (`jev-context`).

Jev không viết code, không thay thế việc chạy build/test, và không quyết định thay chủ dự án.

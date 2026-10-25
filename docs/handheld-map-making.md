# Vẽ map trên Mac rồi chơi trên máy cầm tay

Editor có sẵn trong game chạy rất tốt trên Mac (dùng chuột và bàn phím). File `.map` dùng chung một
định dạng trên mọi nền tảng, nên vẽ xong chỉ cần copy sang máy.

## 1. Mở editor trên Mac

Bản build Mac nằm ở `../cw-build-mac` (build từ repo này với Qt 6.10.3 cài bằng `aqtinstall`).
Asset được để dạng thư mục, nên phải chạy game **từ thư mục repo**. Dùng thư mục người dùng riêng để
map không lẫn vào git:

```bash
mkdir -p ~/CommanderWarsUser
cd <thư-mục-repo>   # ví dụ ~/Coding/Commander_Wars
../cw-build-mac/Commander_Wars.app/Contents/MacOS/Commander_Wars --userPath ~/CommanderWarsUser/
```

Nếu cần build lại:

```bash
cmake -S . -B ../cw-build-mac -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$HOME/Qt/6.10.3/macos -DDEPLOY_RESOURCES_AS_FOLDER=ON -DDEFAULTAIPIPE=OFF
cmake --build ../cw-build-mac -j10
```

## 2. Tạo map phù hợp với máy cầm tay

Ở menu chính chọn **Map Editor**, rồi mở menu của editor và chọn **New Map**.

- **Kích thước:** tối đa **30x30** (mục tiêu giai đoạn 1). Màn 640x480 ở zoom 1x hiển thị 20x15 ô,
  nên map khoảng 20x15 đến 30x25 là dễ chơi nhất.
- **Số người chơi:** **2** (bạn và 1 AI).
- Mỗi phe cần có HQ, vài thành phố và ít nhất 1 nhà máy (factory) để AI có thể xây quân.
- Thao tác: chọn công cụ địa hình, công trình hoặc unit ở thanh chọn. Click trái để đặt, click phải để
  xóa. `Ctrl+Z`/`Ctrl+Y` để hoàn tác/làm lại.

Lưu map bằng **Save Map**. Editor lưu vào `<userPath>/maps/`, tức `~/CommanderWarsUser/maps/`.
Nên đặt map vào thư mục con, ví dụ `maps/custom/TenMap.map`.

## 3. Chơi thử trên Mac

Ở menu chính chọn **Singleplayer**, chọn map vừa lưu, đặt người chơi 1 là Human và người chơi 2 là AI
**Normal**. Nếu một lượt AI trên Mac đã mất hơn 3 giây, máy cầm tay (chậm hơn khoảng 8–15 lần) sẽ vượt
mục tiêu 30 giây mỗi lượt. Khi đó nên thu nhỏ map hoặc giảm số unit ban đầu.

## 4. Copy sang máy (sau giai đoạn 1B)

Game trên máy nằm ở `/storage/roms/ports/CommanderWars/`, và thư mục người dùng chính là thư mục game.

```bash
rsync -av ~/CommanderWarsUser/maps/custom/ root@<ip-may>:/storage/roms/ports/CommanderWars/maps/custom/
```

Không có WiFi thì cắm thẻ nhớ ROCKNIX vào Mac và copy vào `roms/ports/CommanderWars/maps/custom/`.

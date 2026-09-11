# Git Quick Guide

## 1. Clone repository

```bash
git clone git@github.com:Tgz07/Arch-install.git
cd Arch-install
```

## 2. Kiểm tra trạng thái

```bash
git status
```

Xem branch hiện tại:

```bash
git branch --show-current
```

Xem remote:

```bash
git remote -v
```

## 3. Cấu hình Git lần đầu

```bash
git config --global user.name "Tên của bạn"
git config --global user.email "email@example.com"
```

Kiểm tra:

```bash
git config --global --list
```

## 4. Tạo branch

```bash
git switch -c feature-name
```

Chuyển branch:

```bash
git switch main
```

Xem các branch:

```bash
git branch
```

## 5. Thêm thay đổi vào commit

Thêm toàn bộ file:

```bash
git add .
```

Hoặc bao gồm cả file bị xóa:

```bash
git add -A
```

Kiểm tra trước khi commit:

```bash
git status
```

## 6. Commit

Commit thông thường:

```bash
git commit -m "Mô tả thay đổi"
```

Commit có chữ ký GPG:

```bash
git commit -S -m "Mô tả thay đổi"
```

Xem lịch sử:

```bash
git log --oneline
```

## 7. Push lên GitHub

Push branch hiện tại:

```bash
git push
```

Push cụ thể:

```bash
git push origin main
```

Lần đầu push branch mới:

```bash
git push -u origin feature-name
```

## 8. Pull thay đổi mới

```bash
git pull
```

Hoặc:

```bash
git pull origin main
```

## 9. Xem thay đổi

File đã sửa:

```bash
git diff
```

Thay đổi đã `git add`:

```bash
git diff --cached
```

## 10. Hủy thay đổi

Hủy thay đổi của file chưa commit:

```bash
git restore file
```

Bỏ file khỏi staging nhưng giữ nội dung:

```bash
git restore --staged file
```

## 11. Xóa file

```bash
git rm file
git commit -m "Remove file"
git push
```

## 12. Đổi tên file

```bash
git mv old-name new-name
git commit -m "Rename file"
git push
```

## 13. Undo commit gần nhất

Giữ lại thay đổi:

```bash
git reset --soft HEAD~1
```

Xóa cả commit và thay đổi:

```bash
git reset --hard HEAD~1
```

`--hard` sẽ làm mất các thay đổi chưa được lưu ở nơi khác.

## 14. Đồng bộ branch

```bash
git switch main
git pull
```

Sau đó tạo branch mới:

```bash
git switch -c feature-name
```

## 15. Quy trình cơ bản

Sau khi sửa code:

```bash
git status
git add -A
git commit -m "Update files"
git push
```

Nếu dùng GPG:

```bash
git status
git add -A
git commit -S -m "Update files"
git push
```

## 16. Kiểm tra commit đã ký GPG

```bash
git log --show-signature -1
```

## 17. SSH với GitHub

Kiểm tra SSH:

```bash
ssh -T git@github.com
```

Xem public SSH key:

```bash
cat ~/.ssh/id_ed25519.pub
```

**Không chia sẻ private key:**

```text
~/.ssh/id_ed25519
```

Public key có thể thêm vào GitHub:

```text
~/.ssh/id_ed25519.pub
```

## 18. GPG

Liệt kê GPG key:

```bash
gpg --list-secret-keys --keyid-format=long
```

Xuất public GPG key:

```bash
gpg --armor --export KEY_ID
```

Cấu hình Git dùng GPG:

```bash
git config --global user.signingkey KEY_ID
git config --global commit.gpgsign true
```

## 19. Alias hữu ích

Ví dụ:

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm "commit -m"
```

Sau đó:

```bash
git st
git br
git cm "Update files"
```

## 20. Lệnh cần nhớ

```text
git clone     Tải repository
git status    Kiểm tra trạng thái
git add       Đưa thay đổi vào staging
git commit    Tạo commit
git push      Đẩy commit lên remote
git pull      Lấy thay đổi từ remote
git diff      Xem thay đổi
git log       Xem lịch sử
git switch    Chuyển/tạo branch
git restore   Khôi phục thay đổi
```

## Workflow

```bash
git clone git@github.com:Tgz07/Arch-install.git
cd Arch-install

# sửa code

git status
git add -A
git commit -S -m "Update configuration"
git push
```

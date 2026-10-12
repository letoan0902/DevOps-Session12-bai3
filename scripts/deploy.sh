#!/usr/bin/env bash
# Script mô phỏng triển khai ứng dụng lên một môi trường.
# Cách dùng: bash scripts/deploy.sh <staging|production>
set -euo pipefail

# Tên môi trường nhận từ tham số đầu tiên; thiếu tham số thì báo lỗi.
ENV_NAME="${1:-}"
if [ -z "$ENV_NAME" ]; then
  echo "Thiếu tham số. Cách dùng: bash scripts/deploy.sh <staging|production>" >&2
  exit 1
fi

# Chỉ chấp nhận hai môi trường hợp lệ.
case "$ENV_NAME" in
  staging|production) ;;
  *)
    echo "Môi trường không hợp lệ: $ENV_NAME" >&2
    exit 1
    ;;
esac

echo "=== Bắt đầu triển khai lên môi trường: $ENV_NAME ==="

echo "[1/4] Kéo artifact phiên bản mới nhất về máy chủ..."
sleep 2

echo "[2/4] Cập nhật cấu hình cho môi trường $ENV_NAME..."
sleep 2

echo "[3/4] Khởi động lại dịch vụ..."
sleep 2

echo "[4/4] Kiểm tra health của dịch vụ..."
sleep 2
echo "Health check: OK"

echo "=== Triển khai lên $ENV_NAME hoàn tất ==="

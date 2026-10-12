# Bài 3 - Tách biệt luồng CI/CD đa môi trường (Staging và Production) với GitHub Environments

Môn: DevOps - Session 12
Repo: https://github.com/letoan0902/DevOps-Session12-bai3
Tài khoản người duyệt (required reviewer): `letoan0902`

## 1. Mục tiêu

- Quản lý triển khai đa môi trường (Staging và Production) bằng GitHub Environments.
- Tạo 2 environment `staging` và `production` trên repo.
- Cấu hình Environment Protection Rules cho `production`: bật Required reviewers, chọn tài khoản cá nhân làm người duyệt, để mọi lần deploy lên Production phải được phê duyệt thủ công.
- Viết workflow `.github/workflows/cd-multi-env.yml` gồm 2 job:
  - `deploy-staging` dùng `environment: staging`, chạy khi push vào nhánh `develop`.
  - `deploy-prod` dùng `environment: production`, chạy khi push vào nhánh `main`.
- Kiểm tra: push vào `main` thì luồng dừng ở `deploy-prod` với trạng thái chờ phê duyệt (Waiting for review); sau khi bấm Approve and deploy, job chạy tiếp và có dấu tích xanh.

## 2. Khái niệm GitHub Environments

GitHub Environment là một "môi trường triển khai" được đặt tên (ví dụ `staging`, `production`) gắn với repo. Job trong workflow khai báo `environment: <tên>` để được áp dụng cấu hình của môi trường đó. Mỗi environment có thể có:

### 2.1. Secrets và variables theo môi trường

- Environment secrets: bí mật chỉ có hiệu lực với job dùng environment đó (ví dụ `DB_PASSWORD` của staging khác của production).
- Environment variables: biến cấu hình riêng từng môi trường (ví dụ `API_URL`).
- Secret của environment chỉ được giải mã khi job đã vượt qua các protection rules. Nghĩa là job Production chưa được duyệt thì không thể đọc secret Production.

### 2.2. Protection rules (quy tắc bảo vệ)

| Quy tắc | Ý nghĩa |
| --- | --- |
| Required reviewers | Tối đa 6 người hoặc team; chỉ cần 1 người trong danh sách phê duyệt là job được chạy tiếp |
| Wait timer | Chờ một khoảng thời gian (phút) trước khi job được phép chạy |
| Deployment branches and tags | Giới hạn nhánh hoặc tag nào được phép deploy vào environment này |
| Prevent self-review | Người kích hoạt deployment không được tự duyệt chính deployment đó |

Trong bài này dùng Required reviewers cho `production` và Deployment branches chỉ cho phép nhánh `main`. Environment `staging` không đặt rule nào nên deploy tự động.

### 2.3. Lịch sử triển khai

Mỗi lần job dùng environment chạy, GitHub tạo một deployment và ghi lại ở trang Deployments của repo (khu vực Environments ở cột bên phải trang chủ repo). Trường `url` khai báo trong workflow hiển thị ở đây và ở nút "View deployment" trên trang chạy workflow.

## 3. Sơ đồ luồng

```
                          +-----------------------------+
 git push origin develop  |  Workflow: cd-multi-env.yml |
 git push origin main     |  on: push (develop, main)   |
 ------------------------>|                             |
                          +--------------+--------------+
                                         |
              +--------------------------+--------------------------+
              |                                                     |
   github.ref == develop                                  github.ref == main
              |                                                     |
              v                                                     v
   +----------------------+                           +----------------------------+
   | deploy-staging       |                           | deploy-prod                |
   | environment: staging |                           | environment: production    |
   | (khong co rule)      |                           | (Required reviewers)       |
   +----------+-----------+                           +-------------+--------------+
              |                                                     |
              v                                                     v
      Chay ngay, tu dong                              Waiting for review (dung lai)
      checkout -> deploy.sh                                         |
      -> ghi tom tat                                  Reviewer: Review deployments
              |                                         -> tick production
              v                                         -> Approve and deploy
        Tich xanh                                                   |
                                                                    v
                                                      Job chay tiep: checkout
                                                      -> deploy.sh production
                                                      -> kiem tra sau trien khai
                                                                    |
                                                                    v
                                                              Tich xanh
```

Ở mỗi lần push, chỉ một trong hai job chạy; job còn lại có trạng thái Skipped do điều kiện `if`.

## 4. Hướng dẫn tạo environment

### 4.1. Trên giao diện web

1. Mở repo trên GitHub, chọn tab Settings.
2. Ở thanh bên trái, chọn Environments.
3. Bấm New environment, nhập tên `staging`, bấm Configure environment. Không cần thêm rule nào, để mặc định.
4. Quay lại danh sách Environments, bấm New environment lần nữa, nhập tên `production`, bấm Configure environment.
5. Trong mục Deployment protection rules, tick Required reviewers.
6. Ở ô tìm kiếm người duyệt, gõ `letoan0902` và chọn tài khoản này.
7. Bấm Save protection rules.
8. (Tùy chọn, khuyến nghị) Ở mục Deployment branches and tags, chọn Selected branches and tags, bấm Add deployment branch or tag rule, nhập `main` rồi Add rule. Khi đó chỉ nhánh `main` mới được deploy vào `production`.

Lưu ý: với repo private ở plan Free, mục Required reviewers không dùng được. Repo của bài này là public nên dùng bình thường.

### 4.2. Bằng API (gh CLI)

Tạo `staging` (không rule):

```bash
gh api --method PUT repos/letoan0902/DevOps-Session12-bai3/environments/staging
```

Tạo `production` với Required reviewers là `letoan0902` (user id 183306807) và bật chính sách nhánh tùy chỉnh (`custom_branch_policies`):

```bash
cat > prod-env.json <<'JSON'
{
  "reviewers": [
    { "type": "User", "id": 183306807 }
  ],
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
JSON

gh api --method PUT \
  repos/letoan0902/DevOps-Session12-bai3/environments/production \
  --input prod-env.json
```

Thêm quy tắc chỉ cho phép nhánh `main` deploy vào `production`:

```bash
gh api --method POST \
  repos/letoan0902/DevOps-Session12-bai3/environments/production/deployment-branch-policies \
  -f name=main -f type=branch
```

Kiểm tra lại cấu hình:

```bash
gh api repos/letoan0902/DevOps-Session12-bai3/environments/production \
  --jq '{name: .name, rules: [.protection_rules[] | {type: .type, reviewers: (.reviewers // [] | map(.reviewer.login))}], branch_policy: .deployment_branch_policy}'

gh api repos/letoan0902/DevOps-Session12-bai3/environments --jq '.environments[].name'
```

Cách lấy user id của một tài khoản: `gh api users/letoan0902 --jq .id` (kết quả 183306807).

## 5. Giải thích workflow `cd-multi-env.yml`

File nằm ở `.github/workflows/cd-multi-env.yml` (bản sao để nộp bài ở `homework/session_12/ex3/cd-multi-env.yml`).

### 5.1. Phần khai báo chung

```yaml
name: CD - Deploy da moi truong (staging/production)

on:
  push:
    branches:
      - develop
      - main
  workflow_dispatch:

permissions:
  contents: read
```

- `on.push.branches`: workflow chạy khi push vào `develop` hoặc `main`.
- `workflow_dispatch`: cho phép chạy tay từ tab Actions. Khi chạy tay trên nhánh nào thì `github.ref` là nhánh đó nên vẫn áp dụng đúng điều kiện `if`.
- `permissions: contents: read`: nguyên tắc đặc quyền tối thiểu; workflow chỉ cần đọc mã nguồn.

### 5.2. Job `deploy-staging`

```yaml
deploy-staging:
  name: Deploy to Staging
  if: github.ref == 'refs/heads/develop'
  runs-on: ubuntu-latest
  environment:
    name: staging
    url: https://staging.example.com
```

- `if: github.ref == 'refs/heads/develop'`: job chỉ chạy khi push vào `develop`.
- `environment.name: staging`: gắn job với environment `staging` (không có rule nên chạy ngay).
- `environment.url`: đường dẫn hiển thị ở trang Deployments và ở trang chạy workflow.

Các bước:

1. Checkout mã nguồn bằng `actions/checkout@v5` để có file `scripts/deploy.sh`.
2. Hiển thị thông tin triển khai: in nhánh, commit SHA, người kích hoạt và tên environment từ các biến môi trường mặc định (`GITHUB_REF_NAME`, `GITHUB_SHA`, `GITHUB_ACTOR`).
3. Mô phỏng triển khai: chạy `bash scripts/deploy.sh staging`.
4. Ghi tóm tắt: ghi bảng Markdown vào `$GITHUB_STEP_SUMMARY`, hiện ở phần Summary của trang run.

### 5.3. Job `deploy-prod`

```yaml
deploy-prod:
  name: Deploy to Production
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  environment:
    name: production
    url: https://api.prod.example.com
```

- `if: github.ref == 'refs/heads/main'`: job chỉ chạy khi push vào `main`.
- `environment.name: production`: gắn với environment có Required reviewers. Vì protection rules áp ở cấp job, GitHub giữ job ở trạng thái Waiting, chưa cấp runner và chưa cho đọc secret của environment cho đến khi reviewer phê duyệt.
- Các bước giống Staging, thêm bước "Kiểm tra sau triển khai" in thông điệp xác nhận dịch vụ Production hoạt động.

### 5.4. Vì sao dùng `if` theo `github.ref` thay vì tách 2 workflow

- Hai môi trường dùng chung các bước nên gom vào một file để tránh lặp lại và dễ bảo trì.
- Một trang Actions cho thấy toàn bộ luồng CD; job không thuộc nhánh hiện tại ở trạng thái Skipped.
- Nếu tách làm 2 workflow, mỗi workflow dùng `on.push.branches` riêng vẫn được, nhưng phải duy trì hai bản sao gần giống nhau, dễ lệch cấu hình.

### 5.5. Script `scripts/deploy.sh`

Script bash (`set -euo pipefail`) nhận tham số `staging` hoặc `production`, kiểm tra hợp lệ rồi in 4 bước mô phỏng, mỗi bước `sleep 2`:

1. Kéo artifact về máy chủ.
2. Cập nhật cấu hình cho môi trường.
3. Khởi động lại dịch vụ.
4. Kiểm tra health của dịch vụ.

Tham số sai hoặc thiếu thì script thoát với mã lỗi 1, nhờ đó job fail đúng thay vì chạy sai môi trường.

## 6. Cách kiểm tra

### 6.1. Kiểm tra luồng Staging

1. Tạo nhánh `develop` và push lên GitHub.
2. Vào tab Actions, mở run mới nhất của workflow "CD - Deploy da moi truong (staging/production)".
3. Job `Deploy to Staging` chạy ngay, không chờ ai duyệt; job `Deploy to Production` ở trạng thái Skipped.
4. Kết thúc với dấu tích xanh; ở mục Summary có bảng kết quả triển khai Staging.

### 6.2. Kiểm tra luồng Production (cần phê duyệt)

1. Push (hoặc merge) vào nhánh `main`.
2. Vào tab Actions, mở run vừa được tạo.
3. Job `Deploy to Production` hiển thị trạng thái "Waiting for review" (hoặc "Review pending"); job `Deploy to Staging` là Skipped.
4. Ở đầu trang run có banner "This workflow is awaiting approval from a reviewer" kèm nút "Review deployments".
5. Đăng nhập bằng tài khoản `letoan0902` (reviewer), bấm "Review deployments".
6. Trong cửa sổ hiện ra, tick vào `production`, có thể nhập ghi chú vào ô comment.
7. Bấm "Approve and deploy".
8. Job `Deploy to Production` chuyển sang Queued rồi In progress, chạy lần lượt các bước và kết thúc với dấu tích xanh. Nút "View deployment" trỏ tới `https://api.prod.example.com`.

Nếu bấm "Reject" thay vì Approve, job bị hủy và run kết thúc ở trạng thái thất bại.

## 7. Kết quả chạy thật trên GitHub Actions

Repo: https://github.com/letoan0902/DevOps-Session12-bai3 (tab Actions: https://github.com/letoan0902/DevOps-Session12-bai3/actions). Hai environment đã được tạo trước khi push, `production` có required reviewer là `letoan0902` và chỉ cho phép deploy từ nhánh `main`:

```text
$ gh api repos/letoan0902/DevOps-Session12-bai3/environments -q '.environments[] | .name'
production
staging
```

### 7.1. Push nhánh `develop` -> job `deploy-staging` chạy ngay (run 38301827604)

```text
$ gh run view 38301827604 --repo letoan0902/DevOps-Session12-bai3
V develop CD - Deploy da moi truong (staging/production) . 38301827604
Triggered via push

JOBS
V Deploy to Staging in 11s (ID 114986325519)
- Deploy to Production (ID 114986327454)

$ gh api repos/letoan0902/DevOps-Session12-bai3/actions/runs/38301827604/jobs -q '.jobs[] | "\(.name): \(.status)/\(.conclusion)"'
Deploy to Staging: completed/success
Deploy to Production: completed/skipped
```

Trích log bước `Mô phỏng triển khai` của job staging:

```text
=== Bắt đầu triển khai lên môi trường: staging ===
[2/4] Cập nhật cấu hình cho môi trường staging...
Health check: OK
=== Triển khai lên staging hoàn tất ===
```

Environment `staging` không có protection rule nên job chạy thẳng và xanh sau 11 giây. Job `deploy-prod` bị skipped vì điều kiện `if: github.ref == 'refs/heads/main'` không thỏa.

### 7.2. Push nhánh `main` -> job `deploy-prod` dừng chờ phê duyệt (run 38301870340)

```text
$ gh run view 38301870340 --repo letoan0902/DevOps-Session12-bai3
* main CD - Deploy da moi truong (staging/production) . 38301870340
Triggered via push

JOBS
* Deploy to Production (ID 114986471468)
- Deploy to Staging (ID 114986473501)

$ gh api repos/letoan0902/DevOps-Session12-bai3/actions/runs/38301870340/jobs -q '.jobs[] | "\(.name): \(.status)/\(.conclusion // "-")"'
Deploy to Production: waiting/-
Deploy to Staging: completed/skipped

$ gh api repos/letoan0902/DevOps-Session12-bai3/actions/runs/38301870340/pending_deployments
environment=production  current_user_can_approve=true  reviewers=letoan0902
```

Run ở trạng thái `waiting`: job `Deploy to Production` chưa được cấp runner, GitHub tạo một deployment chờ (pending deployment) cho environment `production` và chỉ reviewer `letoan0902` mới được phê duyệt. Trang run hiển thị thông báo chờ phê duyệt kèm nút Review deployments. Trang Deployments của repo ghi nhận hai deployment: `staging` từ `develop` (đã xong) và `production` từ `main` (đang chờ).

### 7.3. Bước phê duyệt (học viên thực hiện và chụp ảnh)

Mở run 38301870340, bấm Review deployments, tích `production`, có thể ghi chú, rồi bấm Approve and deploy. Job `Deploy to Production` sẽ chạy script `scripts/deploy.sh production` và chuyển sang tích xanh; trang Deployments cập nhật URL `https://api.prod.example.com`. Ảnh chụp cửa sổ Review deployments chính là ảnh nộp bài. Tương đương bằng dòng lệnh:

```bash
gh api --method POST repos/letoan0902/DevOps-Session12-bai3/actions/runs/38301870340/pending_deployments   -f "environment_ids[]=<id của production>" -f state=approved -f comment="Dong y deploy production"
```

### 7.4. Bảng tổng hợp

| Nhánh push | Job deploy-staging | Job deploy-prod | Ghi chú |
|---|---|---|---|
| `develop` | success (11s) | skipped | environment `staging` không có rule, chạy ngay |
| `main` | skipped | waiting (chờ reviewer `letoan0902`) | required reviewers của `production` chặn job cho tới khi được duyệt |

## 8. Ảnh chụp màn hình

Phần này do học viên tự thực hiện trong khi run của nhánh `main` đang ở trạng thái chờ duyệt:

1. Vào Actions, mở run của lần push vào `main` (job `Deploy to Production` đang Waiting).
2. Bấm "Review deployments" để mở cửa sổ phê duyệt.
3. Tick `production`, chụp lại toàn bộ cửa sổ Review deployments (thấy tên environment `production`, ô comment và nút "Approve and deploy").
4. Lưu ảnh vào thư mục `homework/session_12/ex3/` (ví dụ `review-deployments.png`) và nộp cùng file workflow.
5. Sau đó bấm "Approve and deploy"; nên chụp thêm ảnh job đã tích xanh để đối chiếu.

Ảnh chụp: (học viên bổ sung)

## 9. Xử lý sự cố

| Hiện tượng | Nguyên nhân | Cách xử lý |
| --- | --- | --- |
| Job `deploy-prod` chạy luôn, không chờ duyệt | Environment `production` chưa được tạo trước khi chạy; GitHub tự tạo environment mới không có rule nào | Tạo environment `production` và bật Required reviewers rồi chạy lại workflow |
| Không thấy mục Required reviewers khi cấu hình | Repo private trên plan Free không hỗ trợ reviewers | Đổi repo sang public hoặc nâng cấp plan (GitHub Pro/Team/Enterprise) |
| Cả 2 job đều Skipped | Điều kiện `if` không khớp với ref, ví dụ push vào nhánh khác hoặc sai tên nhánh (`master` thay vì `main`) | Kiểm tra `github.ref` và tên nhánh; sửa `if` hoặc dùng đúng nhánh |
| Job Production bị từ chối vì nhánh không được phép deploy | Deployment branch policy chỉ cho phép `main`, nhưng run được kích hoạt từ nhánh khác (ví dụ chạy tay `workflow_dispatch` trên nhánh khác) | Chạy từ nhánh `main` hoặc thêm nhánh vào danh sách cho phép ở mục Deployment branches |
| Không thấy nút Review deployments | Tài khoản đang xem không nằm trong danh sách reviewer, hoặc bật Prevent self-review và chính mình là người kích hoạt | Đăng nhập bằng reviewer đúng; tắt Prevent self-review hoặc thêm người duyệt khác |
| Lỗi không tìm thấy `scripts/deploy.sh` | Chưa push thư mục `scripts/` hoặc thiếu bước checkout | Đảm bảo `scripts/deploy.sh` đã commit và job có bước `actions/checkout` |
| Workflow không xuất hiện trong tab Actions | File không nằm đúng `.github/workflows/` hoặc YAML sai cú pháp | Chạy actionlint để kiểm tra cú pháp (xem mục 10) |

## 10. Kiểm tra cú pháp bằng actionlint

```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -no-color .github/workflows/cd-multi-env.yml
```

Kết quả: không có lỗi hay cảnh báo (exit code 0). Chi tiết ở file `actionlint_output.txt`. Script `scripts/deploy.sh` cũng đã qua `bash -n` không lỗi và đã chạy thử cục bộ với cả hai tham số hợp lệ lẫn tham số sai.

## 11. Bảng đối chiếu yêu cầu đề bài

| Yêu cầu đề bài | Cách đáp ứng | Vị trí |
| --- | --- | --- |
| Tạo 2 environment `staging` và `production` | Tạo qua giao diện hoặc API (mục 4) | Settings -> Environments |
| `production` bật Required reviewers, chọn tài khoản cá nhân làm người duyệt | Reviewer là `letoan0902` (id 183306807) | Mục 4.1 bước 5-7, mục 4.2 |
| Workflow `.github/workflows/cd-multi-env.yml` | Có file ở gốc repo, bản sao ở `homework/session_12/ex3/` | `.github/workflows/cd-multi-env.yml` |
| Job `deploy-staging` với `environment: staging`, kích hoạt khi push `develop` | `if: github.ref == 'refs/heads/develop'` và `environment.name: staging` | Mục 5.2 |
| Job `deploy-prod` với `environment: production`, kích hoạt khi push `main` | `if: github.ref == 'refs/heads/main'` và `environment.name: production`, có `url` | Mục 5.3 |
| Push vào `main` thì dừng ở `deploy-prod`, hiển thị Waiting for review | Do Required reviewers của `production` | Mục 6.2 |
| Bấm Approve and deploy thì job tiếp tục và tích xanh | Reviewer duyệt trong cửa sổ Review deployments | Mục 6.2 bước 5-8 |
| Nộp workflow và ảnh cửa sổ phê duyệt Production | Workflow đã có; ảnh do học viên chụp | Mục 8 |
| Đường dẫn gợi ý `homework/session_12/ex3/` | Bài nộp đặt tại thư mục này | `homework/session_12/ex3/` |

## 12. Kết luận

GitHub Environments cho phép tách rõ hai luồng triển khai trong cùng một workflow: Staging chạy tự động mỗi khi push vào `develop`, còn Production chỉ chạy sau khi được người có thẩm quyền phê duyệt thủ công. Protection rules áp dụng ở cấp job nên các bước triển khai Production, cùng secret của environment, không được thực thi trước khi duyệt. Kết hợp với Deployment branches giới hạn nhánh `main`, quy trình vừa nhanh ở môi trường thử nghiệm, vừa an toàn ở môi trường thật, đồng thời lưu lại lịch sử ai đã duyệt, duyệt lúc nào ở trang Deployments.

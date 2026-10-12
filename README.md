# DevOps Session 12 - Bài 3: CD đa môi trường với GitHub Environments

Repo minh họa cách tách biệt luồng triển khai Staging và Production bằng GitHub Environments. Environment `production` bật Required reviewers nên mọi lần deploy lên Production đều phải chờ người duyệt phê duyệt thủ công.

- Báo cáo chi tiết: [homework/session_12/ex3/README.md](homework/session_12/ex3/README.md)
- Workflow: [.github/workflows/cd-multi-env.yml](.github/workflows/cd-multi-env.yml)

## Danh sách file

| File | Mô tả |
| --- | --- |
| `.github/workflows/cd-multi-env.yml` | Workflow CD với 2 job `deploy-staging` và `deploy-prod` |
| `scripts/deploy.sh` | Script bash mô phỏng các bước triển khai |
| `homework/session_12/ex3/cd-multi-env.yml` | Bản sao workflow để nộp bài |
| `homework/session_12/ex3/README.md` | Báo cáo bài làm |
| `homework/session_12/ex3/actionlint_output.txt` | Kết quả kiểm tra cú pháp bằng actionlint |

Trạng thái CD: push `develop` -> run 38301827604, job `Deploy to Staging` thành công (11s). Push `main` -> run 38301870340 đang ở trạng thái waiting tại job `Deploy to Production`, chờ reviewer `letoan0902` bấm Approve and deploy (environment `production` có required reviewers). Chi tiết ở mục 7 của báo cáo. Actions: https://github.com/letoan0902/DevOps-Session12-bai3/actions

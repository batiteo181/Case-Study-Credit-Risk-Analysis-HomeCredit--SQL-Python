# Phân Tích Dữ Liệu Rủi Ro Tín Dụng (Credit Risk Analysis)

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/drive/1jnYylKUXVeZhdyjDaTWBFyerzC8ykWjp?usp=sharing)

**Công cụ sử dụng:** SQL (Google BigQuery), Python (Pandas, NumPy), Tableau Public.

## 1. Giới thiệu & Bài toán Kinh doanh (Ask)
Ngành ngân hàng đang đẩy mạnh việc tích hợp AI và Machine Learning vào Core Banking để tự động hóa quy trình phê duyệt khoản vay (Credit Scoring). Tuy nhiên, để hệ thống AI hoạt động chính xác và hiệu quả, cần xác định rõ các đặc điểm nhân khẩu học dẫn đến nguy cơ nợ xấu (Default).

**Mục tiêu dự án:** Phân tích tập dữ liệu lịch sử tín dụng để tìm ra mối liên hệ giữa độ tuổi, trình độ học vấn và khả năng trả nợ của khách hàng. Từ đó, đề xuất các tham số (rules) để phân luồng phê duyệt tín dụng tự động.

## 2. Nguồn dữ liệu (Prepare)
*   **Nguồn:** Bộ dữ liệu [Home Credit Default Risk (Kaggle)](https://www.kaggle.com/c/home-credit-default-risk/data).
*   **Tập dữ liệu:** Bảng `application_train.csv` (chứa 307,511 bản ghi thông tin khách hàng tại thời điểm nộp đơn vay).

## 3. Xử lý và Làm sạch Dữ liệu (Process)
Dự án thực thi làm sạch dữ liệu song song bằng 2 phương pháp (Python và SQL) để chứng minh sự linh hoạt trong kỹ thuật tiền xử lý.

### Cách 1: Tiền xử lý bằng Python (Google Colab)
*   Nạp và đọc dữ liệu bằng thư viện Pandas.
*   **Xác minh định danh:** Sử dụng `.drop_duplicates()` để loại bỏ các ID khách hàng lặp lại, đảm bảo tính duy nhất của khóa chính `SK_ID_CURR`.
*   **Xử lý điểm dị biệt (Outliers):** Phát hiện lỗi hệ thống ở cột `DAYS_EMPLOYED` với giá trị `365243` (tương đương 1000 năm). Sử dụng `np.nan` thay thế để ngăn chặn sai lệch thống kê.
*   👉 [Xem chi tiết mã nguồn Python tại Google Colab]([https://colab.research.google.com/drive/1jnYylKUXVeZhdyjDaTWBFyerzC8ykWjp#scrollTo=lWP45kcHwzVD](https://colab.research.google.com/drive/1jnYylKUXVeZhdyjDaTWBFyerzC8ykWjp?usp=sharing))

### Cách 2: Tiền xử lý bằng SQL (Google BigQuery)
*   **Khởi tạo:** Tạo bảng ngoài (External Table) kết nối trực tiếp với Google Cloud Storage.
*   **Kiểm tra toàn vẹn:** Sử dụng `COUNT` và `GROUP BY` để xác minh không có sự trùng lặp khóa chính.
*   **Làm sạch khuyết thiếu:** Dùng hàm `NULLIF` và `COALESCE` để xử lý giá trị dị biệt và điền nhãn 'Unknown' cho dữ liệu trống.
*   **Tối ưu hóa:** Tạo Native Table mới (`application_train_cleaned`) để gỡ bỏ giới hạn Read-only và tăng tốc truy vấn.


<summary><b>Mã nguồn SQL khởi tạo bảng sạch</b></summary>

```sql
CREATE OR REPLACE TABLE `your_project.home_credit.application_train_cleaned` AS
SELECT 
    * EXCEPT(DAYS_EMPLOYED, OCCUPATION_TYPE),
    NULLIF(DAYS_EMPLOYED, 365243) AS DAYS_EMPLOYED_CLEANED,
    COALESCE(OCCUPATION_TYPE, 'Unknown') AS OCCUPATION_TYPE_CLEANED
FROM `your_project.home_credit.application_train`;
```


## 4. Phân tích & Trực quan hóa Dữ liệu (Analyze & Share)
Dữ liệu sau khi làm sạch được truy xuất qua SQL để lấy các bảng tổng hợp và đưa vào Tableau xây dựng Dashboard.

(Chèn ảnh Dashboard Tableau tại đây bằng cú pháp: ![Dashboard Phân tích Rủi ro Tín dụng](https://github.com/batiteo181/Case-Study-Credit-Risk-Analysis-HomeCredit--SQL-Python/tree/main/03_Visualizations)

Insights chính rút ra từ dữ liệu:

Phân bổ theo độ tuổi: Nhóm khách hàng trẻ tuổi (Dưới 30 tuổi) có tỷ lệ nợ xấu cao nhất. Tỷ lệ rủi ro giảm dần và đạt mức an toàn nhất ở độ tuổi trung niên và người cao tuổi.

Phân bổ theo học vấn: Khách hàng có trình độ học vấn thấp (Secondary/Lower secondary) mang rủi ro vỡ nợ cao hơn mức trung bình và vượt trội so với nhóm có bằng Đại học trở lên (Higher education).

## 5. Đề xuất Chiến lược Kinh doanh (Act)
Dựa trên kết quả phân tích định lượng, đề xuất tích hợp các quy tắc sau vào mô hình AI Credit Scoring của hệ thống Core Banking:

Thiết lập "Luồng Xanh" (Straight-Through Processing): Tự động duyệt hồ sơ cho các khoản vay tín chấp nhỏ đối với phân khúc khách hàng rủi ro thấp (Trên 30 tuổi và có bằng Đại học). Giải pháp này giúp tối ưu chi phí vận hành và rút ngắn thời gian phê duyệt xuống mức tối thiểu.

Thiết lập "Luồng Thẩm Định Kỹ": Đối với phân khúc rủi ro cao (Dưới 30 tuổi và học vấn cấp 2/cấp 3), hệ thống AI tự động chuyển hướng hồ sơ sang luồng thẩm định thủ công. Bắt buộc nhân viên tín dụng thực hiện gọi điện xác minh chéo, yêu cầu bổ sung chứng từ thu nhập hoặc chỉ định người đồng bảo lãnh trước khi giải ngân.

Tác giả: Nguyen Dinh Tuan

Chuyên môn: Banking Operations Specialist & Data Analyst

Liên hệ: LinkedIn | nguyendinhtuan181@gmail.com

# Case-Study-Credit-Risk-Analysis-HomeCredit--SQL-Python
Case study phân tích rủi ro tín dụng ngân hàng bằng SQL (BigQuery), Python và Tableau.
# Phân Tích Dữ Liệu Rủi Ro Tín Dụng (Credit Risk Analysis) 
**Công cụ sử dụng:** SQL (Google BigQuery), Python, Tableau Public.

## 1. Giới thiệu & Bài toán Kinh doanh (Ask)
Ngành ngân hàng đang đẩy mạnh việc tích hợp AI và Machine Learning vào Core Banking để tự động hóa quy trình phê duyệt khoản vay (Credit Scoring). Tuy nhiên, để AI hoạt động chính xác, chúng ta cần hiểu rõ các đặc điểm nhân khẩu học nào của khách hàng có nguy cơ dẫn đến nợ xấu (Default).

**Mục tiêu dự án:** Phân tích tập dữ liệu lịch sử tín dụng để tìm ra mối liên hệ giữa độ tuổi, trình độ học vấn và khả năng trả nợ của khách hàng. Từ đó đề xuất các quy tắc (rules) để phân luồng phê duyệt tín dụng.

## 2. Nguồn Dữ Liệu (Prepare)
- **Nguồn:** Bộ dữ liệu [Home Credit Default Risk trên Kaggle](https://www.kaggle.com/c/home-credit-default-risk/data).
- **Tập dữ liệu:** Sử dụng bảng `application_train.csv` (chứa hơn 300,000 bản ghi về thông tin khách hàng tại thời điểm nộp đơn vay).

## 3. Xử lý Dữ liệu bằng SQL (Process)
Sử dụng **Google BigQuery** để nạp dữ liệu và thực hiện làm sạch:
- **Kiểm tra trùng lặp:** Xác minh khóa chính `SK_ID_CURR` không có giá trị lặp lại.
- **Xử lý giá trị dị biệt (Outliers):** Phát hiện lỗi hệ thống ở cột `DAYS_EMPLOYED` với giá trị `365243` (tương đương 1000 năm làm việc). Đã sử dụng SQL để loại trừ các giá trị này nhằm tránh sai lệch thống kê.
- **Xử lý dữ liệu thiếu (Missing values):** Dùng hàm `COALESCE` để gán nhãn 'Unknown' cho các trường bị thiếu dữ liệu.

<details>
<summary><b>Bấm vào đây để xem Code SQL làm sạch dữ liệu</b></summary>

```sql
-- Tạo bảng đã làm sạch để phân tích
CREATE OR REPLACE TABLE `your_project.home_credit.application_train_cleaned` AS
SELECT 
    * EXCEPT(DAYS_EMPLOYED, OCCUPATION_TYPE),
    NULLIF(DAYS_EMPLOYED, 365243) AS DAYS_EMPLOYED_CLEANED,
    COALESCE(OCCUPATION_TYPE, 'Unknown') AS OCCUPATION_TYPE_CLEANED
FROM `your_project.home_credit.application_train`;


```
4. Phân tích & Trực quan hóa Dữ liệu (Analyze & Share)
Dữ liệu sau khi làm sạch được truy xuất qua SQL để lấy các bảng tổng hợp và đưa vào Tableau để xây dựng Dashboard.

(Lưu ý: Thay thế dòng bên dưới bằng cách dán link ảnh bạn đã copy ở bước trên vào giữa hai dấu ngoặc đơn)

Insights chính rút ra từ biểu đồ:

Theo độ tuổi: Nhóm khách hàng trẻ tuổi (Dưới 30 tuổi) có tỷ lệ nợ xấu cao nhất. Tỷ lệ rủi ro giảm dần và an toàn nhất ở độ tuổi trung niên và người cao tuổi.

Theo học vấn: Khách hàng có trình độ học vấn thấp (Secondary/Lower secondary) mang rủi ro vỡ nợ cao hơn hẳn so với nhóm có bằng Đại học trở lên (Higher education).

5. Đề xuất Chiến lược Kinh doanh (Act)
Dựa trên các Insight thu được, tôi đề xuất tích hợp các quy tắc sau vào mô hình AI Credit Scoring của hệ thống Core Banking:

Thiết lập "Luồng Xanh" (Straight-Through Processing): Tự động duyệt hồ sơ cho các khoản vay tín chấp nhỏ đối với tệp khách hàng rủi ro thấp (Trên 30 tuổi và có bằng Đại học). Điều này giúp giảm thiểu chi phí vận hành và rút ngắn thời gian phê duyệt xuống còn vài phút.

Thiết lập "Luồng Thẩm Định Kỹ": Đối với tệp rủi ro cao (Dưới 30 tuổi và học vấn cấp 2/cấp 3), hệ thống AI nên tự động đẩy hồ sơ sang luồng thẩm định thủ công. Yêu cầu nhân viên tín dụng gọi điện xác minh, yêu cầu bổ sung giấy tờ chứng minh thu nhập hoặc yêu cầu người đồng bảo lãnh trước khi giải ngân.

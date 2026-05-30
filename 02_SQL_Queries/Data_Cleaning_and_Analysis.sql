Phần 2: Làm sạch dữ liệu bằng SQLĐể dùng SQL, bước đầu tiên là bạn cần nhập dữ liệu của mình (Import your data) vào công cụ quản trị cơ sở dữ liệu như PostgreSQL, MySQL, hoặc MS SQL Server. Hãy tạo một bảng có tên application_train và import file CSV vào đó. Sau khi nạp xong, chúng ta sẽ bắt đầu khám phá dữ liệu, xem xét tổng số hàng, các giá trị khác biệt, giá trị lớn nhất, nhỏ nhất. Bước 1: Kiểm tra tổng quan và dữ liệu trùng lặp:

Kiểm tra tính toàn vẹn và trùng lặp Khóa chính (SK_ID_CURR) không được phép lặp lại.
SQL

-- Đếm tổng số bản ghi
SELECT COUNT(*) AS total_rows
FROM `intense-pier-497108-v9.home_credit.application_train`;
-- Xác định trùng lặp
SELECT SK_ID_CURR, COUNT(*) as count_id
FROM `intense-pier-497108-v9.home_credit.application_train`
GROUP BY SK_ID_CURR
HAVING count_id > 1;
Khắc phục điểm dị biệt (Outliers) và Dữ liệu thiếu bằng Truy vấn Động Không dùng lệnh UPDATE. Sử dụng truy vấn phân tích trực tiếp loại trừ điểm dị biệt và điền dữ liệu khuyết.
SQL

SELECT
COALESCE(OCCUPATION_TYPE, 'Unknown') AS job_type,
COUNT(*) AS total_customers,
SUM(TARGET) AS total_defaulters,
ROUND((SUM(TARGET) / COUNT(*)) * 100, 2) AS default_rate_percent
FROM `intense-pier-497108-v9.home_credit.application_train`
-- Lọc bỏ giá trị dị biệt hệ thống

WHERE DAYS_EMPLOYED != 365243 OR DAYS_EMPLOYED IS NULL
GROUP BY job_type
ORDER BY default_rate_percent DESC;
Khởi tạo Bảng Native đã làm sạch (Bắt buộc) Lưu cấu trúc đã làm sạch thành một bảng nội bộ trên BigQuery để gỡ bỏ giới hạn Read-only và tăng tốc độ xử lý.
SQL

CREATE OR REPLACE TABLE `intense-pier-497108-v9.home_credit.application_train_cleaned` AS
SELECT
 * EXCEPT(DAYS_EMPLOYED, OCCUPATION_TYPE),
NULLIF(DAYS_EMPLOYED, 365243) AS DAYS_EMPLOYED_CLEANED,
COALESCE(OCCUPATION_TYPE, 'Unknown') AS OCCUPATION_TYPE_CLEANED
FROM `intense-pier-497108-v9.home_credit.application_train`;
Bảng application_train_cleaned sẽ được tạo. Truy vấn trực tiếp vào bảng này cho các bước phân tích rủi ro tín dụng tiếp theo. Bấm "SAVE RESULTS" trên giao diện kết quả để xuất CSV/Google Sheets phục vụ vẽ biểu đồ.

https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1sintense-pier-497108-v9!2shome_credit!3sapplication_train_cleaned

https://docs.google.com/spreadsheets/d/1pe3epHDHO-TNViAYi7V41Kqm7fDbglCp20Rq6-3JPBw/edit?gid=1452038888#gid=1452038888

Khối lệnh trực quan hóa tỷ lệ mất cân bằng dữ liệu
SQL

SELECT
CASE
WHEN ABS(DAYS_BIRTH) / 365 < 30 THEN '1. Dưới 30 tuổi'
WHEN ABS(DAYS_BIRTH) / 365 BETWEEN 30 AND 40 THEN '2. Từ 30 - 40 tuổi'
WHEN ABS(DAYS_BIRTH) / 365 BETWEEN 40 AND 50 THEN '3. Từ 40 - 50 tuổi'
WHEN ABS(DAYS_BIRTH) / 365 BETWEEN 50 AND 60 THEN '4. Từ 50 - 60 tuổi'
ELSE '5. Trên 60 tuổi'
END AS age_group,
COUNT(*) AS total_customers,
SUM(TARGET) AS total_defaults,
ROUND((SUM(TARGET) / COUNT(*)) * 100, 2) AS default_rate_percent
FROM `intense-pier-497108-v9.home_credit.application_train_cleaned`
GROUP BY age_group
ORDER BY age_group;
https://drive.google.com/file/d/1gjOhF5nzW53kpo6eFA-CHlqYJua1B9sN/view

Phân tích rủi ro theo Trình độ học vấn (Education Level)
SQL

SELECT
NAME_INCOME_TYPE AS income_type,
COUNT(*) AS total_customers,
ROUND((SUM(TARGET) / COUNT(*)) * 100, 2) AS default_rate_percent
FROM `intense-pier-497108-v9.home_credit.application_train_cleaned`
GROUP BY income_type
-- Chỉ xét các nhóm có số lượng khách hàng đủ lớn để đảm bảo tính thống kê

HAVING total_customers > 100
ORDER BY default_rate_percent DESC;
https://drive.google.com/file/d/1zxCOibdzbtFluJh6z4uCTQSa1eCecYMI/view

Phân tích rủi ro theo Nguồn thu nhập (Income Type)
SQL

SELECT
NAME_INCOME_TYPE AS income_type,
COUNT(*) AS total_customers,
ROUND((SUM(TARGET) / COUNT(*)) * 100, 2) AS default_rate_percent
FROM `intense-pier-497108-v9.home_credit.application_train_cleaned`
GROUP BY income_type
-- Chỉ xét các nhóm có số lượng khách hàng đủ lớn để đảm bảo tính thống kê
HAVING total_customers > 100
ORDER BY default_rate_percent DESC;
https://drive.google.com/file/d/1CQYsRY9pKX7eVoCadfBqrPqiwhfwDpn1/view
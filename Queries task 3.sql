-- =========================================================================
-- ADVANCED QUERIES(Dựa trên Database DBI_GROUP_7)
-- =========================================================================

-- NHÓM 1: TRUY VẤN SO SÁNH VÀ TỔNG HỢP (8 yêu cầu)
-- -------------------------------------------------------------------------

-- 1. Output: order_id, business_id, và tổng giá trị đơn hàng (subtotal + shipping_fee - discount)
--    Requirement: có tổng giá trị cao nhất trong từng doanh nghiệp (business_id).
SELECT O.order_id, O.business_id, (O.subtotal + O.shipping_fee - O.discount) 'total_price'
FROM Orders O,
		(SELECT O.business_id, MAX(O.subtotal + O.shipping_fee - O.discount) 'max_price'
		FROM Orders O
		GROUP BY O.business_id) M
WHERE O.business_id = M.business_id
AND (O.subtotal + O.shipping_fee - O.discount) = M.max_price

-- 2. Output: product_id, name, unit_price
--    Requirement: giá bán cao hơn mức giá trung bình của chính danh mục (category) 
--	  mà sản phẩm đó thuộc về.
SELECT P.product_id, P.name, P.unit_price
FROM Product P, 
	(SELECT P.category, AVG(P.unit_price) AS 'avg_price'
	FROM Product P
	GROUP BY P.category) Avgprice
WHERE Avgprice.category = P.category
AND P.unit_price > Avgprice.avg_price

-- 3. Output: customer_id, name
--    Requirement: có tổng số lượng đơn hàng đã đặt lớn hơn 
--	  số lượng đơn hàng trung bình mà một khách hàng đặt.
SELECT C.customer_id, c.name
FROM Orders O, Customer C
WHERE O.customer_id = C.customer_id
GROUP BY C.customer_id, C.name
HAVING COUNT(O.order_id) >
			(SELECT AVG(A.num_of_orders)
			FROM
				(SELECT customer_id, COUNT(order_id) 'num_of_orders'
				FROM Orders
				GROUP BY customer_id) A)

-- 4. Output: staff_id, full_name
--    Requirement: đang được phân công xử lý nhiều FulfillmentTask nhất trong toàn bộ hệ thống.
SELECT WS.staff_id, WS.full_name
FROM WarehouseStaff WS, FulfillmentTask FT		
WHERE WS.staff_id = FT.assigned_staff_id
GROUP BY WS.staff_id, WS.full_name
HAVING COUNT(FT.task_id) >= ALL
			(SELECT COUNT(FT.task_id) 'num_of_ft'
			FROM FulfillmentTask FT
			GROUP BY FT.assigned_staff_id) 

-- 5. Output: warehouse_id, name, capacity
--    Requirement: có sức chứa lớn hơn sức chứa trung bình của tất cả các kho.
SELECT W.warehouse_id, W.name, W.capacity
FROM Warehouse W
WHERE W.capacity > (SELECT AVG(W.capacity)
					FROM Warehouse W)

-- 6. Output: business_id, name
--    Requirement: có tổng doanh thu (tổng subtotal của tất cả các đơn hàng) cao nhất hệ thống.
SELECT B.business_id, B.name, SUM(O.subtotal) 'sum_of_subtotal'
FROM Business B, Orders O
WHERE B.business_id = O.business_id
GROUP BY B.business_id, B.name
HAVING SUM(O.subtotal) >= ALL (SELECT SUM(O.subtotal) 'sum_of_subtotal'
								FROM Business B, Orders O
								WHERE B.business_id = O.business_id
								GROUP BY B.business_id, B.name)

-- 7. Output: package_id, fulfillment_id, estimated_cost
--    Requirement: có chi phí ước tính cao nhất trong từng Fulfillment (fulfillment_id).
SELECT PK.package_id, PK.fulfillment_id, PK.estimated_cost
FROM Package PK,
		(SELECT fulfillment_id, MAX(PK.estimated_cost) 'max_cost'
		FROM Package PK
		GROUP BY PK.fulfillment_id) MC
WHERE PK.fulfillment_id = MC.fulfillment_id
AND PK.estimated_cost = MC.max_cost
ORDER BY PK.package_id, PK.fulfillment_id

-- 8. Output: staff_id, full_name
--    Requirement: có tổng số lượng FulfillmentTask đã hoàn thành (status = 'completed') 
--    lớn hơn số lượng task hoàn thành trung bình của tất cả nhân viên.
SELECT WS.staff_id, WS.full_name, COUNT(FT.task_id) 'num_of_complete_ft'
FROM WarehouseStaff WS, FulfillmentTask FT
WHERE WS.staff_id = FT.assigned_staff_id
AND FT.status = 'completed'
GROUP BY WS.staff_id, WS.full_name
HAVING COUNT(FT.task_id) >  (SELECT AVG(num_of_ft)
							FROM (SELECT COUNT(FT.task_id) 'num_of_ft'
									FROM FulfillmentTask FT
									WHERE FT.status = 'completed'
									GROUP BY FT.assigned_staff_id) A)

-- NHÓM 2: TRUY VẤN ĐIỀU KIỆN VÀ KIỂM TRA SỰ TỒN TẠI (8 yêu cầu)
-- -------------------------------------------------------------------------

-- 9. Output: warehouse_id, name
--    Requirement: hiện đang có ít nhất một sản phẩm đang tồn kho 
--	  (quantity_on_hand > 0 trong bảng Inventory).
SELECT DISTINCT W.warehouse_id, W.name
FROM Warehouse W
WHERE EXISTS(
	SELECT 1
	FROM  Inventory I
	WHERE I.warehouse_id = W.warehouse_id
	AND I.quantity_on_hand > 0)

-- 10. Output: order_id, order_date
--     Requirement: đã được tạo Fulfillment nhưng chưa có bất kỳ Package nào được đóng gói.
SELECT O.order_id, O.order_date
FROM Orders O
JOIN Fulfillment F ON O.order_id = F.order_id
WHERE NOT EXISTS (SELECT 1
				FROM Package P
				WHERE P.fulfillment_id = F.fulfillment_id
)

-- 11. Output: staff_id, full_name
--     Requirement: chưa từng phê duyệt (approved_by) bất kỳ AIRecommendation nào.
SELECT WS.staff_id, WS.full_name
FROM WarehouseStaff WS
WHERE  NOT EXISTS(SELECT DISTINCT AIR.approved_by
				FROM AIRecommendation AIR
				WHERE AIR.approved_by = WS.staff_id)
-- 12. Output: product_id, name
--     Requirement: chưa từng xuất hiện trong bất kỳ đơn hàng nào (OrderItem).
SELECT P.product_id, P.name
FROM Product P
WHERE NOT EXISTS(SELECT 1
				FROM OrderItem OI
				WHERE OI.product_id = P.product_id)
-- 13. Output: customer_id, name
--     Requirement: đã từng mua ít nhất một sản phẩm có category là 'Thời trang nam'.
SELECT C.customer_id, C.name
FROM Customer C
WHERE EXISTS(SELECT 1
			FROM Orders O
			JOIN OrderItem OI ON O.order_id = OI.order_id
			JOIN Product P ON OI.product_id = P.product_id
			WHERE O.customer_id = C.customer_id 
			AND P.category = N'Thời trang nam'
)

-- 14. Output: warehouse_id, name
--     Requirement: có sức chứa (capacity) lớn hơn sức chứa của tất cả các kho thuộc business_id = 'BUS003'.
SELECT W.warehouse_id, W.name
FROM Warehouse W
WHERE W.capacity > ALL (SELECT W.capacity
						FROM Warehouse W
						WHERE W.business_id = 'BUS003')

-- 15. Output: fulfillment_id
--     Requirement: có mức độ ưu tiên (priority) cao hơn mức ưu tiên 
--	   của bất kỳ fulfillment nào được xử lý bởi nhân viên có staff_id = 'STF011'.
--	   priority càng nhỏ, mức độ ưu tiên càng cao 
SELECT F.fulfillment_id
FROM Fulfillment F
WHERE F.priority < ANY(SELECT F.priority
						FROM Fulfillment F
						WHERE F.assigned_staff_id = 'STF011')

-- 16. Output: order_id
--     Requirement: có tổng số lượng OrderItem lớn hơn 1, 
--	   nhưng tổng mức discount trên bảng Orders lại đúng bằng 0.
SELECT O.order_id
FROM Orders O
WHERE O.discount = 0
AND EXISTS (SELECT 1 
			FROM OrderItem OI
			WHERE OI.order_id = O.order_id
			HAVING COUNT(OI.order_item_id) > 1)

-- NHÓM 3: TRUY VẤN KẾT HỢP VÀ SO SÁNH TẬP HỢP (8 yêu cầu)
-- -------------------------------------------------------------------------

-- 17. Output: Họ tên, Email, Số điện thoại, Loại_người_dùng ('Customer' hoặc 'Staff')
--     Requirement: Tạo một danh sách liên lạc duy nhất lấy từ Khách hàng (Customer) 
--	   và Nhân viên kho (WarehouseStaff).
SELECT C.name, C.email, C.phone_number, 'Customer' AS 'user_type'
FROM Customer C
UNION
SELECT WS.full_name, WS.email, WS.phone, 'Staff' AS 'user_type'
FROM WarehouseStaff WS
-- 18. Output: Mã ID, Loại sự kiện, Thông điệp lỗi
--     Requirement: Lấy từ bảng SyncLog (nơi status = 'failed') 
--	   và các đơn hàng có sync_status = 'failed' 
--     từ bảng Orders (Mã ID là order_id, Loại sự kiện là 'order_sync', Thông điệp lỗi là sync_status).
SELECT SL.sync_id AS N'Mã ID', SL.sync_type AS N'Loại sự kiện', SL.error_message AS N'Thông điệp lỗi' 
FROM SyncLog SL
WHERE SL.status = 'failed'
UNION
SELECT O.order_id, 'order_sync', O.sync_status
FROM Orders O
WHERE O.sync_status = 'failed'

-- 19. Output: province_city
--     Requirement: nằm trong bảng Location mà đồng thời 
--     có khách hàng đăng ký địa chỉ giao hàng trong bảng CustomerAddress.
SELECT province_city FROM Location 

INTERSECT

SELECT L.province_city
FROM CustomerAddress CA JOIN Location L
ON CA.postal_code = L.postal_code
WHERE CA.address_type = 'shipping'

-- 20. Output: product_id
--     Requirement: có trong hệ thống Product nhưng 
--     không xuất hiện trong bảng Inventory (chưa từng được nhập kho).
SELECT P.product_id FROM Product P

EXCEPT

SELECT I.product_id
FROM Inventory I
-- 21. Output: customer_id
--     Requirement: có ít nhất một địa chỉ address_type = 'shipping' 
--     và đồng thời có ít nhất một địa chỉ address_type = 'billing'.
SELECT	CA.customer_id 
FROM CustomerAddress CA 
WHERE CA.address_type = 'shipping'

INTERSECT

SELECT	CA.customer_id 
FROM CustomerAddress CA 
WHERE CA.address_type = 'billing'

-- 22. Output: order_id
--     Requirement: đã có status = 'completed' nhưng chưa được giao thành công 
--     (không có Shipment nào có shipping_status = 'delivered' hoặc không tồn tại shipment_id).
SELECT order_id FROM Orders WHERE status = 'completed'

EXCEPT

SELECT F.order_id 
FROM Fulfillment F
JOIN Package P ON F.fulfillment_id = P.fulfillment_id
JOIN Shipment S ON P.package_id = S.package_id
WHERE S.shipping_status = 'delivered';

-- 23. Output: business_id, name
--     Requirement: có bán Product nhưng chưa từng có bất kỳ bản ghi SyncLog nào với sync_type = 'product'.
SELECT business_id FROM Product
EXCEPT
SELECT business_id FROM SyncLog WHERE sync_type = 'product';

-- 24. Output: staff_id, full_name
--     Requirement: đã từng cập nhật FulfillmentProgress (updated_by) 
--     nhưng chưa từng quản lý Shipment (managed_by).
SELECT updated_by AS staff_id FROM FulfillmentProgress WHERE updated_by IS NOT NULL
EXCEPT
SELECT managed_by AS staff_id FROM Shipment WHERE managed_by IS NOT NULL;
-- =========================================================================
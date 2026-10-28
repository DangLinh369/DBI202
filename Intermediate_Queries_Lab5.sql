-- =========================================================================
-- LAB 5 - INTERMEDIATE QUERIES (Database: DBI_GROUP_7)
-- Người phụ trách: Đặng Thị Mỹ Linh
-- Gồm 36 truy vấn:
--   Nhóm 1: INNER JOIN / LEFT JOIN                 (12 truy vấn: Q1  - Q12)
--   Nhóm 2: GROUP BY + HAVING                      (12 truy vấn: Q13 - Q24)
--   Nhóm 3: Subquery trong WHERE / FROM            (12 truy vấn: Q25 - Q36)
-- =========================================================================
USE DBI_GROUP_7;
GO

-- =========================================================================
-- NHÓM 1: INNER JOIN / LEFT JOIN
-- =========================================================================

-- Q1. Output: order_id, order_date, tên khách hàng, status, tổng giá trị đơn
--     Requirement: liệt kê đơn hàng kèm thông tin khách hàng (Orders + Customer).
SELECT O.order_id, O.order_date, C.name AS customer_name, O.status,
       (O.subtotal + O.shipping_fee - O.discount) AS total_price
FROM Orders O
INNER JOIN Customer C ON O.customer_id = C.customer_id
ORDER BY O.order_date;

-- Q2. Output: order_id, tên khách hàng, tên doanh nghiệp, payment_method, payment_status
--     Requirement: đơn hàng kèm khách hàng và doanh nghiệp bán (Orders + Customer + Business).
SELECT O.order_id, C.name AS customer_name, B.name AS business_name,
       O.payment_method, O.payment_status
FROM Orders O
INNER JOIN Customer C ON O.customer_id = C.customer_id
INNER JOIN Business B ON O.business_id = B.business_id
ORDER BY O.order_id;

-- Q3. Output: fulfillment_id, order_id, tên kho, tên nhân viên phụ trách, priority, status
--     Requirement: thông tin xử lý đơn (Fulfillment + Warehouse + WarehouseStaff).
SELECT F.fulfillment_id, F.order_id, W.name AS warehouse_name,
       WS.full_name AS staff_name, F.priority, F.status
FROM Fulfillment F
INNER JOIN Warehouse W ON F.warehouse_id = W.warehouse_id
INNER JOIN WarehouseStaff WS ON F.assigned_staff_id = WS.staff_id
ORDER BY F.priority, F.fulfillment_id;

-- Q4. Output: product_id, tên sản phẩm, tên kho, quantity_on_hand, quantity_reserved, số lượng khả dụng
--     Requirement: tồn kho của từng sản phẩm tại từng kho (Product + Inventory + Warehouse).
SELECT P.product_id, P.name AS product_name, W.name AS warehouse_name,
       I.quantity_on_hand, I.quantity_reserved,
       (I.quantity_on_hand - I.quantity_reserved) AS available_qty
FROM Product P
INNER JOIN Inventory I ON P.product_id = I.product_id
INNER JOIN Warehouse W ON I.warehouse_id = W.warehouse_id
ORDER BY P.product_id;

-- Q5. Output: product_id, name, category, quantity_on_hand (0 nếu chưa có trong kho)
--     Requirement: TẤT CẢ sản phẩm kể cả sản phẩm chưa có bản ghi tồn kho (LEFT JOIN Product + Inventory).
SELECT P.product_id, P.name, P.category,
       COALESCE(I.quantity_on_hand, 0) AS quantity_on_hand
FROM Product P
LEFT JOIN Inventory I ON P.product_id = I.product_id
ORDER BY P.product_id;

-- Q6. Output: customer_id, name, email
--     Requirement: khách hàng chưa có đơn nào ở trạng thái 'pending'
--                  (LEFT JOIN Customer + Orders, điều kiện lọc đặt trong ON, kết quả lọc IS NULL).
SELECT C.customer_id, C.name, C.email
FROM Customer C
LEFT JOIN Orders O ON C.customer_id = O.customer_id AND O.status = 'pending'
WHERE O.order_id IS NULL;

-- Q7. Output: order_id, tên khách hàng, tên sản phẩm, quantity, unit_price, thành tiền dòng hàng
--     Requirement: chi tiết từng dòng hàng của đơn (OrderItem + Orders + Customer + Product).
SELECT O.order_id, C.name AS customer_name, P.name AS product_name,
       OI.quantity, OI.unit_price,
       (OI.quantity * OI.unit_price - OI.discount) AS line_total
FROM OrderItem OI
INNER JOIN Orders O ON OI.order_id = O.order_id
INNER JOIN Customer C ON O.customer_id = C.customer_id
INNER JOIN Product P ON OI.product_id = P.product_id
ORDER BY O.order_id, OI.order_item_id;

-- Q8. Output: package_id, fulfillment_id, package_type, estimated_cost, tracking_number, shipping_status
--     Requirement: TẤT CẢ kiện hàng kèm thông tin vận chuyển, kể cả kiện chưa có Shipment
--                  (Package LEFT JOIN Shipment).
SELECT PK.package_id, PK.fulfillment_id, PK.package_type, PK.estimated_cost,
       S.tracking_number, COALESCE(S.shipping_status, 'not_shipped') AS shipping_status
FROM Package PK
LEFT JOIN Shipment S ON PK.package_id = S.package_id
ORDER BY PK.package_id;

-- Q9. Output: fulfillment_id, task_type, sequence, status của task, tên nhân viên thực hiện
--     Requirement: danh sách công việc trong từng Fulfillment (Fulfillment + FulfillmentTask + WarehouseStaff).
SELECT F.fulfillment_id, FT.task_type, FT.sequence, FT.status AS task_status,
       WS.full_name AS staff_name
FROM Fulfillment F
INNER JOIN FulfillmentTask FT ON F.fulfillment_id = FT.fulfillment_id
INNER JOIN WarehouseStaff WS ON FT.assigned_staff_id = WS.staff_id
ORDER BY F.fulfillment_id, FT.sequence;

-- Q10. Output: recommendation_id, fulfillment_id, tên hộp gợi ý, tên vật liệu chèn, tên người duyệt
--      Requirement: gợi ý đóng gói của AI (AIRecommendation join PackagingMaterial 2 lần + WarehouseStaff).
SELECT AIR.recommendation_id, AIR.fulfillment_id,
       BOX.name AS box_name, FILLER.name AS filler_name,
       WS.full_name AS approved_by_name
FROM AIRecommendation AIR
INNER JOIN PackagingMaterial BOX ON AIR.recommended_box_id = BOX.material_id
INNER JOIN PackagingMaterial FILLER ON AIR.recommended_filler_id = FILLER.material_id
INNER JOIN WarehouseStaff WS ON AIR.approved_by = WS.staff_id
ORDER BY AIR.recommendation_id;

-- Q11. Output: order_id, tên người nhận, đường, quận/huyện, tỉnh/thành phố
--      Requirement: địa chỉ giao hàng của đơn (Orders + CustomerAddress + Location).
SELECT O.order_id, CA.recipient_name, CA.street, CA.district, L.province_city
FROM Orders O
INNER JOIN CustomerAddress CA ON O.shipping_address_id = CA.address_id
INNER JOIN Location L ON CA.postal_code = L.postal_code
ORDER BY O.order_id;

-- Q12. Output: warehouse_id, tên kho, staff_id, full_name, staff_role
--      Requirement: TẤT CẢ kho kèm nhân viên của kho, kể cả kho chưa có nhân viên
--                   (Warehouse LEFT JOIN WarehouseStaff).
SELECT W.warehouse_id, W.name AS warehouse_name, WS.staff_id, WS.full_name, WS.staff_role
FROM Warehouse W
LEFT JOIN WarehouseStaff WS ON W.warehouse_id = WS.warehouse_id
ORDER BY W.warehouse_id, WS.staff_id;

-- =========================================================================
-- NHÓM 2: GROUP BY + HAVING
-- =========================================================================

-- Q13. Output: business_id, tên doanh nghiệp, số đơn, tổng doanh thu (subtotal)
--      Requirement: doanh thu theo Business, chỉ giữ doanh nghiệp có tổng doanh thu >= 2.000.000.
SELECT B.business_id, B.name, COUNT(O.order_id) AS num_orders, SUM(O.subtotal) AS revenue
FROM Business B
INNER JOIN Orders O ON B.business_id = O.business_id
GROUP BY B.business_id, B.name
HAVING SUM(O.subtotal) >= 2000000
ORDER BY revenue DESC;

-- Q14. Output: warehouse_id, tên kho, tổng tồn kho, tổng đang giữ chỗ
--      Requirement: tồn kho theo Warehouse, chỉ giữ kho có tổng tồn > 100.
SELECT W.warehouse_id, W.name, SUM(I.quantity_on_hand) AS total_on_hand,
       SUM(I.quantity_reserved) AS total_reserved
FROM Warehouse W
INNER JOIN Inventory I ON W.warehouse_id = I.warehouse_id
GROUP BY W.warehouse_id, W.name
HAVING SUM(I.quantity_on_hand) > 100
ORDER BY total_on_hand DESC;

-- Q15. Output: staff_id, full_name, số task được giao
--      Requirement: số FulfillmentTask theo từng Staff, chỉ giữ nhân viên có từ 3 task trở lên.
SELECT WS.staff_id, WS.full_name, COUNT(FT.task_id) AS num_tasks
FROM WarehouseStaff WS
INNER JOIN FulfillmentTask FT ON WS.staff_id = FT.assigned_staff_id
GROUP BY WS.staff_id, WS.full_name
HAVING COUNT(FT.task_id) >= 3
ORDER BY num_tasks DESC;

-- Q16. Output: status, số đơn hàng, tổng giá trị
--      Requirement: thống kê đơn theo trạng thái, chỉ giữ trạng thái có ít nhất 2 đơn.
SELECT O.status, COUNT(*) AS num_orders,
       SUM(O.subtotal + O.shipping_fee - O.discount) AS total_value
FROM Orders O
GROUP BY O.status
HAVING COUNT(*) >= 2;

-- Q17. Output: payment_method, payment_status, số đơn, giá trị trung bình
--      Requirement: thống kê theo phương thức + trạng thái thanh toán, chỉ giữ nhóm có >= 2 đơn.
SELECT O.payment_method, O.payment_status, COUNT(*) AS num_orders,
       AVG(O.subtotal + O.shipping_fee - O.discount) AS avg_value
FROM Orders O
GROUP BY O.payment_method, O.payment_status
HAVING COUNT(*) >= 2;

-- Q18. Output: category, số sản phẩm, giá trung bình, giá cao nhất
--      Requirement: thống kê sản phẩm theo danh mục, chỉ giữ danh mục có từ 2 sản phẩm.
SELECT P.category, COUNT(*) AS num_products, AVG(P.unit_price) AS avg_price,
       MAX(P.unit_price) AS max_price
FROM Product P
GROUP BY P.category
HAVING COUNT(*) >= 2
ORDER BY num_products DESC;

-- Q19. Output: customer_id, name, số đơn, tổng chi tiêu
--      Requirement: khách hàng đã đặt từ 2 đơn trở lên.
SELECT C.customer_id, C.name, COUNT(O.order_id) AS num_orders,
       SUM(O.subtotal + O.shipping_fee - O.discount) AS total_spent
FROM Customer C
INNER JOIN Orders O ON C.customer_id = O.customer_id
GROUP BY C.customer_id, C.name
HAVING COUNT(O.order_id) >= 2
ORDER BY total_spent DESC;

-- Q20. Output: warehouse_id, tên kho, số Fulfillment, priority trung bình
--      Requirement: số lượt xử lý đơn theo kho, chỉ giữ kho có từ 2 Fulfillment.
SELECT W.warehouse_id, W.name, COUNT(F.fulfillment_id) AS num_fulfillments,
       AVG(CAST(F.priority AS DECIMAL(10,2))) AS avg_priority
FROM Warehouse W
INNER JOIN Fulfillment F ON W.warehouse_id = F.warehouse_id
GROUP BY W.warehouse_id, W.name
HAVING COUNT(F.fulfillment_id) >= 2;

-- Q21. Output: carrier_name, số Shipment, tổng phí thực tế, tổng phí ước tính
--      Requirement: thống kê theo hãng vận chuyển, chỉ giữ hãng có phí thực tế tổng > 0.
SELECT S.carrier_name, COUNT(*) AS num_shipments,
       SUM(S.actual_shipping_fee) AS total_actual_fee,
       SUM(S.estimated_shipping_fee) AS total_estimated_fee
FROM Shipment S
GROUP BY S.carrier_name
HAVING SUM(S.actual_shipping_fee) > 0
ORDER BY total_actual_fee DESC;

-- Q22. Output: material_type, số loại vật liệu, tổng tồn kho vật liệu, chi phí trung bình/đơn vị
--      Requirement: thống kê vật liệu đóng gói theo loại, chỉ giữ loại có tổng tồn > 500.
SELECT PM.material_type, COUNT(*) AS num_materials,
       SUM(PM.stock_quantity) AS total_stock, AVG(PM.cost_per_unit) AS avg_cost
FROM PackagingMaterial PM
GROUP BY PM.material_type
HAVING SUM(PM.stock_quantity) > 500
ORDER BY total_stock DESC;

-- Q23. Output: warehouse_id, staff_role, số nhân viên
--      Requirement: số nhân viên theo vai trò trong từng kho, chỉ giữ nhóm có từ 2 người.
SELECT WS.warehouse_id, WS.staff_role, COUNT(*) AS num_staff
FROM WarehouseStaff WS
GROUP BY WS.warehouse_id, WS.staff_role
HAVING COUNT(*) >= 2
ORDER BY WS.warehouse_id;

-- Q24. Output: package_type, số package, tổng chi phí ước tính, cân nặng trung bình
--      Requirement: thống kê kiện hàng theo loại bao bì, chỉ giữ loại có từ 2 package trở lên.
SELECT PK.package_type, COUNT(PK.package_id) AS num_packages,
       SUM(PK.estimated_cost) AS total_cost, AVG(PK.weight) AS avg_weight
FROM Package PK
GROUP BY PK.package_type
HAVING COUNT(PK.package_id) >= 2
ORDER BY num_packages DESC;

-- =========================================================================
-- NHÓM 3: SUBQUERY TRONG WHERE / FROM
-- =========================================================================

-- Q25. Output: order_id, order_date, status
--      Requirement: đơn hàng chưa có Fulfillment (NOT IN subquery trong WHERE).
SELECT O.order_id, O.order_date, O.status
FROM Orders O
WHERE O.order_id NOT IN (SELECT F.order_id FROM Fulfillment F);

-- Q26. Output: product_id, name
--      Requirement: sản phẩm hết hàng - có bản ghi tồn kho nhưng tổng quantity_on_hand = 0
--                   (subquery trong WHERE).
SELECT P.product_id, P.name
FROM Product P
WHERE P.product_id IN (SELECT I.product_id
                       FROM Inventory I
                       GROUP BY I.product_id
                       HAVING SUM(I.quantity_on_hand) = 0);

-- Q27. Output: staff_id, full_name, staff_role
--      Requirement: nhân viên chưa được giao FulfillmentTask nào (NOT IN subquery trong WHERE).
SELECT WS.staff_id, WS.full_name, WS.staff_role
FROM WarehouseStaff WS
WHERE WS.staff_id NOT IN (SELECT FT.assigned_staff_id FROM FulfillmentTask FT);

-- Q28. Output: product_id, name, unit_price
--      Requirement: sản phẩm có giá cao hơn giá trung bình của tất cả sản phẩm (subquery vô hướng).
SELECT P.product_id, P.name, P.unit_price
FROM Product P
WHERE P.unit_price > (SELECT AVG(unit_price) FROM Product)
ORDER BY P.unit_price DESC;

-- Q29. Output: order_id, subtotal
--      Requirement: đơn hàng có subtotal cao hơn subtotal trung bình của toàn hệ thống.
SELECT O.order_id, O.subtotal
FROM Orders O
WHERE O.subtotal > (SELECT AVG(subtotal) FROM Orders)
ORDER BY O.subtotal DESC;

-- Q30. Output: customer_id, name, tổng chi tiêu
--      Requirement: khách hàng có tổng chi tiêu cao hơn mức chi tiêu trung bình của một khách
--                   (subquery trong FROM - bảng dẫn xuất).
SELECT C.customer_id, C.name, T.total_spent
FROM Customer C
INNER JOIN (SELECT customer_id, SUM(subtotal + shipping_fee - discount) AS total_spent
            FROM Orders
            GROUP BY customer_id) T ON C.customer_id = T.customer_id
WHERE T.total_spent > (SELECT AVG(X.total_spent)
                       FROM (SELECT SUM(subtotal + shipping_fee - discount) AS total_spent
                             FROM Orders
                             GROUP BY customer_id) X)
ORDER BY T.total_spent DESC;

-- Q31. Output: warehouse_id, tên kho, capacity, tổng tồn kho, tỉ lệ sử dụng (%)
--      Requirement: so sánh tổng tồn kho với sức chứa của từng kho (subquery trong FROM).
SELECT W.warehouse_id, W.name, W.capacity, S.total_on_hand,
       CAST(S.total_on_hand * 100.0 / W.capacity AS DECIMAL(10,2)) AS usage_percent
FROM Warehouse W
INNER JOIN (SELECT warehouse_id, SUM(quantity_on_hand) AS total_on_hand
            FROM Inventory
            GROUP BY warehouse_id) S ON W.warehouse_id = S.warehouse_id
ORDER BY usage_percent DESC;

-- Q32. Output: product_id, name
--      Requirement: sản phẩm có ít nhất một kho đang tồn kho thấp hơn hoặc bằng mức đặt hàng lại
--                   (reorder_level) - cần nhập thêm (IN subquery).
SELECT P.product_id, P.name
FROM Product P
WHERE P.product_id IN (SELECT I.product_id
                       FROM Inventory I
                       WHERE I.quantity_on_hand <= I.reorder_level);

-- Q33. Output: customer_id, name
--      Requirement: khách hàng đã từng đặt đơn thanh toán bằng 'Banking' (IN subquery).
SELECT C.customer_id, C.name
FROM Customer C
WHERE C.customer_id IN (SELECT O.customer_id FROM Orders O WHERE O.payment_method = 'Banking');

-- Q34. Output: warehouse_id, name, capacity
--      Requirement: kho có sức chứa lớn nhất hệ thống (subquery = MAX).
SELECT W.warehouse_id, W.name, W.capacity
FROM Warehouse W
WHERE W.capacity = (SELECT MAX(capacity) FROM Warehouse);

-- Q35. Output: order_id, số dòng hàng, tổng số lượng
--      Requirement: đơn hàng có nhiều hơn 1 dòng hàng (subquery trong FROM).
SELECT O.order_id, D.num_items, D.total_qty
FROM Orders O
INNER JOIN (SELECT order_id, COUNT(*) AS num_items, SUM(quantity) AS total_qty
            FROM OrderItem
            GROUP BY order_id) D ON O.order_id = D.order_id
WHERE D.num_items > 1;

-- Q36. Output: order_id, order_date, status
--      Requirement: đơn hàng đã có Fulfillment nhưng chưa có Package nào được đóng gói
--                   (subquery lồng nhau trong WHERE).
SELECT O.order_id, O.order_date, O.status
FROM Orders O
WHERE O.order_id IN (SELECT F.order_id FROM Fulfillment F)
  AND O.order_id NOT IN (SELECT F.order_id
                         FROM Fulfillment F
                         WHERE F.fulfillment_id IN (SELECT PK.fulfillment_id FROM Package PK));

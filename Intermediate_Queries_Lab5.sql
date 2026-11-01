-- INTERMEDIATE QUERIES - DBI_GROUP_7
-- Người thực hiện: Đặng Thị Mỹ Linh
-- Gồm 30 câu: INNER JOIN / LEFT JOIN (Q1 - Q10), GROUP BY + HAVING (Q11 - Q20), Subquery (Q21 - Q30)

USE DBI_GROUP_7;
GO

-- ------------------------------------------------------------
-- PHẦN 1: INNER JOIN / LEFT JOIN
-- ------------------------------------------------------------

-- 1. Output: order_id, order_date, tên khách hàng, tên doanh nghiệp bán, status, tổng tiền đơn
--    Requirement: liệt kê tất cả đơn hàng kèm khách đặt và doanh nghiệp bán.
SELECT O.order_id, O.order_date, C.name AS customer_name, B.name AS business_name, O.status,
       O.subtotal + O.shipping_fee + O.tax - O.discount AS total_price
FROM Orders O
INNER JOIN Customer C ON O.customer_id = C.customer_id
INNER JOIN Business B ON O.business_id = B.business_id
ORDER BY O.order_date;

-- 2. Output: order_id, tên sản phẩm, quantity, unit_price, thành tiền
--    Requirement: chi tiết từng dòng sản phẩm trong các đơn hàng
--    (thành tiền = quantity * unit_price - discount của dòng đó).
SELECT O.order_id, P.name AS product_name, OI.quantity, OI.unit_price,
       OI.quantity * OI.unit_price - OI.discount AS line_total
FROM OrderItem OI
INNER JOIN Orders O ON OI.order_id = O.order_id
INNER JOIN Product P ON OI.product_id = P.product_id
ORDER BY O.order_id;

-- 3. Output: order_id, recipient_name, district, province_city
--    Requirement: các đơn hàng có địa chỉ giao hàng nằm ngoài TP. Hồ Chí Minh.
SELECT O.order_id, CA.recipient_name, CA.district, L.province_city
FROM Orders O
INNER JOIN CustomerAddress CA ON O.shipping_address_id = CA.address_id
INNER JOIN Location L ON CA.postal_code = L.postal_code
WHERE L.province_city <> N'TP. Hồ Chí Minh';

-- 4. Output: fulfillment_id, order_id, tên kho, tên nhân viên phụ trách, priority, status
--    Requirement: các Fulfillment chưa hoàn thành (status khác 'completed').
SELECT F.fulfillment_id, F.order_id, W.name AS warehouse_name, WS.full_name AS staff_name,
       F.priority, F.status
FROM Fulfillment F
INNER JOIN Warehouse W ON F.warehouse_id = W.warehouse_id
INNER JOIN WarehouseStaff WS ON F.assigned_staff_id = WS.staff_id
WHERE F.status <> 'completed'
ORDER BY F.priority, F.fulfillment_id;

-- 5. Output: product_id, tên sản phẩm, tên kho, quantity_on_hand, quantity_reserved, reorder_level
--    Requirement: các sản phẩm tại kho có số lượng khả dụng (on_hand - reserved)
--    nhỏ hơn hoặc bằng mức đặt hàng lại (reorder_level).
SELECT P.product_id, P.name AS product_name, W.name AS warehouse_name,
       I.quantity_on_hand, I.quantity_reserved, I.reorder_level
FROM Inventory I
INNER JOIN Product P ON I.product_id = P.product_id
INNER JOIN Warehouse W ON I.warehouse_id = W.warehouse_id
WHERE I.quantity_on_hand - I.quantity_reserved <= I.reorder_level;

-- 6. Output: product_id, name, category, unit_price
--    Requirement: các sản phẩm chưa từng được đặt trong bất kỳ đơn hàng nào (LEFT JOIN OrderItem).
SELECT P.product_id, P.name, P.category, P.unit_price
FROM Product P
LEFT JOIN OrderItem OI ON P.product_id = OI.product_id
WHERE OI.order_item_id IS NULL;

-- 7. Output: package_id, package_type, estimated_cost, carrier_name, tracking_number
--    Requirement: tất cả các Package, kể cả package chưa có vận đơn (Shipment).
SELECT PK.package_id, PK.package_type, PK.estimated_cost,
       COALESCE(S.carrier_name, N'Chưa có vận đơn') AS carrier_name,
       S.tracking_number
FROM Package PK
LEFT JOIN Shipment S ON PK.package_id = S.package_id
ORDER BY PK.package_id;

-- 8. Output: warehouse_id, tên kho, tên doanh nghiệp, capacity
--    Requirement: các kho chưa xử lý (Fulfillment) đơn hàng nào.
SELECT W.warehouse_id, W.name AS warehouse_name, B.name AS business_name, W.capacity
FROM Warehouse W
INNER JOIN Business B ON W.business_id = B.business_id
LEFT JOIN Fulfillment F ON W.warehouse_id = F.warehouse_id
WHERE F.fulfillment_id IS NULL;

-- 9. Output: staff_id, full_name, staff_role, tên kho
--    Requirement: các nhân viên kho chưa được giao FulfillmentTask nào.
SELECT WS.staff_id, WS.full_name, WS.staff_role, W.name AS warehouse_name
FROM WarehouseStaff WS
INNER JOIN Warehouse W ON WS.warehouse_id = W.warehouse_id
LEFT JOIN FulfillmentTask FT ON WS.staff_id = FT.assigned_staff_id
WHERE FT.task_id IS NULL
ORDER BY WS.staff_id;

-- 10. Output: recommendation_id, fulfillment_id, tên hộp gợi ý, tên vật liệu chèn, void_ratio, người duyệt
--     Requirement: các gợi ý đóng gói của AI (bảng PackagingMaterial được join 2 lần: hộp và vật liệu chèn).
SELECT R.recommendation_id, R.fulfillment_id, Box.name AS box_name, Filler.name AS filler_name,
       R.void_ratio, WS.full_name AS approved_by_name
FROM AIRecommendation R
INNER JOIN PackagingMaterial Box ON R.recommended_box_id = Box.material_id
INNER JOIN PackagingMaterial Filler ON R.recommended_filler_id = Filler.material_id
INNER JOIN WarehouseStaff WS ON R.approved_by = WS.staff_id
ORDER BY R.recommendation_id;


-- ------------------------------------------------------------
-- PHẦN 2: GROUP BY + HAVING
-- ------------------------------------------------------------

-- 11. Output: business_id, tên doanh nghiệp, số đơn, doanh thu (tổng subtotal)
--     Requirement: chỉ lấy doanh nghiệp có tổng doanh thu lớn hơn 2.000.000.
SELECT B.business_id, B.name, COUNT(O.order_id) AS num_orders, SUM(O.subtotal) AS revenue
FROM Business B
INNER JOIN Orders O ON B.business_id = O.business_id
GROUP BY B.business_id, B.name
HAVING SUM(O.subtotal) > 2000000;

-- 12. Output: customer_id, tên khách hàng, số đơn đã đặt, tổng tiền đã chi
--     Requirement: chỉ lấy khách hàng đã đặt từ 2 đơn trở lên.
SELECT C.customer_id, C.name, COUNT(O.order_id) AS num_orders,
       SUM(O.subtotal + O.shipping_fee + O.tax - O.discount) AS total_spent
FROM Customer C
INNER JOIN Orders O ON C.customer_id = O.customer_id
GROUP BY C.customer_id, C.name
HAVING COUNT(O.order_id) >= 2;

-- 13. Output: warehouse_id, tên kho, tổng quantity_on_hand, tổng quantity_reserved
--     Requirement: chỉ lấy kho có tổng số lượng tồn từ 180 trở lên.
SELECT W.warehouse_id, W.name, SUM(I.quantity_on_hand) AS total_on_hand,
       SUM(I.quantity_reserved) AS total_reserved
FROM Warehouse W
INNER JOIN Inventory I ON W.warehouse_id = I.warehouse_id
GROUP BY W.warehouse_id, W.name
HAVING SUM(I.quantity_on_hand) >= 180;

-- 14. Output: staff_id, full_name, số FulfillmentTask được giao
--     Requirement: chỉ lấy nhân viên được giao từ 6 task trở lên.
SELECT WS.staff_id, WS.full_name, COUNT(FT.task_id) AS num_tasks
FROM WarehouseStaff WS
INNER JOIN FulfillmentTask FT ON WS.staff_id = FT.assigned_staff_id
GROUP BY WS.staff_id, WS.full_name
HAVING COUNT(FT.task_id) >= 6;

-- 15. Output: status, số đơn hàng, tổng giá trị
--     Requirement: thống kê đơn hàng theo status, chỉ lấy status có ít nhất 2 đơn.
SELECT O.status, COUNT(O.order_id) AS num_orders,
       SUM(O.subtotal + O.shipping_fee + O.tax - O.discount) AS total_value
FROM Orders O
GROUP BY O.status
HAVING COUNT(O.order_id) >= 2;

-- 16. Output: category, số sản phẩm, giá trung bình
--     Requirement: thống kê sản phẩm theo category, chỉ lấy category có từ 2 sản phẩm trở lên
--     và giá trung bình lớn hơn 500.000.
SELECT P.category, COUNT(P.product_id) AS num_products, AVG(P.unit_price) AS avg_price
FROM Product P
GROUP BY P.category
HAVING COUNT(P.product_id) >= 2 AND AVG(P.unit_price) > 500000;

-- 17. Output: carrier_name, số Shipment, tổng phí ước tính, tổng phí thực tế
--     Requirement: thống kê theo hãng vận chuyển, chỉ lấy hãng có từ 2 Shipment trở lên.
SELECT S.carrier_name, COUNT(S.shipment_id) AS num_shipments,
       SUM(S.estimated_shipping_fee) AS total_estimated_fee,
       SUM(S.actual_shipping_fee) AS total_actual_fee
FROM Shipment S
GROUP BY S.carrier_name
HAVING COUNT(S.shipment_id) >= 2;

-- 18. Output: material_type, số loại vật liệu, tổng stock_quantity, cost_per_unit trung bình
--     Requirement: thống kê vật liệu đóng gói theo material_type, chỉ lấy loại có từ 3 vật liệu trở lên.
SELECT PM.material_type, COUNT(PM.material_id) AS num_materials,
       SUM(PM.stock_quantity) AS total_stock, AVG(PM.cost_per_unit) AS avg_cost
FROM PackagingMaterial PM
GROUP BY PM.material_type
HAVING COUNT(PM.material_id) >= 3;

-- 19. Output: warehouse_id, tên kho, số Fulfillment
--     Requirement: chỉ lấy kho đã xử lý từ 3 Fulfillment trở lên.
SELECT W.warehouse_id, W.name, COUNT(F.fulfillment_id) AS num_fulfillments
FROM Warehouse W
INNER JOIN Fulfillment F ON W.warehouse_id = F.warehouse_id
GROUP BY W.warehouse_id, W.name
HAVING COUNT(F.fulfillment_id) >= 3;

-- 20. Output: product_id, tên sản phẩm, tổng số lượng đã bán
--     Requirement: chỉ lấy sản phẩm có tổng số lượng đặt (quantity trong OrderItem) từ 2 trở lên.
SELECT P.product_id, P.name, SUM(OI.quantity) AS total_quantity
FROM Product P
INNER JOIN OrderItem OI ON P.product_id = OI.product_id
GROUP BY P.product_id, P.name
HAVING SUM(OI.quantity) >= 2;


-- ------------------------------------------------------------
-- PHẦN 3: SUBQUERY TRONG WHERE / FROM
-- ------------------------------------------------------------

-- 21. Output: customer_id, name, email
--     Requirement: khách hàng đã từng đặt hàng của doanh nghiệp BUS003.
SELECT C.customer_id, C.name, C.email
FROM Customer C
WHERE C.customer_id IN (SELECT O.customer_id
                        FROM Orders O
                        WHERE O.business_id = 'BUS003');

-- 22. Output: material_id, name, material_type
--     Requirement: vật liệu đóng gói chưa từng được AI gợi ý (cả làm hộp lẫn làm vật liệu chèn).
SELECT PM.material_id, PM.name, PM.material_type
FROM PackagingMaterial PM
WHERE PM.material_id NOT IN (SELECT R.recommended_box_id FROM AIRecommendation R)
  AND PM.material_id NOT IN (SELECT R.recommended_filler_id FROM AIRecommendation R);

-- 23. Output: order_id, order_date, status, tổng tiền đơn
--     Requirement: đơn hàng có tổng tiền lớn hơn tổng tiền trung bình của tất cả đơn hàng.
SELECT O.order_id, O.order_date, O.status,
       O.subtotal + O.shipping_fee + O.tax - O.discount AS total_price
FROM Orders O
WHERE O.subtotal + O.shipping_fee + O.tax - O.discount >
      (SELECT AVG(O2.subtotal + O2.shipping_fee + O2.tax - O2.discount)
       FROM Orders O2);

-- 24. Output: shipment_id, tracking_number, carrier_name, actual_shipping_fee
--     Requirement: Shipment có phí vận chuyển thực tế cao hơn phí thực tế trung bình của tất cả Shipment.
SELECT S.shipment_id, S.tracking_number, S.carrier_name, S.actual_shipping_fee
FROM Shipment S
WHERE S.actual_shipping_fee > (SELECT AVG(S2.actual_shipping_fee)
                               FROM Shipment S2);

-- 25. Output: order_id, order_date, status
--     Requirement: đơn hàng có chứa ít nhất một sản phẩm dễ vỡ (is_fragile = 'True').
SELECT O.order_id, O.order_date, O.status
FROM Orders O
WHERE O.order_id IN (SELECT OI.order_id
                     FROM OrderItem OI
                     INNER JOIN Product P ON OI.product_id = P.product_id
                     WHERE P.is_fragile = 'True');

-- 26. Output: order_id, order_date, status
--     Requirement: đơn hàng đã được gom vào các OrderGroup của kho WH001.
SELECT O.order_id, O.order_date, O.status
FROM Orders O
WHERE O.order_id IN (SELECT OGO.order_id
                     FROM OrderGroupOrder OGO
                     WHERE OGO.group_id IN (SELECT G.group_id
                                            FROM OrderGroup G
                                            WHERE G.warehouse_id = 'WH001'));

-- 27. Output: customer_id, name, tổng tiền đã chi
--     Requirement: khách hàng có tổng tiền đã chi lớn hơn 2.000.000
--     (tính tổng theo khách trong subquery ở mệnh đề FROM).
SELECT C.customer_id, C.name, T.total_spent
FROM Customer C
INNER JOIN (SELECT O.customer_id,
                   SUM(O.subtotal + O.shipping_fee + O.tax - O.discount) AS total_spent
            FROM Orders O
            GROUP BY O.customer_id) T ON C.customer_id = T.customer_id
WHERE T.total_spent > 2000000;

-- 28. Output: staff_id, full_name, số task đang chờ (pending)
--     Requirement: nhân viên còn FulfillmentTask ở trạng thái 'pending'
--     (đếm số task pending theo nhân viên trong subquery ở mệnh đề FROM).
SELECT WS.staff_id, WS.full_name, T.num_pending
FROM WarehouseStaff WS
INNER JOIN (SELECT FT.assigned_staff_id, COUNT(FT.task_id) AS num_pending
            FROM FulfillmentTask FT
            WHERE FT.status = 'pending'
            GROUP BY FT.assigned_staff_id) T ON WS.staff_id = T.assigned_staff_id
ORDER BY T.num_pending DESC;

-- 29. Output: product_id, name, tổng số lượng khả dụng trong toàn hệ thống
--     Requirement: sản phẩm có tổng số lượng khả dụng (on_hand - reserved) ở tất cả các kho nhỏ hơn 50
--     (tính tổng theo sản phẩm trong subquery ở mệnh đề FROM).
SELECT P.product_id, P.name, T.total_available
FROM Product P
INNER JOIN (SELECT I.product_id,
                   SUM(I.quantity_on_hand - I.quantity_reserved) AS total_available
            FROM Inventory I
            GROUP BY I.product_id) T ON P.product_id = T.product_id
WHERE T.total_available < 50;

-- 30. Output: warehouse_id, tên kho, số nhân viên
--     Requirement: kho có số nhân viên lớn hơn số nhân viên trung bình của các kho.
SELECT W.warehouse_id, W.name, T.num_staff
FROM Warehouse W
INNER JOIN (SELECT WS.warehouse_id, COUNT(WS.staff_id) AS num_staff
            FROM WarehouseStaff WS
            GROUP BY WS.warehouse_id) T ON W.warehouse_id = T.warehouse_id
WHERE T.num_staff > (SELECT AVG(CAST(X.num_staff AS DECIMAL(10,2)))
                     FROM (SELECT COUNT(WS2.staff_id) AS num_staff
                           FROM WarehouseStaff WS2
                           GROUP BY WS2.warehouse_id) X);

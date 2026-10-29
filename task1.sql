

USE DBI_GROUP_7
GO

-- ============================================================
-- PHẦN A : SELECT * (10 câu)
-- Mục đích : Xem toàn bộ dữ liệu các bảng chính trong hệ thống
-- ============================================================

-- A01. Xem toàn bộ doanh nghiệp đang vận hành trên hệ thống
SELECT * FROM Business;

-- A02. Xem toàn bộ khách hàng đã đăng ký
SELECT * FROM Customer;

-- A03. Xem toàn bộ kho hàng của các doanh nghiệp
SELECT * FROM Warehouse;

-- A04. Xem toàn bộ sản phẩm có trong hệ thống
SELECT * FROM Product;

-- A05. Xem toàn bộ đơn hàng (từ mọi kênh bán hàng)
SELECT * FROM Orders;

-- A06. Xem toàn bộ tồn kho theo từng sản phẩm - kho
SELECT * FROM Inventory;

-- A07. Xem toàn bộ vật liệu đóng gói hiện có
SELECT * FROM PackagingMaterial;

-- A08. Xem toàn bộ tiến trình hoàn tất đơn hàng (Fulfillment)
SELECT * FROM Fulfillment;

-- A09. Xem toàn bộ gói hàng đã được đóng gói
SELECT * FROM Package;

-- A10. Xem toàn bộ lô hàng vận chuyển và trạng thái giao hàng
SELECT * FROM Shipment;


-- ============================================================
-- PHẦN B : WHERE FILTER (15 câu)
-- Mục đích : Lọc dữ liệu theo nghiệp vụ cụ thể của hệ thống
-- ============================================================

-- B01. Lọc tất cả doanh nghiệp đang hoạt động (status = 'active')
SELECT  business_id,
        name,
        email,
        phone,
        status
FROM    Business
WHERE   status = 'active';

-- B02. Lọc tất cả sản phẩm thuộc danh mục "Thời trang nam"
SELECT  product_id,
        sku,
        name,
        unit_price,
        category,
        status
FROM    Product
WHERE   category = N'Thời trang nam';

-- B03. Lọc các sản phẩm dễ vỡ cần xử lý đặc biệt khi đóng gói
SELECT  product_id,
        sku,
        name,
        is_fragile,
        special_handling,
        category
FROM    Product
WHERE   is_fragile = 'True';

-- B04. Lọc các sản phẩm đang ngừng bán (status <> 'active')
--      Hữu ích để phát hiện SKU lỗi thời còn trong kho
SELECT  product_id,
        sku,
        name,
        status,
        business_id
FROM    Product
WHERE   status not like 'active'
-- B05. Lọc các đơn hàng chưa được thanh toán (payment_status = 'unpaid')
--      Cần ưu tiên theo dõi để tránh xuất kho khi chưa thu tiền
SELECT  *
FROM    Orders
WHERE   payment_status = 'unpaid'

-- B06. Lọc các đơn hàng đang ở trạng thái "pending" (chờ xử lý)
SELECT  *
FROM    Orders
WHERE   status = 'pending'

-- B07. Lọc các đơn hàng có giá trị subtotal trên 1.000.000 VND
--      (đơn hàng giá trị cao cần lưu ý đóng gói kỹ hơn)
SELECT  *
FROM    Orders
WHERE   subtotal > 1000000

-- B08. Lọc các đơn hàng được thanh toán bằng COD (Thu tiền khi giao)
--      Shipper cần lưu ý thu tiền mặt khi giao
SELECT  *
FROM    Orders
WHERE   payment_method = 'COD'

-- B09. Lọc các kho hàng đang hoạt động có sức chứa lớn (capacity >= 3500)
SELECT  *
FROM    Warehouse
WHERE   status = 'active' AND capacity >= 3500

-- B10. Lọc các vật liệu đóng gói thân thiện với môi trường
--      (eco_friendly = 'True') - phù hợp chiến lược Green Logistics
SELECT  material_id,
        name,
        material_type,
        dimensions,
        cost_per_unit,
        eco_friendly,
        recyclable,
        stock_quantity,
        business_id
FROM    PackagingMaterial
WHERE   eco_friendly = 'True';

-- B11. Lọc danh sách nhân viên kho có vai trò lấy hàng (picker) đang hoạt động
SELECT  staff_id,
        full_name,
        email,
        phone,
        staff_role,
        status,
        warehouse_id
FROM    WarehouseStaff
WHERE   staff_role = 'picker' AND status = 'active';

-- B12. Lọc các Fulfillment đã hoàn tất (status = 'completed') kèm thời gian xử lý
SELECT  fulfillment_id,
        order_id,
        warehouse_id,
        assigned_staff_id,
        status,
        start_time,
        completed_time,
        DATEDIFF(MINUTE, start_time, completed_time) AS processing_minutes
FROM    Fulfillment
WHERE   status = 'completed';

-- B13. Lọc các kiện hàng dùng hộp carton (carton_box) có trọng lượng trên 1 kg
SELECT  *
FROM    Package
WHERE   package_type = 'carton_box' AND weight > 1.0;

-- B14. Lọc các lô vận chuyển đang trên đường giao hàng
--      (shipping_status = 'in_transit')
SELECT *
FROM    Shipment
WHERE   shipping_status = 'in_transit'

-- B15. Lọc các bản ghi SyncLog bị lỗi (status = 'failed')
--      Cần điều tra lại để đảm bảo đồng bộ dữ liệu từ các sàn thương mại
SELECT  *
FROM    SyncLog
WHERE   status = 'failed'

-- PHẦN C : ORDER BY (15 câu)

-- C01. Sắp xếp đơn hàng từ mới nhất đến cũ nhất
--      (xem đơn mới nhất được nhận về)
SELECT  order_id,
        external_order_id,
        order_date,
        status,
        payment_method,
        subtotal,
        customer_id,
        business_id
FROM    Orders
ORDER BY order_date DESC

-- C02. Sắp xếp đơn hàng theo giá trị subtotal giảm dần
--      (ưu tiên xử lý đơn có giá trị cao)
SELECT  order_id,
        external_order_id,
        order_date,
        payment_method,
        subtotal,
        shipping_fee,
        discount,
        subtotal + shipping_fee - discount AS total_amount,
        customer_id
FROM    Orders
ORDER BY subtotal DESC;

-- C03. Sắp xếp sản phẩm theo đơn giá từ cao đến thấp
--      (phục vụ báo cáo danh mục sản phẩm)
SELECT  product_id,
        sku,
        name,
        category,
        unit_price,
        currency,
        weight,
        is_fragile,
        business_id
FROM    Product
ORDER BY unit_price DESC;

-- C04. Sắp xếp vật liệu đóng gói theo chi phí một đơn vị tăng dần
--      (lựa chọn vật liệu tiết kiệm nhất)
SELECT  * FROM   PackagingMaterial
ORDER BY cost_per_unit ASC

-- C05. Sắp xếp các kho hàng theo sức chứa (capacity) giảm dần
SELECT  *
FROM    Warehouse
ORDER BY capacity DESC;

-- C06. Sắp xếp nhân viên kho theo vai trò và ngày vào làm (created_at) tăng dần
SELECT  staff_id,
        full_name,
        email,
        phone,
        staff_role,
        warehouse_id,
        created_at,
        status
FROM    WarehouseStaff
ORDER BY staff_role ASC, created_at ASC

-- C07. Sắp xếp FulfillmentProgress theo thời gian sự kiện tăng dần
--      (xem luồng tiến trình từ đầu đến cuối)
SELECT  progress_id,
        fulfillment_id,
        step,
        status,
        event_timestamp,
        note,
        updated_by
FROM    FulfillmentProgress
ORDER BY fulfillment_id ASC, event_timestamp ASC;

-- C08. Sắp xếp gói hàng theo trọng lượng giảm dần
--      (xác định các kiện hàng nặng để ưu tiên xếp xe)
SELECT  package_id,
        package_type,
        length,
        width,
        height,
        weight,
        estimated_cost,
        status,
        fulfillment_id
FROM    Package
ORDER BY weight DESC;

-- C09. Sắp xếp Shipment theo ngày ship thực tế mới nhất
SELECT  shipment_id,
        tracking_number,
        carrier_name,
        shipping_status,
        shipped_at,
        delivered_at,
        estimated_shipping_fee,
        actual_shipping_fee
FROM    Shipment
ORDER BY shipped_at DESC;

-- C10. Sắp xếp AIRecommendation theo tỉ lệ thể tích rỗng (void_ratio) tăng dần
--      (gợi ý đóng gói nào hiệu quả nhất - lãng phí không gian ít nhất)
SELECT  recommendation_id,
        fulfillment_id,
        recommended_box_id,
        box_quantity,
        est_length,
        est_width,
        est_height,
        est_weight,
        void_ratio,
        is_anomaly,
        approval_status
FROM    AIRecommendation
ORDER BY void_ratio ASC;

-- C11. Sắp xếp SyncLog theo thời điểm bắt đầu mới nhất
--      (xem lịch sử đồng bộ gần đây nhất)
SELECT  sync_id,
        business_id,
        sync_type,
        started_at,
        finished_at,
        status,
        success_count,
        error_count
FROM    SyncLog
ORDER BY started_at DESC;

-- C12. Sắp xếp tồn kho theo số lượng tồn thực tế (quantity_on_hand) tăng dần
SELECT  inventory_id,
        product_id,
        warehouse_id,
        shelf_location,
        quantity_on_hand,
        quantity_reserved,
        reorder_level,
        updated_at
FROM    Inventory
ORDER BY quantity_on_hand ASC

-- C13. Sắp xếp các dòng chi tiết đơn hàng (OrderItem) theo thành tiền sau giảm giá giảm dần
SELECT  order_item_id,
        order_id,
        product_id,
        external_item_id,
        quantity,
        unit_price,
        discount,
        (quantity * unit_price) - discount AS line_total,
        status
FROM    OrderItem
ORDER BY line_total DESC

-- C14. Sắp xếp khách hàng theo ngày đăng ký mới nhất
SELECT  customer_id,
        name,
        email,
        phone_number,
        created_at
FROM    Customer
ORDER BY created_at DESC;

-- C15. Sắp xếp PackagingMaterial theo tồn kho giảm dần
--      (phục vụ kế hoạch nhập thêm vật liệu)
SELECT  material_id,
        name,
        material_type,
        stock_quantity,
        cost_per_unit,
        max_weight_capacity,
        status,
        business_id
FROM    PackagingMaterial
ORDER BY stock_quantity DESC;

-- PHẦN D : AGGREGATION (15 câu)
-- Hàm: COUNT / SUM / AVG / MAX / MIN
-- Kết hợp: GROUP BY / HAVING

-- D01. Đếm tổng số đơn hàng theo từng trạng thái
--      (theo dõi phân bổ pipeline xử lý đơn)
SELECT  status,
        COUNT(order_id)  AS total_orders
FROM    Orders
GROUP BY status
ORDER BY total_orders DESC;

-- D02. Tổng doanh thu (subtotal) và tổng phí ship theo từng doanh nghiệp
SELECT  b.business_id,
        b.name                          AS business_name,
        COUNT(o.order_id)               AS total_orders,
        SUM(o.subtotal)                 AS total_subtotal,
        SUM(o.shipping_fee)             AS total_shipping_fee,
        SUM(o.discount)                 AS total_discount,
        SUM(o.subtotal + o.shipping_fee - o.discount) AS total_revenue
FROM    Orders   o
JOIN    Business b ON b.business_id = o.business_id
GROUP BY b.business_id, b.name
ORDER BY total_revenue DESC;

-- D03. Đếm số sản phẩm theo từng danh mục
SELECT  category,
        COUNT(product_id)                   AS total_products,
        MIN(unit_price)                     AS min_price,
        MAX(unit_price)                     AS max_price,
        ROUND(AVG(unit_price), 0)           AS avg_price
FROM    Product
WHERE   status = 'active'
GROUP BY category
ORDER BY total_products DESC;

-- D04. Tổng tồn kho theo từng kho hàng
SELECT  w.warehouse_id,
        w.name                          AS warehouse_name,
        COUNT(inv.inventory_id)         AS total_sku_lines,
        SUM(inv.quantity_on_hand)       AS total_qty_on_hand,
        SUM(inv.quantity_reserved)      AS total_qty_reserved,
        SUM(inv.quantity_on_hand - inv.quantity_reserved) AS total_available_qty
FROM    Inventory  inv
JOIN    Warehouse  w ON w.warehouse_id = inv.warehouse_id
GROUP BY w.warehouse_id, w.name
ORDER BY total_qty_on_hand DESC;

-- D05. Số lượng Fulfillment theo từng kho và trạng thái
SELECT  w.name          AS warehouse_name,
        f.status,
        COUNT(f.fulfillment_id) AS total_fulfillments
FROM    Fulfillment f
JOIN    Warehouse   w ON w.warehouse_id = f.warehouse_id
GROUP BY w.name, f.status
ORDER BY w.name, f.status;

-- D06. Trọng lượng trung bình, lớn nhất và nhỏ nhất của các gói hàng
--      theo từng loại bao bì (package_type)
SELECT  package_type,
        COUNT(package_id)           AS total_packages,
        ROUND(AVG(weight), 3)       AS avg_weight_kg,
        MIN(weight)                 AS min_weight_kg,
        MAX(weight)                 AS max_weight_kg,
        ROUND(AVG(estimated_cost), 0) AS avg_cost_vnd
FROM    Package
GROUP BY package_type
ORDER BY avg_weight_kg DESC;

-- D07. Tỉ lệ rỗng trung bình (avg void_ratio) theo từng loại hộp được AI đề xuất
--      (đánh giá hiệu quả của từng loại vật liệu đóng gói)
SELECT  pm.name                         AS box_material,
        pm.material_type,
        COUNT(ai.recommendation_id)     AS total_recommendations,
        ROUND(AVG(ai.void_ratio), 3)    AS avg_void_ratio,
        MIN(ai.void_ratio)              AS min_void_ratio,
        MAX(ai.void_ratio)              AS max_void_ratio
FROM    AIRecommendation ai
JOIN    PackagingMaterial pm ON pm.material_id = ai.recommended_box_id
GROUP BY pm.name, pm.material_type
ORDER BY avg_void_ratio ASC;

-- D08. Tổng phí vận chuyển thực tế theo đơn vị vận chuyển (carrier)
--      (so sánh chi phí giữa các đối tác vận chuyển)
SELECT  carrier_name,
        COUNT(shipment_id)                  AS total_shipments,
        SUM(actual_shipping_fee)            AS total_actual_fee,
        ROUND(AVG(actual_shipping_fee), 0)  AS avg_actual_fee,
        MIN(actual_shipping_fee)            AS min_fee,
        MAX(actual_shipping_fee)            AS max_fee
FROM    Shipment
GROUP BY carrier_name
ORDER BY total_actual_fee DESC;

-- D09. Đếm số lần đồng bộ (SyncLog) theo loại và trạng thái
SELECT  sync_type,
        status,
        COUNT(sync_id)          AS total_syncs,
        SUM(success_count)      AS total_success_records,
        SUM(error_count)        AS total_errors
FROM    SyncLog
GROUP BY sync_type, status
ORDER BY sync_type, status;

-- D10. Số lượng nhân viên theo từng kho và theo vai trò
SELECT  w.name          AS warehouse_name,
        ws.staff_role,
        COUNT(ws.staff_id) AS headcount
FROM    WarehouseStaff ws
JOIN    Warehouse      w ON w.warehouse_id = ws.warehouse_id
WHERE   ws.status = 'active'
GROUP BY w.name, ws.staff_role
ORDER BY w.name, ws.staff_role;

-- D11. Tổng số OrderItem và tổng số lượng sản phẩm theo từng đơn hàng
SELECT  o.order_id,
        o.external_order_id,
        o.order_date,
        COUNT(oi.order_item_id)         AS total_line_items,
        SUM(oi.quantity)                AS total_quantity,
        SUM(oi.quantity * oi.unit_price - oi.discount) AS calculated_subtotal
FROM    Orders    o
JOIN    OrderItem oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.external_order_id, o.order_date
ORDER BY total_quantity DESC;

-- D12. Giá trị đơn hàng trung bình, lớn nhất và nhỏ nhất theo phương thức thanh toán
SELECT  payment_method,
        COUNT(order_id)                 AS total_orders,
        ROUND(AVG(subtotal), 0)         AS avg_subtotal,
        MIN(subtotal)                   AS min_subtotal,
        MAX(subtotal)                   AS max_subtotal,
        SUM(subtotal)                   AS total_subtotal
FROM    Orders
GROUP BY payment_method
ORDER BY total_subtotal DESC;

-- D13. Tổng chi phí vật liệu đóng gói theo từng doanh nghiệp
--      (ước tính ngân sách vật tư)
SELECT  b.name              AS business_name,
        COUNT(pm.material_id)                       AS total_materials,
        SUM(pm.cost_per_unit * pm.stock_quantity)   AS total_packaging_cost,
        ROUND(AVG(pm.cost_per_unit), 0)             AS avg_cost_per_unit,
        SUM(pm.stock_quantity)                      AS total_stock_units
FROM    PackagingMaterial pm
JOIN    Business          b  ON b.business_id = pm.business_id
GROUP BY b.name
ORDER BY total_packaging_cost DESC;

-- D14. Đếm số đơn hàng mỗi khách hàng đã đặt
--      (phân tích hành vi mua hàng)
SELECT  c.customer_id,
        c.name              AS customer_name,
        c.email,
        COUNT(o.order_id)                       AS total_orders,
        SUM(o.subtotal)                         AS total_spent,
        ROUND(AVG(o.subtotal), 0)               AS avg_order_value,
        MAX(o.order_date)                       AS last_order_date
FROM    Customer c
JOIN    Orders   o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.email
ORDER BY total_spent DESC;

-- D15. Lọc doanh nghiệp có tổng giá trị đơn hàng (subtotal) trên 3.000.000 VND
--      (dùng HAVING để lọc sau khi tổng hợp)
SELECT  b.business_id,
        b.name                          AS business_name,
        COUNT(o.order_id)               AS total_orders,
        SUM(o.subtotal)                 AS total_subtotal,
        ROUND(AVG(o.subtotal), 0)       AS avg_subtotal
FROM    Orders   o
JOIN    Business b ON b.business_id = o.business_id
GROUP BY b.business_id, b.name
HAVING  SUM(o.subtotal) > 3000000
ORDER BY total_subtotal DESC;




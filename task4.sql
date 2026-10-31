USE DBI_GROUP_7;
GO

-- PHẦN 1 : USER-DEFINED FUNCTIONS (4 CÂU: F1 - F4)
-- F1 Viết function fn_GetOrderTotal nhận vào 1 tham số @order_id, truy vấn bảng Orders
-- và trả về tổng tiền của đơn hàng đó theo công thức: subtotal + shipping_fee + tax - discount
CREATE OR ALTER FUNCTION dbo.fn_GetOrderTotal (@order_id NVARCHAR(50))
RETURNS DECIMAL(15, 2)
AS
BEGIN
    DECLARE @result DECIMAL(15, 2);

    SELECT @result = subtotal + shipping_fee + tax - discount
    FROM Orders
    WHERE order_id = @order_id;

    RETURN ISNULL(@result, 0);
END
GO
---
SELECT order_id,
       external_order_id,
       subtotal,
       shipping_fee,
       tax,
       discount,
       dbo.fn_GetOrderTotal(order_id) AS total_amount
FROM Orders;
GO


-- F2 Viết function fn_GetAvailableStock nhận vào @warehouse_id và @product_id,
-- truy vấn bảng Inventory và trả về số lượng hàng có thể bán: quantity_on_hand - quantity_reserved.
-- Nếu không tìm thấy dòng nào thì trả về 0.
CREATE OR ALTER FUNCTION dbo.fn_GetAvailableStock (
    @warehouse_id NVARCHAR(50),
    @product_id   NVARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @available INT;

    SELECT @available = quantity_on_hand - quantity_reserved
    FROM Inventory
    WHERE warehouse_id = @warehouse_id
      AND product_id   = @product_id;

    RETURN ISNULL(@available, 0);
END
GO

--
SELECT warehouse_id,
       product_id,
       quantity_on_hand,
       quantity_reserved,
       dbo.fn_GetAvailableStock(warehouse_id, product_id) AS available_stock
FROM Inventory;

-- Test F2 với mặt hàng không có trong kho (trả về 0):
SELECT dbo.fn_GetAvailableStock('WH005', 'PRD001') AS available_stock_not_found;
GO


-- F3 Viết function fn_GetFulfillmentDuration nhận vào @fulfillment_id,
-- tính số phút từ start_time đến completed_time của Fulfillment đó.
-- Nếu completed_time đang là NULL (chưa xong) thì trả về NULL.
CREATE OR ALTER FUNCTION dbo.fn_GetFulfillmentDuration (@fulfillment_id NVARCHAR(50))
RETURNS INT
AS
BEGIN
    DECLARE @duration_minutes INT;

    SELECT @duration_minutes = CASE
                                   WHEN completed_time IS NULL THEN NULL
                                   ELSE DATEDIFF(MINUTE, start_time, completed_time)
                               END
    FROM Fulfillment
    WHERE fulfillment_id = @fulfillment_id;

    RETURN @duration_minutes;
END
GO
-- 
SELECT fulfillment_id,
       order_id,
       status,
       start_time,
       completed_time,
       dbo.fn_GetFulfillmentDuration(fulfillment_id) AS duration_minutes
FROM Fulfillment;



-- F4 
-- Viết function fn_GetFulfillmentsByWarehouse nhận vào @warehouse_id,
-- trả về một bảng gồm toàn bộ Fulfillment thuộc kho đó với các cột:
-- fulfillment_id, order_id, status, priority, start_time.
GO
CREATE OR ALTER FUNCTION dbo.fn_GetFulfillmentsByWarehouse (@warehouse_id NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
    SELECT fulfillment_id,
           order_id,
           status,
           priority,
           start_time
    FROM Fulfillment
    WHERE warehouse_id = @warehouse_id
)
GO
-- Test F4:
SELECT * FROM dbo.fn_GetFulfillmentsByWarehouse('WH001');



-- ============================================================
-- PHẦN 2 : STORED PROCEDURES (4 CÂU: SP1 - SP4)
-- ============================================================

-- SP1 — Insert 1 bảng (Rất dễ)
-- Viết stored procedure sp_CreateFulfillment nhận vào @order_id, @warehouse_id, @staff_id, @priority.
-- Chỉ cần INSERT một dòng mới vào bảng Fulfillment với status = 'pending', created_at = GETDATE().
-- Không cần transaction, không cần ghi FulfillmentProgress.
CREATE OR ALTER PROCEDURE dbo.sp_CreateFulfillment
    @order_id     NVARCHAR(50),
    @warehouse_id NVARCHAR(50),
    @staff_id     NVARCHAR(50),
    @priority     INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @new_fulfillment_id NVARCHAR(50);

    SELECT @new_fulfillment_id = 'FUL' + RIGHT('0000' + CAST(ISNULL(MAX(CAST(SUBSTRING(fulfillment_id, 4, 10) AS INT)), 0) + 1 AS VARCHAR(10)), 4)
    FROM Fulfillment;

    INSERT INTO Fulfillment (
        fulfillment_id, status, priority, start_time, completed_time,
        note, created_at, updated_at, order_id, warehouse_id, assigned_staff_id
    )
    VALUES (
        @new_fulfillment_id, 'pending', @priority, NULL, NULL,
        NULL, GETDATE(), GETDATE(),
        @order_id, @warehouse_id, @staff_id
    );
END
GO

-- Test SP1:
EXEC dbo.sp_CreateFulfillment
    @order_id     = 'ORD0015',
    @warehouse_id = 'WH001',
    @staff_id     = 'STF001',
    @priority     = 1;

SELECT * FROM Fulfillment WHERE order_id = 'ORD0015';
GO


-- SP2 — Update 1 bảng (Rất dễ)
-- Viết stored procedure sp_UpdateFulfillmentStatus nhận vào @fulfillment_id, @new_status.
-- Chỉ cần UPDATE Fulfillment.status = @new_status cho đúng dòng có fulfillment_id tương ứng.
-- Không cần cập nhật Orders hay FulfillmentProgress.
CREATE OR ALTER PROCEDURE dbo.sp_UpdateFulfillmentStatus
    @fulfillment_id NVARCHAR(50),
    @new_status     NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Fulfillment
    SET status     = @new_status,
        updated_at = GETDATE()
    WHERE fulfillment_id = @fulfillment_id;
END
GO

-- Test SP2:
EXEC dbo.sp_UpdateFulfillmentStatus
    @fulfillment_id = 'FUL0014',
    @new_status     = 'packing';

SELECT fulfillment_id, order_id, status, updated_at FROM Fulfillment WHERE fulfillment_id = 'FUL0014';
GO


-- SP3 — Insert với tham số (Dễ)
-- Viết stored procedure sp_AddFulfillmentProgress nhận vào @fulfillment_id, @step, @status, @updated_by.
-- INSERT một dòng mới vào bảng FulfillmentProgress với event_timestamp = GETDATE().
-- Chỉ insert 1 bảng, không có logic kiểm tra phức tạp.
CREATE OR ALTER PROCEDURE dbo.sp_AddFulfillmentProgress
    @fulfillment_id NVARCHAR(50),
    @step           NVARCHAR(50),
    @status         NVARCHAR(50),
    @updated_by     NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @new_progress_id NVARCHAR(50);

    SELECT @new_progress_id = 'PRG' + RIGHT('0000' + CAST(ISNULL(MAX(CAST(SUBSTRING(progress_id, 4, 10) AS INT)), 0) + 1 AS VARCHAR(10)), 4)
    FROM FulfillmentProgress;

    INSERT INTO FulfillmentProgress (
        progress_id, step, status, event_timestamp, note, fulfillment_id, updated_by
    )
    VALUES (
        @new_progress_id, @step, @status, GETDATE(), NULL, @fulfillment_id, @updated_by
    );
END
GO

-- Test SP3:
EXEC dbo.sp_AddFulfillmentProgress
    @fulfillment_id = 'FUL0014',
    @step           = 'packing',
    @status         = 'in_progress',
    @updated_by     = 'STF002';

SELECT TOP 2 * FROM FulfillmentProgress WHERE fulfillment_id = 'FUL0014' ORDER BY progress_id DESC;
GO


-- SP4 — Insert với tham số (Dễ)
-- Viết stored procedure sp_CreateShipment nhận vào @package_id, @carrier_name, @tracking_number, @managed_by.
-- INSERT một dòng mới vào bảng Shipment với shipping_status = 'pending', pickup_scheduled_at = GETDATE().
CREATE OR ALTER PROCEDURE dbo.sp_CreateShipment
    @package_id      NVARCHAR(50),
    @carrier_name    NVARCHAR(255),
    @tracking_number NVARCHAR(255),
    @managed_by      NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @new_shipment_id NVARCHAR(50);

    SELECT @new_shipment_id = 'SHP' + RIGHT('0000' + CAST(ISNULL(MAX(CAST(SUBSTRING(shipment_id, 4, 10) AS INT)), 0) + 1 AS VARCHAR(10)), 4)
    FROM Shipment;

    INSERT INTO Shipment (
        shipment_id, tracking_number, carrier_name,
        barcode_data, qr_code_data, shipping_label_url, packing_slip_url, manifest_code,
        estimated_shipping_fee, actual_shipping_fee,
        pickup_scheduled_at, shipped_at, delivered_at,
        shipping_status, package_id, managed_by
    )
    VALUES (
        @new_shipment_id, @tracking_number, @carrier_name,
        @tracking_number,
        'https://tracking.example.vn/t/' + @tracking_number,
        'https://files.example.vn/labels/' + @tracking_number + '.pdf',
        'https://files.example.vn/slips/' + @package_id + '.pdf',
        'MNF-' + CONVERT(VARCHAR(8), GETDATE(), 112),
        25000, 25000,
        GETDATE(), NULL, NULL,
        'pending', @package_id, @managed_by
    );
END
GO

-- Test SP4:
EXEC dbo.sp_CreateShipment
    @package_id      = 'PKG0012',
    @carrier_name    = 'GHN',
    @tracking_number = 'GHN999888777',
    @managed_by      = 'STF004';

SELECT * FROM Shipment WHERE package_id = 'PKG0012';
GO


-- ============================================================
-- PHẦN 3 : TRIGGERS (4 CÂU: T1 - T4)
-- ============================================================

-- T1 — AFTER INSERT (Dễ)
-- Viết trigger trg_AfterOrderItem_Insert trên bảng OrderItem.
-- Sau khi INSERT một dòng mới, tự động UPDATE bảng Inventory: tăng quantity_reserved lên đúng bằng quantity vừa được đặt.
-- Cần tìm đúng dòng Inventory theo product_id và warehouse_id của kho đang xử lý đơn hàng đó.
CREATE OR ALTER TRIGGER dbo.trg_AfterOrderItem_Insert
ON OrderItem
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tìm warehouse_id xử lý đơn hàng thông qua bảng Orders và Fulfillment
    ;WITH OrderWarehouse AS (
        SELECT o.order_id,
               MIN(f.warehouse_id) AS warehouse_id
        FROM Orders      o
        JOIN Fulfillment f ON f.order_id = o.order_id
        GROUP BY o.order_id
    ),
    ReservedItems AS (
        SELECT i.product_id,
               ow.warehouse_id,
               SUM(i.quantity) AS total_qty
        FROM inserted       i
        JOIN OrderWarehouse ow ON ow.order_id = i.order_id
        GROUP BY i.product_id, ow.warehouse_id
    )
    UPDATE inv
    SET inv.quantity_reserved = inv.quantity_reserved + ri.total_qty,
        inv.updated_at        = GETDATE()
    FROM Inventory     inv
    JOIN ReservedItems ri  ON ri.product_id   = inv.product_id
                          AND ri.warehouse_id = inv.warehouse_id;
END
GO

-- Test T1:
SELECT inventory_id, warehouse_id, product_id, quantity_on_hand, quantity_reserved
FROM Inventory
WHERE product_id = 'PRD001' AND warehouse_id = 'WH001';

INSERT INTO OrderItem (order_item_id, order_id, product_id, external_item_id, quantity, unit_price, discount, tax, status)
VALUES ('OI0021', 'ORD0015', 'PRD001', 'WEB-ITEM-21', 3, 329000, 0, 0, 'pending');

SELECT inventory_id, warehouse_id, product_id, quantity_on_hand, quantity_reserved
FROM Inventory
WHERE product_id = 'PRD001' AND warehouse_id = 'WH001';
GO


-- T2 — AFTER UPDATE (Dễ)
-- Viết trigger trg_AfterFulfillment_Complete trên bảng Fulfillment.
-- Sau khi UPDATE, nếu cột status thay đổi sang giá trị 'completed'
-- thì tự động UPDATE Orders.status = 'fulfilled' cho đơn hàng tương ứng.
CREATE OR ALTER TRIGGER dbo.trg_AfterFulfillment_Complete
ON Fulfillment
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(status)
        RETURN;

    UPDATE o
    SET o.status     = 'fulfilled',
        o.updated_at = GETDATE()
    FROM Orders   o
    JOIN inserted ins ON ins.order_id       = o.order_id
    JOIN deleted  del ON del.fulfillment_id = ins.fulfillment_id
    WHERE ins.status = 'completed'
      AND del.status <> 'completed';
END
GO

-- Test T2:
SELECT order_id, status FROM Orders WHERE order_id = 'ORD0013';
UPDATE Fulfillment
SET status         = 'completed',
    completed_time = GETDATE()
WHERE fulfillment_id = 'FUL0013';
SELECT order_id, status FROM Orders WHERE order_id = 'ORD0013';
GO


-- T3 — BEFORE DELETE / INSTEAD OF DELETE (Trung bình)
-- Viết trigger trg_PreventDeleteActiveOrder trên bảng Orders.
-- Trước khi DELETE, kiểm tra nếu đơn hàng đó còn Fulfillment đang ở trạng thái 'in_progress' hoặc 'pending' thì không cho xóa.
-- In ra thông báo lỗi rõ ràng và ROLLBACK. (Dùng INSTEAD OF DELETE, nếu OK thì tự DELETE).
CREATE OR ALTER TRIGGER dbo.trg_PreventDeleteActiveOrder
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted     d
        JOIN Fulfillment f ON f.order_id = d.order_id
        WHERE f.status IN ('in_progress', 'pending')
    )
    BEGIN
        RAISERROR(N'Không thể xóa đơn hàng: Đơn hàng vẫn còn Fulfillment đang ở trạng thái pending hoặc in_progress!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Nếu hợp lệ thì tiến hành xóa dữ liệu phụ thuộc và xóa đơn hàng
    DELETE ois
    FROM OrderItemSnapshot ois
    JOIN OrderItem         oi ON oi.order_item_id = ois.order_item_id
    JOIN deleted           d  ON d.order_id       = oi.order_id;

    DELETE oi
    FROM OrderItem oi
    JOIN deleted   d ON d.order_id = oi.order_id;

    DELETE ogo
    FROM OrderGroupOrder ogo
    JOIN deleted         d ON d.order_id = ogo.order_id;

    DELETE o
    FROM Orders  o
    JOIN deleted d ON d.order_id = o.order_id;
END
GO

-- Test T3 (Thử xóa ORD0015 đang có FUL0015 ở trạng thái 'pending' -> sẽ bị chặn):
DELETE FROM Orders WHERE order_id = 'ORD0015';
GO


-- T4 — AFTER UPDATE chuỗi bảng (Trung bình)
-- Viết trigger trg_AfterShipment_Delivered trên bảng Shipment.
-- Sau khi UPDATE, nếu shipping_status thay đổi sang 'delivered' thì:
-- - Cập nhật Orders.status = 'delivered'
-- - Cập nhật Shipment.delivered_at = GETDATE()
-- Cần truy ngược chuỗi: Shipment -> Package -> Fulfillment -> Orders để tìm đúng đơn hàng.
CREATE OR ALTER TRIGGER dbo.trg_AfterShipment_Delivered
ON Shipment
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(shipping_status)
        RETURN;

    -- 1. Cập nhật Shipment.delivered_at = GETDATE()
    UPDATE s
    SET s.delivered_at = GETDATE()
    FROM Shipment s
    JOIN inserted ins ON ins.shipment_id = s.shipment_id
    JOIN deleted  del ON del.shipment_id = ins.shipment_id
    WHERE ins.shipping_status = 'delivered'
      AND del.shipping_status <> 'delivered';

    -- 2. Truy ngược chuỗi Shipment -> Package -> Fulfillment -> Orders để cập nhật Orders.status = 'delivered'
    UPDATE o
    SET o.status     = 'delivered',
        o.updated_at = GETDATE()
    FROM inserted    ins
    JOIN deleted     del ON del.shipment_id  = ins.shipment_id
    JOIN Package     pkg ON pkg.package_id   = ins.package_id
    JOIN Fulfillment f   ON f.fulfillment_id = pkg.fulfillment_id
    JOIN Orders      o   ON o.order_id       = f.order_id
    WHERE ins.shipping_status = 'delivered'
      AND del.shipping_status <> 'delivered';
END
GO

-- Test T4 (Cập nhật SHP0002 từ 'in_transit' sang 'delivered'):
UPDATE Shipment
SET shipping_status = 'delivered'
WHERE shipment_id = 'SHP0002';

SELECT shipment_id, package_id, shipping_status, delivered_at FROM Shipment WHERE shipment_id = 'SHP0002';
SELECT order_id, status, updated_at FROM Orders WHERE order_id = 'ORD0002';
GO


-- ============================================================
-- PHẦN 4 : VIEWS (2 CÂU: V1 - V2)
-- ============================================================

-- V1 — View đơn giản (Dễ)
-- Tạo view vw_OrderSummary hiển thị thông tin đơn hàng kèm tên khách hàng và địa chỉ giao hàng.
-- Các cột: order_id, external_order_id, customer_name, shipping_address, total_amount, status, order_date.
CREATE OR ALTER VIEW dbo.vw_OrderSummary
AS
SELECT o.order_id,
       o.external_order_id,
       c.name AS customer_name,
       CONCAT(
           ca.street,
           CASE WHEN ca.ward IS NOT NULL AND ca.ward <> '' THEN N', ' + ca.ward ELSE N'' END,
           N', ',
           ca.district
       ) AS shipping_address,
       (o.subtotal + o.shipping_fee + o.tax - o.discount) AS total_amount,
       o.status,
       o.order_date
FROM Orders          o
JOIN Customer        c  ON c.customer_id = o.customer_id
JOIN CustomerAddress ca ON ca.address_id = o.shipping_address_id;
GO

-- Test V1:
SELECT * FROM dbo.vw_OrderSummary;
GO


-- V2 — View có GROUP BY (Trung bình)
-- Tạo view vw_FulfillmentDashboard hiển thị trạng thái xử lý đơn hàng theo kho, gồm:
-- fulfillment_id, order_id, tên kho, tên nhân viên phụ trách, status, priority, số task đã hoàn thành.
CREATE OR ALTER VIEW dbo.vw_FulfillmentDashboard
AS
SELECT f.fulfillment_id,
       f.order_id,
       w.name        AS warehouse_name,
       ws.full_name  AS staff_name,
       f.status,
       f.priority,
       COUNT(CASE WHEN ft.status = 'completed' THEN 1 END) AS completed_tasks
FROM Fulfillment          f
JOIN Warehouse            w  ON w.warehouse_id      = f.warehouse_id
JOIN WarehouseStaff       ws ON ws.staff_id         = f.assigned_staff_id
LEFT JOIN FulfillmentTask ft ON ft.fulfillment_id   = f.fulfillment_id
GROUP BY f.fulfillment_id,
         f.order_id,
         w.name,
         ws.full_name,
         f.status,
         f.priority;
GO

-- Test V2:
SELECT * FROM dbo.vw_FulfillmentDashboard;
GO


-- ============================================================
-- PHẦN 5 : INDEXES (2 CÂU: I1 - I2)
-- ============================================================

-- I1 — Single-column Index (Dễ)
-- Tạo một index đơn cột trên Orders(status) để tăng tốc các câu query thường xuyên lọc đơn hàng theo trạng thái.
-- Giải thích:
--   + Trong vận hành kho/TMĐT, hệ thống liên tục lọc các đơn hàng theo trạng thái (WHERE status = 'pending' hoặc 'processing')
--     để ưu tiên xử lý, trong khi phần lớn lịch sử đơn hàng đã ở trạng thái 'completed'/'delivered'.
--   + Đánh Non-Clustered Index trên cột status giúp SQL Server dùng Index Seek tìm thẳng tới nhóm đơn đang chờ xử lý
--     thay vì phải quét toàn bộ bảng Orders (Clustered Index Scan).
DROP INDEX IF EXISTS idx_Orders_Status ON Orders;
GO

CREATE NONCLUSTERED INDEX idx_Orders_Status
ON Orders(status);
GO

-- Truy vấn kiểm tra sử dụng Index I1:
SELECT order_id, external_order_id, customer_id, status, order_date
FROM Orders
WHERE status = 'pending';
GO


-- I2 — Composite Index (Dễ)
-- Tạo một composite index trên Inventory(warehouse_id, product_id) để tăng tốc tra cứu tồn kho.
-- Giải thích tại sao nên đặt warehouse_id trước product_id:
--   + Theo nguyên tắc Left-Prefix của B-Tree Composite Index, cột đứng đầu (warehouse_id) cho phép index phục vụ tốt
--     CẢ 2 nhóm truy vấn phổ biến nhất:
--       (1) Xem/kiểm kê toàn bộ tồn kho của một kho cụ thể (WHERE warehouse_id = @warehouse_id)
--       (2) Tra cứu tồn kho của một sản phẩm cụ thể tại một kho (WHERE warehouse_id = @warehouse_id AND product_id = @product_id)
--   + Ngoài ra, các nghiệp vụ vận hành kho luôn phân vùng theo từng kho (warehouse_id) trước rồi mới tra cứu đến từng SKU (product_id).
DROP INDEX IF EXISTS idx_Inventory_Warehouse_Product ON Inventory;
GO

CREATE NONCLUSTERED INDEX idx_Inventory_Warehouse_Product
ON Inventory(warehouse_id, product_id);
GO

-- Truy vấn kiểm tra sử dụng Index I2:
SELECT inventory_id, warehouse_id, product_id, quantity_on_hand, quantity_reserved, shelf_location
FROM Inventory
WHERE warehouse_id = 'WH001'
  AND product_id   = 'PRD001';
GO

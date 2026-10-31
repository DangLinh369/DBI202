USE DBI_GROUP_7;
GO

IF NOT EXISTS (SELECT 1 FROM Inventory)
BEGIN
    INSERT INTO Inventory (inventory_id, product_id, warehouse_id, quantity_on_hand, quantity_reserved, reorder_level, shelf_location, last_counted_at, updated_at) VALUES
    ('INV001', 'PRD001', 'WH001', 120, 15, 30, 'A1-01', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV002', 'PRD002', 'WH001', 85,  10, 25, 'A1-02', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV003', 'PRD003', 'WH001', 25,  10, 20, 'A1-03', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV004', 'PRD004', 'WH002', 60,  5,  15, 'B1-03', '2025-09-01 08:05:00', '2025-09-25 08:05:00'),
    ('INV005', 'PRD005', 'WH001', 150, 20, 40, 'A1-05', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV006', 'PRD006', 'WH001', 18,  6,  15, 'A2-03', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV007', 'PRD007', 'WH002', 45,  8,  15, 'B2-01', '2025-09-01 08:05:00', '2025-09-25 08:05:00'),
    ('INV008', 'PRD008', 'WH003', 14,  5,  12, 'C2-04', '2025-09-01 08:10:00', '2025-09-25 08:10:00'),
    ('INV009', 'PRD009', 'WH001', 90,  12, 25, 'A1-04', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV010', 'PRD010', 'WH004', 70,  10, 20, 'D1-02', '2025-09-01 08:15:00', '2025-09-25 08:15:00'),
    ('INV011', 'PRD011', 'WH001', 55,  5,  15, 'A2-05', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV012', 'PRD012', 'WH001', 12,  4,  10, 'A3-01', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV013', 'PRD013', 'WH003', 40,  6,  10, 'C1-02', '2025-09-01 08:10:00', '2025-09-25 08:10:00'),
    ('INV014', 'PRD014', 'WH001', 65,  8,  20, 'A3-05', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV015', 'PRD015', 'WH001', 110, 15, 30, 'A2-01', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV016', 'PRD016', 'WH001', 95,  10, 25, 'A2-02', '2025-09-01 08:00:00', '2025-09-25 08:00:00'),
    ('INV017', 'PRD017', 'WH003', 80,  5,  20, 'C1-05', '2025-09-01 08:10:00', '2025-09-25 08:10:00'),
    ('INV018', 'PRD018', 'WH005', 22,  8,  20, 'E1-01', '2025-09-01 08:20:00', '2025-09-25 08:20:00'),
    ('INV019', 'PRD019', 'WH001', 200, 25, 50, 'A1-06', '2025-09-01 08:00:00', '2025-09-25 08:00:00');
END
GO

-- ============================================================
-- PHẦN 1 : USER-DEFINED FUNCTION (4 CÂU)
-- ============================================================

-- Câu F01 (Scalar Function): Viết hàm fn_GetOrderTotalPayable(@order_id) tính tổng số 
--tiền thực tế khách phải thanh toán cho một đơn hàng theo công thức: subtotal + shipping_fee + tax - discount.
GO
CREATE OR ALTER FUNCTION dbo.fn_GetOrderTotalPayable (@order_id NVARCHAR(50))
RETURNS DECIMAL(12, 2)
AS
BEGIN
    DECLARE @total DECIMAL(12, 2);

    SELECT @total = subtotal + shipping_fee + tax - discount
    FROM Orders
    WHERE order_id = @order_id;

    RETURN ISNULL(@total, 0);
END
GO

SELECT order_id, external_order_id, subtotal, shipping_fee, tax, discount,
       dbo.fn_GetOrderTotalPayable(order_id) AS total_payable
FROM Orders;
GO


-- Câu F02 (Scalar Function): Viết hàm fn_GetAvailableStock(@product_id, @warehouse_id)
--trả về số lượng tồn kho khả dụng thực tế (quantity_on_hand - quantity_reserved) của một sản phẩm tại một kho cụ thể.
CREATE OR ALTER FUNCTION dbo.fn_GetAvailableStock (
    @product_id   NVARCHAR(50),
    @warehouse_id NVARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @available INT;

    SELECT @available = quantity_on_hand - quantity_reserved
    FROM Inventory
    WHERE product_id = @product_id
      AND warehouse_id = @warehouse_id;

    RETURN ISNULL(@available, 0);
END
GO

SELECT p.product_id, p.sku, p.name, i.warehouse_id,
       i.quantity_on_hand, i.quantity_reserved,
       dbo.fn_GetAvailableStock(p.product_id, i.warehouse_id) AS available_stock
FROM Product p
JOIN Inventory i ON i.product_id = p.product_id;
GO


-- Câu F03 (Inline Table-Valued Function): Viết hàm fn_GetLowStockAlertByBusiness(@business_id) 
--trả về danh sách các mặt hàng của doanh nghiệp có số lượng tồn khả dụng chạm hoặc thấp hơn mức tái đặt hàng (reorder_level).
CREATE OR ALTER FUNCTION dbo.fn_GetLowStockAlertByBusiness (@business_id NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
    SELECT i.inventory_id,
           p.product_id,
           p.sku,
           p.name AS product_name,
           w.warehouse_id,
           w.name AS warehouse_name,
           i.shelf_location,
           i.quantity_on_hand,
           i.quantity_reserved,
           (i.quantity_on_hand - i.quantity_reserved) AS available_stock,
           i.reorder_level,
           (i.reorder_level - (i.quantity_on_hand - i.quantity_reserved) + 20) AS suggested_restock_qty
    FROM Inventory i
    JOIN Product   p ON p.product_id   = i.product_id
    JOIN Warehouse w ON w.warehouse_id = i.warehouse_id
    WHERE p.business_id = @business_id
      AND (i.quantity_on_hand - i.quantity_reserved) <= i.reorder_level
);
GO

SELECT * FROM dbo.fn_GetLowStockAlertByBusiness('BUS001');
GO


-- Câu F04 (Multi-Statement Table-Valued Function): Viết hàm fn_EvaluateStaffPerformance(@warehouse_id)
--thống kê tổng số tác vụ hoàn thành, thời gian xử lý trung bình (phút) và xếp loại năng suất của từng nhân viên trong một kho.
CREATE OR ALTER FUNCTION dbo.fn_EvaluateStaffPerformance (@warehouse_id NVARCHAR(50))
RETURNS @StaffPerformance TABLE (
    staff_id            NVARCHAR(50),
    full_name           NVARCHAR(255),
    staff_role          NVARCHAR(255),
    completed_tasks     INT,
    in_progress_tasks   INT,
    avg_duration_mins   DECIMAL(10, 2),
    performance_rating  NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @StaffPerformance
    SELECT ws.staff_id,
           ws.full_name,
           ws.staff_role,
           COUNT(CASE WHEN ft.status = 'completed'   THEN 1 END),
           COUNT(CASE WHEN ft.status = 'in_progress' THEN 1 END),
           ISNULL(AVG(CASE WHEN ft.status = 'completed'
                           THEN DATEDIFF(MINUTE, ft.started_at, ft.completed_at) * 1.0 END), 0),
           CASE
               WHEN COUNT(CASE WHEN ft.status = 'completed' THEN 1 END) >= 5 THEN N'Xuất sắc'
               WHEN COUNT(CASE WHEN ft.status = 'completed' THEN 1 END) >= 2 THEN N'Đạt yêu cầu'
               WHEN COUNT(CASE WHEN ft.status = 'completed' THEN 1 END) >= 1 THEN N'Cần cố gắng'
               ELSE N'Chưa có tác vụ hoàn tất'
           END
    FROM WarehouseStaff ws
    LEFT JOIN FulfillmentTask ft ON ft.assigned_staff_id = ws.staff_id
    WHERE ws.warehouse_id = @warehouse_id
      AND ws.status = 'active'
    GROUP BY ws.staff_id, ws.full_name, ws.staff_role;

    RETURN;
END
GO

SELECT * FROM dbo.fn_EvaluateStaffPerformance('WH001');
GO

-- PHẦN 2 : STORED PROCEDURE (4 CÂU)

-- Câu SP01: Viết thủ tục sp_GetOrderFullTimeline(@order_id) kiểm tra tính
--hợp lệ của mã đơn hàng, nếu hợp lệ thì xuất thông tin tổng quan đơn hàng,
--
--gói hàng/vận đơn và lịch sử các bước xử lý (FulfillmentProgress).
CREATE OR ALTER PROCEDURE dbo.sp_GetOrderFullTimeline
    @order_id NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @order_id IS NULL OR LTRIM(RTRIM(@order_id)) = ''
    BEGIN
        PRINT N'Lỗi: Mã đơn hàng không được để trống (NULL)!';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Orders WHERE order_id = @order_id)
    BEGIN
        PRINT N'Lỗi: Không tìm thấy đơn hàng có mã ' + @order_id;
        RETURN;
    END

    SELECT o.order_id,
           o.external_order_id,
           o.order_date,
           o.status          AS order_status,
           o.payment_status,
           o.payment_method,
           dbo.fn_GetOrderTotalPayable(o.order_id) AS total_payable,
           c.name            AS customer_name,
           b.name            AS business_name,
           f.fulfillment_id,
           f.status          AS fulfillment_status,
           pkg.package_id,
           s.tracking_number,
           s.carrier_name,
           s.shipping_status
    FROM Orders o
    JOIN Customer         c   ON c.customer_id    = o.customer_id
    JOIN Business         b   ON b.business_id    = o.business_id
    LEFT JOIN Fulfillment f   ON f.order_id       = o.order_id
    LEFT JOIN Package     pkg ON pkg.fulfillment_id = f.fulfillment_id
    LEFT JOIN Shipment    s   ON s.package_id     = pkg.package_id
    WHERE o.order_id = @order_id;

    SELECT fp.progress_id,
           fp.step,
           fp.status,
           fp.event_timestamp,
           ws.full_name AS updated_by_staff,
           fp.note
    FROM FulfillmentProgress fp
    JOIN Fulfillment    f  ON f.fulfillment_id = fp.fulfillment_id
    JOIN WarehouseStaff ws ON ws.staff_id      = fp.updated_by
    WHERE f.order_id = @order_id
    ORDER BY fp.event_timestamp ASC;
END
GO

EXEC dbo.sp_GetOrderFullTimeline 'ORD0001';
EXEC dbo.sp_GetOrderFullTimeline NULL;
GO


-- Câu SP02: Viết thủ tục sp_AddOrderItemAndRecalculate thêm mới một món hàng vào đơn hàng đang ở trạng thái 'pending', 
--tự động tạo bản ghi OrderItemSnapshot và cập nhật lại subtotal của bảng Orders trong một Transaction.
CREATE OR ALTER PROCEDURE dbo.sp_AddOrderItemAndRecalculate
    @order_item_id    NVARCHAR(50),
    @external_item_id NVARCHAR(50),
    @order_id         NVARCHAR(50),
    @product_id       NVARCHAR(50),
    @quantity         INT,
    @discount         DECIMAL(10, 2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @unit_price       DECIMAL(10, 2);
    DECLARE @weight           DECIMAL(10, 2);
    DECLARE @dimensions       NVARCHAR(255);
    DECLARE @special_handling NVARCHAR(255);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Orders WHERE order_id = @order_id AND status = 'pending')
            THROW 50001, N'Đơn hàng không tồn tại hoặc không ở trạng thái pending!', 1;

        IF @quantity <= 0
            THROW 50002, N'Số lượng đặt phải lớn hơn 0!', 1;

        SELECT @unit_price       = unit_price,
               @weight           = weight,
               @dimensions       = CONCAT(CAST(length AS VARCHAR(20)), 'x', CAST(width AS VARCHAR(20)), 'x', CAST(height AS VARCHAR(20))),
               @special_handling = special_handling
        FROM Product
        WHERE product_id = @product_id AND status = 'active';

        IF @unit_price IS NULL
            THROW 50003, N'Sản phẩm không tồn tại hoặc đã ngừng kinh doanh!', 1;

        INSERT INTO OrderItem (order_item_id, external_item_id, quantity, unit_price, discount, tax, status, order_id, product_id)
        VALUES (@order_item_id, @external_item_id, @quantity, @unit_price, @discount, 0, 'pending', @order_id, @product_id);

        INSERT INTO OrderItemSnapshot (order_item_id, weight, dimensions, special_handling)
        VALUES (@order_item_id, @weight, @dimensions, @special_handling);

        UPDATE Orders
        SET subtotal   = (SELECT SUM(quantity * unit_price) FROM OrderItem WHERE order_id = @order_id),
            discount   = (SELECT SUM(discount)              FROM OrderItem WHERE order_id = @order_id),
            updated_at = GETDATE()
        WHERE order_id = @order_id;

        COMMIT TRANSACTION;
        PRINT N'Thêm OrderItem và cập nhật tổng tiền đơn hàng thành công!';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT N'Lỗi Transaction: ' + ERROR_MESSAGE();
    END CATCH
END
GO

EXEC dbo.sp_AddOrderItemAndRecalculate
    @order_item_id    = 'OI0099',
    @external_item_id = 'WEB-ITEM-99',
    @order_id         = 'ORD0015',
    @product_id       = 'PRD002',
    @quantity         = 2,
    @discount         = 50000;

SELECT * FROM Orders WHERE order_id = 'ORD0015';
SELECT * FROM OrderItem WHERE order_id = 'ORD0015';
SELECT * FROM OrderItemSnapshot WHERE order_item_id = 'OI0099';
GO


-- Câu SP03: Viết thủ tục sp_CompleteFulfillmentTask(@task_id, @staff_id, @note, @ResultMessage OUTPUT) 
--đánh dấu hoàn thành một tác vụ trong kho, tự động ghi log vào FulfillmentProgress 
--và kích hoạt bước kế tiếp (hoặc chốt hoàn tất Fulfillment).
CREATE OR ALTER PROCEDURE dbo.sp_CompleteFulfillmentTask
    @task_id       NVARCHAR(50),
    @staff_id      NVARCHAR(50),
    @note          NVARCHAR(1000),
    @ResultMessage NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fulfillment_id NVARCHAR(50);
    DECLARE @task_type      NVARCHAR(50);
    DECLARE @sequence       INT;
    DECLARE @next_task_id   NVARCHAR(50);
    DECLARE @next_type      NVARCHAR(50);
    DECLARE @new_progress_id NVARCHAR(50);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @fulfillment_id = fulfillment_id,
               @task_type      = task_type,
               @sequence       = sequence
        FROM FulfillmentTask
        WHERE task_id = @task_id;

        IF @fulfillment_id IS NULL
            THROW 50010, N'Không tìm thấy task_id!', 1;

        UPDATE FulfillmentTask
        SET status       = 'completed',
            started_at   = ISNULL(started_at, GETDATE()),
            completed_at = GETDATE(),
            note         = ISNULL(@note, note)
        WHERE task_id = @task_id;

        SET @new_progress_id = 'PRG' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 9000 + 1000 AS VARCHAR(4)), 4);

        INSERT INTO FulfillmentProgress (progress_id, fulfillment_id, updated_by, step, status, event_timestamp, note)
        VALUES (
            @new_progress_id,
            @fulfillment_id,
            @staff_id,
            CASE @task_type
                WHEN 'pick'     THEN 'picking'
                WHEN 'pack'     THEN 'packing'
                WHEN 'qc'       THEN 'qc_passed'
                WHEN 'handover' THEN 'handed_over'
                ELSE @task_type
            END,
            'completed',
            GETDATE(),
            @note
        );

        SELECT TOP 1 @next_task_id = task_id, @next_type = task_type
        FROM FulfillmentTask
        WHERE fulfillment_id = @fulfillment_id AND sequence > @sequence
        ORDER BY sequence ASC;

        IF @next_task_id IS NOT NULL
        BEGIN
            UPDATE FulfillmentTask
            SET status = 'in_progress', started_at = GETDATE()
            WHERE task_id = @next_task_id;

            UPDATE Fulfillment
            SET status = @next_type, updated_at = GETDATE()
            WHERE fulfillment_id = @fulfillment_id;

            SET @ResultMessage = N'Đã hoàn tất [' + @task_type + N']. 
            Đã chuyển sang bước kế tiếp: [' + @next_type + N'] (' + @next_task_id + N')';
        END
        ELSE
        BEGIN
            UPDATE Fulfillment
            SET status = 'completed', completed_time = GETDATE(), updated_at = GETDATE()
            WHERE fulfillment_id = @fulfillment_id;

            SET @ResultMessage = N'Đã hoàn tất bước cuối cùng! Fulfillment [' + @fulfillment_id + N'] 
            đã chuyển sang completed.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ResultMessage = N'Lỗi: ' + ERROR_MESSAGE();
    END CATCH
END
GO

DECLARE @msg NVARCHAR(255);
EXEC dbo.sp_CompleteFulfillmentTask
    @task_id       = 'TSK0050',
    @staff_id      = 'STF012',
    @note          = N'Đã đóng gói xong bộ chăn ga',
    @ResultMessage = @msg OUTPUT;
PRINT @msg;
GO


-- Câu SP04: Viết thủ tục sp_ApproveAIRecommendationAndCreatePackage duyệt đề xuất đóng gói của AI
--(AIRecommendation) và tự động khởi tạo kiện hàng (Package) với kích thước, 
--trọng lượng và chi phí ước tính từ vật liệu bao bì.
CREATE OR ALTER PROCEDURE dbo.sp_ApproveAIRecommendationAndCreatePackage
    @recommendation_id NVARCHAR(50),
    @staff_id          NVARCHAR(50),
    @new_package_id    NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fulfillment_id NVARCHAR(50);
    DECLARE @box_id         NVARCHAR(50);
    DECLARE @filler_id      NVARCHAR(50);
    DECLARE @box_qty        INT;
    DECLARE @len            DECIMAL(10, 2);
    DECLARE @wid            DECIMAL(10, 2);
    DECLARE @hei            DECIMAL(10, 2);
    DECLARE @wei            DECIMAL(10, 2);
    DECLARE @pkg_type       NVARCHAR(50);
    DECLARE @est_cost       DECIMAL(10, 2);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @fulfillment_id = fulfillment_id,
               @box_id         = recommended_box_id,
               @filler_id      = recommended_filler_id,
               @box_qty        = box_quantity,
               @len            = est_length,
               @wid            = est_width,
               @hei            = est_height,
               @wei            = est_weight
        FROM AIRecommendation
        WHERE recommendation_id = @recommendation_id;

        IF @fulfillment_id IS NULL
            THROW 50020, N'Không tìm thấy đề xuất AI!', 1;

        IF EXISTS (SELECT 1 FROM Package WHERE recommendation_id = @recommendation_id)
            THROW 50021, N'Đề xuất AI này đã được tạo kiện hàng Package trước đó!', 1;

        SELECT @pkg_type = material_type,
               @est_cost = cost_per_unit * @box_qty
        FROM PackagingMaterial
        WHERE material_id = @box_id;

        SELECT @est_cost = @est_cost + ISNULL(cost_per_unit, 0)
        FROM PackagingMaterial
        WHERE material_id = @filler_id;

        UPDATE AIRecommendation
        SET approval_status = 'approved',
            approved_by     = @staff_id
        WHERE recommendation_id = @recommendation_id;

        INSERT INTO Package (
            package_id, package_type, length, width, height, weight,
            estimated_cost, status, created_at, updated_at,
            fulfillment_id, recommendation_id, material_id
        )
        VALUES (
            @new_package_id, @pkg_type, @len, @wid, @hei, @wei,
            @est_cost, 'packed', GETDATE(), GETDATE(),
            @fulfillment_id, @recommendation_id, @box_id
        );

        COMMIT TRANSACTION;
        PRINT N'Đã duyệt AIRecommendation và tạo kiện hàng ' + @new_package_id + N' thành công!';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
    END CATCH
END
GO

EXEC dbo.sp_ApproveAIRecommendationAndCreatePackage
    @recommendation_id = 'REC0013',
    @staff_id          = 'STF010',
    @new_package_id    = 'PKG0013';

SELECT * FROM Package WHERE package_id = 'PKG0013';
GO

-- PHẦN 3 : TRIGGER (4 CÂU)

-- Câu TRG01 (AFTER INSERT trên OrderItem): Viết Trigger trg_OrderItem_ReserveInventory tự động kiểm tra tồn kho khả dụng 
--và cộng dồn số lượng giữ chỗ (quantity_reserved) trong bảng Inventory 
--khi có chi tiết đơn hàng mới (có GROUP BY xử lý chèn nhiều dòng).
CREATE OR ALTER TRIGGER dbo.trg_OrderItem_ReserveInventory
ON OrderItem
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT product_id, SUM(quantity) AS total_requested
            FROM inserted
            GROUP BY product_id
        ) req
        LEFT JOIN (
            SELECT product_id, SUM(quantity_on_hand - quantity_reserved) AS total_available
            FROM Inventory
            GROUP BY product_id
        ) inv ON inv.product_id = req.product_id
        WHERE ISNULL(inv.total_available, 0) < req.total_requested
    )
    BEGIN
        RAISERROR(N'Lỗi Trigger: Số lượng tồn kho khả dụng không đủ để đặt giữ cho đơn hàng!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    ;WITH GroupedInserted AS (
        SELECT product_id, SUM(quantity) AS total_qty
        FROM inserted
        GROUP BY product_id
    ),
    TargetInventory AS (
        SELECT inventory_id, product_id,
               ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY (quantity_on_hand - quantity_reserved) DESC) AS rn
        FROM Inventory
    )
    UPDATE inv
    SET quantity_reserved = inv.quantity_reserved + gi.total_qty,
        updated_at        = GETDATE()
    FROM Inventory inv
    JOIN TargetInventory ti ON ti.inventory_id = inv.inventory_id AND ti.rn = 1
    JOIN GroupedInserted gi ON gi.product_id   = inv.product_id;
END
GO

SELECT product_id, quantity_on_hand, quantity_reserved FROM Inventory WHERE product_id = 'PRD001';
INSERT INTO OrderItem (order_item_id, order_id, product_id, external_item_id, quantity, unit_price, discount, tax, status)
VALUES ('OI0100', 'ORD0015', 'PRD001', 'WEB-ITEM-100', 3, 329000, 0, 0, 'pending');
SELECT product_id, quantity_on_hand, quantity_reserved FROM Inventory WHERE product_id = 'PRD001';
GO


-- Câu TRG02 (AFTER INSERT trên Package): Viết Trigger trg_Package_DeductPackagingMaterial 
--tự động trừ số lượng tồn kho bao bì (stock_quantity) trong bảng PackagingMaterial khi một kiện hàng Package được tạo mới;
--nếu bao bì không đủ tồn kho thì ROLLBACK.
CREATE OR ALTER TRIGGER dbo.trg_Package_DeductPackagingMaterial
ON Package
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH MaterialUsage AS (
        SELECT ins.material_id,
               SUM(ISNULL(ai.box_quantity, 1)) AS used_qty
        FROM inserted ins
        LEFT JOIN AIRecommendation ai ON ai.recommendation_id = ins.recommendation_id
        GROUP BY ins.material_id
    )
    UPDATE pm
    SET stock_quantity = pm.stock_quantity - mu.used_qty
    FROM PackagingMaterial pm
    JOIN MaterialUsage mu ON mu.material_id = pm.material_id;

    IF EXISTS (SELECT 1 FROM PackagingMaterial WHERE stock_quantity < 0)
    BEGIN
        RAISERROR(N'Lỗi Trigger: Số lượng vật liệu đóng gói trong kho không đủ!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

SELECT material_id, name, stock_quantity FROM PackagingMaterial WHERE material_id = 'MAT001';
INSERT INTO Package (package_id, fulfillment_id, recommendation_id, material_id, package_type, length, width, height, weight, estimated_cost, status, created_at, updated_at)
VALUES ('PKG0014', 'FUL0014', 'REC0014', 'MAT001', 'poly_mailer', 40, 30, 8, 1.16, 3700, 'packed', GETDATE(), GETDATE());
SELECT material_id, name, stock_quantity FROM PackagingMaterial WHERE material_id = 'MAT001';
GO


-- Câu TRG03 (AFTER UPDATE trên Shipment): Viết Trigger trg_Shipment_SyncOrderAndPackageStatus khi 
--cập nhật shipping_status sang 'delivered' thì tự động đồng bộ trạng thái kiện hàng (Package) sang 'delivered' 
--và đơn hàng (Orders) sang 'completed', 'paid'.
CREATE OR ALTER TRIGGER dbo.trg_Shipment_SyncOrderAndPackageStatus
ON Shipment
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(shipping_status) RETURN;

    ;WITH DeliveredShipments AS (
        SELECT ins.shipment_id, ins.package_id
        FROM inserted ins
        JOIN deleted  del ON del.shipment_id = ins.shipment_id
        WHERE ins.shipping_status = 'delivered'
          AND del.shipping_status <> 'delivered'
    )
    UPDATE s
    SET delivered_at = ISNULL(s.delivered_at, GETDATE())
    FROM Shipment s
    JOIN DeliveredShipments ds ON ds.shipment_id = s.shipment_id;

    UPDATE pkg
    SET status     = 'delivered',
        updated_at = GETDATE()
    FROM Package pkg
    JOIN inserted ins ON ins.package_id = pkg.package_id
    JOIN deleted  del ON del.shipment_id = ins.shipment_id
    WHERE ins.shipping_status = 'delivered'
      AND del.shipping_status <> 'delivered';

    UPDATE o
    SET status         = 'completed',
        payment_status = 'paid',
        updated_at     = GETDATE()
    FROM Orders o
    JOIN Fulfillment f   ON f.order_id       = o.order_id
    JOIN Package     pkg ON pkg.fulfillment_id = f.fulfillment_id
    JOIN inserted    ins ON ins.package_id   = pkg.package_id
    JOIN deleted     del ON del.shipment_id  = ins.shipment_id
    WHERE ins.shipping_status = 'delivered'
      AND del.shipping_status <> 'delivered';
END
GO

UPDATE Shipment SET shipping_status = 'delivered' WHERE shipment_id = 'SHP0002';
SELECT shipment_id, shipping_status, delivered_at FROM Shipment WHERE shipment_id = 'SHP0002';
SELECT package_id, status, updated_at FROM Package WHERE package_id = 'PKG0002';
GO


-- Câu TRG04 (INSTEAD OF DELETE trên Orders): Viết Trigger trg_PreventDeleteActiveOrCompletedOrder 
--chặn thao tác xóa các đơn hàng đã thanh toán ('paid') hoặc đang/đã xử lý ('processing', 'completed'),
--chỉ cho phép xóa đơn nháp/đã hủy.
CREATE OR ALTER TRIGGER dbo.trg_PreventDeleteActiveOrCompletedOrder
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted
        WHERE payment_status = 'paid'
           OR status IN ('processing', 'completed')
    )
    BEGIN
        RAISERROR(N'Lỗi bảo mật nghiệp vụ: Không được phép xóa đơn hàng đã thanh toán hoặc đang/đã hoàn tất xử lý!', 16, 1);
        RETURN;
    END

    DELETE ois
    FROM OrderItemSnapshot ois
    JOIN OrderItem oi ON oi.order_item_id = ois.order_item_id
    JOIN deleted   d  ON d.order_id       = oi.order_id;

    DELETE oi
    FROM OrderItem oi
    JOIN deleted d ON d.order_id = oi.order_id;

    DELETE ogo
    FROM OrderGroupOrder ogo
    JOIN deleted d ON d.order_id = ogo.order_id;

    DELETE o
    FROM Orders o
    JOIN deleted d ON d.order_id = o.order_id;
END
GO

-- Thử xóa đơn đã hoàn tất (sẽ bị Trigger chặn lại):
DELETE FROM Orders WHERE order_id = 'ORD0001';
GO

-- PHẦN 4 : VIEW (2 CÂU)

-- Câu VW01: Tạo View vw_OrderFulfillmentDashboard kết hợp dữ liệu từ 7 bảng
--(Business, Customer, Orders, Fulfillment, Warehouse, Package, Shipment) 
--phục vụ theo dõi toàn trình đơn hàng từ lúc đặt đến lúc giao.
CREATE OR ALTER VIEW dbo.vw_OrderFulfillmentDashboard
AS
SELECT o.order_id,
       o.external_order_id,
       o.order_date,
       b.business_id,
       b.name                                    AS business_name,
       c.customer_id,
       c.name                                    AS customer_name,
       o.status                                  AS order_status,
       o.payment_method,
       o.payment_status,
       (o.subtotal + o.shipping_fee + o.tax - o.discount) AS total_payable,
       w.warehouse_id,
       w.name                                    AS warehouse_name,
       f.fulfillment_id,
       f.priority,
       f.status                                  AS fulfillment_status,
       pkg.package_id,
       pkg.package_type,
       pkg.weight                                AS package_weight_kg,
       s.shipment_id,
       s.carrier_name,
       s.tracking_number,
       s.shipping_status,
       s.shipped_at,
       s.delivered_at
FROM Orders o
JOIN Business         b   ON b.business_id      = o.business_id
JOIN Customer         c   ON c.customer_id      = o.customer_id
LEFT JOIN Fulfillment f   ON f.order_id         = o.order_id
LEFT JOIN Warehouse   w   ON w.warehouse_id     = f.warehouse_id
LEFT JOIN Package     pkg ON pkg.fulfillment_id = f.fulfillment_id
LEFT JOIN Shipment    s   ON s.package_id       = pkg.package_id;
GO

SELECT * FROM dbo.vw_OrderFulfillmentDashboard WHERE business_id = 'BUS001';
GO


-- Câu VW02: Tạo View vw_GreenPackagingEfficiency thống kê hiệu quả đề xuất đóng gói của AI 
--(tỉ lệ rỗng trung bình void_ratio, tổng chi phí bao bì, số kiện hàng) theo từng doanh nghiệp 
--và loại vật liệu thân thiện môi trường.
CREATE OR ALTER VIEW dbo.vw_GreenPackagingEfficiency
AS
SELECT b.business_id,
       b.name                           AS business_name,
       pm.material_id,
       pm.name                          AS material_name,
       pm.material_type,
       pm.eco_friendly,
       pm.recyclable,
       pm.cost_per_unit,
       pm.stock_quantity,
       COUNT(ai.recommendation_id)      AS total_ai_recommendations,
       COUNT(pkg.package_id)            AS total_packages_created,
       ROUND(AVG(ai.void_ratio), 3)     AS avg_void_ratio,
       ISNULL(SUM(pkg.estimated_cost), 0) AS total_estimated_packaging_cost
FROM PackagingMaterial pm
JOIN Business              b   ON b.business_id      = pm.business_id
LEFT JOIN AIRecommendation ai  ON ai.recommended_box_id = pm.material_id
LEFT JOIN Package          pkg ON pkg.recommendation_id = ai.recommendation_id
GROUP BY b.business_id, b.name,
         pm.material_id, pm.name, pm.material_type,
         pm.eco_friendly, pm.recyclable, pm.cost_per_unit, pm.stock_quantity;
GO

SELECT * FROM dbo.vw_GreenPackagingEfficiency ORDER BY total_ai_recommendations DESC;
GO

-- PHẦN 5 : INDEX & DEMO TỐC ĐỘ TRÊN 100.000 DÒNG (2 CÂU)

-- Câu IDX01: Bơm 100.000 dòng dữ liệu giả lập vào bảng Orders, đo tốc độ truy vấn lọc đơn hàng theo
--(business_id, status, payment_status, order_date) 
--TRƯỚC và SAU khi tạo Composite Covering Index idx_Orders_Business_Status_Date.

DROP INDEX IF EXISTS idx_Orders_Business_Status_Date ON Orders;
GO

;WITH Nums AS (
    SELECT TOP (100000)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO Orders (
    order_id, external_order_id, order_date, status, payment_status,
    payment_method, subtotal, shipping_fee, tax, discount, currency,
    note, sync_status, synced_at, created_at, updated_at,
    customer_id, business_id, shipping_address_id, billing_address_id
)
SELECT
    'ORD_TEST_' + RIGHT('000000' + CAST(n AS VARCHAR(6)), 6),
    'EXT_TEST_' + RIGHT('000000' + CAST(n AS VARCHAR(6)), 6),
    DATEADD(MINUTE, -n, '2025-10-01 00:00:00'),
    CASE WHEN n % 20 = 0 THEN 'pending'
         WHEN n % 5  = 0 THEN 'processing'
         ELSE 'completed' END,
    CASE WHEN n % 20 = 0 THEN 'unpaid' ELSE 'paid' END,
    CASE WHEN n % 2  = 0 THEN 'COD'    ELSE 'Banking' END,
    CAST((n % 50 + 1) * 50000 AS DECIMAL(10, 2)),
    25000, 0, 0, 'VND',
    N'Đơn hàng giả lập test hiệu năng Index',
    'synced', GETDATE(), GETDATE(), GETDATE(),
    'CUS' + RIGHT('000' + CAST((n % 10) + 1 AS VARCHAR(3)), 3),
    'BUS' + RIGHT('000' + CAST((n % 5)  + 1 AS VARCHAR(3)), 3),
    'ADR' + RIGHT('000' + CAST((n % 10) + 1 AS VARCHAR(3)), 3),
    'ADR' + RIGHT('000' + CAST((n % 5)  + 11 AS VARCHAR(3)), 3)
FROM Nums
WHERE NOT EXISTS (SELECT 1 FROM Orders WHERE order_id = 'ORD_TEST_000001');
GO

DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- 1. Truy vấn TRƯỚC khi có Index (Clustered Index Scan):
SELECT order_id, customer_id, order_date, subtotal, shipping_fee
FROM Orders
WHERE business_id    = 'BUS001'
  AND status         = 'pending'
  AND payment_status = 'unpaid'
  AND order_date    >= '2025-09-15';

-- 2. Tạo Non-Clustered Composite Covering Index:
CREATE NONCLUSTERED INDEX idx_Orders_Business_Status_Date
ON Orders(business_id ASC, status ASC, payment_status ASC, order_date DESC)
INCLUDE (customer_id, subtotal, shipping_fee);
GO

DBCC DROPCLEANBUFFERS;

-- 3. Truy vấn SAU khi có Index (Index Seek):
SELECT order_id, customer_id, order_date, subtotal, shipping_fee
FROM Orders
WHERE business_id    = 'BUS001'
  AND status         = 'pending'
  AND payment_status = 'unpaid'
  AND order_date    >= '2025-09-15';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- Câu IDX02: Bơm 100.000 dòng dữ liệu vào bảng SyncLog, 
--đo tốc độ truy vấn tìm kiếm các bản ghi đồng bộ bị lỗi (status = 'failed') TRƯỚC và 
--SAU khi tạo Filtered Index idx_SyncLog_Failed_Filtered.

DROP INDEX IF EXISTS idx_SyncLog_Failed_Filtered ON SyncLog;
GO

;WITH Nums AS (
    SELECT TOP (100000)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO SyncLog (
    sync_id, business_id, sync_type, started_at, finished_at,
    status, success_count, error_count, error_message
)
SELECT
    'SYN_TEST_' + RIGHT('000000' + CAST(n AS VARCHAR(6)), 6),
    'BUS' + RIGHT('000' + CAST((n % 5) + 1 AS VARCHAR(3)), 3),
    CASE n % 3 WHEN 0 THEN 'order' WHEN 1 THEN 'inventory' ELSE 'product' END,
    DATEADD(SECOND, -n * 10, '2025-10-01 00:00:00'),
    DATEADD(SECOND, -n * 10 + 5, '2025-10-01 00:00:00'),
    CASE WHEN n % 100 = 0 THEN 'failed' ELSE 'success' END,
    CASE WHEN n % 100 = 0 THEN 0 ELSE 10 END,
    CASE WHEN n % 100 = 0 THEN 1 ELSE 0 END,
    CASE WHEN n % 100 = 0 THEN N'Timeout khi đồng bộ API sàn TMĐT' ELSE NULL END
FROM Nums
WHERE NOT EXISTS (SELECT 1 FROM SyncLog WHERE sync_id = 'SYN_TEST_000001');
GO

DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- 1. Truy vấn TRƯỚC khi có Filtered Index (Clustered Index Scan):
SELECT sync_id, business_id, sync_type, started_at, error_count, error_message
FROM SyncLog
WHERE status      = 'failed'
  AND business_id = 'BUS001'
  AND sync_type   = 'order'
ORDER BY started_at DESC;

-- 2. Tạo Filtered Index chỉ đánh chỉ mục cho các dòng bị lỗi (status = 'failed'):
CREATE NONCLUSTERED INDEX idx_SyncLog_Failed_Filtered
ON SyncLog(business_id ASC, sync_type ASC, started_at DESC)
INCLUDE (error_count, error_message)
WHERE status = 'failed';
GO

DBCC DROPCLEANBUFFERS;

-- 3. Truy vấn SAU khi có Filtered Index (Index Seek):
SELECT sync_id, business_id, sync_type, started_at, error_count, error_message
FROM SyncLog
WHERE status      = 'failed'
  AND business_id = 'BUS001'
  AND sync_type   = 'order'
ORDER BY started_at DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/*
DROP INDEX IF EXISTS idx_Orders_Business_Status_Date ON Orders;
DROP INDEX IF EXISTS idx_SyncLog_Failed_Filtered ON SyncLog;
DELETE FROM Orders  WHERE order_id LIKE 'ORD_TEST_%';
DELETE FROM SyncLog WHERE sync_id  LIKE 'SYN_TEST_%';
*/

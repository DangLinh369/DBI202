--CREATE TABLE
--DROP DATABASE DBI_GROUP_7
--CREATE DATABASE DBI_GROUP_7
USE DBI_GROUP_7;
GO

DROP TABLE IF EXISTS FulfillmentTask;
DROP TABLE IF EXISTS OrderGroupOrder;
DROP TABLE IF EXISTS Shipment;
DROP TABLE IF EXISTS Package;
DROP TABLE IF EXISTS AIRecommendation;
DROP TABLE IF EXISTS FulfillmentProgress;
DROP TABLE IF EXISTS Fulfillment;
DROP TABLE IF EXISTS OrderGroup;
DROP TABLE IF EXISTS OrderItemSnapshot;
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS CustomerAddress;
DROP TABLE IF EXISTS WarehouseStaff;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS PackagingMaterial;
DROP TABLE IF EXISTS SyncLog;
DROP TABLE IF EXISTS Warehouse;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Business;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Location;

CREATE TABLE Location
(
  postal_code NVARCHAR(20) NOT NULL,
  province_city NVARCHAR(255) NOT NULL,
  country NVARCHAR(255) NOT NULL,
  PRIMARY KEY (postal_code)
);

CREATE TABLE Business
(
  business_id NVARCHAR(50) NOT NULL,
  tax_code NVARCHAR(50) NOT NULL,
  name NVARCHAR(255) NOT NULL,
  email NVARCHAR(255) NOT NULL,
  phone NVARCHAR(255) NOT NULL,
  address NVARCHAR(1000) NOT NULL,
  logo NVARCHAR(255),
  status NVARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (business_id),
  UNIQUE (tax_code)
);

CREATE TABLE Customer
(
  customer_id NVARCHAR(50) NOT NULL,
  external_customer_id NVARCHAR(50) NOT NULL,
  name NVARCHAR(255) NOT NULL,
  email NVARCHAR(255) NOT NULL,
  phone_number NVARCHAR(255) NOT NULL,
  default_shipping_address NVARCHAR(255) NOT NULL,
  note NVARCHAR(1000),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (customer_id),
  UNIQUE (external_customer_id)
);

CREATE TABLE CustomerAddress
(
  address_id NVARCHAR(50) NOT NULL,
  address_type NVARCHAR(50) NOT NULL,
  recipient_name NVARCHAR(255) NOT NULL,
  phone NVARCHAR(255) NOT NULL,
  street NVARCHAR(255) NOT NULL,
  ward NVARCHAR(255) NOT NULL,
  district NVARCHAR(255) NOT NULL,
  customer_id NVARCHAR(50) NOT NULL,
  postal_code NVARCHAR(20) NOT NULL,
  PRIMARY KEY (address_id),
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  FOREIGN KEY (postal_code) REFERENCES Location(postal_code)
);

CREATE TABLE Warehouse
(
  warehouse_id NVARCHAR(50) NOT NULL,
  name NVARCHAR(255) NOT NULL,
  address NVARCHAR(1000) NOT NULL,
  contact_name NVARCHAR(255),
  phone NVARCHAR(255) NOT NULL,
  operating_hours NVARCHAR(255),
  capacity INT NOT NULL,
  status NVARCHAR(50) NOT NULL,
  business_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (warehouse_id),
  FOREIGN KEY (business_id) REFERENCES Business(business_id),
  UNIQUE (name)
);

CREATE TABLE Product
(
  product_id NVARCHAR(50) NOT NULL,
  sku NVARCHAR(255) NOT NULL,
  name NVARCHAR(255) NOT NULL,
  description NVARCHAR(1000),
  category NVARCHAR(255) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  currency NVARCHAR(50) NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  length DECIMAL(10,2) NOT NULL,
  width DECIMAL(10,2) NOT NULL,
  height DECIMAL(10,2) NOT NULL,
  is_fragile NVARCHAR(10) NOT NULL,
  special_handling NVARCHAR(255),
  status NVARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  business_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (product_id),
  FOREIGN KEY (business_id) REFERENCES Business(business_id),
  UNIQUE (sku)
);

CREATE TABLE Orders
(
  order_id NVARCHAR(50) NOT NULL,
  external_order_id NVARCHAR(50) NOT NULL,
  order_date DATETIME NOT NULL,
  status NVARCHAR(50) NOT NULL,
  payment_status NVARCHAR(50) NOT NULL,
  payment_method NVARCHAR(50) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  shipping_fee DECIMAL(10,2) NOT NULL,
  tax DECIMAL(10,2) NOT NULL,
  discount DECIMAL(10,2) NOT NULL,
  currency NVARCHAR(50) NOT NULL,
  note NVARCHAR(1000),
  sync_status NVARCHAR(50) NOT NULL,
  synced_at DATETIME,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  customer_id NVARCHAR(50) NOT NULL,
  business_id NVARCHAR(50) NOT NULL,
  shipping_address_id NVARCHAR(50) NOT NULL,
  billing_address_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (order_id),
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  FOREIGN KEY (business_id) REFERENCES Business(business_id),
  FOREIGN KEY (shipping_address_id) REFERENCES CustomerAddress(address_id),
  FOREIGN KEY (billing_address_id) REFERENCES CustomerAddress(address_id),
  UNIQUE (external_order_id)
);

CREATE TABLE OrderItem
(
  order_item_id NVARCHAR(50) NOT NULL,
  external_item_id NVARCHAR(50) NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  discount DECIMAL(10,2) NOT NULL,
  tax DECIMAL(10,2) NOT NULL,
  status NVARCHAR(50) NOT NULL,
  order_id NVARCHAR(50) NOT NULL,
  product_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (order_item_id),
  FOREIGN KEY (order_id) REFERENCES Orders(order_id),
  FOREIGN KEY (product_id) REFERENCES Product(product_id),
  UNIQUE (external_item_id)
);

CREATE TABLE OrderItemSnapshot
(
  weight DECIMAL(10,2) NOT NULL,
  dimensions NVARCHAR(255) NOT NULL,
  special_handling NVARCHAR(255),
  order_item_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (order_item_id),
  FOREIGN KEY (order_item_id) REFERENCES OrderItem(order_item_id)
);

CREATE TABLE OrderGroup
(
  group_id NVARCHAR(50) NOT NULL,
  group_criteria NVARCHAR(255),
  status NVARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  warehouse_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (group_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

CREATE TABLE OrderGroupOrder
(
  group_id NVARCHAR(50) NOT NULL,
  order_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (group_id, order_id),
  FOREIGN KEY (group_id) REFERENCES OrderGroup(group_id),
  FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

CREATE TABLE SyncLog
(
  sync_id NVARCHAR(50) NOT NULL,
  sync_type NVARCHAR(50) NOT NULL,
  started_at DATETIME,
  finished_at DATETIME,
  status NVARCHAR(50) NOT NULL,
  success_count INT NOT NULL,
  error_count INT NOT NULL,
  error_message NVARCHAR(1000),
  business_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (sync_id),
  FOREIGN KEY (business_id) REFERENCES Business(business_id)
);

CREATE TABLE PackagingMaterial
(
  material_id NVARCHAR(50) NOT NULL,
  name NVARCHAR(255) NOT NULL,
  material_type NVARCHAR(50) NOT NULL,
  dimensions NVARCHAR(255) NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  cost_per_unit DECIMAL(10,2) NOT NULL,
  eco_friendly NVARCHAR(10) NOT NULL,
  recyclable NVARCHAR(10) NOT NULL,
  stock_quantity INT NOT NULL,
  supplier NVARCHAR(255),
  max_weight_capacity DECIMAL(10,2) NOT NULL,
  status NVARCHAR(50) NOT NULL,
  business_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (material_id),
  FOREIGN KEY (business_id) REFERENCES Business(business_id),
  UNIQUE (name)
);

CREATE TABLE Inventory
(
  inventory_id NVARCHAR(50) NOT NULL,
  quantity_on_hand INT NOT NULL,
  quantity_reserved INT NOT NULL,
  reorder_level INT NOT NULL,
  shelf_location NVARCHAR(255),
  last_counted_at DATETIME,
  updated_at DATETIME NOT NULL,
  product_id NVARCHAR(50) NOT NULL,
  warehouse_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (inventory_id),
  FOREIGN KEY (product_id) REFERENCES Product(product_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id)
);

CREATE TABLE WarehouseStaff
(
  staff_id NVARCHAR(50) NOT NULL,
  email NVARCHAR(255) NOT NULL,
  full_name NVARCHAR(255) NOT NULL,
  phone NVARCHAR(255) NOT NULL,
  password_hash NVARCHAR(255) NOT NULL,
  staff_role NVARCHAR(255) NOT NULL,
  status NVARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  warehouse_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (staff_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  UNIQUE (email)
);

CREATE TABLE Fulfillment
(
  fulfillment_id NVARCHAR(50) NOT NULL,
  status NVARCHAR(50) NOT NULL,
  priority INT NOT NULL,
  start_time DATETIME,
  completed_time DATETIME,
  note NVARCHAR(1000),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  order_id NVARCHAR(50) NOT NULL,
  warehouse_id NVARCHAR(50) NOT NULL,
  assigned_staff_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (fulfillment_id),
  FOREIGN KEY (order_id) REFERENCES Orders(order_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
  FOREIGN KEY (assigned_staff_id) REFERENCES WarehouseStaff(staff_id)
);

CREATE TABLE FulfillmentTask
(
  task_id NVARCHAR(50) NOT NULL,
  task_type NVARCHAR(50) NOT NULL,
  sequence INT NOT NULL,
  status NVARCHAR(50) NOT NULL,
  started_at DATETIME,
  completed_at DATETIME,
  note NVARCHAR(1000),
  fulfillment_id NVARCHAR(50) NOT NULL,
  assigned_staff_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (task_id),
  FOREIGN KEY (fulfillment_id) REFERENCES Fulfillment(fulfillment_id),
  FOREIGN KEY (assigned_staff_id) REFERENCES WarehouseStaff(staff_id)
);

CREATE TABLE FulfillmentProgress
(
  progress_id NVARCHAR(50) NOT NULL,
  step NVARCHAR(50) NOT NULL,
  status NVARCHAR(50) NOT NULL,
  event_timestamp DATETIME NOT NULL,
  note NVARCHAR(1000),
  fulfillment_id NVARCHAR(50) NOT NULL,
  updated_by NVARCHAR(50) NOT NULL,
  PRIMARY KEY (progress_id),
  FOREIGN KEY (fulfillment_id) REFERENCES Fulfillment(fulfillment_id),
  FOREIGN KEY (updated_by) REFERENCES WarehouseStaff(staff_id)
);

CREATE TABLE AIRecommendation
(
  recommendation_id NVARCHAR(50) NOT NULL,
  box_quantity INT NOT NULL,
  est_length DECIMAL(10,2) NOT NULL,
  est_width DECIMAL(10,2) NOT NULL,
  est_height DECIMAL(10,2) NOT NULL,
  est_weight DECIMAL(10,2) NOT NULL,
  packing_sequence NVARCHAR(1000) NOT NULL,
  void_ratio DECIMAL(10,2) NOT NULL,
  is_anomaly NVARCHAR(10) NOT NULL,
  approval_status NVARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  fulfillment_id NVARCHAR(50) NOT NULL,
  recommended_box_id NVARCHAR(50) NOT NULL,
  recommended_filler_id NVARCHAR(50) NOT NULL,
  approved_by NVARCHAR(50) NOT NULL,
  PRIMARY KEY (recommendation_id),
  FOREIGN KEY (fulfillment_id) REFERENCES Fulfillment(fulfillment_id),
  FOREIGN KEY (recommended_box_id) REFERENCES PackagingMaterial(material_id),
  FOREIGN KEY (recommended_filler_id) REFERENCES PackagingMaterial(material_id),
  FOREIGN KEY (approved_by) REFERENCES WarehouseStaff(staff_id)
);

CREATE TABLE Package
(
  package_id NVARCHAR(50) NOT NULL,
  package_type NVARCHAR(50) NOT NULL,
  length DECIMAL(10,2) NOT NULL,
  width DECIMAL(10,2) NOT NULL,
  height DECIMAL(10,2) NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  estimated_cost DECIMAL(10,2) NOT NULL,
  status NVARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  fulfillment_id NVARCHAR(50) NOT NULL,
  recommendation_id NVARCHAR(50) NOT NULL,
  material_id NVARCHAR(50) NOT NULL,
  PRIMARY KEY (package_id),
  FOREIGN KEY (fulfillment_id) REFERENCES Fulfillment(fulfillment_id),
  FOREIGN KEY (recommendation_id) REFERENCES AIRecommendation(recommendation_id),
  FOREIGN KEY (material_id) REFERENCES PackagingMaterial(material_id)
);

CREATE TABLE Shipment
(
  shipment_id NVARCHAR(50) NOT NULL,
  tracking_number NVARCHAR(255) NOT NULL,
  carrier_name NVARCHAR(255) NOT NULL,
  barcode_data NVARCHAR(255) NOT NULL,
  qr_code_data NVARCHAR(255) NOT NULL,
  shipping_label_url NVARCHAR(255) NOT NULL,
  packing_slip_url NVARCHAR(255) NOT NULL,
  manifest_code NVARCHAR(255) NOT NULL,
  estimated_shipping_fee DECIMAL(10,2) NOT NULL,
  actual_shipping_fee DECIMAL(10,2) NOT NULL,
  pickup_scheduled_at DATETIME,
  shipped_at DATETIME,
  delivered_at DATETIME,
  shipping_status NVARCHAR(50) NOT NULL,
  package_id NVARCHAR(50) NOT NULL,
  managed_by NVARCHAR(50) NOT NULL,
  PRIMARY KEY (shipment_id),
  FOREIGN KEY (package_id) REFERENCES Package(package_id),
  FOREIGN KEY (managed_by) REFERENCES WarehouseStaff(staff_id),
  UNIQUE (tracking_number)
);
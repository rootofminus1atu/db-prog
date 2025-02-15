-- table type for order details provided to the master sproc
CREATE TYPE OrderDetailsType AS TABLE(
    ProductID INT NOT NULL,
    OrderQty SMALLINT NOT NULL
)

-- sproc to calculate discount
CREATE PROCEDURE CalculateProductDiscount
    @ECustomerID INT,
    @EProductID INT,
    @EOrderQty SMALLINT,
    @Discount DECIMAL(5,2) OUTPUT
AS
BEGIN
    -- IF this product is ordered this month, discount allowed

    -- qty is at least half the average qty for any other customer, AKA:
    -- get the quantities for this product from anybody else this month too
    -- if above half 

    -- IF this product is ordered this month, discount allowed

    -- qty is at least half the average qty for any other customer, AKA:
    -- get the quantities for this product from anybody else this month too
    -- do a check for any/avg combined, but in which order?

    -- C1: 90 - this to check out
    -- C2: 150
    -- C3: 250

    -- avg = (150 + 250) / 2 = 200

    -- check if C1's is above or below half the average 

    -- 90 < 200/2

    -- so this one does NOT get a discount

    -- if he ordered 110, he WOULD get a discount


    -- calculation logic, return the discount
END

-- sproc to insert an order
CREATE PROCEDURE InsertOrder
    @ECustomerID INT, 
    @EPurchaseOrderID INT,
    @OrderNo INT OUTPUT
AS
BEGIN TRY
    INSERT INTO dbo.OrderTBL 
        (CustomerID, OrderDate, PurchaseOrderID)
    VALUES 
        (@ECustomerID, GETDATE(), @EPurchaseOrderID)
    
    SELECT @OrderNo = SCOPE_IDENTITY()
END TRY
BEGIN CATCH
    ;THROW
END CATCH

-- sproc to insert order details
CREATE PROCEDURE InsertOrderDetails
    @OrderDetails OrderDetailsWithPriceType READONLY
AS
BEGIN TRY
    INSERT INTO dbo.OrderDetailsTBL 
        (OrderNo, ProductID, Price, QuantityOrdered, Discount)
    SELECT 
        OrderNo, 
        ProductID, 
        UnitPrice, 
        OrderQty, 
        (UnitPrice * OrderQty * (CalculatedDiscount/100.0))
    FROM @OrderDetails
END TRY
BEGIN CATCH
    THROW;
END CATCH

-- master sproc
CREATE PROCEDURE ProcessMasterOrder
    @ECustomerID INT, 
    @EPurchaseOrderID INT, 
    @EOrderDetails OrderDetailsType READONLY
AS
BEGIN
    DECLARE @ICreditLimit MONEY
    DECLARE @ITotalOrderCost MONEY
    DECLARE @IStockAvailability INT
    DECLARE @IOrderNo INT

    -- reads
    SELECT @ICreditLimit = CreditLimit
    FROM dbo.CustomerTBL
    WHERE CustomerID = @CustomerID

    SELECT @IStockAvailability = COUNT(*)
    FROM dbo.ProductTBL p
    JOIN @OrderDetails od ON p.ProductID = od.ProductID
    WHERE ISNULL(p.Quantity, 0) < od.OrderQty

    -- business logic checks
    IF @ICreditLimit < @ITotalOrderCost
    BEGIN
        THROW 50001, 'Not enough credits', 1
    END

    IF @IStockAvailability > 0
    BEGIN
        THROW 50002, 'Not enough in stock', 1
    END

    -- insert the order
    EXEC dbo.InsertOrder 
        @CustomerID, 
        @PurchaseOrderID, 
        @OrderNo = @OrderNo OUTPUT

    -- calculate discounts

    -- insert order details

    PRINT 'Order successfully processed'
END
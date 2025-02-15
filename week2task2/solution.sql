
CREATE PROC Name
    @ECustomerID INT,
    @EPurchaseOrderNumber INT,
    -- arr of [ProductID, Quantity]
AS
BEGIN
    DECLARE @ICreditLimit INT;

    -- if TotalCost > CustomerCreditLimit, reject
    SELECT @ICreditLimit = CreditLimit
	FROM CustomerTBL
	WHERE CustomerId = @ECustomerId;

    -- if OrderQuantity > QuantityInStock, reject
    -- each Product, get its Quantity
    -- compare against the compared OrderQuantity
    -- if any of them >, then reject

    SELECT 


    -- all ok here
    -- insert the order into OrderTBL, give back OrderNo
    -- insert details into OrderDetailsTBL with the OrderNo from above

    -- if date = this month calc discount
    -- if TotalOrderQuantityForMonth > 1/2 AVG(TotalOrderQuantity for all customers), proceed
    -- match and get discount amount





END
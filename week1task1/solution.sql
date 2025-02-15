-- task:
-- create a proc that will tell a customer if they have enough credits to order X amount of a particular product
--
CREATE PROC Name
	@ECustomerId INT,
	@EProductId INT,
	@EAmount INT
AS
BEGIN
	DECLARE @ICreditLimit INT;
	DECLARE @IProductPrice INT;
	DECLARE @ITotalPrice INT;
	DECLARE @IMessage VARCHAR(255);
	
	-- find the credit limit for @ECustomerId
	SELECT @ICreditLimit = CreditLimit
	FROM CustomerTBL
	WHERE CustomerId = @ECustomerId;
	
	-- find the price for @EProductId
	SELECT @IProductPrice = Price
	FROM ProductTBL
	WHERE ProductId = @EProductId;
	
	-- calculate the total price
	SET @ITotalPrice = Price * @EAmount;
	
	-- compare them
	SET @IMessage = IIF(@ITotalPrice > @ICreditLimit, 'You dont have enough credits', 'You have enough credits');
	
	-- return true/false as a message
	SELECT @IMessage;
END
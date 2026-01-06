CREATE TYPE ExcursionList AS TABLE(
    VisitorFirstName VARCHAR(50),
    VisitorLastName VARCHAR(50),
    MobilePhoneNumber CHAR(10),
    ExcursionID INT
)

-- EXMAPLE TEST

DECLARE @VisitorsList AS ExcursionList;

INSERT INTO @VisitorsList (VisitorFirstName, VisitorLastName, MobilePhoneNumber, ExcursionID)
VALUES 
    ('A', 'G', 1234567890, 10),
	('R', 'G', 1234567890, 10);

EXEC ExamMaster @VisitorsList;
-- SHOULD FAIL BECAUSE 10 DOES NOT EXIST



CREATE PROCEDURE InsertBooking
    @EVisitors ExcursionList READONLY
AS
BEGIN
    INSERT INTO ExcrsionDetailsTBL (
        VisitorFirstName,
        VisitorLastName,
        MobilePhoneNumber,
        ExcursionID
    )
    SELECT 
        VisitorFirstName,
        VisitorLastName,
        MobilePhoneNumber,
        ExcursionID
    FROM @EVisitors;
END



CREATE PROCEDURE UpdateRevenue
    @ERevenueToAdd DECIMAL(10, 2),
    @EExhibitID INT
AS
BEGIN
    UPDATE ExhibitTBL
    SET ExhibitRevenue = ISNULL(ExhibitRevenue, 0) + @ERevenueToAdd
    WHERE ExhibitID = @EExhibitID;
END

CREATE TYPE ExcursionListMinimal AS TABLE(
    VisitorFirstName VARCHAR(50)
)



ALTER PROCEDURE ExamMaster
    @EVisitors ExcursionList READONLY
AS
BEGIN
    -- variables
    DECLARE @ILocation VARCHAR(50);
    DECLARE @IStaffPerPerson INT;
    DECLARE @IStaffAssigned INT;
    DECLARE @IExhibitID INT;
    DECLARE @IVisitorsCount INT;
    DECLARE @ITicketPrice DECIMAL(10, 2);
	DECLARE @ITotalPrice DECIMAL(10, 2);
	DECLARE @IExcursionID INT;

    DECLARE @IRetriesCount INT = 0;
    DECLARE @IAllowedRetries INT = 5;
    DECLARE @ISuccess BIT = 0;

    WHILE @IRetriesCount < @IAllowedRetries AND @ISuccess = 0
    BEGIN
        BEGIN TRY 
            SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
            BEGIN TRANSACTION;
            
            -- all reads
            SELECT TOP 1 @IExcursionID = ExcursionID FROM @EVisitors;

            SELECT @ILocation = Location FROM dbo.ExcursionTBL  AS ec
            INNER JOIN dbo.ExhibitTBL AS eh ON eh.ExhibitID = ec.ExhibitID
            WHERE ec.ExcursionID = @IExcursionID;

            SELECT @IExhibitID = ExhibitID 
            FROM ExcursionTBL 
            WHERE ExcursionID = @IExcursionID;

            SELECT @IVisitorsCount = COUNT(*) FROM @EVisitors;

            SELECT @IStaffAssigned = COUNT(*) FROM ExhibitTBL AS e
            INNER JOIN ExhibitionStaffTBL AS es ON e.ExhibitID = es.ExhibitID
            WHERE e.ExhibitID = @IExhibitID;

            SELECT @ITicketPrice = Price FROM ExcursionTBL AS e
            INNER JOIN TicketTBL AS t ON e.TicketID = t.TicketID
            WHERE ExcursionID = 5;

            -- all logic

            -- RULE 1
            -- case location staff count

            SET @IStaffPerPerson = CASE @ILocation
                WHEN 'Main Hall' THEN 7
                WHEN 'Gallery A' THEN 5
                WHEN 'Exhibition Room B' THEN 3
                WHEN 'North Wing' THEN 2
                ELSE NULL
            END 
            IF @IStaffPerPerson IS NULL
            BEGIN
                ;THROW 50001, 'This exhibit is in a location with no staff members, work is still being done, try again in a couple days.', 1;
            END
            IF @IStaffAssigned <= CEILING(@IVisitorsCount / @IStaffPerPerson)
            BEGIN
                ;THROW 50002, 'There are too many visitors and not enough staff assigned for that excursion', 1;
            END;

            -- RULE 2 
            -- add revenue to total
            SET @ITotalPrice = @ITicketPrice * @IVisitorsCount;

            -- all mutations

            -- insert the booking
            BEGIN TRY 
                EXEC InsertBooking @EVisitors;
            END TRY 
            BEGIN CATCH 
                ;THROW
            END CATCH

            -- update the revenue column
            BEGIN TRY 
                EXEC UpdateRevenue @ITotalPrice, @IExhibitID;
            END TRY 
            BEGIN CATCH
                ;THROW
            END CATCH


            COMMIT TRANSACTION;
            SET @ISuccess = 1;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @IRetriesCount = @IRetriesCount + 1;

            IF @IRetriesCount = @IAllowedRetries
            BEGIN 
                DECLARE @ErrorNumber INT = ERROR_NUMBER();
                
                IF @ErrorNumber IN (50001, 50002)
                    THROW;
                ELSE
                    THROW 50003, 'The system is busy, please try again later.', 1;
            END
        END CATCH
    END

    SELECT CONCAT(
        'Visitors admitted and revenue increased by ',
        @ITotalPrice
    ) AS SuccessMessage
END




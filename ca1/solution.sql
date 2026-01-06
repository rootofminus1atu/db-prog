-- master sproc
USE S00240122
GO

CREATE PROC ExamMaster
    @EPatientFirstName VARCHAR(35),
    @EPatientLastName VARCHAR(35),
    @EPatientDOB DATE,
    @EPatientCovidStatus CHAR(8),
    @EWardID INT,
    @ECareTeamID INT
AS
BEGIN
    DECLARE @IDateNow DATE = GETDATE();
    DECLARE @IPatientFirstNameCapitalized VARCHAR(35) = dbo.CapitalizeFirstLetter(@EPatientFirstName);
    DECLARE @IPatientLastNameCapitalized VARCHAR(35) = dbo.CapitalizeFirstLetter(@EPatientLastName);
    DECLARE @IPatientFullName VARCHAR(71) = CONCAT(@IPatientFirstNameCapitalized, ' ', @IPatientLastNameCapitalized);
    DECLARE @NewPatientID INT;

    DECLARE @INumberOfPatients INT;
    DECLARE @IWardCap INT;
    DECLARE @IWardStatusUpdate VARCHAR(20) = NULL;
    DECLARE @IWardSpeciality VARCHAR(20);

    DECLARE @IPatientAge INT = DATEDIFF(YEAR, @EPatientDOB, @IDateNow);

    DECLARE @INurseToAdd INT;
    DECLARE @INursesAmount INT;
    DECLARE @IDoctorsAmount INT;

    DECLARE @INurses TABLE (
        NurseID INT,
        NurseName VARCHAR(50),
        NurseSpeciality VARCHAR(50),
        NurseWard INT,
        COVID19Vacinated BIT
    );

    DECLARE @IDoctors TABLE (
        DoctorID INT,
        DoctorName VARCHAR(50),
        DoctorSpeciality VARCHAR(50),
        DoctorBleepID CHAR(10),
        COVID19Vacinated BIT
    );

    DECLARE @ICandidateNurses TABLE (
        NurseID INT,
        NurseName VARCHAR(50),
        NurseSpeciality VARCHAR(50),
        NurseWard INT,
        COVID19Vacinated BIT,
        ActiveTeams INT
    );

    DECLARE @ErrorMsg VARCHAR(200);

    -- PERFORM ALL READS
    SELECT @INumberOfPatients = COUNT(*)
    FROM PatientTBL
    WHERE PatientWard = @EWardID;

    SELECT 
        @IWardCap = WardCapacity,
        @IWardSpeciality = WardSpeciality
    FROM WarDTBL
    WHERE WardID = @EWardID;

    INSERT INTO @INurses
    SELECT n.NurseID, n.NurseName, n.NurseSpeciality, n.NurseWard, n.COVID19Vacinated
    FROM NurseTBL AS n 
    INNER JOIN NurseCareTeamMembersTBL AS nct ON n.NurseID = nct.MemberID
    WHERE nct.CareTeamID = @ECareTeamID AND nct.CurrentMember = 1;

    INSERT INTO @IDoctors
    SELECT d.DoctorID, d.DoctorName, d.DoctorSpeciality, d.DoctorBleepID, d.COVID19Vacinated
    FROM DoctorTBL AS d
    INNER JOIN DoctorCareTeamMembersTBL AS dct ON d.DoctorID = dct.MemberID
    WHERE dct.CareTeamID = @ECareTeamID AND dct.CurrentMember = 1;

    INSERT INTO @ICandidateNurses
    SELECT 
        n.NurseID, 
        n.NurseName, 
        n.NurseSpeciality, 
        n.NurseWard, 
        n.COVID19Vacinated,
        COUNT(nct.MemberID) AS ActiveTeams
    FROM NurseTBL n
    LEFT JOIN NurseCareTeamMembersTBL nct 
        ON n.NurseID = nct.MemberID 
        AND nct.CurrentMember = 1
    WHERE n.NurseID NOT IN (SELECT NurseID FROM @INurses)
    GROUP BY 
        n.NurseID,
        n.NurseName,
        n.NurseSpeciality,
        n.NurseWard,
        n.COVID19Vacinated;

    SET @INursesAmount = (SELECT COUNT(*) FROM @INurses);
    SET @IDoctorsAmount = (SELECT COUNT(*) FROM @IDoctors);



    -- PERFORM ALL LOGIC

    -- WARD CAP RULES
    
    -- if monday..=friday - cannot assign patient to the ward IF the number of patients exceeds the capacity
    -- monday = 2, friday = 6
    IF (DATEPART(WEEKDAY, @IDateNow) BETWEEN 2 AND 6) AND @INumberOfPatients >= @IWardCap
    BEGIN
		SET @ErrorMsg = 'This ward is full - find a different ward for Patient ' + @IPatientFullName
        ;THROW 50001, @ErrorMsg, 1;
    END;

    -- if weekend - can assign, but cannot exceepd 120% capacity, if that occurs ward status set to OVERFLOW, anything above 120% UNACCEPTABLE
    IF DATEPART(WEEKDAY, @IDateNow) IN (1, 7)
    BEGIN
        IF @INumberOfPatients >= 1.2 * @IWardCap
        BEGIN
            SET @ErrorMsg = 'This ward is overflowing - find a different ward for Patient ' + @IPatientFullName;
            ;THROW 50002, @ErrorMsg, 1;
        END
        ELSE IF @INumberOfPatients >= @IWardCap
        BEGIN
            SET @IWardStatusUpdate = 'OVERFLOW'
        END
    END


    -- WARD AGE RULES
    -- match on age for kids/teens, ward must be specialized for that age
    IF @IPatientAge <= 13 AND (@IWardSpeciality NOT LIKE '%Paediatric13%' AND @IWardSpeciality NOT LIKE '%Paeds13%')
    BEGIN 
        SET @ErrorMsg = 'Patients 13 and under must be assigned to a Paediatrics13/Paeds13 ward';
        ;THROW 50003, @ErrorMsg, 1;
    END

    IF @IPatientAge BETWEEN 13 AND 14 AND (@IWardSpeciality NOT LIKE '%Paediatric15%' AND @IWardSpeciality NOT LIKE '%Paeds15%')
    BEGIN
        SET @ErrorMsg = 'Patients aged 13-14 must be assigned to a Paediatrics15/Paeds15 ward';
        ;THROW 50004, @ErrorMsg, 1;
    END

    IF @IPatientAge BETWEEN 15 AND 18 AND (@IWardSpeciality NOT LIKE '%Paediatric%' AND @IWardSpeciality NOT LIKE '%Paeds%')
    BEGIN
        SET @ErrorMsg = 'Patients aged 15-18 must be assigned to a Paediatrics/Paeds ward';
        ;THROW 50005, @ErrorMsg, 1;
    END

    IF @IPatientAge > 18 AND (@IWardSpeciality LIKE '%Paediatric%' OR @IWardSpeciality LIKE '%Paeds%')
    BEGIN
        SET @ErrorMsg = 'Adult patients must not be assigned to a Paediatrics/Paeds ward';
        ;THROW 50006, @ErrorMsg, 1;
    END


    -- CARE TEAM RULES

    IF @IDoctorsAmount < 1
    BEGIN
        SET @ErrorMsg = 'This care team has no current doctor, cannot proceed further.';
        ;THROW 50008, @ErrorMsg, 1;
    END
    
    IF @INursesAmount = 0
    BEGIN
        SET @ErrorMsg = 'This care team has no nurses, cannot proceed further.';
        ;THROW 50007, @ErrorMsg, 1;
    END

    IF @INursesAmount = 1
    BEGIN
        IF @EPatientCovidStatus IN ('positive', 'unknown')
        BEGIN
            SELECT TOP 1 @INurseToAdd = NurseID
            FROM @ICandidateNurses
            WHERE (NurseWard = @EWardID AND ActiveTeams < 3)
                OR (NurseWard IS NULL AND COVID19Vacinated = 1 AND ActiveTeams = 0)
            ORDER BY NEWID()
        END
        ELSE IF @EPatientCovidStatus = 'negative'
        BEGIN
            SELECT TOP 1 @INurseToAdd = NurseID
            FROM @ICandidateNurses
            WHERE (NurseWard = @EWardID AND ActiveTeams < 3)
                OR (NurseWard IS NULL AND ActiveTeams = 0)
            ORDER BY NEWID()
        END

        IF @INurseToAdd IS NULL
        BEGIN
            SET @ErrorMsg = 'No nurse found to assign to the care team.';
        ;THROW 50009, @ErrorMsg, 1;
        END
    END

    DECLARE @DoctorSpecialityMatches INT;
    DECLARE @NurseSpecialityMatches INT;

    SELECT @DoctorSpecialityMatches = COUNT(*)
    FROM @IDoctors
    WHERE RIGHT(DoctorSpeciality, 3) = LEFT(@IWardSpeciality, 3);

    IF @DoctorSpecialityMatches = 0
    BEGIN
        SET @ErrorMsg = 'No active doctor in the care team matches the speciality requirements.';
        ;THROW 50010, @ErrorMsg, 1;
    END

    SELECT @NurseSpecialityMatches = COUNT(*)
    FROM @INurses
    WHERE RIGHT(NurseSpeciality, 3) = LEFT(@IWardSpeciality, 3);

    IF @NurseSpecialityMatches = 0
    BEGIN
        SET @ErrorMsg = 'No active nurse in the care team matches the speciality requirements.';
        ;THROW 50011, @ErrorMsg, 1;
    END


    -- PERFORM ALL MUTATIONS

    IF @IWardStatusUpdate IS NOT NULL
    BEGIN
        UPDATE WarDTBL
        SET WardStatus = @IWardStatusUpdate
        WHERE WardID = @EWardID
    END

    -- insert patient
    BEGIN TRY 
        EXEC InsertPatient @EPatientFirstName, @EPatientLastName, @EWardID, @EPatientCovidStatus, @NewPatientID OUTPUT;
    END TRY 
    BEGIN CATCH
        ;THROW
    END CATCH

    -- insert to care team
    BEGIN TRY 
        EXEC InsertToCareTeam @NewPatientID, @ECareTeamID;
    END TRY 
    BEGIN CATCH
        ;THROW
    END CATCH

    -- insert nurse if its not null
    IF @INurseToAdd IS NOT NULL
    BEGIN
        BEGIN TRY 
            EXEC InsertNurse @INurseToAdd, @ECareTeamID;
        END TRY 
        BEGIN CATCH
            ;THROW
        END CATCH
    END



    SELECT CONCAT(
        'Successfully added patient ',
        @IPatientFullName,
        ' to ward ',
        @EWardID,
        ' and care team ',
        @ECareTeamID 
    ) AS SuccessMessage
END


-- SUBSPROCS BELOW

CREATE PROC InsertPatient
    @EPatientFirstName VARCHAR(35),
    @EPatientLastName VARCHAR(35),
    @EWardID INT,
    @EPatientCovidStatus CHAR(8),
    @NewPatientID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        INSERT INTO PatientTBL (PatientFname, PatientLname, PatientWard, PatientDependency, PatientCOVIDStatus)
        VALUES (@EPatientFirstName, @EPatientLastName, @EWardID, NULL, @EPatientCovidStatus);

        SET @NewPatientID = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        ;THROW
    END CATCH
END


-- the ones below are moreso updates tbh
CREATE PROC InsertToCareTeam
    @EPatientID INT,
    @ECareTeamID INT
AS
BEGIN
    BEGIN TRY
        UPDATE CareTeamTBL
        SET PatientID = @EPatientID
        WHERE CareTeamID = @ECareTeamID
    END TRY
    BEGIN CATCH
        ;THROW
    END CATCH
END


CREATE PROC InsertNurse
    @ENurseID INT,
    @ECareTeamID INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO NurseCareTeamMembersTBL (CareTeamID, MemberID, DateJoined, CurrentMember)
        VALUES (@ECareTeamID, @ENurseID, GETDATE(), 1);
    END TRY
    BEGIN CATCH
        ;THROW
    END CATCH
END


-- helper for capitalizing
CREATE FUNCTION CapitalizeFirstLetter (@Input VARCHAR(100))
RETURNS VARCHAR(100)
AS
BEGIN
    RETURN UPPER(LEFT(@Input, 1)) + LOWER(SUBSTRING(@Input, 2, LEN(@Input)))
END
-- master sproc
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
    DECLARE @INumberOfPatients INT;
    DECLARE @IWardCap INT;
    DECLARE @IWardStatusUpdate VARCHAR(20) = NULL;
    DECLARE @IPatientAge INT = DATEDIFF(YEAR, @EPatientDOB, @IDateNow);
    DECLARE @IWardSpeciality VARCHAR(20);


    -- PERFORM ALL READS
    SELECT @INumberOfPatients = COUNT(*)
    FROM PatientTBL
    WHERE PatientWard = @EWardID;

    SELECT 
        @IWardCap = WardCapacity,
        @IWardSpeciality = WardSpeciality
    FROM WarDTBL
    WHERE WardID = @EWardID;

    -- PERFORM ALL LOGIC

    -- WARD CAP RULES
    
    -- if monday..=friday - cannot assign patient to the ward IF the number of patients exceeds the capacity
    -- monday = 2, friday = 6
    IF (DATEPART(WEEKDAY, @IDateNow) BETWEEN 2 AND 6) AND @INumberOfPatients >= @IWardCap
    BEGIN
        THROW 50001, CONCAT(
            'This ward is full - find a different ward for Patient ',
            @EPatientFirstName,
            ' ',
            @EPatientLastName
        );  -- TODO: substring to make the first/last name correctly cased (pascal case)
    END

    -- if weekend - can assign, but cannot exceepd 120% capacity, if that occurs ward status set to OVERFLOW, anything above 120% UNACCEPTABLE
    IF DATEPART(WEEKDAY, @IDateNow) IN (1, 7)
    BEGIN
        IF @INumberOfPatients >= 1.2 * @IWardCap
        BEGIN
            THROW 50002, CONCAT(
                'This ward is overflowing - find a different
    ward for Patient ',
                @EPatientFirstName,
                ' ',
                @EPatientLastName
            );
        END
        ELSE IF @INumberOfPatients >= @IWardCap
        BEGIN
            SET @IWardStatusUpdate = 'OVERFLOW'
            -- TODO: update the ward's status at the end IF this is not null
        END
    END

    -- WARD AGE RULES
    -- match on age for kids/teens, ward must be specialized for that age
    IF @IPatientAge <= 13 AND (@IWardSpeciality NOT LIKE '%Paediatric13%' AND @IWardSpeciality NOT LIKE '%Paeds13%')
    BEGIN 
        THROW 50003, 'Patients 13 and under must be assigned to a Paediatrics13/Paeds13 ward';
    END

    IF @IPatientAge BETWEEN 13 AND 14 AND (@IWardSpeciality NOT LIKE '%Paediatric15%' AND @IWardSpeciality NOT LIKE '%Paeds15%')
    BEGIN
        THROW 50004, 'Patients aged 13-14 must be assigned to a Paediatrics15/Paeds15 ward';
    END

    IF @IPatientAge BETWEEN 15 AND 18 AND (@IWardSpeciality NOT LIKE '%Paediatric%' AND @IWardSpeciality NOT LIKE '%Paeds%')
    BEGIN
        THROW 50005, 'Patients aged 15-18 must be assigned to a Paediatrics/Paeds ward';
    END

    IF @IPatientAge > 18 AND (@IWardSpeciality LIKE '%Paediatric%' OR @IWardSpeciality LIKE '%Paeds%')
    BEGIN
        THROW 50006, 'Adult patients must not be assigned to a Paediatrics/Paeds ward';
    END


    -- CARE TEAM RULES
    -- a care team must have 1+ doctor and 2+ nurses
    -- IF 1 nurse, add another nurse, based on:
    -- FIND NURSES SUBSPROC?
    -- at least 1 doc and 1 nurse must have the specialty required by that ward

    DECLARE @Nurses TABLE (
        NurseID INT,
        NurseName VARCHAR(50),
        NurseSpeciality VARCHAR(50),
        NurseWard INT,
        COVID19Vacinated BIT
    );

    DECLARE @Doctors TABLE (
        DoctorID INT,
        DoctorName VARCHAR(50),
        DoctorSpeciality VARCHAR(50),
        DoctorBleepID CHAR(10),
        COVID19Vacinated BIT
    );

    INSERT INTO @Nurses
    SELECT n.NurseID, n.NurseName, n.NurseSpeciality, n.NurseWard, n.COVID19Vacinated
    FROM NurseTBL AS n 
    INNER JOIN NurseCareTeamMembersTBL AS nct ON n.NurseID = nct.MemberID
    WHERE nct.CareTeamID = @ECareTeamID AND nct.CurrentMember = TRUE;

    DECLARE @INursesAmount INT = SELECT COUNT(*) FROM @Nurses;
    
    INSERT INTO @Doctors
    SELECT d.DoctorID, d.DoctorName, d.DoctorSpeciality, d.DoctorBleepID, d.COVID19Vacinated
    FROM DoctorTBL AS d
    INNER JOIN DoctorCareTeamMembersTBL AS dct ON d.DoctorID = dct.MemberID
    WHERE dct.CareTeamID = @ECareTeamID AND dct.CurrentMember = TRUE;

    IF @INursesAmount = 0
    BEGIN
        THROW 50007, 'This care team has no nurses, cannot proceed further.'
    END

    IF @INursesAmount = 1
    BEGIN
        SELECT n.*
        FROM NurseTBL AS n 
        INNER JOIN NurseCareTeamMembersTBL AS nct ON n.NurseID = nct.MemberID
        WHERE n.NurseWarD = @EWardID
        GROUP BY n.NurseID
        HAVING ActiveTeams < 3
        -- continue this and check this, prob not correct
    END


    -- CALL THE SUBSPROCS

END



CREATE PROC InsertPatient 
AS
BEGIN
    -- create a new patient
END



-- the ones below are moreso updates tbh

CREATE PROC InsertToCareTeam
AS
BEGIN
    -- assign the patient to the relevant care team
END

CREATE PROC InsertNurse
AS
BEGIN
    -- insert nurse into the relevant care team
END
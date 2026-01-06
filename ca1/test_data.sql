
-- adult ward with low capacity (full)
INSERT INTO WarDTBL (WardName, WardManager, WardCapacity, WardSpeciality, WardStatus)
VALUES ('FullWard', 1, 2, 'Adult', NULL);

-- pae ward with overflow allowed
INSERT INTO WarDTBL (WardName, WardManager, WardCapacity, WardSpeciality, WardStatus)
VALUES ('KidsWard', 1, 5, 'Paediatric13', NULL);

-- audult ward with overflow allowed
INSERT INTO WarDTBL (WardName, WardManager, WardCapacity, WardSpeciality, WardStatus)
VALUES ('AdultWard', 1, 5, 'Adult', NULL);


-- pae doctor
INSERT INTO DoctorTBL (DoctorName, DoctorSpeciality, DoctorBleepID, COVID19Vacinated)
VALUES ('Dr. Paediatric', 'General-Pae', 'BLEEP001', 1);

-- adu doctor
INSERT INTO DoctorTBL (DoctorName, DoctorSpeciality, DoctorBleepID, COVID19Vacinated)
VALUES ('Dr. Adult', 'Medicine-Adu', 'BLEEP002', 1);


-- pae nurses
INSERT INTO NurseTBL (NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
VALUES ('Nurse P1', 'Nurse-Pae', NULL, 1),
    ('Nurse P2', 'Nurse-Pae', NULL, 0);

-- adult spec nurses
INSERT INTO NurseTBL (NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
VALUES ('Nurse A1', 'Nurse-Adu', NULL, 1),
    ('Nurse A2', 'Nurse-Adu', NULL, 1); 

-- nurse for covid test rule
INSERT INTO NurseTBL (NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
VALUES ('Nurse Candidate', 'Nurse-Adu', NULL, 1);


INSERT INTO CareTeamTBL (CareTeamID, PatientID, DateFormed, DateFinished)
VALUES (100, NULL, GETDATE(), NULL),
    (101, NULL, GETDATE(), NULL),
    (102, NULL, GETDATE(), NULL),
    (103, NULL, GETDATE(), NULL),
    (104, NULL, GETDATE(), NULL),
    (105, NULL, GETDATE(), NULL),
    (106, NULL, GETDATE(), NULL);

-- full ward, one nurse and doc only
INSERT INTO DoctorCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (100, 1, GETDATE(), 1);
INSERT INTO NurseCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (100, 100000, GETDATE(), 1);

-- for adult ward
INSERT INTO DoctorCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (101, 1, GETDATE(), 1);
INSERT INTO NurseCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (101, 100000, GETDATE(), 1);

-- only nurse, no doctor
INSERT INTO NurseCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (102, 100001, GETDATE(), 1);

-- only 1 doctor, no nurses
INSERT INTO DoctorCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (103, 2, GETDATE(), 1);

-- speciality mismatch for this care team
INSERT INTO DoctorTBL (DoctorName, DoctorSpeciality, DoctorBleepID, COVID19Vacinated)
VALUES ('Dr. Mismatch', 'Some-XYZ', 'BLEEP003', 1);
INSERT INTO NurseTBL (NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
VALUES ('Nurse Mismatch', 'Nurse-XYZ', NULL, 1);
INSERT INTO DoctorCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (104, 3, GETDATE(), 1);
INSERT INTO NurseCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (104, 100002, GETDATE(), 1);

-- only 1 nurse and doctor, nurse has to beadded
INSERT INTO DoctorCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (105, 2, GETDATE(), 1);
INSERT INTO NurseCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (105, 100000, GETDATE(), 1);

-- valid doctors and nurses
INSERT INTO DoctorCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (106, 2, GETDATE(), 1);
INSERT INTO NurseCareTeamMembersTBL (CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES (106, 100001, GETDATE(), 1),
    (106, 100003, GETDATE(), 1);

-- patients that would already be occupying some wards
INSERT INTO PatientTBL (PatientFname, PatientLname, PatientWarD, PatientDependency, PatientCOVIDStatus)
VALUES ('Alice', 'Full', 1, NULL, 'negative'),
    ('Bob', 'Full', 1, NULL, 'negative'),
    ('P1', 'Overflow', 2, NULL, 'negative'),
    ('P2', 'Overflow', 2, NULL, 'negative'),
    ('P3', 'Overflow', 2, NULL, 'negative'),
    ('P4', 'Overflow', 2, NULL, 'negative'),
    ('P5', 'Overflow', 2, NULL, 'negative'),
    ('P6', 'Overflow', 2, NULL, 'negative');
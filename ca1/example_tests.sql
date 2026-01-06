-- some example tests possible with the test data

-- age rule test
EXEC ExamMaster 
    @EPatientFirstName = 'Young',
    @EPatientLastName = 'Patient',
    @EPatientDOB = '2025-01-01',
    @EPatientCovidStatus = 'negative',
    @EWardID = 3,
    @ECareTeamID = 101;

-- ward when full test (on weekdays)
EXEC ExamMaster 
    @EPatientFirstName = 'Test',
    @EPatientLastName = 'Full',
    @EPatientDOB = '1990-01-01',
    @EPatientCovidStatus = 'negative',
    @EWardID = 1,
    @ECareTeamID = 100;

-- no doctor in care team
EXEC ExamMaster 
    @EPatientFirstName = 'NoDoc',
    @EPatientLastName = 'Team',
    @EPatientDOB = '1985-05-15',
    @EPatientCovidStatus = 'negative',
    @EWardID = 3,
    @ECareTeamID = 102;

-- speciality not valid
EXEC ExamMaster 
    @EPatientFirstName = 'Spec',
    @EPatientLastName = 'Mismatch',
    @EPatientDOB = '1992-07-07',
    @EPatientCovidStatus = 'negative',
    @EWardID = 3,
    @ECareTeamID = 104;

-- should pass all logic checks
EXEC ExamMaster 
    @EPatientFirstName = 'Valid',
    @EPatientLastName = 'Patient',
    @EPatientDOB = '1985-12-12',
    @EPatientCovidStatus = 'negative',
    @EWardID = 3,
    @ECareTeamID = 106;
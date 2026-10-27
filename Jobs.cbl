       POST-JOB-SECTION SECTION.
           MOVE "--- Post a New Job/Internship ---" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

           INITIALIZE JOBS-RECORD
           MOVE "Enter Job Title:" TO WS-PROMPT
           MOVE 101 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO JO-JOBTITLE

           MOVE "Enter Job Description:" TO WS-PROMPT
           MOVE 101 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO JO-DESCRIPTION

           MOVE "Enter Employer:" TO WS-PROMPT
           MOVE 101 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO JO-EMPLOYER

           MOVE "Enter Location:" TO WS-PROMPT
           MOVE 101 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO JO-LOCATION

           MOVE "Enter Salary (optional):" TO WS-PROMPT
           MOVE 101 TO WS-FIELD-LIMIT
           MOVE 0 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO JO-SALARY

           PERFORM OPEN-JOBS-FOR-POST-SECTION
           WRITE JOBS-RECORD
           IF WS-JOBS-STATUS NOT = "00"
               PERFORM JOB-STORAGE-ERROR-SECTION
           END-IF
           CLOSE JOBS-FILE
           MOVE 0 TO WS-JOBS-OPEN
           IF WS-JOBS-STATUS NOT = "00"
               PERFORM JOB-STORAGE-ERROR-SECTION
           END-IF

           MOVE "Job posted successfully." TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION.

       OPEN-JOBS-FOR-POST-SECTION SECTION.
           OPEN EXTEND JOBS-FILE
           EVALUATE WS-JOBS-STATUS
               WHEN "00"
                   MOVE 1 TO WS-JOBS-OPEN
               WHEN "35"
                   OPEN OUTPUT JOBS-FILE
                   IF WS-JOBS-STATUS = "00"
                       CLOSE JOBS-FILE
                       OPEN EXTEND JOBS-FILE
                       IF WS-JOBS-STATUS = "00"
                           MOVE 1 TO WS-JOBS-OPEN
                       ELSE
                           PERFORM JOB-STORAGE-ERROR-SECTION
                       END-IF
                   ELSE
                       PERFORM JOB-STORAGE-ERROR-SECTION
                   END-IF
               WHEN OTHER
                   PERFORM JOB-STORAGE-ERROR-SECTION
           END-EVALUATE.

       JOB-STORAGE-ERROR-SECTION SECTION.
           MOVE SPACES TO WS-MESSAGE
           STRING "Error: jobs storage failure, status "
               WS-JOBS-STATUS DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           PERFORM FINALIZE-SECTION
           MOVE 1 TO RETURN-CODE
           STOP RUN.

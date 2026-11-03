      * Jobs are append-only. Their one-based record numbers are IDs.
       BROWSE-JOBS-SECTION SECTION.
           MOVE 0 TO WS-BROWSE-DONE
           PERFORM UNTIL WS-BROWSE-DONE = 1
               MOVE "--- Available Job Listings ---" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               MOVE 0 TO WS-JOB-COUNT
               PERFORM OPEN-JOBS-FOR-READ-SECTION
               PERFORM UNTIL END-OF-JOBS-FILE
                   PERFORM READ-NEXT-JOB-SECTION
                   IF NOT END-OF-JOBS-FILE
                       ADD 1 TO WS-JOB-COUNT
                       MOVE WS-JOB-COUNT TO WS-NUMBER-TEXT
                       STRING FUNCTION TRIM(WS-NUMBER-TEXT) ". "
                           FUNCTION TRIM(JO-JOBTITLE) " at "
                           FUNCTION TRIM(JO-EMPLOYER) " ("
                           FUNCTION TRIM(JO-LOCATION) ")"
                           DELIMITED BY SIZE INTO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
                   END-IF
               END-PERFORM
               PERFORM CLOSE-JOBS-READ-SECTION
               IF WS-JOB-COUNT = 0
                   MOVE "No jobs or internships available."
                       TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               END-IF
               MOVE "Enter job number, or 0 to return to Main Menu:"
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM READ-INPUT-SECTION
               EVALUATE TRUE
                   WHEN FUNCTION TRIM(WS-INPUT-LINE) = "0"
                       MOVE 1 TO WS-BROWSE-DONE
                       MOVE "N" TO WS-CONTINUE-FLAG
                   WHEN FUNCTION LENGTH(
                       FUNCTION TRIM(WS-INPUT-LINE)) > 9
                   WHEN FUNCTION TRIM(WS-INPUT-LINE) IS NOT NUMERIC
                       PERFORM INVALID-JOB-SECTION
                   WHEN OTHER
                       COMPUTE WS-SELECTED-JOB = FUNCTION NUMVAL(
                           WS-INPUT-LINE)
                       IF WS-SELECTED-JOB < 1 OR
                           WS-SELECTED-JOB > WS-JOB-COUNT
                           PERFORM INVALID-JOB-SECTION
                       ELSE
                           PERFORM LOAD-SELECTED-JOB-SECTION
                           PERFORM JOB-DETAILS-SECTION
                       END-IF
               END-EVALUATE
           END-PERFORM.

       INVALID-JOB-SECTION SECTION.
           MOVE "Invalid job number. Please try again." TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION.

       OPEN-JOBS-FOR-READ-SECTION SECTION.
           MOVE "N" TO WS-JOBS-EOF-FLAG
           OPEN INPUT JOBS-FILE
           EVALUATE WS-JOBS-STATUS
               WHEN "00" MOVE 1 TO WS-JOBS-OPEN
               WHEN "35" SET END-OF-JOBS-FILE TO TRUE
               WHEN OTHER PERFORM JOB-STORAGE-ERROR-SECTION
           END-EVALUATE.

       READ-NEXT-JOB-SECTION SECTION.
           READ JOBS-FILE
           EVALUATE WS-JOBS-STATUS
               WHEN "00" CONTINUE
               WHEN "10" SET END-OF-JOBS-FILE TO TRUE
               WHEN OTHER PERFORM JOB-STORAGE-ERROR-SECTION
           END-EVALUATE.

       CLOSE-JOBS-READ-SECTION SECTION.
           IF WS-JOBS-OPEN = 1
               CLOSE JOBS-FILE
               MOVE 0 TO WS-JOBS-OPEN
               IF WS-JOBS-STATUS NOT = "00"
                   PERFORM JOB-STORAGE-ERROR-SECTION
               END-IF
           END-IF.

       LOAD-SELECTED-JOB-SECTION SECTION.
           PERFORM OPEN-JOBS-FOR-READ-SECTION
           MOVE 0 TO WS-JOB-COUNT
           PERFORM UNTIL WS-JOB-COUNT = WS-SELECTED-JOB
               OR END-OF-JOBS-FILE
               PERFORM READ-NEXT-JOB-SECTION
               ADD 1 TO WS-JOB-COUNT
           END-PERFORM
           IF END-OF-JOBS-FILE
               PERFORM JOB-STORAGE-ERROR-SECTION
           END-IF
           MOVE JOBS-RECORD TO WS-SELECTED-RECORD
           PERFORM CLOSE-JOBS-READ-SECTION.

       JOB-DETAILS-SECTION SECTION.
           MOVE "--- Job Details ---" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "Title: " FUNCTION TRIM(WS-SELECTED-TITLE)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "Description: " FUNCTION TRIM(WS-SELECTED-DESCRIPTION)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "Employer: " FUNCTION TRIM(WS-SELECTED-EMPLOYER)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "Location: " FUNCTION TRIM(WS-SELECTED-LOCATION)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           IF WS-SELECTED-SALARY NOT = SPACES
               STRING "Salary: " FUNCTION TRIM(WS-SELECTED-SALARY)
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-IF
           MOVE 0 TO WS-DETAIL-DONE
           PERFORM UNTIL WS-DETAIL-DONE = 1
               MOVE "1. Apply for this Job" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               MOVE "2. Back to Job List" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               MOVE "Enter your choice:" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM READ-INPUT-SECTION
               EVALUATE FUNCTION TRIM(WS-INPUT-LINE)
                   WHEN "1"
                       PERFORM APPLY-JOB-SECTION
                       MOVE 1 TO WS-DETAIL-DONE
                   WHEN "2" MOVE 1 TO WS-DETAIL-DONE
                   WHEN OTHER
                       MOVE "Invalid choice! Please try again."
                           TO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
               END-EVALUATE
           END-PERFORM.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. InCollege.




       ENVIRONMENT DIVISION.




       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CHOICE        PIC X(1).
       01 WS-EXIT-FLAG     PIC X VALUE "N".
           88 DONE         VALUE "Y".



       PROCEDURE DIVISION.
           PERFORM UNTIL DONE
               DISPLAY " "
               DISPLAY "==== TEST MENU ===="
               DISPLAY "1. TEST OPTION"
               DISPLAY "2. TEST OPTION 2"
               DISPLAY "3. EXIT"
               DISPLAY "Enter choice: "

               ACCEPT WS-CHOICE

               EVALUATE WS-CHOICE
                   WHEN "1"
                       DISPLAY "SELECTED OPTION 1"
                   WHEN "2"
                       DISPLAY "SELECTED OPTION 2"
                   WHEN "3"
                       DISPLAY "SELECTED OPTION 3"
                       SET DONE TO true
                   WHEN OTHER
                       DISPLAY "INVALID CHOICE"
               END-EVALUATE
           END-PERFORM

           STOP RUN.
      * ================================================================
      * SENDMESSAGE_SRC - Week 8 basic messaging
      * ================================================================

       MESSAGE-MENU-SECTION SECTION.
           MOVE "N" TO WS-MESSAGE-MENU-FLAG

           PERFORM UNTIL MESSAGE-MENU-DONE
               MOVE "--- Messages Menu ---" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION

               MOVE "1. Send a New Message" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION

               MOVE "2. View My Messages" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION

               MOVE "3. Back to Main Menu" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION

               MOVE "Enter your choice:" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION

               PERFORM READ-INPUT-SECTION
               MOVE WS-INPUT-LINE TO WS-MENU-CHOICE

               EVALUATE FUNCTION TRIM(WS-MENU-CHOICE)
                   WHEN "1"
                       PERFORM SEND-NEW-MESSAGE-SECTION

                   WHEN "2"
                       MOVE "View My Messages is under construction."
                           TO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION

                   WHEN "3"
                       SET MESSAGE-MENU-DONE TO TRUE

                   WHEN OTHER
                       MOVE "Invalid choice! Please try again."
                           TO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
               END-EVALUATE
           END-PERFORM.


       SEND-NEW-MESSAGE-SECTION SECTION.
           MOVE SPACES TO WS-MESSAGE-RECIPIENT
           MOVE SPACES TO WS-MESSAGE-CONTENT
           MOVE SPACES TO WS-RECIPIENT-FULL-NAME
           MOVE "N" TO WS-MESSAGE-RECIPIENT-FLAG

           MOVE "Enter recipient's username (must be a connection):"
               TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

           PERFORM READ-INPUT-SECTION
           MOVE FUNCTION TRIM(WS-INPUT-LINE)
               TO WS-MESSAGE-RECIPIENT

      *    Verify that the username actually exists.
           PERFORM VARYING ACCT-IDX FROM 1 BY 1
               UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
               IF FUNCTION TRIM(WS-USERNAME(ACCT-IDX))
                   = FUNCTION TRIM(WS-MESSAGE-RECIPIENT)
                   SET MESSAGE-RECIPIENT-FOUND TO TRUE
               END-IF
           END-PERFORM

           IF MESSAGE-RECIPIENT-MISSING
               MOVE "User not found in your network."
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               EXIT SECTION
           END-IF

      *    Determine the recipient's full name because connections.dat
      *    stores established connections using full names.
           IF WS-PROFILE-OPEN = 0
               PERFORM OPEN-PROFILES-SECTION
           END-IF

           INITIALIZE PROFILE-RECORD
           MOVE WS-MESSAGE-RECIPIENT TO PF-USERNAME

           READ PROFILE-FILE
               INVALID KEY
                   MOVE WS-MESSAGE-RECIPIENT
                       TO WS-RECIPIENT-FULL-NAME
               NOT INVALID KEY
                   STRING FUNCTION TRIM(PF-FIRST)
                       " "
                       FUNCTION TRIM(PF-LAST)
                       DELIMITED BY SIZE
                       INTO WS-RECIPIENT-FULL-NAME
           END-READ

      *    Reuse Week 5's accepted-connection check.
           MOVE WS-RECIPIENT-FULL-NAME TO WS-SEARCH-NAME
           PERFORM CHECK-ALREADY-CONNECTED-SECTION

           IF NOT-ALREADY-CONNECTED
               MOVE "You can only message users you are connected with."
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               EXIT SECTION
           END-IF

      *    Read message text.
           MOVE "Enter your message (max 200 chars):"
               TO WS-PROMPT
           MOVE 200 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-INPUT-FIELD-SECTION

           MOVE WS-INPUT-LINE TO WS-MESSAGE-CONTENT

      *    Persist the message.
           OPEN EXTEND MESSAGES-FILE

           IF WS-MESSAGES-STATUS NOT = "00"
               MOVE "Error: messages.dat file error"
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               EXIT SECTION
           END-IF

           MOVE WS-INPUT-USERNAME TO MF-SENDER-USERNAME
           MOVE WS-MESSAGE-RECIPIENT TO MF-RECIPIENT-USERNAME
           MOVE WS-MESSAGE-CONTENT TO MF-MESSAGE-CONTENT
           MOVE FUNCTION CURRENT-DATE TO MF-TIMESTAMP

           WRITE MESSAGES-RECORD

           IF WS-MESSAGES-STATUS NOT = "00"
               MOVE "Error: messages.dat file error"
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               CLOSE MESSAGES-FILE
               EXIT SECTION
           END-IF

           CLOSE MESSAGES-FILE

           MOVE SPACES TO WS-MESSAGE
           STRING "Message sent to "
               FUNCTION TRIM(WS-MESSAGE-RECIPIENT)
               " successfully!"
               DELIMITED BY SIZE INTO WS-MESSAGE
           END-STRING

           PERFORM PRINT-AND-LOG-SECTION.

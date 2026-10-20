      * ================================================================
      * VIEWNET_SRC - copybook: View My Network + connection checks
      * Included at the end of the PROCEDURE DIVISION with
      *     COPY VIEWNET_SRC.
      * ================================================================

      * VIEW-MY-NETWORK-SECTION - lists every connection of the
      * logged-in user with name, university and major

       VIEW-MY-NETWORK-SECTION SECTION.
           MOVE "--- Your Network ---" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

           IF WS-PROFILE-OPEN = 0
               PERFORM OPEN-PROFILES-SECTION
           END-IF

           MOVE "N" TO WS-NETWORK-FLAG
           MOVE "N" TO WS-CONNECTIONS-EOF-FLAG
           OPEN INPUT CONNECTIONS-FILE
           IF WS-CONNECTIONS-STATUS NOT = "00"
               MOVE "Error: connections.dat file error" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
               PERFORM FINALIZE-SECTION
               STOP RUN
           END-IF

           PERFORM UNTIL END-OF-CONNECTIONS-FILE
               READ CONNECTIONS-FILE
                   AT END
                       SET END-OF-CONNECTIONS-FILE TO TRUE
                   NOT AT END
                       EVALUATE TRUE
                           WHEN CF-USER-ONE-FULLNAME
                               = WS-SENDING-FULL-NAME
                               MOVE CF-USER-TWO-FULLNAME
                                   TO WS-CONNECTED-NAME
                               PERFORM PRINT-CONNECTION-SECTION
                           WHEN CF-USER-TWO-FULLNAME
                               = WS-SENDING-FULL-NAME
                               MOVE CF-USER-ONE-FULLNAME
                                   TO WS-CONNECTED-NAME
                               PERFORM PRINT-CONNECTION-SECTION
                       END-EVALUATE
               END-READ
           END-PERFORM

           CLOSE CONNECTIONS-FILE

           IF NO-CONNECTIONS-FOUND
               MOVE "You have no connections yet." TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-IF

           MOVE "--------------------" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION.

      * PRINT-CONNECTION-SECTION - prints one line for the user named
      * in WS-CONNECTED-NAME, pulling university/major from the profile
       PRINT-CONNECTION-SECTION SECTION.
           SET NETWORK-HAS-CONNECTIONS TO TRUE
           PERFORM LOOKUP-PROFILE-BY-NAME-SECTION

           MOVE SPACES TO WS-MESSAGE
           IF WS-LOOKUP-FOUND = 1
               STRING "Connected with: "
                   FUNCTION TRIM(WS-CONNECTED-NAME)
                   " (University: " FUNCTION TRIM(PF-UNIVERSITY)
                   ", Major: " FUNCTION TRIM(PF-MAJOR) ")"
                   DELIMITED BY SIZE INTO WS-MESSAGE
           ELSE
               STRING "Connected with: "
                   FUNCTION TRIM(WS-CONNECTED-NAME)
                   DELIMITED BY SIZE INTO WS-MESSAGE
           END-IF
           PERFORM PRINT-AND-LOG-SECTION.

      * LOOKUP-PROFILE-BY-NAME-SECTION - scans PROFILE-FILE for the
      * full name in WS-CONNECTED-NAME. On a hit, PROFILE-RECORD holds
      * that user's profile and WS-LOOKUP-FOUND = 1.
       LOOKUP-PROFILE-BY-NAME-SECTION SECTION.
           MOVE 0 TO WS-LOOKUP-FOUND
           MOVE LOW-VALUES TO PF-USERNAME
           START PROFILE-FILE KEY IS NOT LESS THAN PF-USERNAME
           IF WS-PROFILE-STATUS = "00"
               PERFORM UNTIL WS-LOOKUP-FOUND = 1
                   READ PROFILE-FILE NEXT RECORD
                       AT END
                           EXIT PERFORM
                       NOT AT END
                           MOVE SPACES TO WS-COMPARE-NAME
                           STRING FUNCTION TRIM(PF-FIRST) " "
                               FUNCTION TRIM(PF-LAST)
                               DELIMITED BY SIZE INTO WS-COMPARE-NAME
                           IF FUNCTION TRIM(WS-COMPARE-NAME)
                               = FUNCTION TRIM(WS-CONNECTED-NAME)
                               MOVE 1 TO WS-LOOKUP-FOUND
                           END-IF
                   END-READ
               END-PERFORM
           END-IF.

      * CHECK-ALREADY-CONNECTED-SECTION - sets ALREADY-CONNECTED if the
      * logged-in user and WS-SEARCH-NAME are already connected
       CHECK-ALREADY-CONNECTED-SECTION SECTION.
           MOVE "N" TO WS-ALREADY-CONNECTED-FLAG
           MOVE "N" TO WS-CONNECTIONS-EOF-FLAG
           OPEN INPUT CONNECTIONS-FILE
           IF WS-CONNECTIONS-STATUS NOT = "00"
               MOVE "Error: connections.dat file error" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM FINALIZE-SECTION
               STOP RUN
           END-IF

           PERFORM UNTIL END-OF-CONNECTIONS-FILE
               READ CONNECTIONS-FILE
                   AT END
                       SET END-OF-CONNECTIONS-FILE TO TRUE
                   NOT AT END
                       IF (CF-USER-ONE-FULLNAME = WS-SENDING-FULL-NAME
                          AND CF-USER-TWO-FULLNAME = WS-SEARCH-NAME)
                          OR
                          (CF-USER-ONE-FULLNAME = WS-SEARCH-NAME
                          AND CF-USER-TWO-FULLNAME
                              = WS-SENDING-FULL-NAME)
                           SET ALREADY-CONNECTED TO TRUE
                           SET END-OF-CONNECTIONS-FILE TO TRUE
                       END-IF
               END-READ
           END-PERFORM

           CLOSE CONNECTIONS-FILE.

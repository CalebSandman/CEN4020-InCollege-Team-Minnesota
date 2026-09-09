      * ================================================================
      *                        DEVELOPERS READ THIS
      *
      *    To print to console: MOVE "[TEXT]" TO WS_MESSAGE
      *                         PERFORM PRINT-AND-LOG-SECTION
      *
      *    For menu selections READ into WS-MENU-CHOICE
      *
      *    WS stands for working storage
      *    Use on variables that store values
      *
      *
      *
      * ================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCOLLEGE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           
           SELECT ACCOUNT-FILE ASSIGN TO "data/accounts.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-FILE-STATUS.

           SELECT INPUT-FILE ASSIGN TO "data/input.txt"
               ORGANIZATION IS LINE sequential
               FILE STATUS IS WS-INPUT-FILE-STATUS.

           SELECT OUTPUT-FILE ASSIGN TO "data/output.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUTPUT-FILE-STATUS.

      * Do not remove anything from DATA DIVISION
      * Only add new variables as needed
       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-FILE.
       01  ACCOUNT-RECORD.
           05  ACCT-USERNAME           PIC X(50).
           05  ACCT-PASSWORD           PIC X(12).

       FD  INPUT-FILE.
       01  INPUT-RECORD                PIC X(50).
       FD  OUTPUT-FILE.
       01  OUTPUT-RECORD               PIC X(200).

       WORKING-STORAGE SECTION.

      * ---------------------------------------------------------------
      * File status codes (used to detect "file doesn't exist yet"
      * on the very first run, vs. normal read/write results)
      * ---------------------------------------------------------------
       01  WS-ACCOUNT-FILE-STATUS      PIC XX VALUE "00".
       01  WS-INPUT-FILE-STATUS        PIC XX VALUE "00".
       01  WS-OUTPUT-FILE-STATUS       PIC XX VALUE "00".

      * ---------------------------------------------------------------
      * In-memory account table (max 5 accounts)
      * ---------------------------------------------------------------
       01  WS-MAX-ACCOUNTS             PIC 9 VALUE 5.
       01  WS-ACCOUNT-COUNT            PIC 9 VALUE 0.
       01  WS-ACCOUNTS-TABLE.
           05  WS-ACCOUNT OCCURS 5 TIMES INDEXED BY ACCT-IDX.
               10  WS-USERNAME         PIC X(50).
               10  WS-PASSWORD         PIC X(12).

       01  WS-EOF-FLAG                 PIC X VALUE "N".
           88 END-OF-ACCOUNTS          VALUE "Y".

      * ---------------------------------------------------------------
      * Shared I/O helper (PRINT-AND-LOG writes to screen + file)
      * ---------------------------------------------------------------
       01   WS-MESSAGE                 PIC X(200).
       01  WS-INPUT-LINE               PIC X(50).

      * ---------------------------------------------------------------
      * Navigation / control flags
      * ---------------------------------------------------------------
       01  WS-CONTINUE-FLAG            PIC X VALUE "Y".
           88  KEEP-RUNNING            VALUE "Y".

       01  WS-EXIT-FLAG                PIC X VALUE "N".
           88 EXIT-REQUESTED           VALUE "Y".

       01  WS-LOGGED-IN-FLAG           PIC X VALUE "N".
           88  IS-LOGGED-IN            VALUE "Y".

       01  WS-MENU-CHOICE              PIC X(1).
       
      * ---------------------------------------------------------------
      * Login / registration working fields
      * ---------------------------------------------------------------
       01  WS-INPUT-USERNAME           PIC X(50).
       01  WS-INPUT-PASSWORD           PIC X(12).

       01  WS-LOGIN-SUCCESS-FLAG       PIC X VALUE "N".
           88 LOGIN-SUCCESSFUL         VALUE "Y".

       01  WS-FOUND-USER-FLAG         PIC X VALUE "N".
           88 USER-FOUND               VALUE "Y".

      * ---------------------------------------------------------------
      * Password validation working fields
      * ---------------------------------------------------------------
       01  WS-PASSWORD-VALID-FLAG      PIC X VALUE "N".
           88 PASSWORD-IS-VALID        VALUE "Y".

       01  WS-HAS-UPPER-FLAG           PIC X VALUE "N".
           88  HAS-UPPER-CASE          VALUE "Y".

       01  WS-HAS-SPECIAL-FLAG         PIC X VALUE "N".
           88  HAS-SPECIAL-CHAR        VALUE "Y".

       01  WS-TRIMMED-PASSWORD         PIC X(12).
       01  WS-PASSWORD-LENGTH          PIC 99.
       01  WS-CHAR-INDEX               PIC 99.
       01  WS-CURRENT-CHAR             PIC X.

       PROCEDURE DIVISION.

      * ================================================================
      * MAIN-LOGIC - top level flow
      * ================================================================
       MAIN-LOGIC.
           PERFORM INITIALIZE-SECTION

           PERFORM UNTIL NOT KEEP-RUNNING
               PERFORM WELCOME-SECTION
           END-PERFORM

           IF NOT EXIT-REQUESTED
               MOVE "Y" TO WS-CONTINUE-FLAG
               PERFORM UNTIL NOT KEEP-RUNNING
                   PERFORM MAIN-MENU-SECTION
               END-PERFORM
           END-IF

           PERFORM FINALIZE-SECTION
           STOP RUN.

      * ================================================================
      * INITIALIZE-SECTION - open transcript file, load accounts
      * ================================================================
       INITIALIZE-SECTION SECTION.
           OPEN OUTPUT OUTPUT-FILE
           OPEN INPUT INPUT-FILE
           IF WS-INPUT-FILE-STATUS = "35"
               MOVE "Error: data/input.txt not found" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM FINALIZE-SECTION
               STOP RUN
           END-IF

           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-FILE-STATUS = "35"
      *    File doesn't exists yet (first run) - start with 0 accounts
               CONTINUE
           ELSE
               PERFORM UNTIL END-OF-ACCOUNTS
                   READ ACCOUNT-FILE
                       AT END
                           SET END-OF-ACCOUNTS TO true
                       NOT AT END
                           SET ACCT-IDX TO WS-ACCOUNT-COUNT
                           ADD 1 TO WS-ACCOUNT-COUNT
                           SET ACCT-IDX TO WS-ACCOUNT-COUNT
                           MOVE ACCT-USERNAME TO WS-USERNAME(ACCT-IDX)
                           MOVE ACCT-PASSWORD TO WS-PASSWORD(ACCT-IDX)
                   END-READ
               END-PERFORM
               CLOSE ACCOUNT-FILE
           END-IF.

      * ================================================================
      * WELCOME-SECTION - login / register / exit
      * ================================================================
       WELCOME-SECTION SECTION.
           MOVE "Welcome to InCollege!" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

           MOVE "1. Login" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "2. Register" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "3. Exit" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

           PERFORM READ-INPUT-SECTION
           MOVE WS-INPUT-LINE TO WS-MENU-CHOICE

           EVALUATE WS-MENU-CHOICE
               WHEN "1"
                   PERFORM LOGIN-USER-SECTION
                   IF LOGIN-SUCCESSFUL
                       MOVE "N" TO WS-CONTINUE-FLAG
                   END-IF
               WHEN "2"
                   PERFORM REGISTER-USER-SECTION
               WHEN "3"
                   MOVE "N" TO WS-CONTINUE-FLAG
                   SET EXIT-REQUESTED TO TRUE
               WHEN OTHER
                   MOVE "Invalid choice! Please try again."
                   TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
           END-EVALUATE.

      * ================================================================
      * REGISTER-USER-SECTION
      * ================================================================
       REGISTER-USER-SECTION SECTION.
           IF WS-ACCOUNT-COUNT >= WS-MAX-ACCOUNTS
               MOVE "Error: Maximum number of accounts had been reached"
               TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           ELSE
               MOVE "Enter username: " TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM READ-INPUT-SECTION
               MOVE WS-INPUT-LINE TO WS-INPUT-USERNAME

               MOVE "N" TO WS-FOUND-USER-FLAG
               PERFORM VARYING ACCT-IDX FROM 1 BY 1
                   UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
                   IF WS-USERNAME(ACCT-IDX) = WS-INPUT-USERNAME
                       SET USER-FOUND TO TRUE
                   END-IF
               END-PERFORM

               IF USER-FOUND
                   MOVE "Error: Username already taken."
                       TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               ELSE
                   MOVE "Enter password:" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
                   PERFORM READ-INPUT-SECTION
                   MOVE WS-INPUT-LINE TO WS-INPUT-PASSWORD

                   PERFORM VALIDATE-PASSWORD-SECTION

                   IF PASSWORD-IS-VALID
                       ADD 1 TO WS-ACCOUNT-COUNT
                       SET ACCT-IDX TO WS-ACCOUNT-COUNT
                       MOVE WS-INPUT-USERNAME TO WS-USERNAME(ACCT-IDX)
                       MOVE WS-INPUT-PASSWORD TO WS-PASSWORD(ACCT-IDX)

                       PERFORM WRITE-ACCOUNTS-TO-FILE-SECTION

                       MOVE "Account created!"
                           TO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
                   ELSE
                       STRING "Password must be 8-12 character, "
                           "contain one capital letter, and one "
                           "special character."
                           DELIMITED BY SIZE INTO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
                   END-IF
               END-IF
           END-IF.

      * ================================================================
      * VALIDATE-PASSWORD-SECTION
      * Rules: 8-12 characters, at least 1 capital letter,
      *        at least 1 special character
      * ================================================================
       VALIDATE-PASSWORD-SECTION SECTION.
           MOVE "N" TO WS-HAS-UPPER-FLAG
           MOVE "N" TO WS-HAS-SPECIAL-FLAG
           MOVE "N" TO WS-PASSWORD-VALID-FLAG

           MOVE FUNCTION TRIM(WS-INPUT-PASSWORD) TO WS-TRIMMED-PASSWORD
           COMPUTE WS-PASSWORD-LENGTH =
               FUNCTION LENGTH(FUNCTION TRIM(WS-INPUT-PASSWORD))

           IF WS-PASSWORD-LENGTH >= 8 AND WS-PASSWORD-LENGTH <= 12
               PERFORM VARYING WS-CHAR-INDEX FROM 1 BY 1
                   UNTIL WS-CHAR-INDEX > WS-PASSWORD-LENGTH
                   MOVE WS-TRIMMED-PASSWORD(WS-CHAR-INDEX:1)
                       TO WS-CURRENT-CHAR

                   IF WS-CURRENT-CHAR IS ALPHABETIC-UPPER
                       SET HAS-UPPER-CASE TO TRUE
                   END-IF

                   IF WS-CURRENT-CHAR NOT ALPHABETIC
                       AND WS-CURRENT-CHAR NOT NUMERIC
                       SET HAS-SPECIAL-CHAR TO TRUE
                   END-IF
               END-PERFORM

               IF HAS-UPPER-CASE AND HAS-SPECIAL-CHAR
                   SET PASSWORD-IS-VALID TO TRUE
               END-IF
           END-IF.

      * ================================================================
      * WRITE-ACCOUNTS-TO-FILE-SECTION
      * Rewrites accounts.dat from the in-memory table.
      * ================================================================
       WRITE-ACCOUNTS-TO-FILE-SECTION SECTION.
           OPEN OUTPUT ACCOUNT-FILE
           PERFORM VARYING ACCT-IDX FROM 1 BY 1
               UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
               MOVE WS-USERNAME(ACCT-IDX) TO ACCT-USERNAME
               MOVE WS-PASSWORD(ACCT-IDX) TO ACCT-PASSWORD
               WRITE ACCOUNT-RECORD
           END-PERFORM
           CLOSE ACCOUNT-FILE.

      * ================================================================
      * LOGIN-USER-SECTION
      * ================================================================
       LOGIN-USER-SECTION SECTION.
           MOVE "N" TO WS-LOGIN-SUCCESS-FLAG

           MOVE "Enter username: " TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           PERFORM READ-INPUT-SECTION
           MOVE WS-INPUT-LINE TO WS-INPUT-USERNAME

           MOVE "Enter password: " TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           PERFORM READ-INPUT-SECTION
           MOVE WS-INPUT-LINE TO WS-INPUT-PASSWORD

           PERFORM VARYING ACCT-IDX FROM 1 BY 1
               UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
               IF WS-USERNAME(ACCT-IDX) = WS-INPUT-USERNAME
                   AND WS-PASSWORD(ACCT-IDX) = WS-INPUT-PASSWORD
                   SET LOGIN-SUCCESSFUL TO TRUE
               END-IF
           END-PERFORM

           IF LOGIN-SUCCESSFUL
               SET IS-LOGGED-IN TO TRUE
               STRING "Welcome in, "
                   FUNCTION TRIM(WS-INPUT-USERNAME)
                   "!" DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           ELSE
               MOVE "Error: Incorrect username or password."
               TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-IF.

      * ================================================================
      * MAIN-MENU-SECTION - 4 item menu, shown after successful login
      * ================================================================
       MAIN-MENU-SECTION SECTION.
           MOVE "Main Menu:" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "1. Find a job/internship" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "2. Find someone you know" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "3. Learn a new skill" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "4. Logout" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

           PERFORM READ-INPUT-SECTION
           MOVE WS-INPUT-LINE TO WS-MENU-CHOICE

           EVALUATE WS-MENU-CHOICE
               WHEN "1"
                   MOVE "Option is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
      *Functionality not implemented
               WHEN "2"
                   MOVE "Option is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
      *Functionality not implemented
               WHEN "3"
                   PERFORM UNTIL NOT KEEP-RUNNING
                       PERFORM SKILLS-MENU-SECTION
                   END-PERFORM
                   MOVE "Y" TO WS-CONTINUE-FLAG
               WHEN "4"
                   MOVE "N" TO WS-CONTINUE-FLAG
               WHEN OTHER
                   MOVE "Invalid choice! Please try again."
                   TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
           END-EVALUATE.

      * ================================================================
      * SKILLS-MENU-SECTION - 5 item menu, shown after selecting
      * "Learn a new skill"
      * ================================================================
       SKILLS-MENU-SECTION SECTION.
           MOVE "Skills:" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "1. Programming" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "2. Data Analysis" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "3. Research and Information Literacy" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "4. Project Management" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "5. Leadership" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "6. Return" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

           PERFORM READ-INPUT-SECTION
           MOVE WS-INPUT-LINE TO WS-MENU-CHOICE

           EVALUATE WS-MENU-CHOICE
               WHEN "1"
                   MOVE "Skill is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               WHEN "2"
                   MOVE "Skill is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               WHEN "3"
                   MOVE "Skill is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               WHEN "4"
                   MOVE "Skill is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               WHEN "5"
                   MOVE "Skill is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               WHEN "6"
                  MOVE "N" TO WS-CONTINUE-FLAG
               WHEN OTHER
                   MOVE "Invalid choice! Please try again."
                   TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
           END-EVALUATE.

      * ================================================================
      * PRINT-AND-LOG-SECTION - helper paragraph used by every section
      * Displays WS-MESSAGE on screen AND writes it to the output
      * file, so the two can never fall out of sync.
      * ================================================================
       PRINT-AND-LOG-SECTION SECTION.
           DISPLAY WS-MESSAGE
           WRITE OUTPUT-RECORD FROM WS-MESSAGE.

      * ================================================================
      * READ-INPUT-SECTION
      * ================================================================
       READ-INPUT-SECTION SECTION.
           READ INPUT-FILE INTO WS-INPUT-LINE
           AT END
               MOVE "Error: input file ran out of lines" TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               STOP RUN
           END-READ.

           MOVE WS-INPUT-LINE TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION.

      * ================================================================
      * FINALIZE-SECTION - close transcript file, wrap up
      * ================================================================
       FINALIZE-SECTION SECTION.
           CLOSE OUTPUT-FILE.
           CLOSE INPUT-FILE.
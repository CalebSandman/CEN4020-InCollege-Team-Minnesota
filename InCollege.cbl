
      *                        DEVELOPERS READ THIS
      *
      *    To print to console: MOVE "[TEXT]" TO WS_MESSAGE
      *                         PERFORM PRINT-AND-LOG-SECTION
      *
      *    For menu selections READ into WS-MENU-CHOICE
      *
      *    WS stands for working storage
      *    Use on variables that store values




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
           SELECT PROFILE-FILE ASSIGN TO "data/profiles.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS PF-USERNAME
               FILE STATUS IS WS-PROFILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-FILE.
       01  ACCOUNT-RECORD.
           05  ACCT-USERNAME           PIC X(50).
           05  ACCT-PASSWORD           PIC X(12).

       FD  INPUT-FILE.
       01  INPUT-RECORD                PIC X(4096).
       FD  OUTPUT-FILE.
       01  OUTPUT-RECORD               PIC X(4096).

       FD  PROFILE-FILE.
       01  PROFILE-RECORD.
           05 PF-USERNAME       PIC X(50).
           05 PF-FIRST          PIC X(50).
           05 PF-LAST           PIC X(50).
           05 PF-UNIVERSITY     PIC X(100).
           05 PF-MAJOR          PIC X(100).
           05 PF-YEAR           PIC X(4).
           05 PF-ABOUT          PIC X(200).
           05 PF-EXP-COUNT      PIC 9.
           05 PF-EXPERIENCE OCCURS 3 TIMES.
              10 PF-TITLE       PIC X(100).
              10 PF-COMPANY     PIC X(100).
              10 PF-DATES       PIC X(50).
              10 PF-DESCRIPTION PIC X(100).
           05 PF-EDU-COUNT      PIC 9.
           05 PF-EDUCATION OCCURS 3 TIMES.
              10 PF-DEGREE      PIC X(100).
              10 PF-SCHOOL      PIC X(100).
              10 PF-YEARS       PIC X(50).

       WORKING-STORAGE SECTION.
       01  WS-PROFILE-STATUS    PIC XX.
       01  WS-PROFILE-OPEN      PIC 9 VALUE 0.
       01  WS-PROFILE-FOUND     PIC 9 VALUE 0.
       01  WS-PROMPT            PIC X(200).
       01  WS-FIELD-LIMIT       BINARY-LONG.
       01  WS-FIELD-REQUIRED    PIC 9.
       01  WS-FIELD-VALID       PIC 9.
       01  WS-FIELD-LENGTH      BINARY-LONG.
       01  WS-PROFILE-INDEX     BINARY-LONG.
       01  WS-ENTRY-DONE        PIC 9.
       01  WS-ENTRY-NUMBER      PIC 9.



      * File status codes (used to detect "file doesn't exist yet"
      * on the very first run, vs. normal read/write results)

       01  WS-ACCOUNT-FILE-STATUS      PIC XX VALUE "00".
       01  WS-INPUT-FILE-STATUS        PIC XX VALUE "00".
       01  WS-OUTPUT-FILE-STATUS       PIC XX VALUE "00".


      * In-memory account table (max 5 accounts)

       01  WS-MAX-ACCOUNTS             PIC 9 VALUE 5.
       01  WS-ACCOUNT-COUNT            PIC 9 VALUE 0.
       01  WS-ACCOUNTS-TABLE.
           05  WS-ACCOUNT OCCURS 5 TIMES INDEXED BY ACCT-IDX.
               10  WS-USERNAME         PIC X(50).
               10  WS-PASSWORD         PIC X(12).

       01  WS-EOF-FLAG                 PIC X VALUE "N".
           88 END-OF-ACCOUNTS          VALUE "Y".


      * Shared I/O helper (PRINT-AND-LOG writes to screen + file)

       01   WS-MESSAGE                 PIC X(4096).
       01  WS-INPUT-LINE               PIC X(4096).


      * Navigation / control flags

       01  WS-CONTINUE-FLAG            PIC X VALUE "Y".
           88  KEEP-RUNNING            VALUE "Y".

       01  WS-EXIT-FLAG                PIC X VALUE "N".
           88 EXIT-REQUESTED           VALUE "Y".

       01  WS-LOGGED-IN-FLAG           PIC X VALUE "N".
           88  IS-LOGGED-IN            VALUE "Y".

       01  WS-MENU-CHOICE              PIC X(4096).


      * Login / registration working fields

       01  WS-INPUT-USERNAME           PIC X(50).
       01  WS-INPUT-PASSWORD           PIC X(12).

       01  WS-LOGIN-SUCCESS-FLAG       PIC X VALUE "N".
           88 LOGIN-SUCCESSFUL         VALUE "Y".

       01  WS-FOUND-USER-FLAG         PIC X VALUE "N".
           88 USER-FOUND               VALUE "Y".


      * Password validation working fields

       01  WS-PASSWORD-VALID-FLAG      PIC X VALUE "N".
           88 PASSWORD-IS-VALID        VALUE "Y".

       01  WS-HAS-UPPER-FLAG           PIC X VALUE "N".
           88  HAS-UPPER-CASE          VALUE "Y".

       01  WS-HAS-SPECIAL-FLAG         PIC X VALUE "N".
           88  HAS-SPECIAL-CHAR        VALUE "Y".

       01  WS-HAS-DIGIT-FLAG           PIC X VALUE "N".
           88  HAS-DIGIT               VALUE "Y".

       01  WS-TRIMMED-PASSWORD         PIC X(12).
       01  WS-PASSWORD-LENGTH          PIC 99.
       01  WS-CHAR-INDEX               PIC 99.
       01  WS-CURRENT-CHAR             PIC X.

       PROCEDURE DIVISION.


      * MAIN-LOGIC - top level flow

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


      * INITIALIZE-SECTION - open transcript file, load accounts

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


      * REGISTER-USER-SECTION

       REGISTER-USER-SECTION SECTION.
           IF WS-ACCOUNT-COUNT >= WS-MAX-ACCOUNTS
               MOVE "Error: Maximum number of accounts had been reached"
               TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           ELSE
               MOVE "Enter username: " TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM READ-INPUT-SECTION
               IF FUNCTION LENGTH(
                   FUNCTION TRIM(WS-INPUT-LINE)) > 50
                   MOVE "Error: Username exceeds 50 characters."
                       TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
                   EXIT SECTION
               END-IF
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
                   IF FUNCTION LENGTH(
                       FUNCTION TRIM(WS-INPUT-LINE)) > 12
                       MOVE "Error: Password exceeds 12 characters."
                           TO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
                       EXIT SECTION
                   END-IF
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
                           "contain at least one capital letter, one "
                           "digit, and one special character."
                           DELIMITED BY SIZE INTO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
                   END-IF
               END-IF
           END-IF.


      * VALIDATE-PASSWORD-SECTION
      * Rules: 8-12 characters, at least 1 capital letter, 1 digit,
      * and 1 special character

       VALIDATE-PASSWORD-SECTION SECTION.
           MOVE "N" TO WS-HAS-UPPER-FLAG
           MOVE "N" TO WS-HAS-SPECIAL-FLAG
           MOVE "N" TO WS-HAS-DIGIT-FLAG
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

                   IF WS-CURRENT-CHAR IS NUMERIC
                       SET HAS-DIGIT TO TRUE
                   END-IF
               END-PERFORM

               IF HAS-UPPER-CASE AND HAS-SPECIAL-CHAR AND HAS-DIGIT
                   SET PASSWORD-IS-VALID TO TRUE
               END-IF
           END-IF.


      * WRITE-ACCOUNTS-TO-FILE-SECTION
      * Rewrites accounts.dat from the in-memory table.

       WRITE-ACCOUNTS-TO-FILE-SECTION SECTION.
           OPEN OUTPUT ACCOUNT-FILE
           PERFORM VARYING ACCT-IDX FROM 1 BY 1
               UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
               MOVE WS-USERNAME(ACCT-IDX) TO ACCT-USERNAME
               MOVE WS-PASSWORD(ACCT-IDX) TO ACCT-PASSWORD
               WRITE ACCOUNT-RECORD
           END-PERFORM
           CLOSE ACCOUNT-FILE.


      * LOGIN-USER-SECTION

       LOGIN-USER-SECTION SECTION.
           MOVE "N" TO WS-LOGIN-SUCCESS-FLAG

           MOVE "Enter username: " TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           PERFORM READ-INPUT-SECTION
           IF FUNCTION LENGTH(FUNCTION TRIM(WS-INPUT-LINE)) > 50
               MOVE "Error: Username exceeds 50 characters."
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               EXIT SECTION
           END-IF
           MOVE WS-INPUT-LINE TO WS-INPUT-USERNAME

           MOVE "Enter password: " TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           PERFORM READ-INPUT-SECTION
           IF FUNCTION LENGTH(FUNCTION TRIM(WS-INPUT-LINE)) > 12
               MOVE "Error: Password exceeds 12 characters."
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               EXIT SECTION
           END-IF
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


      * MAIN-MENU-SECTION - 4 item menu, shown after successful login

       MAIN-MENU-SECTION SECTION.
           MOVE "Main Menu:" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "1. Create/Edit My Profile" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "2. View My Profile" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "3. Find a job/internship" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "4. Find someone you know" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "5. Learn a new skill" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "6. Logout / Exit" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "Enter your choice:" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           PERFORM READ-INPUT-SECTION
           MOVE WS-INPUT-LINE TO WS-MENU-CHOICE
           EVALUATE WS-MENU-CHOICE
               WHEN "1" PERFORM EDIT-PROFILE-SECTION
               WHEN "2" PERFORM VIEW-PROFILE-SECTION
               WHEN "3"
               WHEN "4"
                   MOVE "Option is under construction" TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               WHEN "5"
                   PERFORM UNTIL NOT KEEP-RUNNING
                       PERFORM SKILLS-MENU-SECTION
                   END-PERFORM
                   MOVE "Y" TO WS-CONTINUE-FLAG
               WHEN "6" MOVE "N" TO WS-CONTINUE-FLAG
               WHEN OTHER
                   MOVE "Invalid choice! Please try again."
                       TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
           END-EVALUATE.


      * SKILLS-MENU-SECTION - 5 item menu, shown after selecting
      * "Learn a new skill"

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


      * PRINT-AND-LOG-SECTION - helper paragraph used by every section
      * Displays WS-MESSAGE on screen AND writes it to the output
      * file, so the two can never fall out of sync.

       PRINT-AND-LOG-SECTION SECTION.
           DISPLAY FUNCTION TRIM(WS-MESSAGE TRAILING)
           WRITE OUTPUT-RECORD FROM WS-MESSAGE
           MOVE SPACES TO WS-MESSAGE.


      * READ-INPUT-SECTION

       READ-INPUT-SECTION SECTION.
           MOVE SPACES TO WS-INPUT-LINE
           READ INPUT-FILE INTO WS-INPUT-LINE
           AT END
               MOVE "--- END_OF_PROGRAM_EXECUTION ---"
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM FINALIZE-SECTION
               STOP RUN
           END-READ.

           MOVE WS-INPUT-LINE TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION.


      * FINALIZE-SECTION - close transcript file, wrap up

       FINALIZE-SECTION SECTION.
           IF WS-PROFILE-OPEN = 1
               CLOSE PROFILE-FILE
               MOVE 0 TO WS-PROFILE-OPEN
           END-IF
           CLOSE OUTPUT-FILE
           CLOSE INPUT-FILE.
       OPEN-PROFILES-SECTION SECTION.
           OPEN I-O PROFILE-FILE
           IF WS-PROFILE-STATUS = "35"
               OPEN OUTPUT PROFILE-FILE
               IF WS-PROFILE-STATUS = "00"
                   CLOSE PROFILE-FILE
                   OPEN I-O PROFILE-FILE
               END-IF
           END-IF
           IF WS-PROFILE-STATUS NOT = "00"
               PERFORM PROFILE-ERROR-SECTION
           ELSE
               MOVE 1 TO WS-PROFILE-OPEN
           END-IF.

       PROFILE-ERROR-SECTION SECTION.
           MOVE SPACES TO WS-MESSAGE
           STRING "Error: profile storage failure, status "
               WS-PROFILE-STATUS DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           PERFORM FINALIZE-SECTION
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       LOAD-PROFILE-SECTION SECTION.
           IF WS-PROFILE-OPEN = 0
               PERFORM OPEN-PROFILES-SECTION
           END-IF
           INITIALIZE PROFILE-RECORD
           MOVE WS-INPUT-USERNAME TO PF-USERNAME
           MOVE 0 TO WS-PROFILE-FOUND
           READ PROFILE-FILE
           EVALUATE WS-PROFILE-STATUS
               WHEN "00" MOVE 1 TO WS-PROFILE-FOUND
               WHEN "23" CONTINUE
               WHEN OTHER PERFORM PROFILE-ERROR-SECTION
           END-EVALUATE.

      * Common field reader: retries the same field on invalid input.
       READ-PROFILE-FIELD-SECTION SECTION.
           MOVE 0 TO WS-FIELD-VALID
           PERFORM UNTIL WS-FIELD-VALID = 1
               MOVE WS-PROMPT TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               PERFORM READ-INPUT-SECTION
               MOVE FUNCTION TRIM(WS-INPUT-LINE) TO WS-INPUT-LINE
               COMPUTE WS-FIELD-LENGTH = FUNCTION LENGTH(
                   FUNCTION TRIM(WS-INPUT-LINE))
               EVALUATE TRUE
                   WHEN WS-FIELD-REQUIRED = 1
                       AND WS-FIELD-LENGTH = 0
                       MOVE "This field is required. Try again."
                           TO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
                   WHEN WS-FIELD-LENGTH > WS-FIELD-LIMIT
                       MOVE "Entry is too long. Try again."
                           TO WS-MESSAGE
                       PERFORM PRINT-AND-LOG-SECTION
                   WHEN OTHER MOVE 1 TO WS-FIELD-VALID
               END-EVALUATE
           END-PERFORM.

       EDIT-PROFILE-SECTION SECTION.
           PERFORM LOAD-PROFILE-SECTION
           MOVE "--- Create/Edit Profile ---" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           IF WS-PROFILE-FOUND = 1
               MOVE "Re-enter all fields to replace your profile."
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-IF
      * Disk record is unchanged until every field is collected.
           INITIALIZE PROFILE-RECORD
           MOVE WS-INPUT-USERNAME TO PF-USERNAME
           MOVE "Enter First Name (max 50):" TO WS-PROMPT
           MOVE 50 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-FIRST
           MOVE "Enter Last Name (max 50):" TO WS-PROMPT
           MOVE 50 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-LAST
           MOVE "Enter University/College (max 100):" TO WS-PROMPT
           MOVE 100 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-UNIVERSITY
           MOVE "Enter Major (max 100):" TO WS-PROMPT
           MOVE 100 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-MAJOR
           PERFORM UNTIL PF-YEAR NOT = SPACES
               MOVE "Enter Graduation Year (2026-2033):" TO WS-PROMPT
               MOVE 4 TO WS-FIELD-LIMIT
               MOVE 1 TO WS-FIELD-REQUIRED
               PERFORM READ-PROFILE-FIELD-SECTION
               IF WS-FIELD-LENGTH = 4
                   AND WS-INPUT-LINE(1:4) IS NUMERIC
                   AND WS-INPUT-LINE(1:4) >= "2026"
                   AND WS-INPUT-LINE(1:4) <= "2033"
                   MOVE WS-INPUT-LINE TO PF-YEAR
               ELSE
                   MOVE "Enter a four-digit year from 2026 to 2033."
                       TO WS-MESSAGE
                   PERFORM PRINT-AND-LOG-SECTION
               END-IF
           END-PERFORM
           MOVE "Enter About Me (max 200; blank to skip):" TO WS-PROMPT
           MOVE 200 TO WS-FIELD-LIMIT
           MOVE 0 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-ABOUT
           MOVE 0 TO WS-ENTRY-DONE
           PERFORM VARYING WS-PROFILE-INDEX FROM 1 BY 1
               UNTIL WS-PROFILE-INDEX > 3 OR WS-ENTRY-DONE = 1
               PERFORM READ-EXPERIENCE-SECTION
           END-PERFORM
           MOVE 0 TO WS-ENTRY-DONE
           PERFORM VARYING WS-PROFILE-INDEX FROM 1 BY 1
               UNTIL WS-PROFILE-INDEX > 3 OR WS-ENTRY-DONE = 1
               PERFORM READ-EDUCATION-SECTION
           END-PERFORM
           IF WS-PROFILE-FOUND = 1
               REWRITE PROFILE-RECORD
           ELSE
               WRITE PROFILE-RECORD
           END-IF
           IF WS-PROFILE-STATUS NOT = "00"
               PERFORM PROFILE-ERROR-SECTION
           END-IF
           CLOSE PROFILE-FILE
           MOVE 0 TO WS-PROFILE-OPEN
           IF WS-PROFILE-STATUS NOT = "00"
               PERFORM PROFILE-ERROR-SECTION
           END-IF
           MOVE "Profile saved successfully!" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "Returning to main menu." TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION.

       READ-EXPERIENCE-SECTION SECTION.
           MOVE WS-PROFILE-INDEX TO WS-ENTRY-NUMBER
           MOVE SPACES TO WS-PROMPT
           STRING "EXPERIENCE #" WS-ENTRY-NUMBER
               " - Title (max 100; DONE to finish):"
               DELIMITED BY SIZE INTO WS-PROMPT
           MOVE 100 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           IF FUNCTION UPPER-CASE(WS-INPUT-LINE) = "DONE"
               MOVE 1 TO WS-ENTRY-DONE
               EXIT SECTION
           END-IF
           MOVE WS-INPUT-LINE TO PF-TITLE(WS-PROFILE-INDEX)
           MOVE "Company/Organization (max 100):" TO WS-PROMPT
           MOVE 100 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-COMPANY(WS-PROFILE-INDEX)
           MOVE "Dates (max 50):" TO WS-PROMPT
           MOVE 50 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-DATES(WS-PROFILE-INDEX)
           MOVE "Description (blank to skip) (max 100):" TO WS-PROMPT
           MOVE 100 TO WS-FIELD-LIMIT
           MOVE 0 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-DESCRIPTION(WS-PROFILE-INDEX)
           ADD 1 TO PF-EXP-COUNT.

       READ-EDUCATION-SECTION SECTION.
           MOVE WS-PROFILE-INDEX TO WS-ENTRY-NUMBER
           MOVE SPACES TO WS-PROMPT
           STRING "EDUCATION #" WS-ENTRY-NUMBER
               " - Degree (max 100; DONE to finish):"
               DELIMITED BY SIZE INTO WS-PROMPT
           MOVE 100 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           IF FUNCTION UPPER-CASE(WS-INPUT-LINE) = "DONE"
               MOVE 1 TO WS-ENTRY-DONE
               EXIT SECTION
           END-IF
           MOVE WS-INPUT-LINE TO PF-DEGREE(WS-PROFILE-INDEX)
           MOVE "University/College (max 100):" TO WS-PROMPT
           MOVE 100 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-SCHOOL(WS-PROFILE-INDEX)
           MOVE "Years Attended (max 50):" TO WS-PROMPT
           MOVE 50 TO WS-FIELD-LIMIT
           MOVE 1 TO WS-FIELD-REQUIRED
           PERFORM READ-PROFILE-FIELD-SECTION
           MOVE WS-INPUT-LINE TO PF-YEARS(WS-PROFILE-INDEX)
           ADD 1 TO PF-EDU-COUNT.

       VIEW-PROFILE-SECTION SECTION.
           PERFORM LOAD-PROFILE-SECTION
           IF WS-PROFILE-FOUND = 0
               MOVE "No profile found. Choose Create/Edit My Profile."
                   TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               EXIT SECTION
           END-IF
           MOVE "--- Your Profile ---" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION

            MOVE SPACES TO WS-MESSAGE
            STRING "==== Profile for "
               FUNCTION TRIM(PF-FIRST)
               " "
               FUNCTION TRIM(PF-LAST)
               DELIMITED BY SIZE
               INTO WS-MESSAGE
            PERFORM PRINT-AND-LOG-SECTION

           STRING "First Name: " FUNCTION TRIM(PF-FIRST)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "Last Name: " FUNCTION TRIM(PF-LAST)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "University: " FUNCTION TRIM(PF-UNIVERSITY)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "Major: " FUNCTION TRIM(PF-MAJOR)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "Graduation Year: " FUNCTION TRIM(PF-YEAR)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           STRING "About Me: " FUNCTION TRIM(PF-ABOUT)
               DELIMITED BY SIZE INTO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           MOVE "Experience:" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           IF PF-EXP-COUNT = 0
               MOVE "None provided." TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-IF
           PERFORM VARYING WS-PROFILE-INDEX FROM 1 BY 1
               UNTIL WS-PROFILE-INDEX > PF-EXP-COUNT
               STRING "Title: "
                   FUNCTION TRIM(PF-TITLE(WS-PROFILE-INDEX))
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               STRING "Company: "
                   FUNCTION TRIM(PF-COMPANY(WS-PROFILE-INDEX))
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               STRING "Dates: "
                   FUNCTION TRIM(PF-DATES(WS-PROFILE-INDEX))
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               STRING "Description: "
                   FUNCTION TRIM(PF-DESCRIPTION(WS-PROFILE-INDEX))
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-PERFORM
           MOVE "Education:" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION
           IF PF-EDU-COUNT = 0
               MOVE "None provided." TO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-IF
           PERFORM VARYING WS-PROFILE-INDEX FROM 1 BY 1
               UNTIL WS-PROFILE-INDEX > PF-EDU-COUNT
               STRING "Degree: "
                   FUNCTION TRIM(PF-DEGREE(WS-PROFILE-INDEX))
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               STRING "University: "
                   FUNCTION TRIM(PF-SCHOOL(WS-PROFILE-INDEX))
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
               STRING "Years: "
                   FUNCTION TRIM(PF-YEARS(WS-PROFILE-INDEX))
                   DELIMITED BY SIZE INTO WS-MESSAGE
               PERFORM PRINT-AND-LOG-SECTION
           END-PERFORM
           MOVE "--------------------" TO WS-MESSAGE
           PERFORM PRINT-AND-LOG-SECTION.

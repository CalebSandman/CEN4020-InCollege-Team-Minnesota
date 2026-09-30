# InCollege - Epic 2

COBOL console application with account registration/login and personal profiles.

## Menus and input order
All selections and values come from `data/input.txt`, one value per line.
No keyboard input is used. Keep blank lines for optional values.

Before login: 1 Login, 2 Register, 3 Exit. Register does not automatically log in.
After login: 1 Create/Edit My Profile, 2 View My Profile, 3 Find a job/internship,
4 Find someone you know, 5 Learn a new skill, 6 Logout / Exit.
Skills retain their existing six-item menu. Logout ends execution as in Epic 1.

After selecting profile creation/editing, supply these lines in order:

1. First name (required, max 50 characters).
2. Last name (required, max 50).
3. University/college (required, max 100).
4. Major (required, max 100).
5. Graduation year (exactly four digits, 2026 through 2033 inclusive).
6. About Me (blank allowed, max 200).
7. Experience title (max 100), or `DONE` to finish experience.
   If a title is entered, follow it with company (required, max 100),
   dates (required, max 50), and description (blank allowed, max 100).
   Repeat up to three entries. After the third entry, education starts
   immediately: **do not insert another DONE line**.
8. Education degree (max 100), or `DONE` to finish education.
   If a degree is entered, follow it with university (required, max 100)
   and years attended (required, max 50). Repeat up to three entries.
   After the third entry, the profile saves immediately: no extra DONE.
9. Next main-menu selection (for example 2 to view, or 6 to exit).

`DONE` is case-insensitive and only recognized at experience title/education
degree prompts. An invalid field consumes its line and re-prompts for the same
field. Leading/trailing spaces are trimmed from profile fields. Optional
sections are omitted with DONE; blank titles/degrees are rejected.

Editing replaces the entire profile: re-enter required fields and all entries
you want to keep. About Me and DONE for both lists clear optional data.
The old saved record is untouched if the input ends partway through editing.
After a successful save, the application automatically returns to the main
menu, where the user can view the profile or exit. The menu is also shown
again after viewing.

## Files and storage

- `data/accounts.dat`: existing Epic 1 account data (maximum five accounts).
- `data/profiles.dat`: indexed profile records keyed by the login username.
  GnuCOBOL backends may create companion files; preserve them together.
  This is runtime data, not a text file to edit or commit. Single-process use
  is assumed; indexed files may not be portable between compiler backends.
- `data/input.txt`: required scripted input; maximum supported line 4096 bytes.
  Profile values are limited further as listed above. Use ordinary text lines.
- `data/output.txt`: transcript, overwritten on each run.
- All application output is displayed and logged with identical trailing-space
  handling. Existing input echoing is retained, including demo passwords.
  Use fictional credentials in shared input/output files.
- End of input prints ` END_OF_PROGRAM_EXECUTION` and closes files.
- Storage failures print an error and exit without a success message.

The assignment's example displays 2025, but its explicit rule is greater than
2025 and less than 2034. The implementation follows that explicit rule.

# InCollege - Epic 4

Epic 4 adds connection request functionality to the existing InCollege system.

Users can now:

- Send a connection request to another user after finding and viewing their profile.
- Persistently store pending connection requests.
- View pending connection requests that were sent to them.

All Epic 4 input continues to be read from `data/input.txt`, and all output is displayed on the console and written to `data/output.txt`.

## Updated Main Menu

After login, the main menu now includes:

1. Create/Edit My Profile
2. View My Profile
3. View My Pending Connection Requests
4. Find someone you know
5. Learn a new skill
6. Logout / Exit

## Sending a Connection Request

To send a connection request:

1. Select `4. Find someone you know`.
2. Enter the full name of the user to search for.
3. If the user is found, their profile is displayed.
4. The following options are shown:

   1. Send Connection Request
   2. Back to Main Menu

5. Select `1` to send the connection request.

A successful request displays a message similar to:

`Connection request sent to <user name>`

Pending requests are saved in:

`data/requests.dat`

The request record stores the sender and receiver information so the request can still be retrieved after the program is closed and reopened.

## Connection Request Validation

- Before saving a new request, the program checks for an existing pending request between the two users.
- If a pending request already exists, the program displays:
- A connection request already exists with this user.`
- The program also prevents a user from sending a connection request to themselves.

## Viewing Pending Connection Requests

To view pending requests, select:

`3. View My Pending Connection Requests`

The program displays all pending connection requests sent to the currently logged-in user.

## Viewing Pending Connection Requests

To view pending requests, select:

`3. View My Pending Connection Requests`

The program displays all pending connection requests sent to the currently logged-in user.
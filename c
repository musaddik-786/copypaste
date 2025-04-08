User Story 1: Automatic Transaction Creation from Bind State

Title:
Automatic Creation of Post-Bind Transaction

User Story:
As a system, when the broker sends the FON acceptance and the workbench processes the email and attachments, I want the system to automatically create a transaction for post-bind data entry so that the underwriter can immediately review and validate the details.

Acceptance Criteria:

Given the broker sends the FON acceptance (Bind State)
When the workbench receives the email with attachments and auto-extracts details,
Then the system must tag the data with the correct submission or policy reference and automatically create a transaction for post-bind data entry.

Given the quotes for a unique reference number are displayed (defaulting to the most recent one),
When the underwriter or system processes the data,
Then the transaction should include the quote reference number and all relevant details extracted from the Bind State phase.



---

User Story 2: Post-Bind Data Validation and Manual Update

Title:
Validate and Update Post-Bind Data on Workbench

User Story:
As a post-bind data entry user, I want to see the attached documents and a checklist/form pre-populated with data pulled from the pre-bind phase so that I can validate the information, make any necessary manual updates (such as selecting a category), and ensure data accuracy before finalizing the transaction.

Acceptance Criteria:

Given the post-bind transaction is auto-created from the Bind State,
When the user opens the transaction on the workbench,
Then the UI must display all attached documents and the relevant checklist/form with pre-populated details (including the quote reference).

Given the pre-populated fields (e.g., from auto-extracted details),
When the user inspects the data,
Then the user must be allowed to manually update any field, with particular emphasis on selecting or updating the “category” field as needed.

Given the user has performed the necessary validations and manual corrections,
When the user clicks the “Save” button,
Then the updated data must be persisted in the database with a confirmation message.



---

User Story 3: Notification and Reporting Post Data Update

Title:
Trigger Notification and Consistent Reporting After Data Update

User Story:
As a system, after the post-bind data entry fields are updated and saved, I want to automatically send an email notification to the designated trigger group and ensure that all subsequent reporting reflects the updated “category” field so that all stakeholders are alerted and future reports remain consistent.

Acceptance Criteria:

Given the user has saved the post-bind data entry transaction successfully,
When the transaction is updated,
Then the system must trigger an automated email to the appropriate trigger group indicating that the post-bind data entry fields have been updated.

Given that the “category” field is updated as part of the manual validation,
When subsequent reporting is generated,
Then all reports must reflect the current value of the “category” field to ensure consistent categorization across records.













As an underwriter (or post-bind data entry user), I want to view and validate the documents and data automatically pulled from the pre-bind phase so that I can make any necessary corrections, update the category fields, and save the transaction, ensuring that an email notification is triggered and the reporting is accurate based on the updated category information.


---

Acceptance Criteria

1. Document Visibility and Checklist Display

Given a transaction has moved from pre-bind to the post-bind data entry phase,

When the user accesses the transaction,

Then all attached documents (e.g., emails, attachments, pre-bind documents) should be visible, and the associated checklist/form should open automatically on the workbench.

And the quote reference number must be clearly displayed within the document.



2. Data Validation and Manual Update

Given data pulled from the pre-bind database is loaded on the UI,

When the user reviews the transaction details,

Then the user should be able to manually update any fields, particularly those associated with the “category” of the transaction.

And the system should allow field-level updates to capture corrections or further details as needed.



3. Save Operation and Data Persistence

Given the user has validated and made necessary updates on the transaction form,

When the user clicks the “Save” button,

Then the updated transaction details should be accurately saved to the database.



4. Email Notification Trigger

Given the successful save operation,

When the transaction details are updated,

Then an email notification should be sent automatically to the designated trigger group.

And the email must clearly indicate that the post-bind data entry fields have been updated.



5. Reporting Based on Updated Category

Given the “category” field has been updated (or confirmed) during the save operation,

When subsequent reports are generated,

Then all reporting should use the current value of the “category” field to ensure accurate categorization of the transaction.

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

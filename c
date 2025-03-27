User Story No	User Story Title	User Story	Acceptance Criteria
US1	System Notifies Customer About Upcoming Renewal 	"As a system,
I want to automatically send renewal reminders to customers via email/SMS,
So that they are aware of their upcoming policy renewal and can take timely action.

Note: This is not a part of the POC. To show the continuity of the Use Case this User Story is created."	"1. The system should check the policy database for policies expiring within the next 45 days.
2. The system should trigger an automated email/SMS reminding the customer of renewal includes the renewal quotes
3. The notification should include below details:
-Policy number
-Expiry date
-Instructions to renew via the contact center or online
4. If the customer has already renewed, the system should suppress the notification.

Pre-requisites: 
1. This notification is sent based on renewal conditions and prompts the customer to contact the CC for any clarifications. 
2. Renewal quotes are generated prior 45 days from the expiration date. These are only renewal quotes without change in coverage"
US2.1	Option #1: AI Agent Initiates Outbound Call for Renewal Verification	"As an AI agent,
I want to call the customer based on 
 - the policy renewal date or 
 - post 15 days of renewal reminder 
   And verify Customer identity
So that if the caller is not the valid customer I can instruct them to transfer the call, and if they are the valid customer, I can proceed with processing their renewal."	"1. The AI agent must greet the customer to confirm the name from the policy record with the caller
2. If the caller is NOT the customer:
 - The AI agent must request to transfer the call to the customer
 - The incident shall be logged and escalated for follow-up by a human agent.
3. If the caller is the valid customer:
 - The AI agent must confirm the customer identity with DOB. 
 - Once confirmed, the AI agent must confirm key details including the policy number and expiry date.
4. AI Agent proceeds with the further renewal process"
US2.2	Option #2: Customer calls AI Agent after receiving the Renewal Notice	"As an AI agent, given the customer calls for the renewal then
I want to ask for the reason of the call and identity proof
So that I validate the customer's identity and guide them as per the reason of the call"	"1. The AI agent must inform the customer that the call may be recorded.
2. The AI agent must ask the customer to confirm the purpose of the call.
3. The AI agent must prompt the customer to provide the DOB if the call is for the renewal
4. The AI must validate the DOB against the system details
5. If the provided data is incorrect or does not match system records, the AI agent must prompt the customer to re-enter the information with valid error message
5. If the details are verified, AI agent should proceed; otherwise, transfer to a human agent."
US3	AI Agent Provides Policy Renewal Details	"As an AI agent, 
I want to inform the customer about their policy expiration and want to understand whether any change in Coverage 
So that the Customer can renew the policy with updated Coverage (if applicable)."	"1. AI agent should retrieve the details and communicate the policy expiry date.
2. AI agent should ask for the updates in the policy:
-Coverage type
-Vehicle details
-Named drivers
3. If changes are requested, (refer to sheet ""with change in coverage"" for user stories
4. If no changes are needed, AI should proceed with the renewal process."
US4	AI Agent Confirms Renewal Amount and Payment Option	"As an AI agent,
I want to retrieve the updated renewal premium based on the coverage changes (if applicable) and offer customer multiple payment options
So that the customer can confirm the premium and complete the renewal transaction conveniently."	"1. The AI agent shall fetch the updated premium amount from the system reflecting the coverage changes.
2. The agent shall confirm the renewal cost with the customer and explain any adjustments due to coverage modifications.
3. AI agent confirms to proceed with the payment from the customer
3. AI should offer multiple payment methods:
-Credit card
-Debit card
-Bank transfer
-Payment link
5. AI should confirm the selected payment method and proceed accordingly.
6. If the customer has additional queries with the pricing, the AI agent must transfer the call to the human agent"
US5	AI Agent Collects and Processes Payment	"As an AI agent,
I want to securely collect and process the customer's payment details
So that I can complete the policy renewal transaction that includes the updated coverage modifications (where applicable)."	"1. The AI agent confirms one of the payment method: 
- Credit card
- Debit card
- Account transfer
- Payment link
2. When the customer opts to pay via card, the AI must request the following details:
- Card number
- Expiry date
3. The AI agent should validate the provided card details before processing the payment.
4. When the customer chooses to pay via a payment link, the AI must send the payment link to the customer
5. The AI agent must validate all payment details (card or payment link) before initiating the transaction.
6. If the payment fails:
The AI agent should allow the user to retry the payment.
7. Upon successful payment:
The AI agent must confirm the transaction with the user."
US6	AI Agent Confirms Successful Renewal and Sends Policy Documents	"As an AI agent,
I want to confirm the successful renewal and send the updated policy documents that include the new coverage changes,
So that the customer receives complete and accurate documentation of their renewed policy."	"1. The AI agent must confirm that the payment was successful and that the renewal is complete with the existing coverage and confirms the policy number
2. The AI agent notifies the PAS system with the details
3. System generates the documents and sends to the customer via email/SMS within next 24hrs and AI agent communicates that the physical letter will reach in 7-10 business days. 
4. The AI agent should log the completion of the renewal process, including timestamps for all key steps."
US7	AI Agent Closes the Call 	"As an AI agent,
I want to close the call after confirming successful renewal,
So that the Customer is fully informed, satisfied with the renewal process, and has clear instructions for future support."	"1. The AI agent confirms the policy renewal details with successful payment
2. The AI agent must provide instructions for contacting support if customer wants 
-  Any further queries/additional information 
- In case of any queries AI agent asks the customer to contact support or transfer the call to the human agent
3.The AI agent must for the feedback
4. The AI agent should log the call closure and any additional customer remarks.
5. The system should archive the call transcript for audit and future reference."

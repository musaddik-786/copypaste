User Story Title	User Story	Acceptance Criteria
System Notifies Customer About Upcoming Renewal 	"As a system,
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
Option #1: AI Agent Initiates Outbound Call for Renewal Verification	"As an AI agent,
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
Option #2: Customer calls AI Agent after receiving the Renewal Notice	"As an AI agent, given the customer calls for the renewal then
I want to ask for the reason of the call and identity proof
So that I validate the customer's identity and guide them as per the reason of the call"	"1. The AI agent must inform the customer that the call may be recorded.
2. The AI agent must ask the customer to confirm the purpose of the call.
3. The AI agent must prompt the customer to provide the DOB if the call is for the renewal
4. The AI must validate the DOB against the system details
5. If the provided data is incorrect or does not match system records, the AI agent must prompt the customer to re-enter the information with valid error message
5. If the details are verified, AI agent should proceed; otherwise, transfer to a human agent."
AI Agent Provides Policy Renewal Details	"As an AI agent, 
I want to inform the customer about their policy expiration and want to understand whether any change in Coverage 
So that the Customer can renew the policy with updated Coverage (if applicable)."	"1. AI agent should retrieve the details and communicate the policy expiry date.
2. AI agent should ask for the updates in the policy:
-Coverage type
-Vehicle details
-Named drivers
3. If changes are requested, (refer to sheet ""with change in coverage"" for user stories
4. If no changes are needed, AI should proceed with the renewal process."
"AI Agent Presents Coverage Modification Options
"	"As an AI agent,
I want to provide customer with possible options to update the coverage during renewal,
So that customer can renew the policy with all the updates."	"1. The AI agent shall retrieve the current coverage details from the system.
2. The agent shall ask which coverage the customer wish to update (For example: driver details, vehicle details, coverage limits, optional add-ons, or usage type.)

Option #1: The Customer might mention one or more of the following :
a.Driver Details Update (Driver Addition,Existing Driver Removal, Existing Driver Details Modification)
b.Vehicle Details (Vehicle Addition, Vehicle Removal, Vehicle Replacement)
c.Non-Driver Details Update (Non-Driver Addition,Non-Driver Removal, Non-Driver Details Modification)
d.Change in Coverages (Limits and Optional Add-Ons)
e.Change in Vehicle Usage Type During Renewal

2.1. If the customer opts to modify coverage from above mentioned [For POC, the Customers asks for Driver Addition and Vehicle Addition], 
        Then 
          a. the agent shall reconfirm the customers selection.
          b. The customer’s selection shall be logged and will be proceeded accordingly.
2.2. Else If the customer wants to modify anything other than above mentioned
        Then AI agent should ask for confimation to route the call to human agent.
Option #2: If the customer mentions no changes in the Coverage, the agent shall confirm that the existing coverage will be renewed as is. That will be covered as part of US4 of ""Without change in Coverage"" tab
"
AI Agent adds a Driver to the Policy	"As an AI agent,
I want to ask the customer relevant to addition of a driver 
So that the policy gets renewed accurately with the driver details and the premium is recalculated accordingly
"	"1. The AI agent must ask the customer whether the customer wants to add a new driver to their policy
2. The AI agent shall retrieve the current list of covered drivers from the policy record 
3. The AI agent should ask for the following details one by one:
- New driver’s full name?
- date of birth (DOB)
- driver’s license number (and expiration date, if available)
- relationship to the policyholder
- last 4 digits of their SSN (if applicable)
- drinking and smoking habits
4. If any detail is missing or invalid, the AI agent shall display an appropriate error message and asks the customer to re-enter the correct information (up to two retries).
5. AI Agent should send those information to PAS System and PAS system internally connects to Quoting and Rating Engine.
6. PAS System recalculates the Premium amount and send it to AI Agent.
7. AI agent will then confirms the Driver addition and ask the customer whether he/she wants to add a new vehicle as he/she mentioned before. "
AI Agent adds a Vehicle to the Policy	"As an AI agent,
I want to ask the customer relevant to addition of a Vehicle 
So that the policy gets renewed accurately with the new vehicle details and the premium is recalculated accordingly
"	"1. The AI agent shall retrieve the current list of vehicles from the policy record.
2. The agent shall confirm that the customer has selected “Add New Vehicle.”
3. The agent should ask for the following details one by one:
 - Vehicle Make and Model
 - Vehicle Identification Number (VIN)
 - Registration Number
 - Details of any Modifications or Upgrades (e.g., aftermarket parts, performance upgrades)
 - Primary Parking Location (e.g., garage, driveway, street)
4. If any detail is missing or invalid, the AI agent shall display an appropriate error message and asks the customer to re-enter the correct information (up to two retries).
5. AI Agent should send those information to PAS System and PAS system internally connects to Motor Vehicle Info system.
6. PAS System recalculates the Premium amount and send it to AI Agent.
7. AI agent will then confirms the Vehicle addition and ask the customer whether he/she wants to add / modify any other details
8. If Yes, then again some more discussions which are not part of the POC
    If No, then AI Agent continues to payment Process."
AI Agent Confirms Renewal Amount and Payment Option	"As an AI agent,
I want to retrieve the updated renewal premium based on the coverage changes 
  And share multiple payment options with customer
So that the customer can confirm the premium and complete the renewal transaction conveniently."	"1. The AI agent shall fetch the updated premium amount from the system reflecting the coverage changes.
2. The agent shall confirm the renewal cost with the customer and explain the adjustments due to the coverage modifications(Driver and Vehicle addition).
3. The AI agent asks whether the customer wants to pay now
    If Customer does not want to pay now
    Then  
     - AI Agent shares the payment link in Customers email and asks them to complete the payment
     - If the customer has additional queries with the pricing, the AI agent must transfer the call to the human agent
    Else 
     - AI agent confirms to proceeed with the payment from the customer
     - AI should offer multiple payment methods:
          - Credit card
          - Debit card
          - Bank transfer
          - Payment link
     - AI should confirm the selected payment method and proceed accordingly."
AI Agent Collects and Processes Payment	"As an AI agent,
I want to securely collect and process the customer's payment details
So that I can complete the policy renewal transaction that includes the updated coverage modifications (where applicable)."	"1. The AI agent confirms one of the payment method: 
- Credit card
- Debit card
- Account transer
- Payment link
2. When the customer opts to pay via card, the AI must request the following details:
- Card number
- Expiry date
3. The AI should validate the provided card details before processing the payment.
4. When the customer chooses to pay via a payment link, the AI must send the payment link to the customer
5. The AI must validate all payment details (card or payment link) before initiating the transaction.
6. If the payment fails:
The AI should allow the user to retry the payment.
7. Upon successful payment:
The AI must confirm the transaction with the user."
AI Agent Confirms Successful Renewal and Sends Policy Documents	"As an AI agent,
I want to confirm the successful renewal and send the updated policy documents that include the new coverage changes,
So that the customer receives complete and accurate documentation of their renewed policy."	"1. The AI agent must confirm that the payment was successful and that the renewal is complete with the existing coverage and confirms the policy number
2. The AI agent notifies the PAS system with the details
3. System generates the documents and sends to the customer via email/sms within next 24hrs and AI agent communicates that the physical letter will reach in 7-10 business days. 
4. The AI agent should log the completion of the renewal process, including timestamps for all key steps."
AI Agent Closes the Call 	"As an AI agent,
I want to close the call after confirming successful renewal,
So that the Customer is fully informed, satisfied with the renewal process, and has clear instructions for future support."	"1. The AI agent confirms the policy renewal details
2. The AI agent must provide instructions for contacting support if customer wants 
-  Any futher queries/additional information 
- In case of any queries AI agent asks the customer to contact support .
3.The AI agent must for the feedback
4. The AI agent should log the call closure and any additional customer remarks.
5. The system should archive the call transcript for audit and future reference."

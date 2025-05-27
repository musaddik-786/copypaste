Coding Challenge: Hospital Management System 

•	Project submissions should be done through the partcipants’ Github repository and the link should be shared with trainers and Hexavarsity. 

•	Follow object-oriented principles throughout the project. Use classes and objects to model realworld entities, encapsulate data and behavior, and ensure code reusability. 

•	Throw user defined exceptions from corresponding methods and handled. 

•	The following Directory structure is to be followed in the application.  

o	entity 

▪	Create entity classes in this package. All entity class should not have any business logic. o 	dao 

▪	Create Service Provider interface to showcase functionalities. 

▪	Create the implementation class for the above interface with db interaction. o 	exception 

▪	Create user defined exceptions in this package and handle exceptions whenever needed. 

o	util 

▪	Create a DBPropertyUtil class with a static function which takes property file name as parameter and returns connection string. 

▪	Create a DBConnUtil class  which holds static method which takes connection string as parameter file and returns connection object(Use method defined in DBPropertyUtil class to get the connection String). o 	main 

▪	Create a class MainModule and demonstrate the functionalities in a menu driven application. 

 

Problem Statement: 

 

 1Create SQL Schema from the following classes class, use the class attributes for table column names. 

  

1. Create the following model/entity classes within package entity with variables declared private, constructors(default and parametrized,getters,setters and toString()) 

 

1.	Define  `Patient` class with the following confidential attributes:  

 

a.	patientId 

b.	firstName 

c.	lastName;  

d.	dateOfBirth 

e.	gender 

f.	contactNumber 

g.	address; 

2.	Define  ‘Doctor` class with the following confidential attributes: 

a.	doctorId 

b.	firstName 

c.	lastName 

d.	specialization 

e.	contactNumber;  

3.	Appointment Class: 

a.	appointmentId 

b.	patientId  

c.	doctorId 

d.	appointmentDate 

e.	description 

 

2.	Implement the following for all model classes. Write default constructors and overload the constructor with parameters, getters and setters, method to print all the member variables and values.  

 

3.	Define IHospitalService interface/abstract class with following methods to interact with database  

Keep the interfaces and implementation classes in package dao 

 

a.	getAppointmentById() 

i.	Parameters: appointmentId 

ii.	ReturnType: Appointment object 

b.	getAppointmentsForPatient() 

i.	Parameters: patientId 

ii.	ReturnType: List of Appointment objects 

 

c.	getAppointmentsForDoctor() 

i.	Parameters: doctorId 

ii.	ReturnType: List of Appointment objects 

 

d.	scheduleAppointment() 

i.	Parameters: Appointment Object 

ii.	ReturnType: Boolean 

 

e.	updateAppointment() 

i.	Parameters: Appointment Object 

ii.	ReturnType: Boolean 

 

f.	ancelAppointment() 

i.	Parameters: AppointmentId ii. ReturnType: Boolean 

 

6.	Define HospitalServiceImpl class and implement all  the methods  IHospitalServiceImpl . 

7.	Create a utility class DBConnection  in a package util  with  a static variable connection of Type Connection and a static method getConnection() which returns connection. 

Connection properties supplied in the connection string should be read from a property file. 

Create a utility class PropertyUtil which contains a static method named getPropertyString()  which reads a property fie containing connection details like hostname, dbname, username, password, port number and returns a connection string. 

8.	Create the exceptions in package myexceptions 

 Define the following custom exceptions and throw them in methods whenever needed. Handle all the exceptions in main method, 

1. PatientNumberNotFoundException :throw this exception when user enters an invalid patient number which doesn’t exist in db 

9.	Create class named MainModule with main method in   package mainmod. 

Trigger all the methods in service implementation class. 



















Policyholder Name: ABC Enterprises
Policy Type: Commercial Property Insurance
Decision: Approved with Standard Terms
Rationale:
The risk assessment for the insured property located at 123 Business Avenue was conducted based on the following factors:
Property Details: The property is a two-story commercial building constructed in 2015, with a total insured value (TIV) of $5 million. The building is primarily used for office purposes, with no hazardous operations conducted on-site. The property is well-maintained and complies with local building codes.
Location Risk: The property is situated in a low-risk area with minimal exposure to natural catastrophes. It is not located in a flood-prone zone, and the seismic risk is negligible based on the latest geospatial data.
Fire Protection Measures: The building is equipped with a modern sprinkler system, fire alarms, and extinguishers, all of which are inspected annually. The nearest fire station is within a 5-minute response time, further mitigating fire risk.
Security Measures: Adequate security measures are in place, including CCTV cameras, access control systems, and a 24/7 security guard presence.
Claims History: The insured has a clean claims history for the past five years, indicating a proactive approach to risk management.
Occupancy and Usage: The building is leased to reputable tenants with stable financials. There are no high-risk activities or hazardous materials stored on the premises.
Additional Considerations:
A minor concern was identified regarding the roof's age, which is nearing the end of its expected lifespan. A recommendation has been made to replace the roof within the next two years to maintain coverage.
The insured has agreed to implement additional risk mitigation measures, including upgrading the fire suppression system in the warehouse area.
Conclusion:
Based on the above factors, the risk is deemed acceptable, and the policy is approved with standard terms. The insured's proactive risk management practices and low-risk profile justify the decision. The policy includes a standard deductible of $10,000 and a premium rate of 0.25 per $100 of coverage.




Policyholder: ABC Enterprises

Policy Type: Commercial Property Insurance

Decision: Approved with standard terms

Property Details:

Two-story commercial building (office use) built in 2015

Total insured value (TIV): $5 million

Well-maintained; compliant with local building codes


Location Risk:

Situated in a low-risk area

Minimal exposure to natural catastrophes

Not in a flood-prone zone; negligible seismic risk


Fire Protection Measures:

Modern sprinkler system, fire alarms, extinguishers

Annual inspections

Nearest fire station within a 5-minute response time


Security Measures:

CCTV cameras and access control systems

24/7 security guard presence


Claims History:

No claims in the past five years

Indicates proactive risk management


Occupancy & Usage:

Leased to reputable tenants with stable financials

No hazardous operations or materials on-site


Additional Considerations:

Roof nearing end of expected lifespan; replacement recommended within two years

Insured to upgrade fire suppression in warehouse area


Conclusion & Terms:

Overall risk: acceptable

Standard deductible: $10,000

Premium rate: $0.25 per $100 of coverage

Approval justified by low-risk profile and strong risk management practices































# Prompt for AI PPT Generator

**Presentation Title:**  
AI-Driven Insurance Renewal Use Case – Commercial & Specialty Lines POC

**Design Guidance:**  
- **Template:** Clean corporate theme (blue/teal accents)  
- **Fonts:** Sans-serif (headings 32 pt, body 20 pt)  
- **Colors:** Primary #005b96 (navy), Accent #0096c7 (teal)  
- **Icons & SmartArt:**  
  - Use calendar, database, AI/robot, user-customer icons  
  - Flowcharts for end-to-end processes  
  - Highlight “AI Bot” and “Customer” nodes in accent color  

---

## Slide 1: Title & Objective  
- **Title:** AI-Driven Insurance Renewal Use Case – Commercial & Specialty Lines  
- **Subtitle:** Proof of Concept – End-to-End Automation  
- **Footer:** Date: May 24, 2025 | Presenter: [Your Name]  

**Key Bullet:**  
> Showcase how AI & data-driven rating models automate renewals, with and without coverage changes.

---

## Slide 2: Agenda  
1. Objective & Scope  
2. Data Solution & Rating Model  
3. Workflow Overview (Customer-Driven)  
4. Use Case A: Renewal WITHOUT Coverage Change  
5. Use Case B: Renewal WITH Coverage Change  
6. Decision Rules & AI Criteria  
7. Benefits & Next Steps  

---

## Slide 3: Objective & Scope  
- **Objective:** Automate commercial & specialty policy renewals end-to-end, minimizing manual work  
- **Scope:**  
  - **Lines:** Property, Casualty, Marine, Cyber, Directors & Officers  
  - **Scenarios:**  
    1. Standard renewal (no coverage edits)  
    2. Renewal with customer-initiated coverage changes  

---

## Slide 4: Data Solution & Rating Model  
**Data Inputs (table or icon list):**  
- Policy & exposure data (limits, deductibles, schedules)  
- Business metrics (revenue, payroll, fleet size)  
- Claims & loss history  
- External factors (catastrophe models, inflation indices, market rates)  

**AI/ML Components (bullet list):**  
- **Predictive Retention Model:** Forecast renewal likelihood  
- **Risk Assessment Engine:** Flag anomalies & fraud  
- **Dynamic Rating Engine:** Real-time premium calculation via API  
- **NLG Module:** Auto-compose personalised renewal offers  
- **Chatbot Interface:** Guide customers through options  

---

## Slide 5: Workflow Overview (Customer-Driven Flowchart)  
*Flowchart with two swimlanes (Customer vs AI System)*  
1. **Customer**: Renewal reminder arrives → Clicks “Review Policy”  
2. **AI System**: Extract policy & exposure data  
3. **AI System**: Run risk & claims analysis  
4. **Decision Point** (Customer node):  
   - Choose “Proceed as-is”  
   - Or “Request Coverage Change”  
5a. **If as-is**: AI Bot generates renewal quote → Customer reviews & pays → Issue policy  
5b. **If change**: Chatbot walks customer through options → Underwriter-assist AI reviews → Recalculate premium → Generate revised quote → Customer approves & pays → Issue policy  
6. **End**

---

## Slide 6: Use Case A – Renewal WITHOUT Coverage Change  
*Flowchart fragment highlighting “as-is” branch*  
- **Step 1:** Customer clicks “Renew” in portal  
- **Step 2:** AI Bot fetches policy data & runs underwriting checks  
- **Step 3:** Rating engine calculates premium (no changes)  
- **Step 4:** NLG module emails renewal quote  
- **Step 5:** Chatbot confirms payment & auto-issue  

---

## Slide 7: Use Case B – Renewal WITH Coverage Change  
*Flowchart fragment highlighting “change” branch*  
- **Step 1:** Customer selects “Modify Coverage”  
- **Step 2:** Chatbot collects change details (limits, endorsements)  
- **Step 3:** AI-assist underwriter reviews risk adjustments  
- **Step 4:** Rating engine recalculates new premium  
- **Step 5:** NLG module sends revised quote & change summary  
- **Step 6:** Customer approves via chatbot → Pays → Issue updated policy  

---

## Slide 8: Decision Rules & AI-Driven Criteria  
*SmartArt decision tree*  
- **Auto-Renew Conditions:** No open claims & ML score ≥ 0.85 → Auto-renew  
- **Coverage Change Auto-Approve:**  
  - Limit ↑ ≤ 20% & no major violations → Auto-approve  
  - Else → Underwriter-assist AI  
- **Premium Rounding:** Nearest ₹50 via AI rounding module  

---

## Slide 9: Benefits & Next Steps  
**Benefits:**  
- Turnaround time ↓ 60% with AI orchestration  
- Manual errors ↓ 90% via automated checks  
- Customer engagement ↑ through 24/7 chatbot  

**Next Steps:**  
1. Integrate AI modules with Policy Admin System  
2. Pilot on 200 commercial policies  
3. Monitor KPIs: renewal rate, cycle time, customer satisfaction  

---

## Slide 10: Thank You & Q&A  
- Contact details & feedback link

---

**Usage:**  
Copy-paste the above prompt into your AI PPT generator.  
It will produce:  
- Swimlane flowcharts showing customer & AI interactions  
- Clear “with/without change” branches  
- Tables and icon lists for data inputs & model components  
- Consistent corporate styling and SmartArt elements





















import Header from './components/Header/Header';
import InfoBar from './components/InfoBar/InfoBar';
import Card from './components/Card/Card';

function App() {
  return (
    <div style={{ display: 'flex', height: '100vh' }}>
      {/* Left sidebar */}
      <Sidebar />

      {/* Main content area */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: '#f7f8fa' }}>
        {/* Top header with search */}
        <Header />

        {/* Info bar below header */}
        <InfoBar />

        {/* Dashboard cards row */}
        <div style={{ display: 'flex', padding: '16px', gap: '16px' }}>
          {/* System Load card with a simple progress bar */}
          <Card
            title="System Load"
            value="100%"
            extra={
              <div style={{
                width: '100%',
                height: '8px',
                background: '#e0e0e0',
                borderRadius: '4px',
                overflow: 'hidden'
              }}>
                <div style={{
                  width: '100%',
                  height: '100%',
                  background: '#3b82f6',
                  borderRadius: '4px'
                }} />
              </div>
            }
          />

          {/* Active Agents card */}
          <Card
            title="Active Agents"
            value="8/8"
            extra={<span style={{ color: '#10b981', fontWeight: '500' }}>Active</span>}
          />

          {/* Response Time card */}
          <Card
            title="Response Time"
            value="800 ms"
            extra={<span style={{ fontStyle: 'italic', color: '#6b7280' }}>avg</span>}
          />
        </div>
      </div>
    </div>
  );
}

export default App;














import React from 'react';
import './InfoBar.css';

export default function InfoBar() {
  return (
    <div className="info-bar">
      <div className="left-text">
        Hexaware Technologies Ltd.
      </div>
      <div className="progress-pill">
        <span className="pill-label">JARVIS®</span>
        <span className="pill-text">metabrain&nbsp;|&nbsp;IntelliAgent</span>
      </div>
    </div>
  );
}


.info-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #eef5ff;
  padding: 8px 16px;
  border-radius: 999px;
  margin: 8px 16px; /* matches header padding */
}

.left-text {
  color: #1a4cbf;
  font-size: 0.9rem;
  font-weight: 500;
}

.progress-pill {
  display: flex;
  align-items: center;
  background: linear-gradient(90deg, #ffa500 0%, #ffb84d 100%);
  border-radius: 999px;
  padding: 4px 12px;
}

.pill-label {
  background-color: white;
  color: #ff8c00;
  font-size: 0.8rem;
  font-weight: bold;
  padding: 2px 6px;
  border-radius: 4px;
  margin-right: 8px;
}

.pill-text {
  color: white;
  font-size: 0.8rem;
}




/* src/components/Sidebar/Sidebar.css */
.sidebar {
  width: 240px;
  background-color: #1e1f22;
  color: white;
  height: 100vh;
  padding: 16px;
}

.sidebar h2 {
  margin-bottom: 24px;
  font-size: 1.25rem;
}

.nav-item {
  padding: 12px 0;
  cursor: pointer;
}
.nav-item:hover {
  background-color: #292a2e;
}


// src/components/Sidebar/Sidebar.jsx
import React from 'react';
import './Sidebar.css';

export default function Sidebar() {
  return (
    <aside className="sidebar">
      <h2>JARVIS®</h2>
      <nav>
        <div className="nav-item">Dashboard</div>
        <div className="nav-item">Use Cases</div>
        <div className="nav-item">Agents</div>
        <div className="nav-item">Insights</div>
        <div className="nav-item">Settings</div>
      </nav>
    </aside>
  );
}



















https://jarvis-intelligence-abhiroopb1.replit.app/login





Proof-of-concept for an Agentic AI renewal assistant that automates the end-to-end policy renewal workflow: from applying eligibility rules (e.g., single-policy, sub-USD 50 k premium, ≥2 prior renewals, 80 % loss ratio) and notifying upcoming expiries, to drafting renewal records, exchanging quotes with brokers, evaluating risk factors and sanctions, calculating rates via a rating model, binding accepted renewals, and finally registering policies in PAS and archiving documents in DMS—all with real-time insights, human-in-the-loop checks,









User Story No	User Story Title	User Story	Acceptance Criteria
 US 1 	Criteria and Rules	Criteria and Rules	"

Criteria and Rules:
1.Only process renewals for single policy contracts.
2.Only process renewals for policies with premiums less than 50,000 USD.
3.Only process renewals for policies that have previously been renewed twice.
4.Renew to maintain a gross loss ratio of 80% over past 3 years. "
 US 2	Agentic AI Assistant cerates Draft Renewal Record 	"As an Agentic AI Assistant, I want to be notified about policies set to expire in 3 months, 
so that I can consider them for renewal and create the Draft Renewal Record in the UWB."	"1.Agentic AI assistant should receive a policy renewal notification, Once notified about the renewal , the Agentic AI assistant should have the ability to create Draft Renewal Record in the UWB based on Policy data
2.The creation should comply with the rules such as incrementing the policy period etc. (based on the Policy Administration System), 
3.The Draft Renewal record should include the updated coverage and wordings for the associated Insurance Product."
 US 3	Agentic AI Assistant sends contract details 	"As an Agentic AI Assistant I want to share contract renewal details with the Broker 
so that confirmation can be received from the customer and changes can be made if required for the existing contract during renewal  
"	"1.Agentic AI Assistant should be able to shares the contract renewal details with the broker
2.After the Customer confirms the details, with or without changes to the existing renewal contract, the Agentic AI Assistant should have the capability to actively monitor the mailbox to identify the confirmation email received from the Broker, indicating that the Client would like to renew the contract without further coverage changes. The Assistant should then await the renewal quote from the Broker."
 US 4	Agentic AI Assistant assess the policy and evaluate the key factors 	"As an Agentic AI Assistant I want to assess the policy and evaluate the key factors  
so that I can recommend whether or not to renew the policy with the adjusted premium rates "	"1. Agentic AI Assistant should have the ability to assess the policy based on below key factors 
     i).Review policy performance, claims, and loss runs across the renewal chain.
    ii).To conducts clearance and sanctions checks on UWB, ensuring the client isn’t on any sanctions lists or the policy isn’t renewed under another arrangement.
   iii).Product Studio: To confirm if ABC Insurance still offers the product or if coverages/wordings have changed.
   iv).Market, Regulatory, and Compliance Condition Agents: To consider insurance market trends and ensure regulatory compliance.
    v).Social, Political, and Environmental Factors Agents: To evaluate external influences.
   vi).ABC Insurance’s Capacity: To assesses internal capacity to underwrite the policy.

2. Agentic AI Assistant should be able to decide based on the above evaluation of factors and only recommend renewing the policy with adjusted premium rates
If
  i). Gross Loss Ratio of 72% 
 ii).No Sanction Inssues
"
US 5	Rating Model receives the renewal data for calculating the renewal rate	"As an Agentic AI Assistant I want to send the renewal data feed to the rating model
So that Renewal rates are calculated and are applied to the renewal record in the UWB"	"1. Agentic AI Assistant  should be able to utilize UWB(Renewal Record Data) and Data Solution (e.g., Claims Data) to provide information to the Rating Model for calculating the renewal rate.
2. Once the renewal rate is calculated, Agentic AI Assistant should be able to apply the Calculated renewal rate to the Renewal Record in the UWB. 

"
 US 6	Agentic AI Assistant Generates the Quote document in UWB and sends it to the Broker	"As an Agentic AI Assistant I want to create the renewal quote document
so that I can send the renewal quote to the Broker "	"1.The Agentic AI Assistant should be able to make a decision on whether to proceed with the quote based on the renewal rate, its competitiveness, and whether the forecast performance metric threshold will be maintained.
2.The Agentic AI Assistant I  should have the ability to generate a Quote Document in UWB using the Renewal Record, including policy coverages, wordings, subjectivities, terms, and conditions.
3.After a sanity check by the Underwriter, the Agentic AI Assistant should be able to send the Quote Document to Broker via e-mail.







"
 US 7	Agentic AI Assistant monitors the mailbox for confirmation from the Broker and Binds the quote	"As an Agentic AI Assistant I want to monitor mailbox for the Broker's Confirmation on the Renewal Quote
so that I can proceed with binding the renewal policy details"	"
1.Agentic AI Assistant should have the ability to monitor the mailbox to check the received confirmation in an email from the Broker DEF stipulation that the Renewal Quote and all updated terms and conditions are acceptable to the Insured.
2.Agentic AI Assistant should be able to make a Decision on whether to proceed to bind, based on the Broker’s response.
3.Agentic AI Assistant should be able to proceed with binding the policy details in the UWB."
 US 8	"Agentic AI Assistant Ensures that the 
1.Policy renewal is recorded in PAS
2.Documents are maintained in DMS
also, monitors the premium payment (PAS)"	"As an Agentic AI Assistant I want to Register the policy renewal in the PAS(Policy Administration System)
so that the Renewal Policy is recorded in the PAS(Policy Administration System)"	"1.Agentic AI Assistant should be able to ensure that the Renewal Polciy is recorded in the PAS(Policy Administration System).
2.Agentic AI Assistant should be able to Store and Maintain documentations in DMS(Document Management System) received from Broker DEF.
3.Agentic AI Assistant should have the ability to monitor the Premium Payment from the Broker or Insured"































I want a GenAI chatbot running on Replit’s free tier (≤0.5 GB RAM, CPU only) that:
- Uses llama.cpp to load the file `gpt4all-j-v1.3-groovy-guanaco-3B.ggmlv3.q4_0.bin` from the workspace.
- Exposes a HTTP endpoint `/chat` on port 3000 that accepts JSON `{ "message": "<user text>" }` and returns `{ "reply": "<model text>" }`.
- Includes a `.replit` file so the repl auto-starts everything (installs dependencies, builds llama.cpp, and runs the server).
- Installs only what’s needed (e.g. `build-essential`, `cmake`, `python3`, `flask`, etc.).
- Keeps the total RAM footprint under 500 MB.
Please generate all necessary files and directory structure; I don’t want to write any code by hand.




drop database sf;
create database sf;
use sf;


INSERT INTO SeatStructure (seatNo) VALUES
('1A'), ('1B'), ('1C'), ('1D'), ('1E'), ('1F'),
('2A'), ('2B'), ('2C'), ('2D'), ('2E'), ('2F'),
('3A'), ('3B'), ('3C'), ('3D'), ('3E'), ('3F'),
('4A'), ('4B'), ('4C'), ('4D'), ('4E'), ('4F'),
('5A'), ('5B'), ('5C'), ('5D'), ('5E'), ('5F'),
('6A'), ('6B'), ('6C'), ('6D'), ('6E'), ('6F'),
('7A'), ('7B'), ('7C'), ('7D'), ('7E'), ('7F'),
('8A'), ('8B'), ('8C'), ('8D'), ('8E'), ('8F'),
('9A'), ('9B'), ('9C'), ('9D'), ('9E'), ('9F'),
('10A'), ('10B'), ('10C'), ('10D'), ('10E'), ('10F'),
('11A'), ('11B'), ('11C'), ('11D'), ('11E'), ('11F'),
('12A'), ('12B'), ('12C'), ('12D'), ('12E'), ('12F'),
('13A'), ('13B'), ('13C'), ('13D'), ('13E'), ('13F'),
('14A'), ('14B'), ('14C'), ('14D'), ('14E'), ('14F'),
('15A'), ('15B'), ('15C'), ('15D'), ('15E'), ('15F');

INSERT INTO SeatStructure (seatNo) VALUES
('16A'), ('16B'), ('16C'), ('16D'), ('16E'), ('16F'),
('17A'), ('17B'), ('17C'), ('17D'), ('17E'), ('17F'),
('18A'), ('18B'), ('18C'), ('18D'), ('18E'), ('18F'),
('19A'), ('19B'), ('19C'), ('19D'), ('19E'), ('19F'),
('20A'), ('20B'), ('20C'), ('20D'), ('20E'), ('20F'),
('21A'), ('21B'), ('21C'), ('21D'), ('21E'), ('21F'),
('22A'), ('22B'), ('22C'), ('22D'), ('22E'), ('22F'),
('23A'), ('23B'), ('23C'), ('23D'), ('23E'), ('23F'),
('24A'), ('24B'), ('24C'), ('24D'), ('24E'), ('24F'),
('25A'), ('25B'), ('25C'), ('25D'), ('25E'), ('25F');

CREATE TABLE id_sequence (
    id_name VARCHAR(50) PRIMARY KEY,
    current_value INT
);


select * from id_sequence;
select * from passengers;
INSERT INTO id_sequence (id_name, current_value) VALUES ('passenger_id',125);

select * from airports;
select * from airlines;
select * from flights;
select * from flightowner;
select * from flighttrip;
select * from seats;
select * from bookings;
select * from customer;


INSERT INTO Flights (flightCode, lastArrivalTime, lastArrivedAirportId, totalSeats, checkInWeight, cabinWeight, airlineId, flightStatus)
VALUES 
('AI-7890', '2024-10-07 18:00:00', 'DEL', 150, 20, 7, 'AI', 'Active'),
('AI-3456', '2024-10-08 22:00:00', 'DEL', 150, 20, 7, 'AI', 'Inactive');


INSERT INTO FlightTrip (departure, arrival, ticketPrice, status, filledSeats, duration, flight_code, sourceIATACode, destinationIATACode)
VALUES 
('2024-10-10 10:00:00', '2024-10-10 12:00:00', 5000, 'Running', 50, 120, 'AI-7890', 'DEL', 'BOM');


select * from airports;


select * from airline;


select * from seats;


select * from seatstructure;






drop table flights;



create database sf;
use sf;

drop database sf;
select * from admin;

select * from Flights;


select * from customer;


select * from flighttrip;

select * from airlines;
select * from FlightOwner;
select *from bookings;
select * from booking_id_seq;
select * from passengers;
select * from bookings_passengers;
select * from payments;


drop table FlightOwner;
drop table flights;
drop table bookings;
drop table Flighttrip;


drop table airlines;
drop table customer;




create database final;
use final;






drop database user_auth;
CREATE DATABASE user_auth;
use user_auth;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL
);

select * from users;


create database sl;
use sl;

drop database sl;
 
INSERT INTO SeatStructure (seatNo) VALUES
('1A'), ('1B'), ('1C'), ('1D'), ('1E'), ('1F'),
('2A'), ('2B'), ('2C'), ('2D'), ('2E'), ('2F'),
('3A'), ('3B'), ('3C'), ('3D'), ('3E'), ('3F'),
('4A'), ('4B'), ('4C'), ('4D'), ('4E'), ('4F'),
('5A'), ('5B'), ('5C'), ('5D'), ('5E'), ('5F'),
('6A'), ('6B'), ('6C'), ('6D'), ('6E'), ('6F'),
('7A'), ('7B'), ('7C'), ('7D'), ('7E'), ('7F'),
('8A'), ('8B'), ('8C'), ('8D'), ('8E'), ('8F'),
('9A'), ('9B'), ('9C'), ('9D'), ('9E'), ('9F'),
('10A'), ('10B'), ('10C'), ('10D'), ('10E'), ('10F'),
('11A'), ('11B'), ('11C'), ('11D'), ('11E'), ('11F'),
('12A'), ('12B'), ('12C'), ('12D'), ('12E'), ('12F'),
('13A'), ('13B'), ('13C'), ('13D'), ('13E'), ('13F'),
('14A'), ('14B'), ('14C'), ('14D'), ('14E'), ('14F'),
('15A'), ('15B'), ('15C'), ('15D'), ('15E'), ('15F');

INSERT INTO SeatStructure (seatNo) VALUES
('16A'), ('16B'), ('16C'), ('16D'), ('16E'), ('16F'),
('17A'), ('17B'), ('17C'), ('17D'), ('17E'), ('17F'),
('18A'), ('18B'), ('18C'), ('18D'), ('18E'), ('18F'),
('19A'), ('19B'), ('19C'), ('19D'), ('19E'), ('19F'),
('20A'), ('20B'), ('20C'), ('20D'), ('20E'), ('20F'),
('21A'), ('21B'), ('21C'), ('21D'), ('21E'), ('21F'),
('22A'), ('22B'), ('22C'), ('22D'), ('22E'), ('22F'),
('23A'), ('23B'), ('23C'), ('23D'), ('23E'), ('23F'),
('24A'), ('24B'), ('24C'), ('24D'), ('24E'), ('24F'),
('25A'), ('25B'), ('25C'), ('25D'), ('25E'), ('25F');


CREATE TABLE id_sequence (
    id_name VARCHAR(50) PRIMARY KEY,
    current_value INT
);

INSERT INTO id_sequence (id_name, current_value) VALUES ('passenger_id',125);

select * from airports;
select * from SeatStructure;


create database bookprac;
use bookprac;
select * from Book;
show tables;

INSERT INTO Book (name, publication_year, authorname, description)
VALUES
('The Great Gatsby', 1925, 'F. Scott Fitzgerald', 'A novel set in the Roaring Twenties, exploring themes of wealth and society.'),
('To Kill a Mockingbird', 1960, 'Harper Lee', 'A story of racial injustice and childhood innocence in the American South.'),
('1984', 1949, 'George Orwell', 'A dystopian novel depicting a totalitarian regime and the concept of Big Brother.'),
('Pride and Prejudice', 1813, 'Jane Austen', 'A classic romance novel highlighting issues of class and marriage.'),
('Moby-Dick', 1851, 'Herman Melville', 'An epic tale of a sea captain\'s obsession with a white whale.');



use book;
select * from Book;

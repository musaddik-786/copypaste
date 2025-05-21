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

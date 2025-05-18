
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

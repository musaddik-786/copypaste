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

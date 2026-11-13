-- STREAMIFY: Entertainment and Streaming Management System
-- MySQL 8.0+ | Run this entire script in MySQL Workbench.
-- WARNING: The DROP DATABASE statement recreates the project database.
DROP DATABASE IF EXISTS StreamifyDB;
CREATE DATABASE StreamifyDB CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE StreamifyDB;

-- 1. ACCOUNT AND SUBSCRIPTION TABLES
CREATE TABLE Users (
  UserID INT AUTO_INCREMENT PRIMARY KEY,
  FullName VARCHAR(100) NOT NULL,
  Email VARCHAR(255) NOT NULL UNIQUE,
  PasswordHash VARCHAR(255) NOT NULL,
  DateCreated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Profiles (
  ProfileID INT AUTO_INCREMENT PRIMARY KEY,
  UserID INT NOT NULL,
  ProfileName VARCHAR(60) NOT NULL,
  IsKidsProfile BOOLEAN NOT NULL DEFAULT FALSE,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_profile_per_user UNIQUE (UserID, ProfileName),
  CONSTRAINT fk_profiles_user FOREIGN KEY (UserID)
    REFERENCES Users(UserID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Plans (
  PlanID INT AUTO_INCREMENT PRIMARY KEY,
  PlanName VARCHAR(40) NOT NULL UNIQUE,
  MonthlyPrice DECIMAL(8,2) NOT NULL,
  MaxStreams INT NOT NULL,
  VideoQuality VARCHAR(20) NOT NULL,
  CONSTRAINT chk_plan_price CHECK (MonthlyPrice >= 0),
  CONSTRAINT chk_plan_streams CHECK (MaxStreams >= 1)
) ENGINE=InnoDB;

CREATE TABLE Subscriptions (
  SubscriptionID INT AUTO_INCREMENT PRIMARY KEY,
  UserID INT NOT NULL,
  PlanID INT NOT NULL,
  StartDate DATE NOT NULL,
  EndDate DATE NULL,
  Status ENUM('Active','Suspended','Cancelled','Expired') NOT NULL DEFAULT 'Active',
  CONSTRAINT fk_sub_user FOREIGN KEY (UserID)
    REFERENCES Users(UserID) ON DELETE CASCADE,
  CONSTRAINT fk_sub_plan FOREIGN KEY (PlanID)
    REFERENCES Plans(PlanID),
  CONSTRAINT chk_subscription_dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
) ENGINE=InnoDB;

CREATE TABLE Payments (
  PaymentID INT AUTO_INCREMENT PRIMARY KEY,
  SubscriptionID INT NOT NULL,
  Amount DECIMAL(8,2) NOT NULL,
  PaymentDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PaymentMethod ENUM('Card','UPI','NetBanking','Wallet') NOT NULL,
  PaymentStatus ENUM('Successful','Pending','Failed','Refunded') NOT NULL,
  TransactionReference VARCHAR(60) NOT NULL UNIQUE,
  CONSTRAINT fk_payment_subscription FOREIGN KEY (SubscriptionID)
    REFERENCES Subscriptions(SubscriptionID) ON DELETE CASCADE,
  CONSTRAINT chk_payment_amount CHECK (Amount >= 0)
) ENGINE=InnoDB;

-- 2. CONTENT CATALOG TABLES
CREATE TABLE Content (
  ContentID INT AUTO_INCREMENT PRIMARY KEY,
  Title VARCHAR(200) NOT NULL,
  ReleaseYear YEAR NOT NULL,
  MaturityRating VARCHAR(10) NOT NULL,
  ContentType ENUM('Movie','TVShow') NOT NULL,
  Description VARCHAR(500),
  CONSTRAINT chk_release_year CHECK (ReleaseYear >= 1888)
) ENGINE=InnoDB;

CREATE TABLE Genres (
  GenreID INT AUTO_INCREMENT PRIMARY KEY,
  GenreName VARCHAR(40) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE Content_Genre (
  ContentID INT NOT NULL,
  GenreID INT NOT NULL,
  PRIMARY KEY (ContentID, GenreID),
  CONSTRAINT fk_cg_content FOREIGN KEY (ContentID)
    REFERENCES Content(ContentID) ON DELETE CASCADE,
  CONSTRAINT fk_cg_genre FOREIGN KEY (GenreID)
    REFERENCES Genres(GenreID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Movies (
  MovieID INT AUTO_INCREMENT PRIMARY KEY,
  ContentID INT NOT NULL UNIQUE,
  DurationMinutes INT NOT NULL,
  VideoResolution VARCHAR(20) NOT NULL DEFAULT 'HD',
  CONSTRAINT fk_movie_content FOREIGN KEY (ContentID)
    REFERENCES Content(ContentID) ON DELETE CASCADE,
  CONSTRAINT chk_movie_duration CHECK (DurationMinutes > 0)
) ENGINE=InnoDB;

CREATE TABLE TV_Shows (
  ShowID INT AUTO_INCREMENT PRIMARY KEY,
  ContentID INT NOT NULL UNIQUE,
  Network VARCHAR(100),
  CONSTRAINT fk_show_content FOREIGN KEY (ContentID)
    REFERENCES Content(ContentID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Seasons (
  SeasonID INT AUTO_INCREMENT PRIMARY KEY,
  ShowID INT NOT NULL,
  SeasonNumber INT NOT NULL,
  SeasonTitle VARCHAR(150),
  CONSTRAINT uq_show_season UNIQUE (ShowID, SeasonNumber),
  CONSTRAINT fk_season_show FOREIGN KEY (ShowID)
    REFERENCES TV_Shows(ShowID) ON DELETE CASCADE,
  CONSTRAINT chk_season_number CHECK (SeasonNumber > 0)
) ENGINE=InnoDB;

CREATE TABLE Episodes (
  EpisodeID INT AUTO_INCREMENT PRIMARY KEY,
  SeasonID INT NOT NULL,
  EpisodeNumber INT NOT NULL,
  EpisodeTitle VARCHAR(200) NOT NULL,
  DurationMinutes INT NOT NULL,
  CONSTRAINT uq_season_episode UNIQUE (SeasonID, EpisodeNumber),
  CONSTRAINT fk_episode_season FOREIGN KEY (SeasonID)
    REFERENCES Seasons(SeasonID) ON DELETE CASCADE,
  CONSTRAINT chk_episode_duration CHECK (DurationMinutes > 0)
) ENGINE=InnoDB;

-- 3. USER INTERACTION TABLES
CREATE TABLE Watchlists (
  ProfileID INT NOT NULL,
  ContentID INT NOT NULL,
  DateAdded DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ProfileID, ContentID),
  CONSTRAINT fk_watchlist_profile FOREIGN KEY (ProfileID)
    REFERENCES Profiles(ProfileID) ON DELETE CASCADE,
  CONSTRAINT fk_watchlist_content FOREIGN KEY (ContentID)
    REFERENCES Content(ContentID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Watch_History (
  HistoryID INT AUTO_INCREMENT PRIMARY KEY,
  ProfileID INT NOT NULL,
  ContentID INT NOT NULL,
  LastWatchedPositionSeconds INT NOT NULL DEFAULT 0,
  WatchDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  IsCompleted BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT uq_profile_content_watch UNIQUE (ProfileID, ContentID),
  CONSTRAINT fk_history_profile FOREIGN KEY (ProfileID)
    REFERENCES Profiles(ProfileID) ON DELETE CASCADE,
  CONSTRAINT fk_history_content FOREIGN KEY (ContentID)
    REFERENCES Content(ContentID) ON DELETE CASCADE,
  CONSTRAINT chk_watch_position CHECK (LastWatchedPositionSeconds >= 0)
) ENGINE=InnoDB;

CREATE TABLE Ratings (
  ProfileID INT NOT NULL,
  ContentID INT NOT NULL,
  Score TINYINT NOT NULL,
  ReviewText VARCHAR(1000),
  RatingDate DATE NOT NULL,
  PRIMARY KEY (ProfileID, ContentID),
  CONSTRAINT fk_rating_profile FOREIGN KEY (ProfileID)
    REFERENCES Profiles(ProfileID) ON DELETE CASCADE,
  CONSTRAINT fk_rating_content FOREIGN KEY (ContentID)
    REFERENCES Content(ContentID) ON DELETE CASCADE,
  CONSTRAINT chk_rating_score CHECK (Score BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- Helpful indexes for common lookups
CREATE INDEX idx_content_title ON Content(Title);
CREATE INDEX idx_content_type_year ON Content(ContentType, ReleaseYear);
CREATE INDEX idx_history_date ON Watch_History(WatchDate);
CREATE INDEX idx_sub_status ON Subscriptions(Status);

-- SAMPLE DATA
INSERT INTO Users (FullName, Email, PasswordHash) VALUES
('Aarav Sharma','aarav@example.com','demo_hash_aarav'),
('Meera Kapoor','meera@example.com','demo_hash_meera'),
('Kabir Singh','kabir@example.com','demo_hash_kabir'),
('Isha Verma','isha@example.com','demo_hash_isha'),
('Rohan Das','rohan@example.com','demo_hash_rohan');

INSERT INTO Profiles (UserID, ProfileName, IsKidsProfile) VALUES
(1,'Aarav',FALSE),(1,'Kids',TRUE),(2,'Meera',FALSE),
(3,'Kabir',FALSE),(4,'Isha',FALSE),(5,'Rohan',FALSE);

INSERT INTO Plans (PlanName, MonthlyPrice, MaxStreams, VideoQuality) VALUES
('Basic',199.00,1,'SD'),('Standard',499.00,2,'Full HD'),('Premium',699.00,4,'4K UHD');

INSERT INTO Subscriptions (UserID, PlanID, StartDate, EndDate, Status) VALUES
(1,3,'2026-10-01',NULL,'Active'),
(2,2,'2026-10-15',NULL,'Active'),
(3,1,'2026-09-01','2026-10-01','Expired'),
(4,3,'2026-11-01',NULL,'Active'),
(5,1,'2026-10-20',NULL,'Suspended');

INSERT INTO Payments (SubscriptionID, Amount, PaymentDate, PaymentMethod, PaymentStatus, TransactionReference) VALUES
(1,699.00,'2026-10-01 10:00:00','UPI','Successful','STRM-TXN-1001'),
(2,499.00,'2026-10-15 11:30:00','Card','Successful','STRM-TXN-1002'),
(3,199.00,'2026-09-01 09:00:00','NetBanking','Successful','STRM-TXN-1003'),
(4,699.00,'2026-11-01 12:00:00','UPI','Successful','STRM-TXN-1004'),
(5,199.00,'2026-10-20 13:00:00','Wallet','Pending','STRM-TXN-1005');

INSERT INTO Content (Title, ReleaseYear, MaturityRating, ContentType, Description) VALUES
('Interstellar',2014,'PG-13','Movie','A science-fiction journey through space and time.'),
('The Dark Knight',2008,'PG-13','Movie','A superhero crime drama.'),
('Dangal',2016,'U/A 13+','Movie','A sports drama about wrestling.'),
('Stranger Things',2016,'TV-14','TVShow','A science-fiction mystery series.'),
('Breaking Bad',2008,'TV-MA','TVShow','A crime drama series.'),
('The Great Indian Kitchen',2021,'U/A 13+','Movie','A social drama.'),
('Planet Earth',2006,'G','TVShow','A nature documentary series.');

INSERT INTO Genres (GenreName) VALUES
('Sci-Fi'),('Action'),('Drama'),('Sports'),('Thriller'),('Crime'),('Documentary');

INSERT INTO Content_Genre VALUES
(1,1),(1,3),(2,2),(2,5),(3,3),(3,4),
(4,1),(4,5),(5,3),(5,6),(6,3),(7,7);

INSERT INTO Movies (ContentID, DurationMinutes, VideoResolution) VALUES
(1,169,'4K UHD'),(2,152,'4K UHD'),(3,161,'Full HD'),(6,100,'Full HD');

INSERT INTO TV_Shows (ContentID, Network) VALUES
(4,'Streamify Originals'),(5,'Streamify Originals'),(7,'Nature Studios');

INSERT INTO Seasons (ShowID, SeasonNumber, SeasonTitle) VALUES
(1,1,'Season 1'),(1,2,'Season 2'),(2,1,'Season 1'),(3,1,'Season 1');

INSERT INTO Episodes (SeasonID, EpisodeNumber, EpisodeTitle, DurationMinutes) VALUES
(1,1,'The Vanishing of Will Byers',48),(1,2,'The Weirdo on Maple Street',55),
(2,1,'MADMAX',50),(3,1,'Pilot',58),(3,2,'Cat''s in the Bag',48),
(4,1,'Planet Earth: From Pole to Pole',58);

INSERT INTO Watchlists (ProfileID, ContentID, DateAdded) VALUES
(1,2,'2026-11-01 10:00:00'),(1,4,'2026-11-02 10:00:00'),
(3,1,'2026-11-03 10:00:00'),(4,3,'2026-11-04 10:00:00'),
(5,7,'2026-11-05 10:00:00');

INSERT INTO Watch_History (ProfileID, ContentID, LastWatchedPositionSeconds, WatchDate, IsCompleted) VALUES
(1,1,5400,'2026-11-05 20:00:00',FALSE),
(1,2,9120,'2026-11-04 19:00:00',TRUE),
(3,4,2820,'2026-11-06 21:00:00',FALSE),
(4,3,9660,'2026-11-07 18:00:00',TRUE),
(5,7,1200,'2026-11-08 17:00:00',FALSE),
(2,4,1200,'2026-11-08 19:00:00',FALSE);

INSERT INTO Ratings (ProfileID, ContentID, Score, ReviewText, RatingDate) VALUES
(1,2,5,'Excellent action and storytelling.','2026-11-04'),
(3,1,5,'A memorable science-fiction film.','2026-11-05'),
(3,4,4,'Very engaging series.','2026-11-06'),
(4,3,5,'Inspiring sports drama.','2026-11-07'),
(5,7,4,'Beautiful documentary.','2026-11-08'),
(1,4,4,'Interesting mystery and characters.','2026-11-08');

-- 15-20 PROJECT QUERIES (20 queries)
-- Q1. Display all registered users.
SELECT UserID, FullName, Email, DateCreated FROM Users;

-- Q2. Display all available content with type and release year.
SELECT ContentID, Title, ContentType, ReleaseYear FROM Content ORDER BY Title;

-- Q3. Find all active subscriptions with user and plan details.
SELECT u.FullName, p.PlanName, p.MonthlyPrice, s.StartDate
FROM Users u JOIN Subscriptions s ON u.UserID=s.UserID
JOIN Plans p ON s.PlanID=p.PlanID
WHERE s.Status='Active';

-- Q4. Display profiles with their account email.
SELECT pr.ProfileName, pr.IsKidsProfile, u.Email
FROM Profiles pr JOIN Users u ON pr.UserID=u.UserID;

-- Q5. List movies available in 4K UHD.
SELECT c.Title, m.DurationMinutes, m.VideoResolution
FROM Content c JOIN Movies m ON c.ContentID=m.ContentID
WHERE m.VideoResolution='4K UHD';

-- Q6. Show TV shows and their total registered episodes.
SELECT c.Title, COUNT(e.EpisodeID) AS TotalEpisodes
FROM Content c JOIN TV_Shows t ON c.ContentID=t.ContentID
LEFT JOIN Seasons s ON t.ShowID=s.ShowID
LEFT JOIN Episodes e ON s.SeasonID=e.SeasonID
GROUP BY c.ContentID,c.Title;

-- Q7. Calculate average rating and number of ratings for each content item.
SELECT c.Title, ROUND(AVG(r.Score),2) AS AverageRating, COUNT(r.Score) AS RatingCount
FROM Content c LEFT JOIN Ratings r ON c.ContentID=r.ContentID
GROUP BY c.ContentID,c.Title ORDER BY AverageRating DESC;

-- Q8. Find content with average rating of at least 4.
SELECT c.Title, ROUND(AVG(r.Score),2) AS AverageRating
FROM Content c JOIN Ratings r ON c.ContentID=r.ContentID
GROUP BY c.ContentID,c.Title HAVING AVG(r.Score)>=4;

-- Q9. Count profiles under each user account.
SELECT u.FullName, COUNT(p.ProfileID) AS ProfileCount
FROM Users u LEFT JOIN Profiles p ON u.UserID=p.UserID
GROUP BY u.UserID,u.FullName;

-- Q10. Display incomplete viewing sessions.
SELECT p.ProfileName,c.Title,w.LastWatchedPositionSeconds,w.WatchDate
FROM Watch_History w JOIN Profiles p ON w.ProfileID=p.ProfileID
JOIN Content c ON w.ContentID=c.ContentID WHERE w.IsCompleted=FALSE;

-- Q11. Find content that has never been rated (subquery).
SELECT c.Title FROM Content c
WHERE NOT EXISTS (SELECT 1 FROM Ratings r WHERE r.ContentID=c.ContentID);

-- Q12. Find content released before the average release year.
SELECT Title,ReleaseYear FROM Content
WHERE ReleaseYear < (SELECT AVG(ReleaseYear) FROM Content);

-- Q13. Find the highest-rated content item(s).
SELECT c.Title,AVG(r.Score) AS AverageRating
FROM Content c JOIN Ratings r ON c.ContentID=r.ContentID
GROUP BY c.ContentID,c.Title
HAVING AVG(r.Score)=(SELECT MAX(x.avg_score) FROM
 (SELECT AVG(Score) AS avg_score FROM Ratings GROUP BY ContentID) x);

-- Q14. Find users who have more than one profile.
SELECT u.FullName,COUNT(p.ProfileID) AS ProfileCount
FROM Users u JOIN Profiles p ON u.UserID=p.UserID
GROUP BY u.UserID,u.FullName HAVING COUNT(p.ProfileID)>1;

-- Q15. Calculate successful payment revenue by plan.
SELECT pl.PlanName,SUM(pay.Amount) AS TotalRevenue
FROM Payments pay JOIN Subscriptions s ON pay.SubscriptionID=s.SubscriptionID
JOIN Plans pl ON s.PlanID=pl.PlanID
WHERE pay.PaymentStatus='Successful'
GROUP BY pl.PlanID,pl.PlanName;

-- Q16. List content and its genres.
SELECT c.Title,g.GenreName
FROM Content c JOIN Content_Genre cg ON c.ContentID=cg.ContentID
JOIN Genres g ON cg.GenreID=g.GenreID ORDER BY c.Title,g.GenreName;

-- Q17. Find content added to the most watchlists (aggregate).
SELECT c.Title,COUNT(w.ProfileID) AS SavedCount
FROM Content c LEFT JOIN Watchlists w ON c.ContentID=w.ContentID
GROUP BY c.ContentID,c.Title ORDER BY SavedCount DESC;

-- Q18. Display the longest episode registered.
SELECT c.Title AS ShowTitle,e.EpisodeTitle,e.DurationMinutes
FROM Episodes e JOIN Seasons s ON e.SeasonID=s.SeasonID
JOIN TV_Shows t ON s.ShowID=t.ShowID JOIN Content c ON t.ContentID=c.ContentID
ORDER BY e.DurationMinutes DESC LIMIT 1;

-- Q19. Create and query a view showing content engagement.
CREATE OR REPLACE VIEW ContentEngagement AS
SELECT c.ContentID,c.Title,COUNT(w.HistoryID) AS ViewRecords,
SUM(CASE WHEN w.IsCompleted=TRUE THEN 1 ELSE 0 END) AS CompletedRecords
FROM Content c LEFT JOIN Watch_History w ON c.ContentID=w.ContentID
GROUP BY c.ContentID,c.Title;
SELECT * FROM ContentEngagement ORDER BY ViewRecords DESC;

-- Q20. Demonstrate a transaction with rollback (safe demonstration).
START TRANSACTION;
UPDATE Subscriptions SET Status='Suspended' WHERE SubscriptionID=1;
SELECT SubscriptionID,Status FROM Subscriptions WHERE SubscriptionID=1;
ROLLBACK;
SELECT SubscriptionID,Status FROM Subscriptions WHERE SubscriptionID=1;

-- DDL examples: ALTER (adds a nullable column) and DROP example shown as comment
ALTER TABLE Users ADD COLUMN Country VARCHAR(60) DEFAULT 'India';
-- DROP TABLE example (do not run unless intentionally removing a table):
-- DROP TABLE table_name;

-- DCL demonstration: run only if your MySQL account has CREATE USER / GRANT privileges.
-- Replace password with a strong local password. These statements may be skipped in
-- restricted college lab accounts; ask the lab administrator if permission is denied.
-- CREATE USER 'streamify_reader'@'localhost' IDENTIFIED BY 'ChangeThis_StrongPassword!';
-- GRANT SELECT ON StreamifyDB.* TO 'streamify_reader'@'localhost';
-- REVOKE SELECT ON StreamifyDB.* FROM 'streamify_reader'@'localhost';

-- Useful verification:
SELECT COUNT(*) AS TotalUsers FROM Users;
SELECT COUNT(*) AS TotalContent FROM Content;
SELECT COUNT(*) AS TotalTables
FROM information_schema.tables WHERE table_schema='StreamifyDB';

USE StreamifyDB;

SHOW TABLES;

SELECT COUNT(*) AS TotalUsers FROM Users;

SELECT COUNT(*) AS TotalContent FROM Content;

SELECT COUNT(*) AS TotalPayments FROM Payments;

USE StreamifyDB;

-- Query 1: Display all users
SELECT * FROM Users;

-- Query 2: Display all content
SELECT * FROM Content;

-- Query 3: Display active subscriptions
SELECT u.FullName, p.PlanName, p.MonthlyPrice, s.Status
FROM Users u
JOIN Subscriptions s ON u.UserID = s.UserID
JOIN Plans p ON s.PlanID = p.PlanID
WHERE s.Status = 'Active';

-- Query 4: Display average ratings
SELECT c.Title, AVG(r.Score) AS AverageRating
FROM Content c
LEFT JOIN Ratings r ON c.ContentID = r.ContentID
GROUP BY c.ContentID, c.Title;

-- Query 5: Display content with its genres
SELECT c.Title, g.GenreName
FROM Content c
JOIN Content_Genre cg ON c.ContentID = cg.ContentID
JOIN Genres g ON cg.GenreID = g.GenreID;


USE StreamifyDB;

-- Q6. Display TV Shows and Total Episodes
SELECT c.Title, COUNT(e.EpisodeID) AS TotalEpisodes
FROM Content c
JOIN TV_Shows t ON c.ContentID = t.ContentID
LEFT JOIN Seasons s ON t.ShowID = s.ShowID
LEFT JOIN Episodes e ON s.SeasonID = e.SeasonID
GROUP BY c.ContentID, c.Title;


-- Q7. Calculate Average Rating of Each Content
SELECT c.Title,
       ROUND(AVG(r.Score), 2) AS AverageRating,
       COUNT(r.Score) AS RatingCount
FROM Content c
LEFT JOIN Ratings r ON c.ContentID = r.ContentID
GROUP BY c.ContentID, c.Title
ORDER BY AverageRating DESC;


-- Q8. Find Content Having Average Rating At Least 4
SELECT c.Title, ROUND(AVG(r.Score), 2) AS AverageRating
FROM Content c
JOIN Ratings r ON c.ContentID = r.ContentID
GROUP BY c.ContentID, c.Title
HAVING AVG(r.Score) >= 4;


-- Q9. Count Profiles Under Each User
SELECT u.FullName,
       COUNT(p.ProfileID) AS ProfileCount
FROM Users u
LEFT JOIN Profiles p ON u.UserID = p.UserID
GROUP BY u.UserID, u.FullName;


-- Q10. Display Incomplete Viewing Sessions
SELECT p.ProfileName, c.Title,
       w.LastWatchedPositionSeconds,
       w.WatchDate
FROM Watch_History w
JOIN Profiles p ON w.ProfileID = p.ProfileID
JOIN Content c ON w.ContentID = c.ContentID
WHERE w.IsCompleted = FALSE;


-- Q11. Find Content That Has Never Been Rated
SELECT c.Title
FROM Content c
WHERE NOT EXISTS (
    SELECT 1
    FROM Ratings r
    WHERE r.ContentID = c.ContentID
);


-- Q12. Find Content Released Before Average Release Year
SELECT Title, ReleaseYear
FROM Content
WHERE ReleaseYear < (
    SELECT AVG(ReleaseYear)
    FROM Content
);


-- Q13. Find Highest Average-Rated Content
SELECT c.Title,
       AVG(r.Score) AS AverageRating
FROM Content c
JOIN Ratings r ON c.ContentID = r.ContentID
GROUP BY c.ContentID, c.Title
HAVING AVG(r.Score) = (
    SELECT MAX(x.avg_score)
    FROM (
        SELECT AVG(Score) AS avg_score
        FROM Ratings
        GROUP BY ContentID
    ) x
);


-- Q14. Find Users Having More Than One Profile
SELECT u.FullName,
       COUNT(p.ProfileID) AS ProfileCount
FROM Users u
JOIN Profiles p ON u.UserID = p.UserID
GROUP BY u.UserID, u.FullName
HAVING COUNT(p.ProfileID) > 1;


-- Q15. Calculate Successful Revenue By Subscription Plan
SELECT pl.PlanName,
       SUM(pay.Amount) AS TotalRevenue
FROM Payments pay
JOIN Subscriptions s
    ON pay.SubscriptionID = s.SubscriptionID
JOIN Plans pl
    ON s.PlanID = pl.PlanID
WHERE pay.PaymentStatus = 'Successful'
GROUP BY pl.PlanID, pl.PlanName;


-- Q16. Display Content With Its Genres
SELECT c.Title, g.GenreName
FROM Content c
JOIN Content_Genre cg
    ON c.ContentID = cg.ContentID
JOIN Genres g
    ON cg.GenreID = g.GenreID
ORDER BY c.Title, g.GenreName;


-- Q17. Find Most Saved Content
SELECT c.Title,
       COUNT(w.ProfileID) AS SavedCount
FROM Content c
LEFT JOIN Watchlists w
    ON c.ContentID = w.ContentID
GROUP BY c.ContentID, c.Title
ORDER BY SavedCount DESC;


-- Q18. Find the Longest Episode
SELECT c.Title AS ShowTitle,
       e.EpisodeTitle,
       e.DurationMinutes
FROM Episodes e
JOIN Seasons s ON e.SeasonID = s.SeasonID
JOIN TV_Shows t ON s.ShowID = t.ShowID
JOIN Content c ON t.ContentID = c.ContentID
ORDER BY e.DurationMinutes DESC
LIMIT 1;


-- Q19. Create Content Engagement View
CREATE OR REPLACE VIEW ContentEngagement AS
SELECT c.ContentID,
       c.Title,
       COUNT(w.HistoryID) AS ViewRecords,
       SUM(
           CASE
               WHEN w.IsCompleted = TRUE THEN 1
               ELSE 0
           END
       ) AS CompletedRecords
FROM Content c
LEFT JOIN Watch_History w
    ON c.ContentID = w.ContentID
GROUP BY c.ContentID, c.Title;

-- Display the View
SELECT *
FROM ContentEngagement
ORDER BY ViewRecords DESC;


-- Q20. Demonstrate Transaction and Rollback
START TRANSACTION;

UPDATE Subscriptions
SET Status = 'Suspended'
WHERE SubscriptionID = 1;

-- Check updated status
SELECT SubscriptionID, Status
FROM Subscriptions
WHERE SubscriptionID = 1;

-- Undo the update
ROLLBACK;

-- Check original status
SELECT SubscriptionID, Status
FROM Subscriptions
WHERE SubscriptionID = 1;

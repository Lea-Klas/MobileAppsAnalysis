/*
DATA CLEANING
1. Duplicates
2. Missing Values
3. Drop irrelevant columns
4. Irregularities
*/

-- check number of unique app ids in both tables
SELECT COUNT(DISTINCT id) AS unique_id 
FROM applestore;

SELECT COUNT(DISTINCT id) AS unique_id 
FROM applestore_description;

-- check for duplicates in both tables
SELECT id, COUNT(*) AS count
FROM applestore
GROUP BY id
HAVING count > 1;

SELECT id, COUNT(*) AS count
FROM applestore_description
GROUP BY id
HAVING count > 1;

-- check for missing values in the fields we will use for analysis
SELECT COUNT(*) AS missingvalues 
FROM applestore
WHERE id IS NULL 
	OR track_name IS NULL 
	OR size_bytes IS NULL
	OR price IS NULL
	OR rating_count_tot IS NULL
	OR user_rating IS NULL 
	OR prime_genre IS NULL
	OR `sup_devices.num` IS NULL
	OR `lang.num` IS NULL;

SELECT COUNT(*) AS missingvalues 
FROM applestore_description
WHERE id IS NULL 
	OR track_name IS NULL 
	OR app_desc IS NULL;

-- check that currency is same for all entries to compare prices
SELECT DISTINCT currency 
FROM applestore;

-- drop columns that are irrelevant for our analysis
ALTER TABLE applestore
	DROP column `Unnamed: 0`,
	DROP column size_bytes,
	DROP column currency,
	DROP column rating_count_ver,
	DROP column user_rating_ver,
	DROP column ver,
	DROP column cont_rating,
	DROP column `ipadSc_urls.num`,
	DROP column vpp_lic;

-- check for irregularities/misspellings in prime_genre
SELECT DISTINCT prime_genre
FROM applestore
ORDER BY prime_genre;


/*
DATA ANALYSIS
1. Identify the app genres with the highest number of apps.
2. Analyze the distribution of user ratings.
3. Determine which app analytics metrics influence user ratings.
4. Identify the top-rated app in each genre.
5. Identify the genre with the highest number of free apps.
*/

-- compute the number of apps per genre
SELECT prime_genre, COUNT(*) AS count
FROM applestore
GROUP BY prime_genre
ORDER BY count DESC;

-- check distribution of user ratings
SELECT MIN(user_rating) AS min_rating, MAX(user_rating) AS max_rating, AVG(user_rating) AS avg_rating
FROM applestore;

-- check ratings by genres
SELECT prime_genre, AVG(user_rating) AS avg_rating
FROM applestore
GROUP BY prime_genre
ORDER BY avg_rating DESC;

-- check ratings by genres taking rating_count_tot into account 
SELECT prime_genre, AVG(user_rating) AS avg_rating, AVG(rating_count_tot) AS avg_num_total_ratings, AVG(user_rating)/AVG(rating_count_tot) AS rating_score
FROM applestore
GROUP BY prime_genre
ORDER BY rating_score ASC;

-- identify the top app for each genre
SELECT prime_genre, track_name, user_rating
FROM (
	SELECT prime_genre,	track_name,	user_rating,
		RANK() OVER(PARTITION BY prime_genre ORDER BY user_rating DESC, rating_count_tot DESC) AS `rank`
	FROM applestore
	 ) AS ranked_apps
WHERE ranked_apps.rank = 1;

-- check whether paid apps have higher ratings than free apps
SELECT CASE
		WHEN price > 0 THEN 'paid'
		ELSE 'free'
	END AS app_type,
AVG(user_rating) AS avg_rating
FROM applestore
GROUP BY app_type;

-- check whether number of supported languages influences ratings
SELECT CASE
		WHEN `lang.num` < 10 THEN '<10'
		WHEN `lang.num` between 10 and 30 THEN '10-30'
		ELSE '>30'
	END AS num_languages,
AVG(user_rating) AS avg_rating
FROM applestore
GROUP BY num_languages
ORDER BY avg_rating DESC;

-- check whether number of supported devices influences ratings
SELECT CASE
		WHEN `sup_devices.num` < 20 THEN '<20'
		WHEN `sup_devices.num` between 20 and 40 THEN '20-40'
		ELSE '>40'
	END AS supported_devices,
AVG(user_rating) AS avg_rating
FROM applestore
GROUP BY supported_devices
ORDER BY avg_rating DESC;

-- check whether length of app description influences ratings
SELECT CASE
		WHEN LENGTH(t2.app_desc) < 500 THEN 'short'
		WHEN LENGTH(t2.app_desc) BETWEEN 500 AND 1000 THEN 'medium'
		ELSE 'long'
	END AS desc_length,
AVG(t1.user_rating) AS avg_rating
FROM applestore AS t1
JOIN applestore_description AS t2
ON t1.id = t2.id
GROUP BY desc_length
ORDER BY avg_rating DESC;

-- check which genre has the most free apps in total
SELECT prime_genre, COUNT(*) AS count
FROM applestore
WHERE price = 0
GROUP BY prime_genre
ORDER BY count DESC;

-- check which genre has the most free apps in percentage
WITH all_apps AS (
			SELECT prime_genre, COUNT(*) AS num_all_apps
			FROM applestore
			GROUP BY prime_genre),
	 free_apps AS (
			SELECT prime_genre, COUNT(*) AS num_free_apps
			FROM applestore
			WHERE price = 0
			GROUP BY prime_genre)
SELECT 
    all_apps.prime_genre,
    free_apps.num_free_apps / all_apps.num_all_apps AS free_apps_pct,
    all_apps.num_all_apps,
    free_apps.num_free_apps
FROM 
    all_apps
JOIN 
    free_apps ON all_apps.prime_genre = free_apps.prime_genre
ORDER BY free_apps_pct DESC;


/*
Key Findings & Suggestions

1. Genre Distribution:
   - Most apps are in the genres: Games, Entertainment, and Education.
   - Fewest apps are in the genres: Catalogs, Medical, and Navigation.
   -> Suggestion: To avoid high competition, consider developing an app in genres Catalogs, Medical, or Navigation. 
   However, there is a high user demand in the genres Games, Medical, and Navigation, which also might be beneficial.

2. User Rating:
   - The average user rating is 3.5.
   -> Goal: Aim to develop an app with a rating higher than 3.5.

3. High and Low Rated Genres:
   - Highest-rated genres: Social Networking, Music, and Reference.
   - Lowest-rated genres: Medical, Education, and Catalogs.
   -> Suggestion: There is a need for satisfactory apps in the Medical, Education, and Catalogs genres, 
   so consider creating an app in these genres.

4. Paid vs. Free Apps:
   - Paid apps have slightly higher ratings than free apps.
   -> Suggestion: Consider charging a certain amount for the app.

5. Language Support:
   - Apps that support 10-30 languages have higher ratings.
   -> Suggestion: Focus on supporting 10-30 languages rather than as many as possible.

6. Device Compatibility:
   - Apps supported on fewer than 20 devices have the highest ratings.
   -> Suggestion: Focus on ensuring compatibility with up to 20 devices rather than as many as possible.

7. App Description Length:
   - Apps with longer descriptions have higher ratings.
   -> Suggestion: Provide a detailed and comprehensive app description.

8. Free App Distribution:
   - The highest percentage of free apps is in the Shopping, Catalogs, and Social Networking genres.
*/

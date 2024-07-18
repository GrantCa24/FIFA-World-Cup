-- Create FIFA_World_Cup Database
CREATE DATABASE FIFA_World_Cup;

-- Schema for the FIFA_World_Cup Database
-- the order of the datasets for creating primary and foreign keys:

-- tournaments
-- players_men
-- teams_men
-- award_winners_men
-- matches_men
-- goals_men

CREATE TABLE tournaments(
  tournament_id TEXT NOT NULL,
  tournament_name TEXT,
  year INTEGER,
  start_date DATE,
  end_date DATE,
  host_country TEXT,
  winner TEXT,
  host_won BOOLEAN,
  count_teams INTEGER,
  PRIMARY KEY (tournament_id)
);
-- men's players
CREATE TABLE players_men(
  player_id TEXT NOT NULL,
  family_name TEXT,
  given_name TEXT,
  birth_date DATE,
  goal_keeper BOOLEAN,
  defender BOOLEAN,
  midfielder BOOLEAN,
  forward BOOLEAN,
  count_tournaments INTEGER,
  list_tournaments TEXT,
  PRIMARY KEY (player_id)
);
-- men's teams
CREATE TABLE teams_men(
	team_id TEXT NOT NULL,
	team_name TEXT,
	team_code TEXT,
	region_name TEXT,
	PRIMARY KEY (team_id)
);
-- men's award_winnners
-- one record per award winner per tournament
CREATE TABLE award_winners_men(
	tournament_id TEXT NOT NULL,
	award_id TEXT NOT NULL,
	award_name TEXT NOT NULL,
	shared BOOLEAN,
	player_id TEXT NOT NULL,
	team_id TEXT NOT NULL,
	PRIMARY KEY (tournament_id, award_id, player_id),
	FOREIGN KEY (tournament_id) REFERENCES tournaments (tournament_id),
	FOREIGN KEY (player_id) REFERENCES players_men (player_id),
	FOREIGN KEY (team_id) REFERENCES teams_men (team_id)
);
-- men's matches
-- one record per match
CREATE TABLE matches_men(
	tournament_id TEXT NOT NULL,
	match_id TEXT NOT NULL,
	match_name TEXT,
	stage_name TEXT,
	group_name TEXT,
	group_stage BOOLEAN,
	knockout_stage BOOLEAN,
	replayed BOOLEAN,
	replay BOOLEAN,
	match_date DATE,
	match_time TIME,
	stadium_name TEXT,
	city_name TEXT,
	country_name TEXT,
	home_team_id TEXT NOT NULL,
	away_team_id TEXT NOT NULL,
	home_team_score INTEGER,
	away_team_score INTEGER,
	home_team_score_margin INTEGER,
	away_team_score_margin INTEGER,
	extra_time BOOLEAN,
	penalty_shootout BOOLEAN,
	score_penalties TEXT,
	home_team_score_penalties INTEGER,
	away_team_score_penalties INTEGER,
	home_team_win BOOLEAN,
	away_team_win BOOLEAN,
	draw BOOLEAN,
	PRIMARY KEY (match_id),
	FOREIGN KEY (tournament_id) REFERENCES tournaments (tournament_id),
	FOREIGN KEY (home_team_id) REFERENCES teams_men (team_id),
	FOREIGN KEY (away_team_id) REFERENCES teams_men (team_id)
);
-- men's goals
-- one observation per goal
CREATE TABLE goals_men(
  goal_id TEXT NOT NULL,
  tournament_id TEXT NOT NULL,
  match_id TEXT NOT NULL,
  team_id TEXT NOT NULL,
  home_team BOOLEAN,
  away_team BOOLEAN,
  player_id TEXT NOT NULL,
  shirt_number INTEGER,
  player_team_id TEXT NOT NULL,
  minute_label TEXT,
  minute_regulation INTEGER,
  minute_stoppage INTEGER,
  match_period TEXT,
  own_goal BOOLEAN,
  penalty BOOLEAN,
  PRIMARY KEY (goal_id),
  FOREIGN KEY (tournament_id) REFERENCES tournaments (tournament_id),
  FOREIGN KEY (match_id) REFERENCES matches_men (match_id),
  FOREIGN KEY (team_id) REFERENCES teams_men (team_id),
  FOREIGN KEY (player_id) REFERENCES players_men (player_id),
  FOREIGN KEY (player_team_id) REFERENCES teams_men (team_id)
);

-- Queries for insights

-- Q1. For matches in knockout stage, when do they hold during the week? Specify weekday and weekend (Saturday and Sunday).
/* Note: TO_CHAR(match_date, 'Day') pads the day names with spaces to a width of 9 characters. Using TRIM To avoid issues
with trailing spaces. */
SELECT
	DISTINCT(stage_name),
	CASE
		WHEN TRIM(TO_CHAR(match_date, 'Day')) IN ('Saturday', 'Sunday') THEN 'Weekend'
		ELSE 'Weekday'
	END AS day_category,
	TO_CHAR(match_date, 'Day') AS day_of_week,
	COUNT(match_id) AS number_of_match
FROM matches_men
WHERE knockout_stage IS TRUE
GROUP BY
	DISTINCT(stage_name),
	day_of_week
ORDER BY
	stage_name,
	day_category,
	number_of_match DESC;

-- Q2. What is the average scoring time (do not include penalty kick and own goal) in each tournament in three time frame (first half, second half, and extra time)? Seperate the goal into three categories: penalty, own_goal, and goal.
WITH cte_goal_timing AS (
	SELECT
		tournament_id,
		CASE
			WHEN own_goal IS FALSE AND penalty IS FALSE THEN 'goal'
			WHEN own_goal IS FALSE AND penalty IS TRUE THEN 'penalty_goal'
			WHEN own_goal IS TRUE THEN 'own_goal'
		END AS goal_category,
		CASE
			WHEN minute_regulation <= 45 THEN 'first_half'
			WHEN minute_regulation BETWEEN 46 AND 90 THEN 'second_half'
			WHEN minute_regulation >= 91 THEN 'extra_time'
		END AS match_period_category,
		AVG(minute_regulation + minute_stoppage)::NUMERIC(10,2)  AS average_scoring_time,
		COUNT(goal_id) AS number_of_goal
	FROM goals_men
	GROUP BY
		tournament_id,
		goal_category,
		match_period_category
)
SELECT cte.tournament_id, t.host_country, cte.match_period_category, cte.average_scoring_time, cte.number_of_goal
FROM cte_goal_timing cte
LEFT JOIN tournaments t ON cte.tournament_id = t.tournament_id 
WHERE goal_category = 'goal'
ORDER BY
	cte.tournament_id DESC,
	cte.average_scoring_time DESC;

-- Q3. How is the distribution of award win by each region?
SELECT
	a.award_name,
	t.region_name,
	COUNT(t.team_id) AS number_of_award
FROM
	award_winners_men a
LEFT JOIN
	teams_men t ON a.team_id = t.team_id
GROUP BY
	a.award_name,
	t.region_name
ORDER BY
	a.award_name,
	number_of_award DESC;

-- Q4. What is the award-winning player's average age for Golden Boot, Silver Boot, Bronze Boot, and Golden Glove?
-- age calculation formula: tournament start date - birth date. extract the interval of the year only.
SELECT
	a.award_name,
	AVG(EXTRACT(YEAR FROM age(t.start_date, p.birth_date)))::numeric(10, 2) AS average_age,
	COUNT(a.player_id) AS number_of_player
FROM
	award_winners_men a
LEFT JOIN
	players_men p ON a.player_id = p.player_id
LEFT JOIN
	tournaments t ON a.tournament_id = t.tournament_id
GROUP BY
	a.award_name
HAVING
	award_name LIKE ('%Boot') or award_name = 'Golden Glove'
ORDER BY average_age DESC;

-- Q5. Who is the youngest award winner for Golden Boot, Silver Boot, Bronze Boot, and Golden Glove?
-- age calculation formula: tournament start date - birth date. extract the interval of the year only.
WITH cte_award_winner_age AS(
	SELECT
		a.award_name,
		a.player_id,
		p.family_name,
		p.given_name,
		p.birth_date,
		EXTRACT(YEAR FROM age(t.start_date, p.birth_date)) AS age_at_the_time
	FROM
		award_winners_men a
	LEFT JOIN
		players_men p ON a.player_id = p.player_id
	LEFT JOIN
		tournaments t ON a.tournament_id = t.tournament_id
	WHERE
		a.award_name LIKE '%Boot%' OR a.award_name = 'Golden Glove'
)
SELECT
	awg.award_name,
	awg.family_name,
	awg.given_name,
	awg.age_at_the_time
FROM
	cte_award_winner_age awg
WHERE
	(awg.award_name, awg.age_at_the_time) IN (
	SELECT
		award_name,
		MIN(age_at_the_time)
	FROM
		cte_award_winner_age
	GROUP BY
		award_name
	)
ORDER BY
	awg.award_name,
	awg.age_at_the_time;

-- Q6. Who are the top 5 players that scored the most goals in a single tournament?
WITH top_five_player_score AS (
	SELECT
		tournament_id,
		player_id,
		COUNT(goal_id) AS number_of_goal
	FROM
		goals_men
	WHERE
		own_goal IS FALSE
	GROUP BY
		tournament_id,
		player_id
	ORDER BY
		number_of_goal DESC
	FETCH FIRST 5 ROWS WITH TIES
)
SELECT
	tf.tournament_id, pm.family_name, pm.given_name, tf.number_of_goal
FROM
	top_five_player_score tf
LEFT JOIN
	players_men pm
ON
	tf.player_id = pm.player_id;

-- Q7 What is the number of tournaments hosted by each country, separated into men's and women's tournaments, and order the results by the total number of tournaments hosted.
SELECT
	host_country,
	COUNT(tournament_id) AS number_of_host,
	SUM(CASE WHEN tournament_name LIKE '%Men%' THEN 1 ELSE 0 END) AS number_of_men_tournament,
	SUM(CASE WHEN tournament_name LIKE '%Women%' THEN 1 ELSE 0 END) AS number_of_women_tournament
FROM
	tournaments
GROUP BY
	host_country
ORDER BY
	number_of_host DESC;

-- List the host country and the number of host (Include Mene's and Women's)
SELECT
	host_country,
	COUNT(tournament_id) AS number_of_host
FROM
	tournaments
GROUP BY
	host_country
ORDER BY
	number_of_host DESC;

-- Q8: Which team performs better in penalty shootouts?
WITH penalty_shootout_stats AS (
    SELECT
        match_id,
        home_team_id AS team_id,
        home_team_win AS team_win,
        penalty_shootout
    FROM
        matches_men
    WHERE
        penalty_shootout = TRUE

    UNION ALL

    SELECT
        match_id,
        away_team_id AS team_id,
        away_team_win AS team_win,
        penalty_shootout
    FROM
        matches_men
    WHERE
        penalty_shootout = TRUE
)

SELECT
    t.team_name,
    COUNT(ps.match_id) AS total_shootouts,
    SUM(CASE WHEN ps.team_win = TRUE THEN 1 ELSE 0 END) AS shootout_wins,
    SUM(CASE WHEN ps.team_win = FALSE THEN 1 ELSE 0 END) AS shootout_losses,
    ROUND(
		(SUM(CASE WHEN ps.team_win = TRUE THEN 1 ELSE 0 END) * 100.0) / COUNT(ps.match_id), 2
	) AS win_rate_percentage
FROM
    penalty_shootout_stats ps
JOIN
    teams_men t ON ps.team_id = t.team_id
GROUP BY
    t.team_name
ORDER BY
    win_rate_percentage DESC, total_shootouts DESC;


-- penalty_shootout_stats (a unified dataset) showing consolidated records of penalty shootouts from both home and away teams.
SELECT
	match_id,
	home_team_id AS team_id,
	home_team_win AS team_win,
	penalty_shootout
FROM
	matches_men
WHERE
	penalty_shootout = TRUE

UNION ALL

SELECT
	match_id,
	away_team_id AS team_id,
	away_team_win AS team_win,
	penalty_shootout
FROM
	matches_men
WHERE
	penalty_shootout = TRUE
ORDER BY match_id;

select * from tournaments;
select * from goals_men;
select * from matches_men;

-- Q9: Which team has the highest win rate in matches that went to extra time?
WITH cte_extra_time_stats AS (
	SELECT
		match_id,
		home_team_id AS team_id,
		home_team_win AS team_win,
		penalty_shootout
	FROM
		matches_men
	WHERE
		extra_time = TRUE
	
	UNION ALL
	
	SELECT
		match_id,
		away_team_id AS team_id,
		away_team_win AS team_win,
		penalty_shootout
	FROM
		matches_men
	WHERE
		extra_time = TRUE
	ORDER BY match_id DESC
)
SELECT
	t.team_name,
	COUNT(match_id) AS total_extra_time_matches,
	SUM(CASE WHEN team_win IS TRUE AND penalty_shootout IS FALSE THEN 1 ELSE 0 END) AS extra_time_wins_no_shootout,
	SUM(CASE WHEN team_win IS FALSE AND penalty_shootout IS FALSE THEN 1 ELSE 0 END) AS extra_time_losses_no_shootout,
	CASE
		WHEN
			COUNT(
					CASE WHEN penalty_shootout IS FALSE THEN match_id ELSE NULL END) = 0 THEN NULL
		ELSE
			ROUND(
				SUM(CASE WHEN team_win IS TRUE AND penalty_shootout IS FALSE THEN 1 ELSE 0 END) * 100.0
					/ COUNT(CASE WHEN penalty_shootout IS FALSE THEN match_id ELSE NULL END), 2
					)
	END AS win_rate_no_shootout,
	SUM(CASE WHEN team_win IS TRUE AND penalty_shootout IS TRUE THEN 1 ELSE 0 END) AS extra_time_wins_with_shootout,
	SUM(CASE WHEN team_win IS FALSE AND penalty_shootout IS TRUE THEN 1 ELSE 0 END) AS extra_time_losses_with_shootout,
	CASE
		WHEN
			COUNT(
					CASE WHEN penalty_shootout IS TRUE THEN match_id ELSE NULL END) = 0 THEN NULL
		ELSE
			ROUND(
				SUM(CASE WHEN team_win IS TRUE AND penalty_shootout IS TRUE THEN 1 ELSE 0 END) * 100.0
					/ COUNT(CASE WHEN penalty_shootout IS TRUE THEN match_id ELSE NULL END), 2
			)
	END AS win_rate_with_shootout
FROM
	cte_extra_time_stats et
JOIN
	teams_men t ON et.team_id = t.team_id
GROUP BY
	t.team_name
ORDER BY
	win_rate_no_shootout DESC,
	win_rate_with_shootout DESC;

--Q10: Which player position has received the most awards? And what is the average age?
SELECT
    pp.position,
	awa.award_name,
    COUNT(awa.award_name) AS total_awards,
    ROUND(AVG(awa.age_at_the_time), 2) AS average_age
FROM
    award_winners_ages awa
JOIN
    player_positions pp ON awa.player_id = pp.player_id
GROUP BY
    pp.position,
	awa.award_name
ORDER BY
    pp.position DESC,
	awa.award_name DESC,
	average_age DESC;

SELECT
    pp.position,
    COUNT(awa.award_name) AS total_awards,
    ROUND(AVG(awa.age_at_the_time), 2) AS average_age
FROM
    award_winners_ages awa
JOIN
    player_positions pp ON awa.player_id = pp.player_id
GROUP BY
    pp.position
ORDER BY
    average_age DESC;

select * from players_men;
select * from award_winners_ages;
select * from player_positions;



-- Create Views
-- View for award-winners's age
CREATE VIEW award_winners_ages AS
SELECT
	a.award_name,
	a.player_id,
	p.family_name,
	p.given_name,
	p.birth_date,
	EXTRACT(YEAR FROM age(t.start_date, p.birth_date)) AS age_at_the_time
FROM
	award_winners_men a
LEFT JOIN
	players_men p ON a.player_id = p.player_id
LEFT JOIN
	tournaments t ON a.tournament_id = t.tournament_id;

-- View that decomposes the dates into details.
CREATE VIEW detail_date_of_matches_men AS
SELECT
	*,
	EXTRACT(CENTURY FROM match_date) AS match_century,
	EXTRACT(YEAR FROM match_date) AS match_year,
	EXTRACT(MONTH FROM match_date) AS match_month,
	EXTRACT(DAY FROM match_date) AS match_day,
	EXTRACT(DOW FROM match_date) AS match_dow	
FROM 
	matches_men;

-- Create the view to include multiple positions (splits the positions into separate rows for each player)
CREATE VIEW player_positions AS
SELECT
    player_id,
    family_name,
    given_name,
    birth_date,
    'Goalkeeper' AS position
FROM
    players_men
WHERE
    goal_keeper = TRUE

UNION ALL

SELECT
    player_id,
    family_name,
    given_name,
    birth_date,
    'Defender' AS position
FROM
    players_men
WHERE
    defender = TRUE

UNION ALL

SELECT
    player_id,
    family_name,
    given_name,
    birth_date,
    'Midfielder' AS position
FROM
    players_men
WHERE
    midfielder = TRUE

UNION ALL

SELECT
    player_id,
    family_name,
    given_name,
    birth_date,
    'Forward' AS position
FROM
    players_men
WHERE
    forward = TRUE;








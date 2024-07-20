# FIFA-World-Cup
[FIFA World Cup 2026](https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/match-schedule-fixtures-results-teams-stadiums) is coming! With Canada hosting matches in Vancouver and Toronto, it is a great opportunity to dive into history before watching the World Cup. By finding trends and patterns, I hope to predict the upcoming World Cup and become more familiar with the overall statistics. In this Project, I provide some fun insights from the FIFA World Cup tournaments held between 1930 and 2022.

## Data source
The data source for this project is from [The Fjelstul World Cup Database](https://github.com/jfjelstul/worldcup) (© 2023 Joshua C. Fjelstul, Ph.D. CC-BY-SA 4.0 license).

## Data cleaning
Due to the large amount of data, I filtered out observations for **males only** in all csv files except for `tournaments.csv` before importing the data into PostgreSQL. 

## Database Schema
The following tables were created in PostgreSQL:
1. `tournaments`
2. `players_men`
3. `teams_men`
4. `winners_men`
5. `matches_men`
6. `goals_men`

## Analysis
1. When are matches in the knockout stage held during the week?
2. What is the average scoring time (do not include penalty kick and own goal) in each tournament in three frames: first half, second half, and extra time?
3. How is the distribution of awards won by each region?
4. What is the average age of the award-winning player for Golden Boot, Silver Boot, Bronze Boot, and Golden Glove?
5. Who is the youngest award winner of Golden Boot, Silver Boot, Bronze Boot, and Golden Glove?
6. Who are the top 5 players that scored the most goals (do not include own goal) in a single tournament?
7. What is the number of tournaments hosted by each country?
8. Which team performs better in penalty shootouts?
9. Which team has the highest win rate in matches that went to extra time?
10. Which player position has received the most awards? And what is the average age?

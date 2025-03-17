# Overview
This is a new Phoenix LiveView project that will implement a text-based
adventure game. In the game, the user will be playing the role of the founder of
a startup.

In playing the game, the user will be presented with different scenarios,
challenges, setbacks, etc, to which they will write a textual description of how
they would like to respond. These interactions continue until either their
company runs out of business or exits via buyout/IPO.

The interface for playing the game will be a chat, with the premise that the
user is communicating with their cofounder, who comes to them asking for what
they think should be done next. In that sense, the game will bare a strong
resemblance to existing interfaces to LLM's through chat like ChatGPT and
Claude.

## Playing a Game
- The user starts by describing their startup/product, e.g. "Uber for dry cleaning"
- The game then proceeds in rounds, where in each round the system ("cofounder")
  presents a situation and askes for the user response. Situations may include (but are not limited to):
  - Need to raise funds
  - Need to hire employees
  - Need to deal with publicity
- The game keeps track of the following information for the company:
  - The amount of cash-on-hand for the company
  - The burn/spending rate (together with cash on hand we get the runway)
  - How ownership of the company is distributed, e.g. who owns what percent of the company
- The game continues until either:
  - the company runs out of money
  - the company is acquired
  - the company IPOs
  - the company is forced to shutdown (e.g. due to lawsuits)

## User Games
- By default, an individual game is private to a user
- Each user can have many games
- Each game can be complete/incomplete
- A game can be paused to be resumed at a later time

## Leaderboard
- The site includes a leaderboard of the highest "exits"
- If a user wishes, they can make the result of their game eligible for the leaderboard
- If a user wishes, they can make their entire completed game viewable by other users
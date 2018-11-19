## Debugging Deep Dive
Work In Progress

### The Game Engine
The first thing to know about debugging your fleet has nothing to do with your
fleet itself: you must understand how the game engine works. Fire up the yard
server and read the module summary for:

* FleetManager
* FleetMessageHandler
* GameStateChanger
* SanitizedMessageProcessor

Now open `bin/aifc-game.rb`. Inside `main` and `run_game` is the orchestration
that makes the game work. Feel free to explore the code as much as you want, but
for debugging your fleet, what you need to understand starts in `run_game` and
`GameCoordinator::game_tick`. Depending on which version of the code you have,
there may be some `Concurrent::Future` statements; you can ignore that gem, but
pay attention to the RubyFC functions it calls. In general, the game works
by calling `game_tick` repeatedly until the mission decides the game is over.
Specifically:

1. Send a tick message to the game state changer for once-per-tick state updates
1. Update the mission (this lets the mission affect the game first, before any
fleets)
1. Send a tick message to each living fleet and process all the messages the
fleet has sent since the last tick as well as any fleet logs
1. Update all the mobs (Moving OBjectS) with the kinematic
engine; this performs all motion, collision detection, munition detonation,
energy update, hit point update, and target update processing. This also sends
a number of messages to the fleets. How this works could be a deep dive by
itself. For debugging purposes, knowing where and when this code is called is
enough.
1. Update each fleet's state; this is where you'll get notified that the game
is over for you (but maybe not for your opponents)
1. Send an end of tick message to each living fleet; this is where you must
respond with a tick acknowledge or be disqualified
1. Determine if the mission has ended

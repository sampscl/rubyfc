## The Fleet API
There are 2 APIs to know. The fleet-to-game API is how you tell the game about
what your fleet of ships is doing. Concepts like "turn left to face West" and
"Fire a missile at that ship" are implemented in this API. The game-to-fleet API
is how the game tells you about game events like "your ship just took damage
from an enemy missile" and "you don't have enough credits to build that ship".

These APIs are documented in the code using [YARD](https://yardoc.org). The
easiest way to access the documentation is 

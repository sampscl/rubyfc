# Ruby Fleet Commander
Ruby Fleet Commander is a re-imagining of the old AI Fleet Commander game that
is abandoned at http://fcomm.sourceforge.net. The core concept remains the same:
write a program that will control a fleet of space ships in order to complete a
mission.

This is what is known as a *programming game*. Instead of playing the game in
real-time, you must plan in advance and then write software to implement that
plan.

## License
Ruby Fleet Commander is published under the MIT license. The original artwork
stored in lib/images is copyrighted by Devon Ellis (I think) and is made
available from Source Forge under the GPL V2 license.

## Additional Documentation
1. [TODO](md/todo.md)
1. [Debugging Deep Dive](md/debugging_deep.md)
1. [Making A New Mission](md/making_a_mission.md)

## Prerequisites
1. A development environment; I use MacOS, Linux, Atom, bash, and git with git-flow
1. Ruby, some new-ish version (I'm on 2.3)
1. Homebrew on MacOS (https://brew.sh)
1. Qt4 (the GUI is optional but really useful), on Ubuntu: `sudo apt install qt4-default`,
on MacOS: `brew tap cartr/qt4 && brew tap-pin cartr/qt4 && brew install qt@4`
1. Globally-installed `YARD` for easy access to the APIs. Use
`sudo gem install --no-user yard`
1. A really strong desire to play this game or contribute, it is still very immature

## Getting Started

### Starting anew

First get all your prerequisites and get the gems installed. If you can do this
without errors, you're on your way:

```bash
git clone https://github.com/sampscl/rubyfc.git
cd rubyfc
bin/bundle install --path vendor/bundle --no-deployment
```

### Updating to a new version

New versions of RubyFC will become available from github. If you want to
upgrade, you have some options. First, bring your repository up to date with
github:

```bash
cd rubyfc # or wherever you cloned rubyfc
git fetch origin --tags
```

RubyFC uses git-flow
(https://datasift.github.io/gitflow/IntroducingGitFlow.html) so the latest
code is always in the develop branch and the master branch is tagged with
specific versions of the code. As RubyFC matures, it will also begin using
semantic versioning (https://semver.org), so it should be pretty
obvious when you run `git tag` which version is the most recent. So, after
fetching you can:

* Use a specific version `git checkout v1.0`
* Get the latest development version `git checkout develop`

Don't forget to run `bin/bundle install --path vendor/bundle --no-deployment`
to make sure your gems are up to date.

## A Working Example
There are some example programs and helper scripts in `lib/examples`. Lets make
a very basic program fight a slightly more advanced one. Depending on the speed
of your computer this will execute in under a minute, and it won't produce
much output.

Open a terminal and:

```bash
cd rubyfc # or wherever you cloned rubyfc
bin/aifc-game --fleet lib/examples/advanced_minimal.rb --fleet lib/examples/sit_n_scan.rb --log_file game.log --mission Paidgeeks::RubyFC::Missions::Deathmatch
```

Ok, that command line can be a lot to look at. Let's dissect it a bit:
* `bin/aifc-game` This starts the game engine, but that's not enough
to get anything done...
* `--fleet lib/examples/advanced_minimal.rb` adds a fleet to the game
* `--fleet lib/examples/sit_n_scan.rb` adds a fleet to the game
* `--log_file game.log` RubyFC works on a pure message-passing system. Every action
the game engine takes is represented by a message (stored as base 64 encoded
JSON) stored one message per line.
* `--mission Paidgeeks::RubyFC::Missions::Deathmatch` We will be running the
Deathmatch mission; last fleet standing wins

If you got this far without errors, congratulations! You've run a complete
deathmatch mission. That's probably anti-climactic. Using `bin/aifc-game` is how
tournaments are run but it's not very exciting to not-watch a game and see only
the final result. So, lets take this a small step further and add a GUI to the
mix. This will play the game in real-time or step-by-step.

```bash
bin/playback log/game.log # assuming you have logged a game.log
```

If you want to see it in real-time, click the "Play" button. If you want to step
through one game tick at a time, press the "Tick" button. Note that the messages
are printed in the console as they are processed. Cool!

Want extra cool? Of course you do. The playback tool can zip through your game
at light speed (CPU-defined speed of said light):

```bash
cat log/game.log | bin/playback
```

Tying it all together, you can watch a game play live. too. This will run and
display the game as fast as your computer can do it:

```bash
cd rubyfc # or wherever you cloned rubyfc
bin/aifc-game --fleet lib/examples/advanced_minimal.rb --fleet lib/examples/sit_n_scan.rb --log_file - --mission Paidgeeks::RubyFC::Missions::Deathmatch | tee log/game.log | bin/playback
```

Note that the game log is set to "-", which is shorthand for "log to the
terminal". This is passed through the tee program and simultaneously sent to
log/game.log and to the playback GUI.

Finally, you can also view a transcript of a game. The log files are stored as
base 64 encoded JSON, but the game can unpack that for you. Pipe it through the
`less` program for more easy traversal and search:

```bash
cd rubyfc # or wherever you cloned rubyfc
bin/aifc-game --just-show-transcript --log_file game.log | less
```

## Debugging Your Fleet
This is, without a doubt, the thing you will spend the most time doing.
Programming, like hacking, looks sexy on TV and in the movies, but the reality
is far less entertaining to watch. Still really fun to do, though.

Note: The playback tool, while very useful for visualizing a game, is not integrated
with debug-aifc-game or aifc-game. That feature is coming.

So, how do you debug? One step at a time:

```bash
cd rubyfc # or wherever you cloned rubyfc
bin/debug-aifc-game --fleet lib/examples/sit_n_scan.rb --fleet lib/examples/sit_n_scan.rb --log_file game.log --mission Paidgeeks::RubyFC::Missions::Deathmatch
# Once in the shell, type "?" and press <Enter> to see a list of available commands
```

This works exactly like `aifc-game`, except it drops you to a text debugging
session that allows you to issue commands, and, most usefully of all, use the
fantastic `pry` gem to introspect absolutely everything in the game engine.

Extra credit: check out `bin/debug-aifc-game`. See that aspect being applied to
`Paidgeeks::write_object`? Dig deep, figure out how that works, and you will be
a rubyfc debugging master.

So, things you can do in a debugging session:
* open terminal windows to tail the game and fleet(s) log files
* open a `pry` session; `$gc` is a global is accessible here, and contains the
game coordinator with which you can inspect almost everything. Within the `pry`
session, the `pry-nav` gem is also loaded so you can step through the game with
debugger commands. See https://github.com/nixme/pry-nav
* tick the game any number of game ticks at a time

## The Fleet API
There are 2 APIs to know. The fleet-to-game API is how you tell the game about
what your fleet of ships is doing. Concepts like "turn left to face West" and
"Fire a missile at that ship" are implemented in this API. The game-to-fleet API
is how the game tells you about game events like "your ship just took damage
from an enemy missile" and "you don't have enough credits to build that ship".

These APIs are documented in the code using [YARD](https://yardoc.org). The
easiest way to access the documentation is to run a local yard server. Assuming
you have installed yard globally as a gem as recommended in the README.md's
prerequisites section:

```bash
cd rubyfc # or wherever you cloned rubyfc
yard doc # makes sure the docs are up to date, only needed once unless the docs change
yard server # run the server
```

At this point, just run your favorite web browser and point it at
(http://localhost:8808/). The game-to-fleet API is described in
(http://localhost:8808/docs/Paidgeeks/RubyFC/Engine/GameStateChanger). The
fleet-to-game API is described in
(http://localhost:8808/docs/Paidgeeks/RubyFC/Engine/FleetMessageHandler).

When you're done, exit the yard server with `CTRL-C`.

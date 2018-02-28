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
1. [TODO](doc/todo.md)
1. [Fleet API](doc/fleet_api.md)
1. [Debugging Deep Dive](doc/debugging_deep.md)
1. [Making A New Mission](doc/making_a_mission.md)

## Prerequisites
1. A development environment; I use Linux, Atom, bash, and git with git-flow
1.  Ruby, some new-ish version (I'm on 2.3)
1. Qt4 (only if you want the *optional* UI), on Ubuntu: `sudo apt install qt4-default`
1. I have had no real luck getting this to run on MacOS and I haven't tried
Windows; you might be stuck with Linux
1. A really strong desire to play this game or contribute, it is very immature
and liable to break in surprising ways
1. Globally-installed `pry` gem; you don't have to have this, but it makes
debugging your fleets much easier. Use `sudo gem install --no-user --nodoc pry`
1. Globally-installed `YARD` for easy access to the APIs. Use
`sudo gem install --no-user yard`

## Getting Started

These steps are only necessary if you are starting anew or have gotten a new
version of RubyFC and need to bring your development environment up-to-date.

First get all your prerequisites and get the gems installed. If you can do this
without errors, you're on your way:

```bash
git clone https://github.com/sampscl/rubyfc.git
cd rubyfc
bin/bundle install --path vendor/bundle --no-deployment
```

Most of RubyFC doesn't need rails, but there is code in there that does and that
will only grow in the future as some of the TODOs are TODONE. You need a
database and we'll do this with a production database even though you're
officially a software developer. The reason to stay with the production database
is that several of the helper scripts will work without the `RAILS_ENV`
environment variable by assuming you mean `RAILS_ENV=production`. So lets get
that little task out of the way. If you want to preserve your existing database,
just don't do the `db:drop db:create`:

```bash
RAILS_ENV=production bin/rake db:drop db:create db:migrate db:seed
```

## A Working Example
There are some example programs and helper scripts in `lib/examples`. Lets make
a very basic program fight an identical copy of itself. Depending on the speed
of your computer this will execute in under a minute, and it won't produce
much output.

Open a terminal and:

```bash
cd rubyfc # or wherever you cloned rubyfc
bin/bundle exec bin/aifc-game --fleet lib/examples/sit_n_scan.rb --fleet lib/examples/sit_n_scan.rb --log_file game.log --mission Paidgeeks::RubyFC::Missions::Deathmatch
```

Ok, that command line can be a lot to look at. Let's dissect it a bit:
* `bin/bundle exec bin/aifc-game` Is necessary once, I think. After that you can
shorten it to `bin/aifc-game`. This starts the game engine, but that's not enough
to get anything done...
* `--fleet lib/examples/sit_n_scan.rb` adds a fleet to the game; remember that
we are making this program fight itself and so you see the same fleet added twice
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

## Debugging Your Fleet
This is, without a doubt, the thing you will spend the most time doing.
Programming, like hacking, looks sexy on TV and in the movies, but the reality
is far less entertaining to watch. Still really fun to do, though.

Note: The playback tool, while very useful for visualizing a game, is not integrated
with debug-aifc-game or aifc-game. That feature is coming.

So, how do you debug? One step at a time:

```bash
cd rubyfc # or wherever you cloned rubyfc
bin/bundle exec bin/debug-aifc-game --fleet lib/examples/sit_n_scan.rb --fleet lib/examples/sit_n_scan.rb --log_file game.log --mission Paidgeeks::RubyFC::Missions::Deathmatch
# Once in the shell, type "?" and press <Enter> to see a list of available commands
```

This works exactly like `aifc-game`, except it drops you to a text debugging
session that allows you to issue commands, and, most usefully of all, use the
fantastic **pry** gem to introspect absolutely everything in the game.

Extra credit: check out `bin/debug-aifc-game`. See that aspect being applied to
`Paidgeeks::write_object`? Dig deep, figure out how that works, and you will be
a rubyfc debugging master.

So, things you can do in a debugging session:
* open terminal windows to tail the game and fleet(s) log files
* open a `pry` session; $gc is a global is accessible here, and contains the
game coordinator with which you can inspect almost everything.
* tick the game any number of game ticks at a time

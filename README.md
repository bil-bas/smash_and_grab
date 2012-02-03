Smash and Grab
==============

* [Website](http://spooner.github.com/games/smash_and_grab/)
* The game was developed by Spooner (Bil Bas) bil.bagpuss@gmail.com

Description
-----------

_Smash and Grab!_ is a retro isometric supervillainous turn-based hiest game.

Requirements
------------

### Windows

If running <tt>smash_and_grab.exe</tt>, there are no other requirements.

### OS X

If running OS X, use the executable (<tt>SmashAndGrab.app</tt>), which has no dependencies.

### Source for Linux (or Windows/OS X if not using the executable)

If running from source, users must install the Ruby interpreter and some rubygems. Linux users must also install some "extra dependencies](https://github.com/jlnr/gosu/wiki/Getting-Started-on-Linux for Gosu.

#### Dependencies

* Ruby 1.9.2 (Install via package manager or rvm). Ruby 1.9.3 recommended though, since loading is significantly faster.
** Gosu gem 0.7.32 (Dependencies: "Linux only](https://github.com/jlnr/gosu/wiki/Getting-Started-on-Linux)
** A number of other rubygems, which can be installed automatically using Bundler (see below).
** Linux Only: <tt>xsel</tt> or <tt>xcopy</tt> command to allow access to the system clipboard:
<pre>    sudo apt-get install xsel</pre>

#### Using Bundler to install gems

If the Bundler gem isn't already installed, that can be installed with:

<pre>
    gem install bundler --no-ri --no-rdoc
</pre>

In the game's main directory (with <tt>Gemfile</tt> in it), use Bundler to automatically install the correct gem versions:

<pre>
    bundle install
</pre>

#### Running the game

May need to use <tt>ruby19</tt> rather than <tt>ruby</tt>. Depends how you installed Ruby!

<pre>
    ruby bin/smash_and_grab.rbw
</pre>

How to Play
-----------

Move your supervillains around until you win!

### Implemented game features

* Scroll map with keyboard arrows; zoom with mouse wheel.
* Your Villains can move around.
* Your Villains can melee with enemies (Goodies or Bystanders).
* You can activate _Sprint_ ability to give a Villain extra movement (sacrificing all actions for that turn).
* Goodies and Bystanders will take a turn (very trivial AI) when you end yours.
* Editor works, but some bugs with placing Vehicles over other objects.
* Saving/loading (F5/F6) of state in Editor & Game.
* Undo/Redo (Ctrl-Z/Ctrl-Shift-Z)support in both Editor and Game (can't take back attacks though, since they are non-deterministic).

### Saved data

Save games and configuration are saved into (Windows):

    C:\Users\<your-username>\AppData\Roaming\Smash And Grab\

or (OS X / Linux):

    /home/<your-username>/.smash_and_grab/

Credits
-------

Many thanks to:

* Kaiserbill and SiliconEidolon for epic brainstorming sessions.
* Kaiserbill, SiliconEidolon and Tomislav Uzelac and for play-testing and feedback.

Third party tools and assets used
---------------------------------

* Original music by [Maverick (Brian Peppers)](http://polyhedricpeppers.weebly.com/). [![http://i.creativecommons.org/l/by-sa/3.0/88x31.png](CC BY-SA)](http://creativecommons.org/licenses/by-sa/3.0/)
* Original sprites created with [GIMP](http://www.gimp.org/) and Graphics Gale [Free Edition]
* Sound effects created using [bfxr](http://www.bfxr.net/) and converted using [Audacity](http://audacity.sourceforge.net/
* [Unmasked font](http://www.blambot.com/font_unmasked.shtml) by "Nate Piekos" [Free for personal use]
* [Gosu](http://libgosu.org/) game development library
* [Chingu](http://ippa.se/chingu) game library (extending Gosu)
* [Fidgit](https://github.com/Spooner/fidgit) gui library (extending Chingu)
* [Texplay](http://banisterfiend.wordpress.com/2008/08/23/texplay-an-image-manipulation-tool-for-ruby-and-gosu/ image manipulation library for Gosu.
* [R18n](http://r18n.rubyforge.org/) i18n library
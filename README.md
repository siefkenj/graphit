Graphit
=======

Graphit is a browser-based application for creating mathematical figures.
Based on the asciisvg library, Graphit uses javascript code to create figures 
which can then be saved in SVG, PDF, and PNG formats. Using javascript allows for the 
graphing of arbitrary user-defined functions as well as complicated figures 
(such as an illustration of a Riemann Sum) that other graphing packages do 
not provide tools for.

To run Graphit, open graphit.html in a web browser.  You can run
Graphit locally without a web server (works best from firefox
since chrome security policies disable things like local storage
when running local files), or you can run it from a php enabled
web server for full functionality.

You can try out a live version of Graphit yourself at
http://web.uvic.ca/~siefkenj/graphit/graphit.html

Liscense
========

Graphit is liscensed under the GPL-3.  Projects accessed as libraries
by graphit retain their original liscense.


Hacking
=======

Graphit is programmed primarily in coffeescript, a language that
compiles to javascript.  To start hacking, you will need to install
`Node.js` and then install coffeescript with the command `npm install -g coffee-script`.
You many need root permissions for this.

Once coffeescript is installed, the `coffee` command should be available.
To compile all of Graphit's coffeescript files run

	coffee -c --bare js/

from the Graphit root directory. If you are actively developing,
you may wish to have coffeescript automatically recompile your
scripts whenever a file changes.  You can do this with

	coffee -c --bare --watch js/


Prospective Features
====================

Here is a list of features and ideas for future versions
of Graphit.  Hackers welcome!

	* Full documentation for available graphing functions
	and variables.
	* Autocompletion support in the code editor
	* Dynamically increase the sample resolution when graphing
	functions of high curvature (e.g., pick a lot of sample
	points around zero for the graph of sin(1/x))
	* PNG metadata support so you can reload graphs saved as PNG
	* More, interesting examples to show off different functions
	* Detection of graphing operations that will take a long time
	(e.g. if someone sets the bounds from -10000 to 10000 and has
	gridlines every 1 unit, this will take a really long time,
	a lot of memory, and won't really show up right, so we should avoid
	actually doing the exact graph requested...)
	* General interface improvements: things like keyboard navigation
	would be nice.
	* Graph auto-updating: if it's not too computationally intensive,
	it'd be nice to have the graph auto-update.
	* Searching and sorting of previously saved graphs and examples


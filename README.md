Graphit
=======

Graphit is a browser-based application for creating mathematical figures.
Based on the asciisvg library, Graphit uses javascript code to create figures 
which can then be saved in SVG, PDF, and PNG formats. Using javascript allows for the 
graphing of arbitrary user-defined functions as well as complicated figures 
(such as an illustration of a Riemann Sum) that other graphing packages do 
not provide tools for.

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


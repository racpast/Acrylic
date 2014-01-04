if (-e 'perllib.pl') { require 'perllib.pl' } else { require 'C:/Wintools/Console/perllib.pl' }

# ---------------------------------------------------------------------------

use 5.016;
use strict;
use warnings;

# ---------------------------------------------------------------------------

# Text transformation and refactoring (trim & crop)
for my $f (lsfr('*.bat;*.bdsproj;*.cfg;*.cs;*.css;*.dfm;*.dof;*.dpr;*.exe.manifest;*.htm;*.html;*.ini;*.js;*.less;*.nsi;*.pas;*.php;*.pl;*.txt')) { my ($t, $e) = readtext($f); my $_ = $t; s#[ \t]+$##gm; s#^(\r\n|\n|\r)+##s; s#(\r\n|\n|\r)+$##s; if ($_ ne $t) { writetext($f, $_, $e); } }

# Text transformation and refactoring (compact empty lines)
for my $f (lsfr('*.cs;*.css;*.dpr;*.htm;*.html;*.js;*.less;*.pas;*.php;*.pl')) { my ($t, $e) = readtext($f); my $_ = $t; s#^(\r\n|\n|\r){2}(\r\n|\n|\r)+#$1#s; if ($_ ne $t) { writetext($f, $_, $e); } }

# ---------------------------------------------------------------------------
elvish-complete-from-bash
=========================

**An [Elvish](https://elv.sh) module for importing Bash completion scripts.**

Specifically, the module is designed for use with the [`bash-completion`
package](https://github.com/scop/bash-completion), a set of completion scripts common across many
operating systems. It is similar to the [`elvish-bash-completion`
module](https://github.com/aca/elvish-bash-completion), with two major differences.

* It provides an `autoimport` command to import as many completions as possible, rather than
  requiring the user to specifically import the ones they're interested in in their `rc.elv`.
* It uses the system's copy of `bash-completions` rather than bundling its own. This is desirable if
  you want to be sure that you're using completion code that's been vetted by your operating
  system's package maintainers or corporate I.T. team, for example. (`complete-from-bash` is
  intended to be short and easy to audit yourself, if you care about that kind of thing.)

Installation
------------

Install the package via [`epm`](https://elv.sh/ref/epm.html):

```elvish
epm:install github.com/HarryCutts/elvish-complete-from-bash
```

Usage
-----

Run the `autoimport` function in your `rc.elv` to import Bash completions for all commands in your
`$paths` that don't already have a completion function assigned, assuming that one's available in
Bash:

```elvish
# Import all your native Elvish completers...
set edit:completion:arg-completer[foo] = $my-foo-completer~
use some/other/completion/module

use github.com/HarryCutts/elvish-complete-from-bash/complete-from-bash
complete-from-bash:autoimport
```

Alternatively, you can import a specific completer using `import-for`:

```
use github.com/HarryCutts/elvish-complete-from-bash/complete-from-bash
complete-from-bash:import-for apt
```

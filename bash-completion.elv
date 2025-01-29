use path
use str

fn import-for {|command| 
  set edit:completion:arg-completer[$command] = {|@args|
    # TODO: swallow annoying error message as output by dd completer or systemctl status
    var script = '
      source /usr/share/bash-completion/bash_completion
      source /usr/share/bash-completion/completions/'$command'

      COMP_WORDS=("$@")
      COMP_CWORD='(- (count $args) 1)'
      COMP_LINE="$@"
      COMP_POINT=${#COMP_LINE}
      COMP_TYPE=9
      COMP_KEY=9

      #local logfile="/tmp/completion-log.txt"
      #echo "COMP_WORDS:" >> $logfile
      #for i in ${!COMP_WORDS[@]}; do echo ${COMP_WORDS[$i]} >> $logfile; done
      #echo "COMP_CWORD:" $COMP_CWORD >> $logfile
      #echo "COMP_LINE:" $COMP_LINE >> $logfile
      #echo "COMP_POINT:" $COMP_POINT >> $logfile

      # TODO: $2 should be the word being completed, and $3 should be the word before (https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html#:~:text=%2DF%20option.-,%2DF%20function,-The%20shell%20function)
      _'$command' '$command'

      for reply in ${COMPREPLY[@]}; do
        echo $reply
      done
    '
    # TODO: --norc and --noprofile?
    var replies = [(echo $script | bash -s $@args)]
    put $@replies
  }
}

fn -list-externals {
  var externals = [&]
  for dir $paths {
    for f [$dir/*[nomatch-ok]] {
      # TODO: use os:is-dir instead once Elvish 0.20.0 comes to Debian
      # TODO: this call adds ~300ms to the runtime, and just eliminates a few directories on my machine (/usr/bin/flutter/, /bin/flutter/, /usr/bin/flutter/bin/{cache internal}). Consider getting rid of it or optimizing
      if (not (path:is-dir $f)) {
        set externals[(path:base $f)] = $true
      }
    }
  }

  put (keys $externals)
}

fn -locate-completions {
  var completions = [&]
  # TODO: handle multiple dirs as described by the bash-completion docs (https://github.com/scop/bash-completion/tree/main?tab=readme-ov-file#faq:~:text=zsh.org/.-,Q.%20What%20is%20the%20search%20order%20for%20the%20completion%20file%20of%20each%20target%20command%3F,-A.%20The%20completion)
  var completions-dir = /usr/share/bash-completion/completions/
  # Look for <command>.bash files first then override them if a <command> file exists, since it
  # appears that <command> takes precedence over <command>.bash in bash-completion.
  for f [$completions-dir/*[nomatch-ok].bash] {
    var command = (str:trim-suffix (path:base $f) .bash)
    set completions[$command] = $f
  }
  for f [$completions-dir/*[nomatch-ok]] {
    if (not (str:has-suffix $f .bash)) {
      set completions[(path:base $f)] = $f
    }
  }
  put $completions
}

fn autoimport {
  # TODO: include eagerly-loaded completions (which it sounds like take precedence over the lazily-loaded ones)
  #   * Source all the files in the compatdir (`pkg-config --variable=compatdir bash-completion`) and then ~/.bash_completion
  #   * Run `complete` to get a list of all the current completions
  var completions = (-locate-completions)
  for command [(-list-externals)] {
    if (has-key $edit:completion:arg-completer $command) {
      continue
    }

    if (has-key $completions $command) {
      import-for $command
    }
  }
}

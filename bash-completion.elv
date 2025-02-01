use path
use str

fn import-for {|command| 
  var script = '
    source /usr/share/bash-completion/bash_completion
    source /usr/share/bash-completion/completions/'$command'

    COMP_WORDS=("$@")
    COMP_CWORD="$((${#COMP_WORDS[@]} - 1))"
    COMP_LINE="$@"
    COMP_POINT=${#COMP_LINE}
    COMP_TYPE=9
    COMP_KEY=9

    if [[ "$COMP_CWORD" -gt 0 ]]; then
      _'$command' '$command' "${COMP_WORDS[$COMP_CWORD]}" "${COMP_WORDS[$((COMP_CWORD - 1))]}"
    else
      _'$command' '$command' "${COMP_WORDS[$COMP_CWORD]}"
    fi

    for reply in ${COMPREPLY[@]}; do
      echo $reply
    done
  '
  set edit:completion:arg-completer[$command] = {|@args|
    # TODO: swallow annoying error message as output by dd completer or systemctl status
    # TODO: --norc and --noprofile?
    var replies = [(echo $script | bash -s $@args)]
    put $@replies
  }
}

fn -list-externals {
  var externals = [&]
  for dir $paths {
    for f [$dir/*[nomatch-ok]] {
      # TODO: using [type:regular] on the wildcard above _should_ just exclude directories, but it
      # also seems to exclude symlinks. I should check if this is still an issue in the latest
      # Elvish and report it if so. In the meantime, including directories isn't the end of the
      # world; at worst, it'll just mean a completer or two gets loaded unnecessarily.
      #
      # (Using path:is-dir instead adds ~300ms to the runtime, which isn't worth it.)
      set externals[(path:base $f)] = $true
    }
  }

  put (keys $externals)
}

fn -locate-completions {
  var completions = [&]
  # TODO: handle multiple dirs as described by the bash-completion docs
  # (https://github.com/scop/bash-completion/tree/main?tab=readme-ov-file#faq:~:text=zsh.org/.-,Q.%20What%20is%20the%20search%20order%20for%20the%20completion%20file%20of%20each%20target%20command%3F,-A.%20The%20completion)
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
  # TODO: include eagerly-loaded completions (which it sounds like take precedence over the
  # lazily-loaded ones)
  #   * Source all the files in the compatdir (`pkg-config --variable=compatdir bash-completion`)
  #     and then ~/.bash_completion
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

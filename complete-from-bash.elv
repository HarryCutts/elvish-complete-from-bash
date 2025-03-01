use flag
use path
use str

# For debugging purposes, set this to a file to receive stderr output from the completion script.
var -completer-stderr = /dev/null

var -bash-complete-getopt-specs = [
  # Arguments to the `complete` Bash builtin taken from `man 7 bash-builtins`.
  (each {|no-arg-flag| put [&short=$no-arg-flag]} abcdefgjksuvDEI)
  (each {|arg-flag| put [&short=$arg-flag &arg-required]} oAGWFCXPS)
]

fn -get-completion-info {|command comp-file-path|
  var script = '
    source /usr/share/bash-completion/bash_completion
    source '$comp-file-path'
    complete -p '$command'
  '
  var bash-complete-command = (echo $script | bash --norc --noprofile -s stderr>> $-completer-stderr)
  # `bash-complete-command` now contains the Bash command used to register the completion, e.g.
  # `complete -o bashdefault -o default -o nospace -F __git_wrap__git_main git`, which we can parse.
  var options _ = (flag:parse-getopt [(str:split ' ' $bash-complete-command)] $-bash-complete-getopt-specs)
  var comp-options = [&]
  var function-name = $nil
  for opt $options {
    var short = $opt[spec][short]
    if (eq $short F) {
      set function-name = $opt[arg]
    } elif (eq $short o) {
      set comp-options[$opt[arg]] = $true
    }
  }
  put $function-name $comp-options
}

fn import-for {|command &from-file=$nil|
  var comp-file-path = (coalesce $from-file /usr/share/bash-completion/completions/$command)
  var comp-fn-name comp-options = (-get-completion-info $command $comp-file-path)
  var strip-spaces = (has-key $comp-options nospace)
  var script = '
    source /usr/share/bash-completion/bash_completion
    source '$comp-file-path'

    COMP_WORDS=("$@")
    COMP_CWORD="$((${#COMP_WORDS[@]} - 1))"
    COMP_LINE="$*"
    COMP_POINT=${#COMP_LINE}
    COMP_TYPE=9
    COMP_KEY=9

    if [[ "$COMP_CWORD" -gt 0 ]]; then
      '$comp-fn-name' '$command' "${COMP_WORDS[$COMP_CWORD]}" "${COMP_WORDS[$((COMP_CWORD - 1))]}"
    else
      '$comp-fn-name' '$command' "${COMP_WORDS[$COMP_CWORD]}"
    fi

    for reply in "${COMPREPLY[@]}"; do
      echo "$reply"
    done
  '
  fn put-replies {
    each {|reply|
      if (str:has-suffix $reply '=') {
        # Avoid Elvish quoting long options completed with an =, by moving the equals to the
        # code-suffix of a complex-candidate.
        edit:complex-candidate &code-suffix='=' &display=$reply (str:trim-suffix $reply '=')
      } elif $strip-spaces {
        # Some Bash completers, such as for `git`, set `-o nospace` so that they can only add spaces
        # to the end of some completion candidates. This causes Elvish to quote the completion with
        # the extra space, resulting in a line such as `git 'status '`, which is invalid. By
        # default, Elvish doesn't add a space to the end of completion candidates anyway, so just
        # strip the extra whitespace.
        str:trim-space $reply
      } else {
        put $reply
      }
    }
  }
  set edit:completion:arg-completer[$command] = {|@args|
    echo $script | bash --norc --noprofile -s $@args stderr>> $-completer-stderr | put-replies
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
  # TODO: don't assume the completions are in the Debian default location
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
      # Importing each completion immediately would take too long (seconds), due to having to source
      # the completion file to find out what completion function to call. Instead, lazily import the
      # completion when it's first used.
      set edit:completion:arg-completer[$command] = {|cmd @args|
        # We can't use $command within this function since Elvish captures by reference, so it will
        # have moved on to another name by the time the completer's executed. Use $cmd instead.
        import-for $cmd &from-file=$completions[$cmd]
        $edit:completion:arg-completer[$cmd] $cmd $@args
      }
    }
  }
}

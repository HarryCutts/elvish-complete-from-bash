use str

fn import-for {|command| 
  set edit:completion:arg-completer[$command] = {|@args|
    # TODO: swallow annoying error message as output by dd completer
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

# In the function called from rc.elv:
# * Find out which commands have eagerly-loaded completions (which it sounds like take precedence over the lazily-loaded ones)
#   * Source all the files in the compatdir (`pkg-config --variable=compatdir bash-completion`) and then ~/.bash_completion
#   * Run `complete` to get a list of all the current completions
# * Look through all commands in the path that don't have completers already set up in Elvish. For each one:
#   * If a completion for it was eagerly-loaded, make an Elvish completion function based on that
#   * Otherwise, look through the various bash-completion search dirs for a matching file (see [0])
#     * If a matching file is found, source it, run `complete -p $CMD`, and create an Elvish completer based on the output
#
# [0]: https://github.com/scop/bash-completion/tree/main?tab=readme-ov-file#faq:~:text=zsh.org/.-,Q.%20What%20is%20the%20search%20order%20for%20the%20completion%20file%20of%20each%20target%20command%3F,-A.%20The%20completion

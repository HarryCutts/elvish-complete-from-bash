source /usr/share/bash-completion/bash_completion
source /usr/share/bash-completion/completions/dd

COMP_WORDS=('bs=4' 'c')
COMP_CWORD=1
COMP_LINE='dd bs=4 c'
COMP_POINT=${#COMP_LINE}
COMP_TYPE=9  # TAB (https://echorand.me/posts/linux_shell_autocompletion/#:~:text=COMP_TYPE%3A%20This%20is%20the%20type%20of%20completion%20that%20is%20being%20done%2C%2063%20is%20the%20ASCII%20code%20for%20%3F.%20According%20to%20the%20manual%2C%20this%20is%20the%20operation%20which%20will%20list%20completions%20after%20successive%20tabs)
COMP_KEY=9
# TODO: COMP_WORDBREAKS?

_dd

echo ${COMPREPLY[@]}

# Currently gives an error while running:
#  bash: compopt: not currently executing completion function
# This is generated in builtins/complete.def in the Bash source. Someone else trying to bridge Bash completions has encountered it too: https://github.com/tillig/ps-bash-completions#:~:text=If%20you%20run%20the%20troubleshooting,out%20isn%27t%20deep%20enough.
# However, it still lists some completions, so I guess it isn't the end of the world?

# ==============================================================================
# AUTHOR: M. H. IMAM (FxP1998)
# GITHUB: https://github.com/FxP1998
# ==============================================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Global Text Editor Routing (Required for Yazi, Git, etc.)
export EDITOR="nvim"
export VISUAL="nvim"

# Core Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Prompt Formatting
PS1='[\u@\h \W]\$ '

# Integrations
eval "$(zoxide init bash)"

############################################################################
#                                 ALIASES                                  #
############################################################################
alias ls="eza -l -a --icons=always"
alias k="kubectl"
alias akslogin="~/scripts/akslogin"

############################################################################
#                                  TOOLS                                   #
############################################################################
eval $(thefuck --alias)

############################################################################
#                             VISUAL & PROMPT                              #
############################################################################
# OMP
eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/zen.toml)"

# OMP zsh-vi-mode integration
bindkey -v
_omp_redraw-prompt() {
  local precmd
  for precmd in "${precmd_functions[@]}"; do
    "$precmd"
  done
  zle .reset-prompt
}

export POSH_VI_MODE="insert"

function zvm_after_select_vi_mode() {
  case $ZVM_MODE in
  $ZVM_MODE_NORMAL)
    POSH_VI_MODE="normal"
    ;;
  $ZVM_MODE_INSERT)
    POSH_VI_MODE="insert"
    ;;
  $ZVM_MODE_VISUAL)
    POSH_VI_MODE="visual"
    ;;
  $ZVM_MODE_VISUAL_LINE)
    POSH_VI_MODE="visual-line"
    ;;
  $ZVM_MODE_REPLACE)
    POSH_VI_MODE="replace"
    ;;
  esac
  _omp_redraw-prompt
}
# vi-mode config

function zvm_config() {
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
}


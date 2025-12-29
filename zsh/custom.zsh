# Homebrew
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v brew > /dev/null; then
  export HOMEBREW_NO_AUTO_UPDATE=1
fi

# Pipenv
export PIPENV_VENV_IN_PROJECT=1

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init -)"
    fi
fi

# Poetry
export PATH="$HOME/.local/bin:$PATH"
# alias poetry_shell='. "$(dirname $(poetry run which python))/activate"'

# Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
if command -v starship > /dev/null; then
    eval "$(starship init zsh)"
    # Check if a specialized theme matches, otherwise default
    if [ -n "$STARSHIP_THEME" ]; then
        starship config palette "$STARSHIP_THEME"
    fi
fi

# Load Git completion
if [ -f "$HOME/.config/zsh/git-completion.bash" ]; then
  zstyle ':completion:*:*:git:*' script $HOME/.config/zsh/git-completion.bash
fi
fpath=($HOME/.config/zsh $fpath)
autoload -Uz compinit && compinit

# Redshift
export ODBCINI="$HOME/.odbc.ini"
export ODBCSYSINI="/opt/amazon/redshift/Setup"
export AMAZONREDSHIFTODBCINI="/opt/amazon/redshift/lib/amazon.redshiftodbc.ini"
# Dynamic Library Path logic for Linux compatibility
if [[ "$(uname -s)" == "Darwin" ]]; then
    export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:/usr/local/lib"
fi

# Neovim as MANPAGER
export MANPAGER='nvim +Man!'

# fzf
if [ -f "$HOME/.fzf.zsh" ]; then
    source "$HOME/.fzf.zsh"
elif [ -f "/usr/share/doc/fzf/examples/key-bindings.zsh" ]; then
    source "/usr/share/doc/fzf/examples/key-bindings.zsh"
    # completion might be in a similar place, let's try to source it if it exists
    [ -f "/usr/share/doc/fzf/examples/completion.zsh" ] && source "/usr/share/doc/fzf/examples/completion.zsh"
fi

export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_DEFAULT_COMMAND='rg --hidden -l ""' # Include hidden files

# Fix for ALT+C on Mac (Option+C produces ç)
if [[ "$(uname -s)" == "Darwin" ]]; then
    # Check if widget exists before binding to avoid zsh-syntax-highlighting errors
    if zle -la | grep -q "^fzf-cd-widget$"; then
        bindkey "ç" fzf-cd-widget 
    fi
fi

# fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# fh - search in your command history and execute selected command
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

# Tmux (Commented out default)
# ...

# zoxide - a better cd command
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Zsh Plugins Logic
ZSH_PLUGINS_DIR=""
if command -v brew > /dev/null; then
    ZSH_PLUGINS_DIR="$(brew --prefix)/share"
elif [ -d "/usr/share" ]; then
    ZSH_PLUGINS_DIR="/usr/share"
fi

# Activate syntax highlighting
if [ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Disable underline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

# Activate autosuggestions
if [ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Vi mode
bindkey -v # Enable vi keybindings
export KEYTIMEOUT=1 # Makes switching modes quicker
export VI_MODE_SET_CURSOR=true # trigger cursor shape changes when switching modes

# Gets called every time the keymap changes (insert <-> normal mode)
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]]; then
    echo -ne '\e[2 q' # block
  else
    echo -ne '\e[6 q' # beam
  fi
}
# Register this function as a ZLE (Zsh Line Editor) widget
zle -N zle-keymap-select

# Runs once when a new ZLE session starts (e.g. when a prompt appears)
zle-line-init() {
  zle -K viins # initiate 'vi insert' as keymap (can be removed if 'binkey -V has been set elsewhere')
  echo -ne '\e[6 q'
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup

# Yank to the system clipboard
function vi-yank-xclip {
  zle vi-yank
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "$CUTBUFFER" | pbcopy -i
  else
     echo "$CUTBUFFER" | xclip -selection clipboard
  fi
}

zle -N vi-yank-xclip
bindkey -M vicmd 'y' vi-yank-xclip

# Press 'v' in normal mode to launch Vim with current line
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

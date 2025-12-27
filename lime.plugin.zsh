prompt_lime_precmd() {
  # Set title
  prompt_lime_set_title

  # Get VCS information
  vcs_info
}

prompt_lime_preexec() {
  # Show the current job
  prompt_lime_set_title "$1"
}

prompt_lime_set_title() {
  local window_title="$(prompt_lime_window_title)"
  local tab_title="$(prompt_lime_tab_title "$@")"

  # Inside screen or tmux
  case "$TERM" in
    screen*)
      # Set window title
      print -n '\e]0;'
      print -rn "${window_title}"
      print -n '\a'

      # Set window name
      print -n '\ek'
      print -rn "${tab_title}"
      print -n '\e\\'
      ;;
    cygwin|putty*|rxvt*|xterm*)
      # Set window title
      print -n '\e]2;'
      print -rn "${window_title}"
      print -n '\a'

      # Set tab name
      print -n '\e]1;'
      print -rn "${tab_title}"
      print -n '\a'
      ;;
    *)
      # Set window title if it's available
      zmodload zsh/terminfo
      if [[ -n "$terminfo[tsl]" ]] && [[ -n "$terminfo[fsl]" ]]; then
        echoti tsl
        print -rn "${window_title}"
        echoti fsl
      fi
      ;;
  esac
}

prompt_lime_window_title() {
  # Username, hostname and current directory
  print -Pn '%n@%m: %~'
}

prompt_lime_tab_title() {
  if [[ $# -eq 1 ]]; then
    prompt_lime_first_command "$1"
  else
    # `%40<..<` truncates following string longer than 40 characters with `..`.
    # `%~` is current working directory with `~` instead of full `$HOME` path.
    # `%<<` sets the end of string to truncate.
    print -Pn '%40<..<%~%<<'
  fi
}

prompt_lime_first_command() {
  setopt local_options extended_glob

  # Return the first command excluding env, options, sudo, ssh
  print -rn ${1[(wr)^(*=*|-*|sudo|ssh)]:gs/%/%%}
}

prompt_lime_render() {
  print -rn "${prompt_lime_rendered_user}"
  print -n ' '
  prompt_lime_dir
  print -n ' '
  prompt_lime_git
  print -rn "${prompt_lime_rendered_symbol}"
}

prompt_lime_user() {
  local prompt_color="${LIME_USER_COLOR:-$prompt_lime_default_user_color}"
  if (( ${LIME_SHOW_HOSTNAME:-0} )) && [[ -n "$SSH_CONNECTION" ]]; then
    print -n "%F{${prompt_color}}%n@%m%f"
  else
    print -n "%F{${prompt_color}}%n%f"
  fi
}

prompt_lime_dir() {
  local prompt_color="${LIME_DIR_COLOR:-$prompt_lime_default_dir_color}"
  local dir_components="${LIME_DIR_DISPLAY_COMPONENTS:-0}"
  if (( dir_components )); then
    print -n "%F{${prompt_color}}%($((dir_components + 1))~:...%${dir_components}~:%~)%f"
  else
    print -n "%F{${prompt_color}}%~%f"
  fi
}

prompt_lime_git() {
  # Store working_tree without the 'x' prefix
  local working_tree="${vcs_info_msg_1_#x}"
  [[ -n $working_tree ]] || return

  local prompt_color="${LIME_GIT_COLOR:-$prompt_lime_default_git_color}"
  print -n "%F{${prompt_color}}${vcs_info_msg_0_}$(prompt_lime_git_dirty)%f "
}

prompt_lime_git_dirty() {
  [[ -n "$(command git status --porcelain -unormal --ignore-submodules=dirty)" ]] && print -n '*'
}

prompt_lime_symbol() {
  if [[ $UID -eq 0 ]]; then
    print -n '#'
  else
    print -n '$'
  fi
}

prompt_lime_setup() {
  precmd_functions+=(prompt_lime_precmd)
  preexec_functions+=(prompt_lime_preexec)

  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git
  # Export only two msg variables from vcs_info
  zstyle ':vcs_info:*' max-exports 2
  # %s: The current version control system, like 'git' or 'svn'
  # %r: The name of the root directory of the repository
  # #S: The current path relative to the repository root directory
  # %b: Branch information, like 'master'
  # %m: In case of Git, show information about stashes
  # %u: Show unstaged changes in the repository (works with 'check-for-changes')
  # %c: Show staged changes in the repository (works with 'check-for-changes')
  #
  # vcs_info_msg_0_ = '%b'
  # vcs_info_msg_1_ = 'x%r' x-prefix prevents creation of a named path
  #                         (AUTO_NAME_DIRS)
  zstyle ':vcs_info:git*' formats '%b' 'x%r'
  # '%a' is for action like 'rebase', 'rebase-i', 'merge'
  zstyle ':vcs_info:git*' actionformats '%b(%a)' 'x%r'

  # Support 8 colors
  if [[ "$TERM" = *"256color" ]]; then
    prompt_lime_default_user_color=109
    prompt_lime_default_dir_color=143
    prompt_lime_default_git_color=109
  else
    prompt_lime_default_user_color=cyan
    prompt_lime_default_dir_color=green
    prompt_lime_default_git_color=cyan
  fi

  prompt_lime_rendered_user="$(prompt_lime_user)"
  prompt_lime_rendered_symbol="$(prompt_lime_symbol)"

  # If set, parameter expansion, command substitution and arithmetic expansion
  # is performed in prompts
  setopt prompt_subst
  PROMPT='$(prompt_lime_render) '
}

prompt_lime_setup

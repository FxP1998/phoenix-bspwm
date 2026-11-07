# ==============================================================================
# AUTHOR: M. H. IMAM (FxP1998)
# GITHUB: https://github.com/FxP1998
# ==============================================================================

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Hardware Video Acceleration (VA-API) for Intel HD 520 (Skylake)
export LIBVA_DRIVER_NAME=i965

# Force Qt applications to use the Catppuccin GTK theme engine
export QT_STYLE_OVERRIDE=kvantum

# Auto-start X11 on TTY1 Login
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec startx
fi

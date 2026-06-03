#!/usr/bin/env bash
#
# setup-macos-headless-terminal-20260603.sh
# ------------------------------------------------------------------------------
# 헤드리스 Mac mini(모니터 없이 SSH 접속) 의 "기본 zsh" 터미널을
# 컬러풀하게 + fish 셸처럼 편하게 + 도움되는 CLI 툴까지 한 번에 셋업한다.
#
#   - 컬러풀 프롬프트            : starship (git/언어버전/실행시간 표시, 2줄 프롬프트)
#   - fish 스타일 자동완성/제안  : zsh-autosuggestions (회색 고스트 텍스트 → →키로 수락)
#   - 입력 중 실시간 문법 컬러   : zsh-syntax-highlighting
#   - 폴더/파일 한눈에 구분      : eza (ls 대체, 컬러 + 아이콘)
#   - 도움되는 모던 CLI 툴       : bat fzf zoxide fd ripgrep gh jq btop tldr delta
#
# 특징:
#   * 기본 셸(zsh)을 그대로 유지한다 → 돌아가는 봇/스크립트 깨질 위험 없음 (chsh 안 함)
#   * 여러 번 실행해도 안전 (idempotent). ~/.zshrc 의 관리 블록만 교체한다.
#   * Apple Silicon(/opt/homebrew) / Intel(/usr/local) 자동 감지
#   * `brew upgrade` 전체 업그레이드는 안 한다 → 돌고 있는 환경을 흔들지 않음
#
# 사용법 (맥미니에 SSH로 붙은 상태에서, root 가 아닌 본인 계정으로):
#   chmod +x setup-macos-headless-terminal-20260603.sh
#   ./setup-macos-headless-terminal-20260603.sh
#   # 끝나면:  exec zsh   (또는 SSH 재접속)
#
# ⚠️ 폰트는 "접속하는 쪽(클라이언트) 터미널"에서 설정해야 아이콘이 보입니다.
#    스크립트 끝에 클라이언트 설정 안내가 출력됩니다.
#
# 이 스크립트는 시스템을 변경합니다(Homebrew 설치, 패키지 설치, dotfile 수정).
# 위 DFIR 트리아지 스크립트들과 달리 read-only 가 아닙니다 — setup 스크립트입니다.
# ------------------------------------------------------------------------------

set -o pipefail

# ----------------------------- 출력 헬퍼 --------------------------------------
c_reset=$'\033[0m'; c_red=$'\033[1;31m'; c_grn=$'\033[1;32m'
c_ylw=$'\033[1;33m'; c_blu=$'\033[1;34m'; c_cyn=$'\033[1;36m'; c_bold=$'\033[1m'
info() { printf '%s\n' "${c_blu}▶${c_reset} $*"; }
ok()   { printf '%s\n' "${c_grn}✔${c_reset} $*"; }
warn() { printf '%s\n' "${c_ylw}⚠${c_reset} $*"; }
err()  { printf '%s\n' "${c_red}✘${c_reset} $*" >&2; }
hr()   { printf '%s\n' "${c_cyn}────────────────────────────────────────────────────────${c_reset}"; }

hr
printf '%s\n' "${c_bold}  GitNote · Headless Mac mini zsh 터미널 셋업${c_reset}"
hr

# ----------------------------- 사전 점검 --------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "이 스크립트는 macOS 전용입니다. (현재: $(uname -s)) 맥미니에서 실행하세요."
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  err "root 로 실행하지 마세요. Homebrew 는 일반 사용자 계정으로 설치해야 합니다."
  err "  → 본인 계정으로 다시 실행하세요 (필요할 때만 sudo 비밀번호를 물어봅니다)."
  exit 1
fi

# ----------------------------- 1) Homebrew ------------------------------------
if ! command -v brew >/dev/null 2>&1 \
   && [[ ! -x /opt/homebrew/bin/brew ]] && [[ ! -x /usr/local/bin/brew ]]; then
  info "Homebrew 가 없어 설치합니다. (Command Line Tools 도 자동 설치됩니다)"
  warn "중간에 sudo 비밀번호를 물어볼 수 있습니다 — 본인 로그인 비밀번호를 입력하세요."
  if ! NONINTERACTIVE=1 /bin/bash -c \
       "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    err "Homebrew 설치에 실패했습니다. 네트워크/권한을 확인 후 다시 실행하세요."
    exit 1
  fi
  ok "Homebrew 설치 완료"
else
  ok "Homebrew 이미 설치됨"
fi

# brew 경로 확정 + 현재 셸 세션에 로드
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_PREFIX="/usr/local"
else
  BREW_PREFIX="$(command -v brew >/dev/null 2>&1 && dirname "$(dirname "$(command -v brew)")")"
fi
if [[ -z "${BREW_PREFIX:-}" ]] || [[ ! -x "$BREW_PREFIX/bin/brew" ]]; then
  err "brew 실행파일을 찾지 못했습니다. 설치를 확인하세요."
  exit 1
fi
eval "$("$BREW_PREFIX/bin/brew" shellenv)"
info "Homebrew prefix: ${c_bold}${BREW_PREFIX}${c_reset}"

# 포뮬러 인덱스만 갱신 (전체 upgrade 는 일부러 안 함 → 돌아가는 환경 보호)
info "brew 인덱스 갱신 중..."
brew update >/dev/null 2>&1 && ok "brew update 완료" || warn "brew update 건너뜀(무시 가능)"

# ----------------------------- 2) CLI 툴 설치 ---------------------------------
# 한 개 실패해도 전체가 멈추지 않도록 개별 설치 + 이미 깔린 건 건너뜀
brew_install() {
  local pkg
  for pkg in "$@"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      ok "$pkg (이미 설치됨)"
    else
      info "설치: $pkg ..."
      if brew install "$pkg" >/dev/null 2>&1; then
        ok "$pkg 설치 완료"
      else
        warn "$pkg 설치 실패 — 건너뜁니다 (나중에 'brew install $pkg' 재시도 가능)"
      fi
    fi
  done
}

info "모던 CLI 툴 + zsh 플러그인 설치"
brew_install \
  starship \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zsh-completions \
  eza \
  bat \
  fzf \
  zoxide \
  fd \
  ripgrep \
  git \
  gh \
  jq \
  btop \
  tlrc \
  git-delta

# ----------------------------- 3) Nerd Font (선택) ----------------------------
# 헤드리스 서버에는 사실상 필요 없지만(=화면이 없음), 파일을 받아두면
# 클라이언트로 복사하기 편하고, Screen Sharing 으로 GUI 쓸 때도 도움됨.
info "Nerd Font 설치 시도: JetBrainsMono Nerd Font (가독성 좋은 sans 고정폭)"
if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
  ok "font-jetbrains-mono-nerd-font (이미 설치됨)"
elif brew install --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
  ok "JetBrainsMono Nerd Font 설치 완료 (맥미니 쪽)"
else
  warn "폰트 설치는 건너뜀 — 어차피 핵심은 '클라이언트' 쪽 폰트 설정입니다(끝에서 안내)."
fi

# ----------------------------- 4) ~/.zprofile (Homebrew PATH) -----------------
ZPROFILE="$HOME/.zprofile"
touch "$ZPROFILE"
if ! grep -qF 'brew shellenv' "$ZPROFILE"; then
  printf '\n# Homebrew (added by GitNote terminal setup)\neval "$(%s/bin/brew shellenv)"\n' \
    "$BREW_PREFIX" >> "$ZPROFILE"
  ok ".zprofile 에 Homebrew 경로 등록"
else
  ok ".zprofile 에 Homebrew 경로 이미 있음"
fi

# ----------------------------- 5) ~/.zshrc 관리 블록 --------------------------
ZSHRC="$HOME/.zshrc"
MARKER_START="# >>> gitnote terminal setup >>>"
MARKER_END="# <<< gitnote terminal setup <<<"
touch "$ZSHRC"

# 재실행 시 기존 관리 블록(마커 사이)을 통째로 제거 → 항상 최신 설정으로 교체.
# 동시에 끝쪽 빈 줄을 정리해서, 여러 번 실행해도 빈 줄이 쌓이지 않게 한다.
if grep -qF "$MARKER_START" "$ZSHRC"; then
  cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d%H%M%S)"
  info "기존 .zshrc 관리 블록 갱신 (백업: $ZSHRC.bak.*)"
fi
tmp_zshrc="$(mktemp)"
awk -v s="$MARKER_START" -v e="$MARKER_END" '
  $0==s {skip=1}
  skip!=1 {a[++n]=$0}
  $0==e {skip=0}
  END {
    while (n > 0 && a[n] ~ /^[[:space:]]*$/) n--   # 끝쪽 빈 줄 제거
    for (i = 1; i <= n; i++) print a[i]
  }
' "$ZSHRC" > "$tmp_zshrc" && mv "$tmp_zshrc" "$ZSHRC"

# 기존 내용이 있으면 한 줄 띄우고 블록을 붙인다 (없으면 그냥 붙임)
[[ -s "$ZSHRC" ]] && printf '\n' >> "$ZSHRC"
cat >> "$ZSHRC" <<'ZSHRC_BLOCK'
# >>> gitnote terminal setup >>>
# GitNote headless terminal setup (managed block)
# ▸ 이 마커 사이는 setup 스크립트가 다시 쓸 수 있으니, 직접 수정은 마커 "바깥"에 하세요.

# --- Homebrew 경로 자동 감지 (Apple Silicon: /opt/homebrew, Intel: /usr/local) ---
if [[ -d /opt/homebrew ]]; then
  export BREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]]; then
  export BREW_PREFIX="/usr/local"
fi
[[ -n "${BREW_PREFIX:-}" ]] && export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"

# --- 기본 환경 ---
export LANG="en_US.UTF-8"          # SSH 로케일 경고 방지 (한글 표시는 UTF-8 이라 정상)
# export LC_ALL="en_US.UTF-8"      # locale 경고가 계속 뜨면 이 줄 주석 해제
export EDITOR="nano"               # 원하면 vim / nvim 으로 변경
export CLICOLOR=1                  # 기본 BSD ls 컬러 (eza 미사용 상황 대비)
export PAGER="less -R"

# --- zsh 편의 옵션 (fish 느낌) ---
setopt AUTO_CD                     # 디렉토리명만 입력해도 cd
setopt INTERACTIVE_COMMENTS        # 프롬프트에서 # 주석 허용
setopt EXTENDED_GLOB
setopt NO_BEEP

# --- 히스토리: 넉넉 + 중복정리 + 세션 공유 ---
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS INC_APPEND_HISTORY

# --- 자동완성: brew completions 등록 + 컬러 메뉴 + 대소문자 무시 ---
if [[ -n "${BREW_PREFIX:-}" ]]; then
  fpath=("$BREW_PREFIX/share/zsh-completions" "$BREW_PREFIX/share/zsh/site-functions" $fpath)
fi
autoload -Uz compinit && compinit -i
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# --- eza: 컬러 + 폴더/파일 한눈에 구분 (ls 대체) ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git --time-style=long-iso'
  alias la='eza -a  --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
fi

# --- bat: 컬러 + 문법 강조 cat. (cat 자체는 봇/스크립트 안전을 위해 그대로 둠) ---
command -v bat >/dev/null 2>&1 && export BAT_THEME="ansi"

# --- fzf: 퍼지 검색 (Ctrl-R 히스토리 / Ctrl-T 파일 / Alt-C 디렉토리 이동) ---
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS="--height 40% --layout reverse --border --info inline"
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)                                   # fzf 0.48+ 셸 통합
  elif [[ -f "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
    source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"  # 구버전 폴백
    [[ -f "$BREW_PREFIX/opt/fzf/shell/completion.zsh" ]] && \
      source "$BREW_PREFIX/opt/fzf/shell/completion.zsh"
  fi
fi

# --- zoxide: 똑똑한 cd. 예) z gitnote → 자주 가던 디렉토리로 점프 ---
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# --- zsh-autosuggestions: fish 처럼 다음 명령어를 회색으로 미리보기 (→ 키로 수락) ---
if [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"                  # 고스트 텍스트 = 회색
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)           # 히스토리 + 자동완성 기반 제안
fi

# --- starship: 컬러풀 2줄 프롬프트 (git / 언어버전 / 실행시간) ---
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# --- zsh-syntax-highlighting: 입력 중 실시간 컬러 (★ 반드시 맨 마지막에 로드) ---
if [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
# <<< gitnote terminal setup <<<
ZSHRC_BLOCK
ok ".zshrc 관리 블록 작성 완료"

# ----------------------------- 6) starship 설정 -------------------------------
mkdir -p "$HOME/.config"
STARSHIP_CONF="$HOME/.config/starship.toml"
if [[ -f "$STARSHIP_CONF" ]]; then
  cp "$STARSHIP_CONF" "$STARSHIP_CONF.bak.$(date +%Y%m%d%H%M%S)"
  info "기존 starship.toml 백업 후 교체 (백업: $STARSHIP_CONF.bak.*)"
fi
cat > "$STARSHIP_CONF" <<'STARSHIP_TOML'
# GitNote headless terminal — Starship 프롬프트
# 2줄 프롬프트: 1줄=정보(user/host/dir/git/언어/시간), 2줄=입력 라인.
# 아이콘( /  / ➜ 등)은 "클라이언트" 터미널에 Nerd Font 가 설정돼 있어야 제대로 보입니다.
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = true
command_timeout = 1000

format = """
[╭─](bold white)$username$hostname$directory$git_branch$git_status$nodejs$python$rust$golang$docker_context$cmd_duration
[╰─](bold white)$character """

[username]
show_always = true
style_user = "bold yellow"
style_root = "bold red"
format = "[$user]($style)"

[hostname]
ssh_only = false
style = "bold green"
format = "[@$hostname]($style) "

[directory]
style = "bold cyan"
truncation_length = 4
truncate_to_repo = true
read_only = " 󰌾"
read_only_style = "red"
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
style = "bold purple"
format = "[$symbol$branch]($style) "

[git_status]
style = "bold red"
format = '([$all_status$ahead_behind]($style)) '

[cmd_duration]
min_time = 2000
style = "bold yellow"
format = "took [$duration]($style) "

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[nodejs]
symbol = " "
format = "[$symbol($version )]($style)"

[python]
symbol = " "
format = "[$symbol($version )]($style)"

[rust]
symbol = " "

[golang]
symbol = " "

[docker_context]
symbol = " "
STARSHIP_TOML
ok "starship.toml 작성 완료 → $STARSHIP_CONF"

# ----------------------------- 7) 설치 결과 요약 ------------------------------
hr
printf '%s\n' "${c_bold}  설치된 도구 확인${c_reset}"
hr
check_ver() {
  local name="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$(printf '%-10s' "$name") $("$cmd" --version 2>/dev/null | head -n1)"
  else
    warn "$(printf '%-10s' "$name") (미설치)"
  fi
}
check_ver starship starship
check_ver eza      eza
check_ver bat      bat
check_ver fzf      fzf
check_ver zoxide   zoxide
check_ver ripgrep  rg
check_ver fd       fd
check_ver gh       gh
check_ver jq       jq
check_ver btop     btop
check_ver delta    delta
check_ver tldr     tldr

# ----------------------------- 8) 마무리 안내 ---------------------------------
hr
printf '%s\n' "${c_grn}${c_bold}  ✔ 맥미니 쪽 셋업 완료!${c_reset}"
hr
cat <<EOF

${c_bold}1) 지금 바로 적용${c_reset}
   ${c_cyn}exec zsh${c_reset}        # 또는 SSH 재접속

${c_bold}2) ⭐ 가장 중요 — '접속하는 쪽(클라이언트)' 터미널에 Nerd Font 설치/설정${c_reset}
   SSH 로 붙으면 글자/아이콘 렌더링은 맥미니가 아니라 '클라이언트'가 합니다.
   클라이언트에 JetBrainsMono Nerd Font 를 깔고, 터미널 폰트로 지정하세요.

   • ${c_bold}클라이언트가 macOS${c_reset} 인 경우:
       brew install --cask font-jetbrains-mono-nerd-font
     - iTerm2 : Settings → Profiles → Text → Font → "JetBrainsMono Nerd Font"
     - 기본 Terminal.app : Settings → Profiles → Text → Font 변경
   • ${c_bold}Windows Terminal${c_reset} : 설정 → 프로필 → 모양 → 글꼴 → "JetBrainsMono Nerd Font"
       (폰트는 https://www.nerdfonts.com 또는 'winget install --id DEVCOM.JetBrainsMonoNerdFont')
   • ${c_bold}VS Code 내장 터미널${c_reset} : settings.json →
       "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"

   ※ 폰트를 안 바꾸면 컬러는 나오지만 아이콘 자리에 네모(□)가 보일 수 있어요.

${c_bold}3) 새로 생긴 것들 빠른 사용법${c_reset}
   • 폴더/파일 컬러 목록 :  ${c_cyn}ls${c_reset} / ${c_cyn}ll${c_reset} / ${c_cyn}lt${c_reset}        (eza)
   • 다음 명령어 회색 제안 :  타이핑하면 자동, ${c_cyn}→${c_reset}(오른쪽 화살표)로 수락  (autosuggestions)
   • 히스토리 퍼지 검색    :  ${c_cyn}Ctrl-R${c_reset}                       (fzf)
   • 똑똑한 디렉토리 점프  :  ${c_cyn}z 키워드${c_reset}                     (zoxide)
   • 컬러 cat / 명령어 도움 : ${c_cyn}bat 파일${c_reset} / ${c_cyn}tldr 명령어${c_reset}        (bat / tldr)

${c_bold}4) 취향 손보기${c_reset}
   • 프롬프트 모양 :  ${c_cyn}~/.config/starship.toml${c_reset}   (프리셋 구경: starship preset --list)
   • 셸 설정       :  ${c_cyn}~/.zshrc${c_reset} 의 "gitnote terminal setup" 블록

EOF

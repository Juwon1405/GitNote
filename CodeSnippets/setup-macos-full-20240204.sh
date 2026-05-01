#!/bin/bash

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update and upgrade Homebrew packages
brew update
brew upgrade

# Install iTerm2 if it's not installed
if [ ! -d "/Applications/iTerm.app" ]; then
  echo "Installing iTerm2..."
  brew install --cask iterm2
fi

# Install Fish shell if it's not already installed
if ! which fish > /dev/null; then
  echo "Installing Fish shell..."
  brew install fish
  # Add Fish shell to list of allowed shells
  echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
  # Change default shell to Fish for the current user
  chsh -s /opt/homebrew/bin/fish
fi

# Install applications using Brew if they are not installed
apps=(
  010-editor
  adobe-acrobat-reader
  alfred
  alt-tab
  appcleaner
  cyberduck
  db-browser-for-sqlite
  discord
  drawio
  firefox
  github
  google-chrome
  keka
  maccy
  magnet
  microsoft-edge
  microsoft-excel
  microsoft-powerpoint
  microsoft-remote-desktop
  microsoft-word
  obsidian
  postman
  slack
  sublime-text
  tableplus
  telegram
  visual-studio-code
  zoom
)

for app in "${apps[@]}"; do
  if ! brew list --cask | grep -q "^${app}\$"; then
    echo "Installing $app..."
    brew install --cask $app
  fi
done

# Install tools using Brew if they are not installed
tools=(
  bat
  exa
  lsd
  git-delta
  dust
  duf
  broot
  fd
  ripgrep
  the_silver_searcher
  fzf
  mcfly
  choose
  jq
  sd
  cheat
  tldr
  bottom
  glances
  gtop
  hyperfine
  gping
  procs
  httpie
  curlie
  xh
  zoxide
  dog
)

for tool in "${tools[@]}"; do
  if ! which $tool > /dev/null; then
    echo "Installing $tool..."
    brew install $tool
  fi
done

# Configure Fish shell as per user's config
fish_config_path=~/.config/fish/config.fish
mkdir -p $(dirname $fish_config_path)

# Inserting the user's fish shell config into the config.fish file
cat > $fish_config_path << 'EOF'
# Show public IP address in interactive sessions
if status is-interactive
  # curl ifconfig.io
end

# Set environment
set -U fish_user_paths $HOME/go/bin/ $fish_user_paths

# Commands to run in interactive sessions can go here
if status is-interactive
    
end

# Install modern Unix tools with brew
  # brew install bat
  # brew install exa
  # brew install lsd
  # brew install delta
  # brew install dust
  # brew install duf
  # brew install broot
  # brew install fd
  # brew install rg
  # brew install ag
  # brew install fzf
  # brew install mcfly
  # brew install choose
  # brew install jq
  # brew install sd
  # brew install cheat
  # brew install tldr
  # brew install bottom
  # brew install glances
  # brew install gtop
  # brew install hyperfine
  # brew install gping
  # brew install procs
  # brew install httpie
  # brew install curlie 
  # brew install xh
  # brew install zoxide
  # brew install dog

# User defined environment
function fish_prompt
    set -l last_status $status
    # Define prompt colors
    set_color $fish_color_cwd
    set -l dir (prompt_pwd)
    set_color $fish_color_git
    set_color green #normal
    # Build prompt
    if test $last_status -ne 0
        set_color $fish_color_error
        echo -n '[ERROR] '
    end
    # Display hostname
    echo -n (hostname)"@"
    echo -n (basename $dir)
    echo -n '> '
    set_color normal
end

set -gx PS1 '%d# '
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH "/Applications/Sublime Text.app/Contents/SharedSupport/bin" $PATH

# User defined alias and functions here
alias ls='exa'
alias df='duf'
alias du='dust -r'
alias ols='/bin/ls'
alias odf='/bin/df'
alias odu='/usr/bin/du'
alias xclip='pbcopy'
alias pip='pip3'
alias python='python3'
alias ping 'grc ping'
alias rm 'rm -rf'
alias ps 'grc ps'
alias diff 'grc diff'
alias dig 'grc dig'
alias gcc 'grc gcc'
alias echo 'echo -n'
alias grep 'grep -i'
alias ifconfig 'grc ifconfig'
alias lsof 'grc lsof'
alias sortuniq 'sort | uniq -c | sort -n'
alias netstat 'grc netstat'
alias md5sum 'grc md5sum'
alias powershell 'pwsh'
alias oman '/usr/bin/man'
alias man 'tldr'
alias man2 'cheat'
alias ghidra '$HOME/Documents/macOS_Sharing_Env/Tools/ghidra_10.2.3_PUBLIC/ghidraRun'
alias identify 'identify -verbose'
alias exiftool 'exiftool -A'
alias mediainfo 'mediainfo -A'
alias mediainfo 'ipinfo'


function __complete_ipinfo
    set -lx COMP_LINE (commandline -cp)
    test -z (commandline -ct)
    and set COMP_LINE "$COMP_LINE "
    /usr/local/bin/ipinfo
end
complete -f -c ipinfo -a "(__complete_ipinfo)"


# variable function

function ip
    ipinfo $argv -t e6455fc4941996
end


# Personal functions ($HOME/Documents/macOS_Sharing_Env/Tools)

        function gg
            cd $HOME/Documents/Incident_Analysis/Temp_Analysis
        end        

        function mac
            cd $HOME/Documents/macOS_Sharing_Env
        end        

        function tools
            cd $HOME/Documents/macOS_Sharing_Env/Tools
        end

        function checkip --description 'Reputation lookup script for ip address'
            python $HOME/Documents/macOS_Sharing_Env/Tools/checkip.py $argv
        end
        
        function evtx_dump-to_jsonlines --description 'evtx dump to jsonlines'
            python $HOME/Documents/macOS_Sharing_Env/Tools/evtx_dump-to_jsonlines.py
        end
        
        function unzip_all --description 'unzip_all(Tried passwords as cert and infected.)'
            bash $HOME/Documents/macOS_Sharing_Env/Tools/unzip_all.sh
        end
        
        function mft2csv --description 'mft2csv(plaso, log2timeline)'
            bash $HOME/Documents/macOS_Sharing_Env/Tools/mft2csv.sh $argv
        end

        function chatgpt --description 'cli interpreter based chatgpt(gpt-3.5-turbo model)'
        python $HOME/Documents/macOS_Sharing_Env/Tools/chatgpt-cli/chatgpt.py $argv
        end

        function dcode_shift_jis --description 'Decoding script for Japanese shift_jis charset'
        python $HOME/Documents/macOS_Sharing_Env/Tools/dcode_shift_jis.py $argv
        end

        function chrome-sqlite3-to-csv --description 'Script to read and output chrome browser history sqlite3 file'
        python $HOME/Documents/macOS_Sharing_Env/Tools/chrome-sqlite3-to-csv.py $argv
        end

        #function ipinfo --description 'Script to load reputation lookup site in terminal https://ipinfo.io/{ip} '
        #python $HOME/Documents/macOS_Sharing_Env/Tools/ipinfo.py $argv
        #end

        function bplist2json --description 'Script to parse bplist file to json'
        python $HOME/Documents/macOS_Sharing_Env/Tools/bplist2json.py $argv
        end

        function whois-history --description 'https://whois-history.whoisxmlapi.com'
        python $HOME/Documents/macOS_Sharing_Env/Tools/whois_history.py $argv
        end

        function urldecode
            python3 -c "import sys; from urllib.parse import unquote; print(unquote(sys.stdin.read()));"
        end        

        function config
            /Applications/Sublime\ Text.app/Contents/MacOS/sublime_text ~/.config/fish/config.fish
        end        

        function urldecode_stream
            python3 -c "import sys, urllib.parse as u1; [sys.stdout.write(u1.unquote_plus(l)) for l in sys.stdin]"
        end        

        function getemail
            grep -E '([[:alnum:]_.-]{1,64}@([[:alnum:]_.-]{2,255})\.[[:alpha:].]{2,4})'
        end        

        function geturl
            grep -Eo 'https?://[a-zA-Z0-9./?=_%:-]*\"' | sed -e 's/\"//g'
        end        

        function ds-delete
            find ./* -name '.DS_Store' -type f -delete
        end        

        function hangul_change
            convmv -f utf8 -t utf8 --nfc --notest ./*
        end        

        function pcat
            if test (count $argv) -eq 0
                man pygmentize
                return
            end        

            set remove_comments 0
            set options "style=monokai,tabsize=4"
            set files        

            for arg in $argv
                switch $arg
                    case "-n"
                        set options "style=monokai,linenos=1,tabsize=4"
                    case "-c"
                        set remove_comments 1
                    case "*"
                        set files $files $arg
                end
            end        

            if test $remove_comments -eq 1
                pygmentize -f terminal256 -O $options -g $files | egrep -v '^\s*#|^\s*//|^\s*<!--|^\s*-->' | egrep -v '\s*/\*|\*/|\s*#'
            else
                pygmentize -f terminal256 -O $options -g $files
            end
        end

# Add more aliases and functions as per the provided configuration

EOF

echo "Environment setup complete. Please restart your terminal or source the fish config file."

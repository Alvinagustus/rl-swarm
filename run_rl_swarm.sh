#!/bin/bash

set -euo pipefail

# General arguments
ROOT=$PWD

RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
PORT=3000

export PUB_MULTI_ADDRS
export PEER_MULTI_ADDRS
export HOST_MULTI_ADDRS
export IDENTITY_PATH
export CONNECT_TO_TESTNET
export ORG_ID
export HF_HUB_DOWNLOAD_TIMEOUT=120  # 2 minutes

# Check if public multi-address is given else set to default
DEFAULT_PUB_MULTI_ADDRS=""
PUB_MULTI_ADDRS=${PUB_MULTI_ADDRS:-$DEFAULT_PUB_MULTI_ADDRS}

# Check if peer multi-address is given else set to default
DEFAULT_PEER_MULTI_ADDRS="/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ" # gensyn coordinator node
PEER_MULTI_ADDRS=${PEER_MULTI_ADDRS:-$DEFAULT_PEER_MULTI_ADDRS}

# Check if host multi-address is given else set to default
DEFAULT_HOST_MULTI_ADDRS="/ip4/0.0.0.0/tcp/38331"
HOST_MULTI_ADDRS=${HOST_MULTI_ADDRS:-$DEFAULT_HOST_MULTI_ADDRS}

# Path to an RSA private key. If this path does not exist, a new key pair will be created.
# Remove this file if you want a new PeerID.
DEFAULT_IDENTITY_PATH="$ROOT"/swarm.pem
IDENTITY_PATH=${IDENTITY_PATH:-$DEFAULT_IDENTITY_PATH}

SMALL_SWARM_CONTRACT="0x69C6e1D608ec64885E7b185d39b04B491a71768C"
BIG_SWARM_CONTRACT="0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58"

# Will ignore any visible GPUs if set.
CPU_ONLY=${CPU_ONLY:-""}

# Set if successfully parsed from modal-login/temp-data/userData.json.
ORG_ID=${ORG_ID:-""}

GREEN_TEXT="\033[32m"
BLUE_TEXT="\033[34m"
RED_TEXT="\033[31m"
RESET_TEXT="\033[0m"

echo_green() {
    echo -e "$GREEN_TEXT$1$RESET_TEXT"
}

echo_blue() {
    echo -e "$BLUE_TEXT$1$RESET_TEXT"
}

echo_red() {
    echo -e "$RED_TEXT$1$RESET_TEXT"
}

ROOT_DIR="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"


# Function to clean up the server process upon exit
cleanup() {
    echo_green ">> Shutting down trainer..."

    # Remove modal credentials if they exist
    rm -r $ROOT_DIR/modal-login/temp-data/*.json 2> /dev/null || true

    # Kill all processes belonging to this script's process group
    kill -- -$$ || true

    exit 0
}

errnotify() {
    echo_red ">> An error was detected while running rl-swarm. See $ROOT/logs for full logs."
}

trap cleanup EXIT
trap errnotify ERR

echo -e "\033[38;5;224m"
cat << "EOF"

***********+++++*%      .##*.    -*-#       ##    *-#   .%#:       -%*%       %+=-=#%%%******+++++++
+++++++++++++++++%   :++*@*   -.  =*#   :**#%%    =%=    @#-   ==.  :%%   :%@@@#+++*%@%+====++++++++
+++++++++++++++=+%   =#+=*=   ##++##%   -*:::#    :@.    @%-   %*+   %@   :@%%%%%+==*@#=====++++++++
++++++++++++==+++%    .:#*%.   -%-.-%      %=#     +     @%-   +=.  :%%      #@%%%+=+*#=====++++++++
+====+========---%      #+-*+    -#-%     .%=#  -.   .:  %%-       -%*%    .:#@%%@%+*%#=============
+=--::..........:%   -#+++**#@+   :%%   -#---#  ==   ==  @%-   %##**++%.  :@#*#%%%%%*#+=============
=-:::---=========%   =#==*+  :@:  .@@   -#+++#  +#   *+  %@-   %++++++%.  :@%%%%%@@@%#+=============
==----===----==-=%.     .%%.      -@%       ##  +@.  %+  %@-   %====++%.      #%%@%%@#==============
----------------=@=======#-#*-::-%%%@+++++++@@**%@#*#@%**@@#***@====++@%######@%%%%%@+==============
--------------------------==+******#####*+=----=++*############**+++++***######%%%%%%+=-============
----------------------::=*#*+*%%%%%###***=::::-=+**#################*+**#**###%%%%%@*--==-==========
---------------------....::=-=#####*##*=:...:-==++*##**##*******##**##*****####%%%%%=----===========
--------------------:.....:--=========-.....:==+++***##*****+++++***##****#####%%%%*=====+++++++++++
-::-:--------------:............:::::......:-===+++*##*++=#%%###**********#####%%%#+==++++++++++****
==----------------:.......................:--===========--#%%%%%%####******#*##%%%#*######%%%%%%@@%%
---==-===========-........................::--===========+**##*#%%####****##*##########%%%%%%%%%%%%%
=======-=++++++++-........................::-=====--------==+*****+++******############%%%%%%%%%%%%%
*###*##########*-......:::::::.:=+=-::----------==-::::::::::-----==+******############%%%%%%%%%%%%%
**############+.....:::::::::::+#%%*+====++===--==-::::::::::::---==+*****########%%%%%%%%@@@@%@@@@@
############*:  .:.::::---:....=**#******#%%%#++==-:::::::::-----==++******+++*%##%%%%%%%%%@@@@@@@@@
###########==**=+-::----:......:::--+****######*+=--:::::::----===++**********#%##%%%%%%@%@@@%%%%%@@
#########*-*#####=:::::........:::---======+***+=------::-----===+******###**+*###%%%%%%@@@@@@@@@@@@
########-=#######+:::..::::--======++============-----------==+++*****##*+*#+++**#%%%%%%@@@@@@@@@@@@
#######-+########+:::::=+*+-:::::..:----=++++=====---=======++***********++**++*#%%%%%%%%%@@@@@@@@@@
######-*#########*-:-=***==+*****++====++==+**+=========++++******###***##=..=*#%%%%%%%%%@@@@@@@@@@@
#####=+###########---++*##*****************+=+**+===++++++*****#**####**#*:-+**%%%%%%%@%%%@@@@@@@@@@
####*-############=--=-:::.....:=+***#######**+****++++********#######*+-::++*#%%%%%%%%%%%%@@@@@@@@@
%%%%*=####%%######+-==-:::::::::..::::::-=+*#######*****************##+-:..+*#%%%%%%%%%%%%%@@@@@@@@@
%%%%+=####%%%%####*=--------------------==++++***************#**#####*-*#*#%%%%%%%%%%%%%%%%%@@@@@@@@
%@@@*=%%%%%%%%%%###+------===++====-===++++++=+++*********########%###=-####%%%%%%%%%%%%%%%@@@@@@@@@
@@@@#=%%@@@%%%@%%%%%=----=++**********++++++++********############%%%%%+:#%%%%%%%%%%%%%@@@@@@@@@@@@@
@@@%#=#%@@@@%%%%%%%%+----==+******##***************##############%%%@%%%==%%@@@@%@@@%@@@@@@@@@@@@@@@
@@%##++@@@%%%%%%%%%%#--------=+***********#******###############%@@@@@@%#-%%%@@@@@@@@@@@@@@@@@@@@@@@
@%#***=*@@######%%%*=-------------=====+++***###########%%%#####%%@@@%%%#-#%%%@@@%%%%%@%@@@@@@@@@@@@
%****##=%%#######*++%*==================+*****##########%#####@@@@#*#%%%*=#%%%@@%%%%%%%%%%%%%%%%@@@@
#***#%@#+#*******#@@@*********+++++++=+****#####%%%%%%#######%@@@@@@#+#*-*%%%@@%%%%%%%%%%%%%%%%%%%%@
***#%@@@++******#%@@@+*####################%%%%%%%%#########%@@@@@@@@#--*%%%%@%%%%####%%%%%%%%%%%%%@
*#*%@@@@#=+***##@@@@%==*#%%%%%@@%%%%%%%%@@@@@%%%%#####***##%%@@@@@@@%=-=#%%%@%%#########%%%%%%%%##%@
#*%@@@@###*+*#%@@@@%*--=+**%%%%%%%%%%%%%%@@@%%%%###*****###%%@@@@@%=+%#-*%%%@%%#######%%%######***#@
##%@@@%#*##%%#%@%#%%*---=++#%%%%%%%%%%%%%%%%#######****####%@@@@*=#@@@@%%%%%@%#####**##%%#######**%@
#%@@@####%@@@@@#%@@@*=-===++*######%%%%%%########*****####%%@%+-#@@@@@@#*#%@%*+++++**#############@@
#######%@@@@@%*%@@@%======+****###############**#**#*##%%%%%*=%@@@@@@@@@%%%@@%%######%%#***#**++*#@%
#####%%@@@@@#+%@@@%*+====++************#####*#**********+=%%%%%@@@@@@@@%%%@@@@%%####%%%##########%@@
#####@@@@@@*:=@@@#+++====++++***********##*#####*-:..:*@@@@@@@@@@@@%%%%%%%@@@@%%%%#%@%######%%%%%%@@
####%@@@@@+..#%*++++=====++++++++++*********+-....-#@@@@@@@@@@@@@%+----=*%@@%%%%%%%%@%######%%%%%%@@
####%@@@@+..+*==============+=====+*****+-....:+%@@@@@@@@@@@@@@@%+---::::-**########%%######%%%%%@@@
#%%%%%@@*-:+#+++++=+*******###*===+=-:.:=####@@@@@@@@@@@@@@@@@@@@@@%%%#.:-%%%@%#@%%%@##%@#*++#@@%@@@
@+ .+@@*. :@@-...**#...:@%. ..%+-.....#-.     -@@@=       .%@@@@@.   .*=:=*   #@#   %#@-       :@@@%
@+   *@+  :@@-   **#   .%%    %:  ..-@:   ==   .@@=   ++   .@@@@#     =@+=#   .%#   %%#   :@+   +@#%
@+    %*  :@@-   **#   .%%    #:.-*#%@.   @@.   %@=   %@*   %@@@=     .@%%#    :*   #@=   -@#...=@##
*+    .=  :@@-   **%   .##.   %##%%%#@.   @@.   %@=   -=.  =@@@@:  -.  #@@#         #%=   =@@@@@@#-:
#+        .@@-   **%          %%###+-@.   @@.   #@=        *@@@%   #:  -@@%         #%=   =*    -#--
**   .    .@%-   **%.   *#    ##**+-*@.   @@.   #@+   #@+   +@@*   %-  .@@%   +.    #%=   =@%   -%==
**   #.   .@%=   +#%.   @@.   #@#*:*%@.   @@:   #@+   #@#   -@@-        #@%   *#    *%+   -@@.  -@##
**   %%   .@%=   +@@.   @@.   #@%-=%@@:   *%.   %@+   #@#   -@@   -@@.  :@%   *@=   **%    :.   -@##

 ██████╗ ███████╗███╗   ██╗███████╗██╗   ██╗███╗   ██╗                
██╔════╝ ██╔════╝████╗  ██║██╔════╝╚██╗ ██╔╝████╗  ██║                
██║  ███╗█████╗  ██╔██╗ ██║███████╗ ╚████╔╝ ██╔██╗ ██║                
██║   ██║██╔══╝  ██║╚██╗██║╚════██║  ╚██╔╝  ██║╚██╗██║                
╚██████╔╝███████╗██║ ╚████║███████║   ██║   ██║ ╚████║                
 ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝                
                                                                      
██████╗ ██╗      ███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗        
██╔══██╗██║      ██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║        
██████╔╝██║█████╗███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║        
██╔══██╗██║╚════╝╚════██║██║███╗██║██╔══██║██╔══██╗██║╚██╔╝██║        
██║  ██║███████╗ ███████║╚███╔███╔╝██║  ██║██║  ██║██║ ╚═╝ ██║        
╚═╝  ╚═╝╚══════╝ ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝        
                                                                      
██████╗ ██╗   ██╗                                                     
██╔══██╗╚██╗ ██╔╝                                                     
██████╔╝ ╚████╔╝                                                      
██╔══██╗  ╚██╔╝                                                       
██████╔╝   ██║                                                        
╚═════╝    ╚═╝                                                        
                                                                      
 █████╗ ███╗   ███╗██████╗  █████╗ ███╗   ██╗ ██████╗ ██████╗ ███████╗
██╔══██╗████╗ ████║██╔══██╗██╔══██╗████╗  ██║██╔═══██╗██╔══██╗██╔════╝
███████║██╔████╔██║██████╔╝███████║██╔██╗ ██║██║   ██║██║  ██║█████╗  
██╔══██║██║╚██╔╝██║██╔══██╗██╔══██║██║╚██╗██║██║   ██║██║  ██║██╔══╝  
██║  ██║██║ ╚═╝ ██║██████╔╝██║  ██║██║ ╚████║╚██████╔╝██████╔╝███████╗
╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝

EOF

while true; do
    echo -en $GREEN_TEXT
    read -p ">> Would you like to connect to the Testnet? [Y/n] " yn
    echo -en $RESET_TEXT
    yn=${yn:-Y}  # Default to "Y" if the user presses Enter
    case $yn in
        [Yy]*)  CONNECT_TO_TESTNET=true && break ;;
        [Nn]*)  CONNECT_TO_TESTNET=false && break ;;
        *)  echo ">>> Please answer yes or no." ;;
    esac
done

while true; do
    echo -en $GREEN_TEXT
    read -p ">> Which swarm would you like to join (Math (A) or Math Hard (B))? [A/b] " ab
    echo -en $RESET_TEXT
    ab=${ab:-A}  # Default to "A" if the user presses Enter
    case $ab in
        [Aa]*)  USE_BIG_SWARM=false && break ;;
        [Bb]*)  USE_BIG_SWARM=true && break ;;
        *)  echo ">>> Please answer A or B." ;;
    esac
done
if [ "$USE_BIG_SWARM" = true ]; then
    SWARM_CONTRACT="$BIG_SWARM_CONTRACT"
else
    SWARM_CONTRACT="$SMALL_SWARM_CONTRACT"
fi
while true; do
    echo -en $GREEN_TEXT
    read -p ">> How many parameters (in billions)? [0.5, 1.5, 7, 32, 72] " pc
    echo -en $RESET_TEXT
    pc=${pc:-0.5}  # Default to "0.5" if the user presses Enter
    case $pc in
        0.5 | 1.5 | 7 | 32 | 72) PARAM_B=$pc && break ;;
        *)  echo ">>> Please answer in [0.5, 1.5, 7, 32, 72]." ;;
    esac
done

# Create logs directory if it doesn't exist
mkdir -p "$ROOT/logs"

if [ "$CONNECT_TO_TESTNET" = true ]; then
    # Run modal_login server.
    echo "Please login to create an Ethereum Server Wallet"
    cd modal-login
    # Check if the yarn command exists; if not, install Yarn.

    # Node.js + NVM setup
    if ! command -v node > /dev/null 2>&1; then
        echo "Node.js not found. Installing NVM and latest Node.js..."
        export NVM_DIR="$HOME/.nvm"
        if [ ! -d "$NVM_DIR" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        fi
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        nvm install node
    else
        echo "Node.js is already installed: $(node -v)"
    fi

    if ! command -v yarn > /dev/null 2>&1; then
        # Detect Ubuntu (including WSL Ubuntu) and install Yarn accordingly
        if grep -qi "ubuntu" /etc/os-release 2> /dev/null || uname -r | grep -qi "microsoft"; then
            echo "Detected Ubuntu or WSL Ubuntu. Installing Yarn via apt..."
            curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
            echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
            sudo apt update && sudo apt install -y yarn
        else
            echo "Yarn not found. Installing Yarn globally with npm (no profile edits)…"
            # This lands in $NVM_DIR/versions/node/<ver>/bin which is already on PATH
            npm install -g --silent yarn
        fi
    fi

    ENV_FILE="$ROOT"/modal-login/.env
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS version
        sed -i '' "3s/.*/SMART_CONTRACT_ADDRESS=$SWARM_CONTRACT/" "$ENV_FILE"
    else
        # Linux version
        sed -i "3s/.*/SMART_CONTRACT_ADDRESS=$SWARM_CONTRACT/" "$ENV_FILE"
    fi

    yarn install --immutable
    echo "Building server"
    yarn build > "$ROOT/logs/yarn.log" 2>&1
    yarn start >> "$ROOT/logs/yarn.log" 2>&1 & # Run in background and log output

    SERVER_PID=$!  # Store the process ID
    echo "Started server process: $SERVER_PID"
    sleep 5

    # Login
    echo -e "\n${CYAN}${BOLD}[✓] Detecting system architecture...${NC}"
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    if [ "$ARCH" = "x86_64" ]; then
        NGROK_ARCH="amd64"
        CF_ARCH="amd64"
        echo -e "${GREEN}${BOLD}[✓] Detected x86_64 architecture.${NC}"
    elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        NGROK_ARCH="arm64"
        CF_ARCH="arm64"
        echo -e "${GREEN}${BOLD}[✓] Detected ARM64 architecture.${NC}"
    elif [[ "$ARCH" == arm* ]]; then
        NGROK_ARCH="arm"
        CF_ARCH="arm"
        echo -e "${GREEN}${BOLD}[✓] Detected ARM architecture.${NC}"
    else
        echo -e "${RED}[✗] Unsupported architecture: $ARCH. Please use a supported system.${NC}"
        exit 1
    fi

check_url() {
        local url=$1
        local max_retries=3
        local retry=0
        
        while [ $retry -lt $max_retries ]; do
            http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
            if [ "$http_code" = "200" ] || [ "$http_code" = "404" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
                return 0
            fi
            retry=$((retry + 1))
            sleep 2
        done
        return 1
    }

    install_localtunnel() {
        if command -v lt >/dev/null 2>&1; then
            echo -e "${GREEN}${BOLD}[✓] Localtunnel is already installed.${NC}"
            return 0
        fi
        echo -e "\n${CYAN}${BOLD}[✓] Installing localtunnel...${NC}"
        npm install -g localtunnel > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${BOLD}[✓] Localtunnel installed successfully.${NC}"
            return 0
        else
            echo -e "${RED}${BOLD}[✗] Failed to install localtunnel.${NC}"
            return 1
        fi
    }

    install_cloudflared() {
        if command -v cloudflared >/dev/null 2>&1; then
            echo -e "${GREEN}${BOLD}[✓] Cloudflared is already installed.${NC}"
            return 0
        fi
        echo -e "\n${YELLOW}${BOLD}[✓] Installing cloudflared...${NC}"
        CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$CF_ARCH"
        wget -q --show-progress "$CF_URL" -O cloudflared
        if [ $? -ne 0 ]; then
            echo -e "${RED}${BOLD}[✗] Failed to download cloudflared.${NC}"
            return 1
        fi
        chmod +x cloudflared
        sudo mv cloudflared /usr/local/bin/
        if [ $? -ne 0 ]; then
            echo -e "${RED}${BOLD}[✗] Failed to move cloudflared to /usr/local/bin/.${NC}"
            return 1
        fi
        echo -e "${GREEN}${BOLD}[✓] Cloudflared installed successfully.${NC}"
        return 0
    }

    install_ngrok() {
        if command -v ngrok >/dev/null 2>&1; then
            echo -e "${GREEN}${BOLD}[✓] ngrok is already installed.${NC}"
            return 0
        fi
        echo -e "${YELLOW}${BOLD}[✓] Installing ngrok...${NC}"
        NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-$OS-$NGROK_ARCH.tgz"
        wget -q --show-progress "$NGROK_URL" -O ngrok.tgz
        if [ $? -ne 0 ]; then
            echo -e "${RED}${BOLD}[✗] Failed to download ngrok.${NC}"
            return 1
        fi
        tar -xzf ngrok.tgz
        if [ $? -ne 0 ]; then
            echo -e "${RED}${BOLD}[✗] Failed to extract ngrok.${NC}"
            rm ngrok.tgz
            return 1
        fi
        sudo mv ngrok /usr/local/bin/
        if [ $? -ne 0 ]; then
            echo -e "${RED}${BOLD}[✗] Failed to move ngrok to /usr/local/bin/.${NC}"
            rm ngrok.tgz
            return 1
        fi
        rm ngrok.tgz
        echo -e "${GREEN}${BOLD}[✓] ngrok installed successfully.${NC}"
        return 0
    }


    get_ngrok_url_method1() {
        local url=$(grep -o '"url":"https://[^"]*' ngrok_output.log 2>/dev/null | head -n1 | cut -d'"' -f4)
        echo "$url"
    }

    get_ngrok_url_method2() {
        local try_port
        local url=""
        for try_port in $(seq 4040 4045); do
            local response=$(curl -s "http://localhost:$try_port/api/tunnels" 2>/dev/null)
            if [ -n "$response" ]; then
                url=$(echo "$response" | grep -o '"public_url":"https://[^"]*' | head -n1 | cut -d'"' -f4)
                if [ -n "$url" ]; then
                    break
                fi
            fi
        done
        echo "$url"
    }

    get_ngrok_url_method3() {
        local url=$(grep -o "Forwarding.*https://[^ ]*" ngrok_output.log 2>/dev/null | grep -o "https://[^ ]*" | head -n1)
        echo "$url"
    }

    try_ngrok() {
        echo -e "\n${CYAN}${BOLD}[✓] Trying ngrok...${NC}"
        if install_ngrok; then
            TUNNEL_TYPE="ngrok"
            while true; do
                echo -e "\n${YELLOW}${BOLD}To get your authtoken:${NC}"
                echo "1. Sign up or log in at https://dashboard.ngrok.com"
                echo "2. Go to 'Your Authtoken' section: https://dashboard.ngrok.com/get-started/your-authtoken"
                echo "3. Click on the eye icon to reveal your ngrok auth token"
                echo "4. Copy that auth token and paste it in the prompt below"
                echo -e "\n${BOLD}Please enter your ngrok authtoken:${NC}"
                read -p "> " NGROK_TOKEN
            
                if [ -z "$NGROK_TOKEN" ]; then
                    echo -e "${RED}${BOLD}[✗] No token provided. Please enter a valid token.${NC}"
                    continue
                fi
                pkill -f ngrok || true
                sleep 2
            
                ngrok authtoken "$NGROK_TOKEN" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}${BOLD}[✓] Successfully authenticated ngrok!${NC}"
                    break
                else
                    echo -e "${RED}[✗] Authentication failed. Please check your token and try again.${NC}"
                fi
            done

            echo -e "\n${CYAN}${BOLD}[✓] Starting ngrok with method 1...${NC}"
            ngrok http "$PORT" --log=stdout --log-format=json > ngrok_output.log 2>&1 &
            TUNNEL_PID=$!
            sleep 5
            
            NGROK_URL=$(get_ngrok_url_method1)
            if [ -n "$NGROK_URL" ]; then
                FORWARDING_URL="$NGROK_URL"
                return 0
            else
                echo -e "${RED}${BOLD}[✗] Failed to get ngrok URL (method 1).${NC}"
                kill $TUNNEL_PID 2>/dev/null || true
            fi

            echo -e "\n${CYAN}${BOLD}[✓] Starting ngrok with method 2...${NC}"
            ngrok http "$PORT" > ngrok_output.log 2>&1 &
            TUNNEL_PID=$!
            sleep 5
            
            NGROK_URL=$(get_ngrok_url_method2)
            if [ -n "$NGROK_URL" ]; then
                FORWARDING_URL="$NGROK_URL"
                return 0
            else
                echo -e "${RED}${BOLD}[✗] Failed to get ngrok URL (method 2).${NC}"
                kill $TUNNEL_PID 2>/dev/null || true
            fi

            echo -e "\n${CYAN}${BOLD}[✓] Starting ngrok with method 3...${NC}"
            ngrok http "$PORT" --log=stdout > ngrok_output.log 2>&1 &
            TUNNEL_PID=$!
            sleep 5
            
            NGROK_URL=$(get_ngrok_url_method3)
            if [ -n "$NGROK_URL" ]; then
                FORWARDING_URL="$NGROK_URL"
                return 0
            else
                echo -e "${RED}${BOLD}[✗] Failed to get ngrok URL (method 3).${NC}"
                kill $TUNNEL_PID 2>/dev/null || true
            fi
        fi
        return 1
    }

    start_tunnel() {
        if try_localtunnel; then
            return 0
        fi
        
        if try_cloudflared; then
            return 0
        fi
        
        if try_ngrok; then
            return 0
        fi
        return 1
    }

    start_tunnel
    if [ $? -eq 0 ]; then
        if [ "$TUNNEL_TYPE" != "localtunnel" ]; then
            echo -e "${GREEN}${BOLD}[✓] Success! Please visit this website and log in using your email:${NC} ${CYAN}${BOLD}${FORWARDING_URL}${NC}"
        fi
    else
        echo -e "\n${BLUE}${BOLD}[✓] Don't worry, you can use this manual method. Please follow these instructions:${NC}"
        echo "1. Open this same WSL/VPS or GPU server on another tab"
        echo "2. Paste this command into this terminal: ngrok http 3000"
        echo "3. It will show a link similar to this: https://xxxx.ngrok-free.app"
        echo "4. Visit this website and login using your email, this website may take 30 sec to load."
        echo "5. Now go back to the previous tab, you will see everything will run fine"
    fi

    cd ..


    echo_green ">> Waiting for modal userData.json to be created..."
    while [ ! -f "modal-login/temp-data/userData.json" ]; do
        sleep 5  # Wait for 5 seconds before checking again
    done
    echo "Found userData.json. Proceeding..."

    ORG_ID=$(awk 'BEGIN { FS = "\"" } !/^[ \t]*[{}]/ { print $(NF - 1); exit }' modal-login/temp-data/userData.json)
    echo "Your ORG_ID is set to: $ORG_ID"

    # Wait until the API key is activated by the client
    echo "Waiting for API key to become activated..."
    while true; do
        STATUS=$(curl -s "http://localhost:3000/api/get-api-key-status?orgId=$ORG_ID")
        if [[ "$STATUS" == "activated" ]]; then
            echo "API key is activated! Proceeding..."
            break
        else
            echo "Waiting for API key to be activated..."
            sleep 5
        fi
    done
fi

echo_green ">> Getting requirements..."

pip install --upgrade pip
if [ -n "$CPU_ONLY" ] || ! command -v nvidia-smi &> /dev/null; then
    # CPU-only mode or no NVIDIA GPU found
    pip install -r "$ROOT"/requirements-cpu.txt
    CONFIG_PATH="$ROOT/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml" # TODO: Fix naming.
    GAME="gsm8k"
else
    # NVIDIA GPU found
    pip install -r "$ROOT"/requirements-gpu.txt
    pip install flash-attn --no-build-isolation

    case "$PARAM_B" in
        32 | 72) CONFIG_PATH="$ROOT/hivemind_exp/configs/gpu/grpo-qwen-2.5-${PARAM_B}b-bnb-4bit-deepseek-r1.yaml" ;;
        0.5 | 1.5 | 7) CONFIG_PATH="$ROOT/hivemind_exp/configs/gpu/grpo-qwen-2.5-${PARAM_B}b-deepseek-r1.yaml" ;;
        *) exit 1 ;;
    esac

    if [ "$USE_BIG_SWARM" = true ]; then
        GAME="dapo"
    else
        GAME="gsm8k"
    fi
fi

echo_green ">> Done!"

HF_TOKEN=${HF_TOKEN:-""}
if [ -n "${HF_TOKEN}" ]; then # Check if HF_TOKEN is already set and use if so. Else give user a prompt to choose.
    HUGGINGFACE_ACCESS_TOKEN=${HF_TOKEN}
else
    echo -en $GREEN_TEXT
    read -p ">> Would you like to push models you train in the RL swarm to the Hugging Face Hub? [y/N] " yn
    echo -en $RESET_TEXT
    yn=${yn:-N} # Default to "N" if the user presses Enter
    case $yn in
        [Yy]*) read -p "Enter your Hugging Face access token: " HUGGINGFACE_ACCESS_TOKEN ;;
        [Nn]*) HUGGINGFACE_ACCESS_TOKEN="None" ;;
        *) echo ">>> No answer was given, so NO models will be pushed to Hugging Face Hub" && HUGGINGFACE_ACCESS_TOKEN="None" ;;
    esac
fi

echo_green ">> Good luck in the swarm!"
echo_blue ">> Post about rl-swarm on X/twitter! --> https://tinyurl.com/swarmtweet"
echo_blue ">> And remember to star the repo on GitHub! --> https://github.com/gensyn-ai/rl-swarm"

if [ -n "$ORG_ID" ]; then
    python -m hivemind_exp.gsm8k.train_single_gpu \
        --hf_token "$HUGGINGFACE_ACCESS_TOKEN" \
        --identity_path "$IDENTITY_PATH" \
        --modal_org_id "$ORG_ID" \
        --contract_address "$SWARM_CONTRACT" \
        --config "$CONFIG_PATH" \
        --game "$GAME"
else
    python -m hivemind_exp.gsm8k.train_single_gpu \
        --hf_token "$HUGGINGFACE_ACCESS_TOKEN" \
        --identity_path "$IDENTITY_PATH" \
        --public_maddr "$PUB_MULTI_ADDRS" \
        --initial_peers "$PEER_MULTI_ADDRS" \
        --host_maddr "$HOST_MULTI_ADDRS" \
        --config "$CONFIG_PATH" \
        --game "$GAME"
fi

wait  # Keep script running until Ctrl+C

#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# General arguments
ROOT=$PWD

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
RESET_TEXT="\033[0m"

echo_green() {
    echo -e "$GREEN_TEXT$1$RESET_TEXT"
}

echo_blue() {
    echo -e "$BLUE_TEXT$1$RESET_TEXT"
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

trap cleanup EXIT

echo -e "\033[38;5;224m"
cat << "EOF"

=========================+====+%@@@@@@%%%%%%%%%##%%%%#####*###*=+#%%%%%%######%%%%%%%%%#+===========
=====---=============+##%%%###%@@@@@@%%%%%####%%%%%#####%%%#**+++++###%%################*+==========
=======--==========+#@@@@@@@@@@@@@@@%%%%%%####%@%*+++*#***+++**#**+=+****+++++=-=======+++==========
---------=========+#@@@@@@@@@@@@@@@@%%%%%######****+++*+=-:=*#*+++**++***+=+=+=:-==-----=========+##
---------=========*%@@@@@@@@@@@@@@@%%%%%#####***###+*#**##*+--==-=++**++++===++=+++=--=+=-====+*###*
----------==----===*%@@@@@@@@@@@@@@%%%%###%%#*##%%####**###%*=:=*+==+++=---=+=-+*+**=-=+=-=+**#%%#++
----------==++++==+#%@@@@@@@@@@@@@%%%%%%%%%%%#####******+=+###+=*+----++-::==: .-===-=++=--+%@@%%%%%
----------=+*#####%%@%@@@@@@@@@@@@@@@@%######%**#######**####***+=---++=::=+**=----::-+*+--+%@%%@@@@
------------=+#%%%%@@@@@@@@@@@@@@@@%%@@%%%%%@@%%%%###########+=*#*+====--++++**==+=:::-++=-+#%%%%%%%
-----------=*%%##%@%%%%@@@@@@@@@@@@@@@@@@@@@@@%%######**+===++++****+=--=+=---=++*+=====----=*%%%%%%
----------=#%#+=+%%#*%@@@@@@@@@@@@@@@@@@@@%%%%####%%%%%##*++===-----===*#**+====--=+*+=-:--=+*#%%%%%
----------=++=-=+%%##@@@@@@@@@@@@@@@@@@@%%%%%%%%%%##%%%%%%%##*+==-:::::-=+*###*+=-==+**-==-=+*#%%%%%
----------------+%@%%@@@@@@@@@@@@@@@%%%%%%%%%%%%#########%%%%###*+=--::::::--=+===++--=+*+--=*%@%%%%
----------------=+#%%%%%@@@@@@@@@@@%%%%%%%%%%%%%###**++==+*#####**+==--::::::::-==+*+*+=+++++#@%%%%%
------------------=+++#%@@@@@@@@@%%%%%%%%##%%@@%%%##*+++==+*#####**++==-------:---==*##*+===*%@%%%%%
------------------==+*%%@@@@@@@%%%%%%%%%#####%%%@@@%%#*###***##%##**+=================+###+=*%@%%%%%
--------------==+++*%%%%%%@@@%%%%%%%%%%##########%#############%%###*+===++**####**+===+#%#*#@@%%%%%
-------------=+#%%%%#+*%%%%%%%%%%%%%%%%##########****+++*###########*******##%%%%%%##**+***+#%@@@@%%
--------------==+++=-=#%%%%%%%%%%%%%%%###****++*****+==--=+**#####*+==**#######****####**##*#%@@@@@@
=========------------+#%%%%%%%%%%%%%%%###**+++===+**++========+***+-:-+**#####*+====++**#%%%@@@@@@@@
+++++++++=-----------+#%#%%%%%%%%%%%%%%##**+++====---------==++**+=-:-=++*##%%##***+++++*%@@@@@@@%#%
+++++++++=-----------=*#%%%@%%%%%%%%%%%%##***++==-:::::::-==++++++-::-===+**###%%%####*+#%@@@@@@%##%
+++++++++=----==-------+*%@@@%%%%%%%%%%%%##***++==--::---=+++++++=-::-==-==+++++*##%%%#*#%%%%@@@@%%%
+++++++++=------::.....::=#%@%%%%%%%%%%%%%##***++===+++++*****+==-:::-==---==++=++++*****+===*#@@#*+
+++++++++=---:.............-*%%%%%%%%%%%%%%##**+++++++***+===+==-:::--===-::-=+++++++++=------=**+=-
+++++++++=--:......    ......+%%%%%%%%%%%%%%##*+++++*##**+=====-::..:-===-::::--==+++*+=-----------=
+++++++++=-:....:=:   .=:.....+%%%%%%%%%%%%##***+++*#%%####*+++==-:::--===-::::::--=+++=-----------*
+++++++++=:::---:.     .:---:.-%%%%%%%%%%%%#********#%%%%%%%%#**+=-------===--:::--=++=-----------+#
+++++++++=:::..-=-     :=-.:..:#@%%%%%%%%##****#########%%%%%%##**++++==-==+==----==++=----------+#*
+++++++++=: :.:#%%.....#%%:.::-%%%%%%%%%##**##################*+*######*+==++======++==---------+#*=
+++++++++:  .::=+-.....=+=::::*@%%%%%%%%#**####%%%###***+++==+++***###*+=--=+++==++++=---------=*#+-
+++++++++-  .-:::-=++==:::::-+%%%@%@%%%%#*####%%%%%####*+++===-===+****+====**++++++=+++=------=+=--
+++++++++=-:-----=+++++=---=#@%%%%%%%%%%######%%%%%##*****++++=====++****++=***+**+==##*+=----------
+++++++++==--------------=#%@%%@%%%%@@%%############*+==----==+++++++++***++***++++++##*+=----------
+++++++++==-------------=*%@%%@@@@@@@@@%%#############*+=--::::-==+*******++***+=-=+###*+=----------
+++++++++==----=--------=*%@@@@@@@@@@@@@%%%%#####%%%%%##*++=---::--=+*###*****++++=*###**+=---------
++++++++===----=---------*%@@@@@@@@@@@@@@%%%%%########%%###**+++==++++*#*****+=+*=-+###***+==-------
++++++++===--------------*%@@@@@@@@@@@@@@%%%%%######**###########****++******##%#==+###*#**+==------
++++++++===--------------*%@@@@@@@@@@@@@@%%%%%######**+++++**####****+++***##%@@%+=*######**+==-----
++++=++++==------------=*%@@@@@@@@@@@@@@@@%%%%%%%%%##**+++=+++++*********###%%%@%+=+######**++=--==+
+++==+++===-------=+++*#%@@@@@@@@@@@@@@@@@@@@@%%%%%%###****++++*******######%%%@%+=*######**+++++***
============----=*#%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%###*******#####*+*##%%%#**########*********
==++++++*******##%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%##***#####*+=+***#**+***######********+
*###%%%%%%%%@@%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%#########+=-+********************++++
#%%%%%%%%%%@@@%%#%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#######*+--=+*****************++++++

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

# 2. Variabel PORT (port aplikasi lokal Anda):
#    Contoh:
PORT=3000
#
# 3. Variabel Arsitektur dan Sistem Operasi (untuk instalasi Cloudflared & ngrok):
#    Anda mungkin perlu mendeteksi ini secara otomatis, contoh:
#    OS=$(uname -s | tr '[:upper:]' '[:lower:]') # e.g., linux, darwin
#    ARCH=$(uname -m)
#
#    Untuk Cloudflared (CF_ARCH):
if [[ "$ARCH" == "x86_64" ]]; then CF_ARCH="amd64";
elif [[ "$ARCH" == "aarch64" ]]; then CF_ARCH="arm64";
else CF_ARCH="$ARCH"; fi # Sesuaikan jika perlu
#
#    Untuk ngrok (NGROK_ARCH):
if [[ "$ARCH" == "x86_64" ]]; then NGROK_ARCH="amd64";
elif [[ "$ARCH" == "aarch64" ]]; then NGROK_ARCH="arm64";
elif [[ "$ARCH" == "i386" ]] || [[ "$ARCH" == "i686" ]]; then NGROK_ARCH="386";
elif [[ "$ARCH" == "armv7l" ]]; then NGROK_ARCH="arm";
else NGROK_ARCH="$ARCH"; fi # Sesuaikan jika perlu
#
# Global variables for tunnel info
TUNNEL_PID=""
FORWARDING_URL=""
TUNNEL_TYPE=""

# --- Fungsi-Fungsi ---

check_url() {
    local url=$1
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 10 2>/dev/null) # Added timeout
        if [ "$http_code" = "200" ] || [ "$http_code" = "404" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            return 0
        fi
        retry=$((retry + 1))
        echo -e "${YELLOW}[i] check_url: Retrying $url (Attempt: $retry/$max_retries, HTTP Code: $http_code)...${NC}"
        sleep 2
    done
    echo -e "${RED}[✗] check_url: Failed to get a valid response from $url after $max_retries attempts.${NC}"
    return 1
}

install_localtunnel() {
    if command -v lt >/dev/null 2>&1; then
        echo -e "${GREEN}${BOLD}[✓] Localtunnel is already installed.${NC}"
        return 0
    fi
    echo -e "\n${CYAN}${BOLD}[i] Installing localtunnel...${NC}"
    if npm install -g localtunnel > /dev/null 2>&1; then
        echo -e "${GREEN}${BOLD}[✓] Localtunnel installed successfully.${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}[✗] Failed to install localtunnel. Make sure Node.js and npm are installed.${NC}"
        return 1
    fi
}

try_localtunnel() {
    echo -e "\n${CYAN}${BOLD}[i] Trying Localtunnel...${NC}"
    if ! command -v npm >/dev/null 2>&1; then
        echo -e "${RED}${BOLD}[✗] npm is not installed. Cannot install Localtunnel.${NC}"
        return 1
    fi
    if install_localtunnel; then
        TUNNEL_TYPE="localtunnel"
        # Kill previous instances if any
        pkill -f "lt --port $PORT" > /dev/null 2>&1 || true 
        sleep 1

        echo -e "${YELLOW}${BOLD}[i] Starting Localtunnel on port $PORT...${NC}"
        # Start localtunnel in background, redirect output to a file
        # Adding --open false as we don't want it to attempt to open a browser by itself
        lt --port "$PORT" --open false > localtunnel_output.log 2>&1 &
        TUNNEL_PID=$!
        
        echo -e "${YELLOW}${BOLD}[i] Waiting for Localtunnel to establish connection (up to 15 seconds)...${NC}"
        # Wait for lt to start and print URL. Increased sleep for reliability.
        for _ in $(seq 1 8); do sleep 1; printf "."; done; echo

        # Try to extract URL from log file
        LT_URL=$(grep -o 'https://[a-zA-Z0-9.-]*\.loca\.lt' localtunnel_output.log | head -n1)

        if [ -n "$LT_URL" ]; then
            echo -e "${GREEN}${BOLD}[i] Localtunnel URL obtained: $LT_URL ${NC}"
            echo -e "${YELLOW}${BOLD}[i] Verifying Localtunnel URL...${NC}"
            if check_url "$LT_URL"; then
                FORWARDING_URL="$LT_URL"
                echo -e "${GREEN}${BOLD}[✓] Localtunnel started successfully! URL:${NC} ${CYAN}${BOLD}$FORWARDING_URL${NC}"
                echo -e "${YELLOW}${BOLD}[!] Note: Some localtunnel instances may show a temporary landing page first.${NC}"
                return 0
            else
                echo -e "${RED}${BOLD}[✗] Localtunnel URL ($LT_URL) is not accessible or check_url failed.${NC}"
                echo -e "${BLUE}${BOLD}[i] Tip: Try opening the URL manually in your browser. It might require interaction.${NC}"
                # Provide URL anyway for manual check, but signal failure for automated next step
                FORWARDING_URL="$LT_URL" # Set it so user can see it if this is the only option that partially worked
                kill $TUNNEL_PID > /dev/null 2>&1 || true
            fi
        else
            echo -e "${RED}${BOLD}[✗] Failed to get Localtunnel URL after startup.${NC}"
            echo -e "${BLUE}${BOLD}[i] Localtunnel output:${NC}"
            cat localtunnel_output.log # Show output for debugging
            kill $TUNNEL_PID > /dev/null 2>&1 || true
        fi
        rm localtunnel_output.log 2>/dev/null
    fi
    return 1
}

install_cloudflared() {
    if command -v cloudflared >/dev/null 2>&1; then
        echo -e "${GREEN}${BOLD}[✓] Cloudflared is already installed.${NC}"
        return 0
    fi
    echo -e "\n${CYAN}${BOLD}[i] Installing Cloudflared...${NC}"
    if [ -z "$CF_ARCH" ]; then
        echo -e "${RED}${BOLD}[✗] CF_ARCH variable is not set. Cannot determine Cloudflared architecture.${NC}"
        return 1
    fi
    CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$CF_ARCH"
    echo -e "${BLUE}${BOLD}[i] Downloading Cloudflared from $CF_URL ${NC}"
    if ! wget -q --show-progress "$CF_URL" -O cloudflared; then
        echo -e "${RED}${BOLD}[✗] Failed to download Cloudflared.${NC}"
        return 1
    fi
    chmod +x cloudflared
    if sudo mv cloudflared /usr/local/bin/; then
        echo -e "${GREEN}${BOLD}[✓] Cloudflared installed successfully.${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}[✗] Failed to move Cloudflared to /usr/local/bin/. Check permissions or if sudo is available.${NC}"
        rm cloudflared 2>/dev/null
        return 1
    fi
}

try_cloudflared() {
    echo -e "\n${CYAN}${BOLD}[i] Trying Cloudflared...${NC}"
    if install_cloudflared; then
        TUNNEL_TYPE="cloudflared"
        pkill -f "cloudflared tunnel --url" > /dev/null 2>&1 || true # Kill previous instances
        sleep 1

        echo -e "${YELLOW}${BOLD}[i] Starting Cloudflared tunnel for http://localhost:$PORT...${NC}"
        # Start cloudflared in background, redirect output to a file.
        cloudflared tunnel --url "http://localhost:$PORT" --no-autoupdate > cloudflared_output.log 2>&1 &
        TUNNEL_PID=$!
        
        echo -e "${YELLOW}${BOLD}[i] Waiting for Cloudflared to establish connection (up to 20 seconds)...${NC}"
         # Wait for cloudflared to start and print URL. Increased sleep for reliability.
        for _ in $(seq 1 10); do sleep 1; printf "."; done; echo

        # Try to extract URL from log file. Cloudflared URLs usually end with .trycloudflare.com
        CF_URL=$(grep -o 'https://[a-zA-Z0-9.-]*\.trycloudflare\.com' cloudflared_output.log | head -n 1)

        if [ -n "$CF_URL" ]; then
            echo -e "${GREEN}${BOLD}[i] Cloudflared URL obtained: $CF_URL ${NC}"
            echo -e "${YELLOW}${BOLD}[i] Verifying Cloudflared URL...${NC}"
            if check_url "$CF_URL"; then
                FORWARDING_URL="$CF_URL"
                echo -e "${GREEN}${BOLD}[✓] Cloudflared tunnel started successfully! URL:${NC} ${CYAN}${BOLD}$FORWARDING_URL${NC}"
                return 0
            else
                echo -e "${RED}${BOLD}[✗] Cloudflared URL ($CF_URL) is not accessible or check_url failed.${NC}"
                kill $TUNNEL_PID > /dev/null 2>&1 || true
            fi
        else
            echo -e "${RED}${BOLD}[✗] Failed to get Cloudflared URL after startup.${NC}"
            echo -e "${BLUE}${BOLD}[i] Cloudflared output:${NC}"
            cat cloudflared_output.log # Show output for debugging
            kill $TUNNEL_PID > /dev/null 2>&1 || true
        fi
        rm cloudflared_output.log 2>/dev/null
    fi
    return 1
}

install_ngrok() {
    if command -v ngrok >/dev/null 2>&1; then
        echo -e "${GREEN}${BOLD}[✓] ngrok is already installed.${NC}"
        return 0
    fi
    echo -e "\n${CYAN}${BOLD}[i] Installing ngrok...${NC}"
    if [ -z "$OS" ] || [ -z "$NGROK_ARCH" ]; then
        echo -e "${RED}${BOLD}[✗] OS or NGROK_ARCH variable is not set. Cannot determine ngrok download URL.${NC}"
        return 1
    fi
    NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-$OS-$NGROK_ARCH.tgz"
    echo -e "${BLUE}${BOLD}[i] Downloading ngrok from $NGROK_URL ${NC}"
    if ! wget -q --show-progress "$NGROK_URL" -O ngrok.tgz; then
        echo -e "${RED}${BOLD}[✗] Failed to download ngrok.${NC}"
        return 1
    fi
    if ! tar -xzf ngrok.tgz; then
        echo -e "${RED}${BOLD}[✗] Failed to extract ngrok.${NC}"
        rm ngrok.tgz 2>/dev/null
        return 1
    fi
    if sudo mv ngrok /usr/local/bin/; then
        echo -e "${GREEN}${BOLD}[✓] ngrok installed successfully.${NC}"
        rm ngrok.tgz 2>/dev/null
        return 0
    else
        echo -e "${RED}${BOLD}[✗] Failed to move ngrok to /usr/local/bin/. Check permissions or if sudo is available.${NC}"
        rm ngrok ngrok.tgz 2>/dev/null
        return 1
    fi
}

get_ngrok_url_method1() {
    # Uses ngrok log with JSON format
    local url=$(grep -o '"url":"https://[^"]*' ngrok_output.log 2>/dev/null | head -n1 | cut -d'"' -f4)
    echo "$url"
}

get_ngrok_url_method2() {
    # Uses ngrok API (alternative if logs don't work or not in JSON)
    local try_port
    local url=""
    # Try default ngrok API ports
    for try_port in $(seq 4040 4045); do 
        local response=$(curl -s "http://localhost:$try_port/api/tunnels" 2>/dev/null)
        if [ -n "$response" ]; then
            # Look for https tunnels first
            url=$(echo "$response" | grep -o '"public_url":"https://[^"]*' | head -n1 | cut -d'"' -f4)
            if [ -n "$url" ]; then break; fi
            # Fallback to http if no https found (though ngrok usually gives https)
            if [ -z "$url" ]; then
                 url=$(echo "$response" | grep -o '"public_url":"http://[^"]*' | head -n1 | cut -d'"' -f4)
                 if [ -n "$url" ]; then break; fi
            fi
        fi
    done
    echo "$url"
}

get_ngrok_url_method3() {
    # Uses plain text log format
    local url=$(grep -o "Forwarding.*https://[^ ]*" ngrok_output.log 2>/dev/null | grep -o "https://[^ ]*" | head -n1)
    echo "$url"
}

try_ngrok() {
    echo -e "\n${CYAN}${BOLD}[i] Trying ngrok...${NC}"
    if install_ngrok; then
        TUNNEL_TYPE="ngrok"
        
        # Check if authtoken is already configured
        if [ -f "$HOME/.config/ngrok/ngrok.yml" ] || [ -f "$HOME/.ngrok2/ngrok.yml" ]; then # Common ngrok config paths
             if grep -q "authtoken:" "$HOME/.config/ngrok/ngrok.yml" 2>/dev/null || grep -q "authtoken:" "$HOME/.ngrok2/ngrok.yml" 2>/dev/null ; then
                echo -e "${GREEN}${BOLD}[✓] ngrok authtoken already configured.${NC}"
             else
                NEEDS_AUTH=true
             fi
        else
            NEEDS_AUTH=true
        fi

        if [ "$NEEDS_AUTH" = true ]; then
            while true; do
                echo -e "\n${YELLOW}${BOLD}To get your ngrok authtoken (optional but recommended for stable URLs & features):${NC}"
                echo "1. Sign up or log in at https://dashboard.ngrok.com"
                echo "2. Go to 'Your Authtoken' section: https://dashboard.ngrok.com/get-started/your-authtoken"
                echo "3. Copy your authtoken and paste it below (or press Enter to skip if you want an anonymous tunnel)."
                read -p "$(echo -e "${BOLD}Enter ngrok authtoken (or press Enter to skip):${NC} ")" NGROK_TOKEN
            
                if [ -z "$NGROK_TOKEN" ]; then
                    echo -e "${YELLOW}[i] Skipping ngrok authtoken. Using anonymous tunnel.${NC}"
                    break 
                fi
            
                # Kill existing ngrok before applying authtoken to avoid conflicts
                pkill -f ngrok > /dev/null 2>&1 || true
                sleep 1
                ngrok authtoken "$NGROK_TOKEN" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}${BOLD}[✓] Successfully authenticated ngrok!${NC}"
                    break
                else
                    echo -e "${RED}[✗] Authentication failed. Please check your token and try again, or press Enter to skip.${NC}"
                fi
            done
        fi

        # Kill existing ngrok before starting a new tunnel
        pkill -f ngrok > /dev/null 2>&1 || true
        sleep 1

        # Method 1: JSON log output (preferred)
        echo -e "\n${CYAN}${BOLD}[i] Starting ngrok (method 1: JSON log)...${NC}"
        ngrok http "$PORT" --log=stdout --log-format=json > ngrok_output.log 2>&1 &
        TUNNEL_PID=$!
        sleep 5 
        NGROK_URL=$(get_ngrok_url_method1)
        if [ -n "$NGROK_URL" ] && check_url "$NGROK_URL"; then
            FORWARDING_URL="$NGROK_URL"
            echo -e "${GREEN}${BOLD}[✓] ngrok (method 1) started! URL:${NC} ${CYAN}${BOLD}$FORWARDING_URL${NC}"
            return 0
        else
            echo -e "${RED}${BOLD}[✗] Failed to get ngrok URL or check failed (method 1).${NC}"
            kill $TUNNEL_PID > /dev/null 2>&1 || true
            pkill -f ngrok > /dev/null 2>&1 || true # Ensure ngrok is killed
            sleep 1
        fi

        # Method 2: API (fallback)
        echo -e "\n${CYAN}${BOLD}[i] Starting ngrok (method 2: API)...${NC}"
        # For API method, ngrok needs to be running without specific stdout log format
        ngrok http "$PORT" --log=ngrok_output.log > /dev/null 2>&1 & # Log to file, not stdout for this
        TUNNEL_PID=$!
        sleep 8 # Give more time for API to be available
        NGROK_URL=$(get_ngrok_url_method2)
        if [ -n "$NGROK_URL" ] && check_url "$NGROK_URL"; then
            FORWARDING_URL="$NGROK_URL"
            echo -e "${GREEN}${BOLD}[✓] ngrok (method 2) started! URL:${NC} ${CYAN}${BOLD}$FORWARDING_URL${NC}"
            return 0
        else
            echo -e "${RED}${BOLD}[✗] Failed to get ngrok URL or check failed (method 2).${NC}"
            kill $TUNNEL_PID > /dev/null 2>&1 || true
            pkill -f ngrok > /dev/null 2>&1 || true
            sleep 1
        fi
        
        # Method 3: Plain text log (another fallback)
        echo -e "\n${CYAN}${BOLD}[i] Starting ngrok (method 3: plain text log)...${NC}"
        ngrok http "$PORT" --log=stdout > ngrok_output.log 2>&1 &
        TUNNEL_PID=$!
        sleep 5
        NGROK_URL=$(get_ngrok_url_method3)
        if [ -n "$NGROK_URL" ] && check_url "$NGROK_URL"; then
            FORWARDING_URL="$NGROK_URL"
            echo -e "${GREEN}${BOLD}[✓] ngrok (method 3) started! URL:${NC} ${CYAN}${BOLD}$FORWARDING_URL${NC}"
            return 0
        else
            echo -e "${RED}${BOLD}[✗] Failed to get ngrok URL or check failed (method 3).${NC}"
            kill $TUNNEL_PID > /dev/null 2>&1 || true
            pkill -f ngrok > /dev/null 2>&1 || true
        fi
        rm ngrok_output.log 2>/dev/null
    fi
    return 1
}

start_tunnel() {
    echo -e "\n${BLUE}${BOLD}=====================================${NC}"
    echo -e "${BLUE}${BOLD}🚀 Starting Tunneling Service... 🚀${NC}"
    echo -e "${BLUE}${BOLD}=====================================${NC}"
    echo -e "${YELLOW}${BOLD}[i] Application Port: $PORT${NC}"


    # Try Localtunnel first
    if try_localtunnel; then
        return 0
    else
        echo -e "${RED}[i] Localtunnel failed. Trying next option...${NC}"
    fi
    
    # Then try Cloudflared
    if try_cloudflared; then
        return 0
    else
        echo -e "${RED}[i] Cloudflared failed. Trying next option...${NC}"
    fi
    
    # Finally, try ngrok
    if try_ngrok; then
        return 0
    else
        echo -e "${RED}[i] ngrok also failed.${NC}"
    fi
    
    echo -e "\n${RED}${BOLD}[✗] All tunneling attempts failed.${NC}"
    return 1
}

# --- Logika Utama ---

# (Pastikan variabel PORT, warna, OS, ARCH sudah di-set di atas atau di awal skrip utama Anda)

# Panggil fungsi untuk memulai tunnel
start_tunnel

# Periksa hasil dari start_tunnel
if [ $? -eq 0 ] && [ -n "$FORWARDING_URL" ]; then
    echo -e "\n${GREEN}${BOLD}==================================================================${NC}"
    echo -e "${GREEN}${BOLD}[✓] ✅ SUCCESS! Your application is accessible via:${NC}"
    echo -e "${CYAN}${BOLD}${FORWARDING_URL}${NC}"
    if [ "$TUNNEL_TYPE" != "localtunnel" ]; then # Localtunnel sudah memberikan pesan spesifik
         echo -e "${GREEN}Please visit this website. If it's a web service, you might need to log in.${NC}"
    fi
    echo -e "${GREEN}${BOLD}==================================================================${NC}"
    # Anda bisa menambahkan perintah untuk membuka URL di browser jika diinginkan, misalnya:
    # if command -v xdg-open > /dev/null; then xdg-open "$FORWARDING_URL"; 
    # elif command -v open > /dev/null; then open "$FORWARDING_URL"; 
    # fi
else
    echo -e "\n${BLUE}${BOLD}==================================================================${NC}"
    echo -e "${BLUE}${BOLD}[⚠️] Manual Setup Required or All Tunnels Failed ⚠️${NC}"
    echo -e "${BLUE}Don't worry, you can try to set up a tunnel manually.${NC}"
    echo -e "${BLUE}For example, using ngrok:${NC}"
    echo "1. Open another terminal tab on this server/WSL."
    echo "2. Ensure ngrok is installed (you can run 'install_ngrok' from this script or install manually)."
    echo "3. Paste this command into the new terminal: ${YELLOW}ngrok http $PORT${NC}"
    echo "4. ngrok will show a forwarding URL similar to: https://xxxx.ngrok-free.app"
    echo "5. Visit that URL in your browser. It may take a few moments to load."
    echo -e "${BLUE}${BOLD}==================================================================${NC}"
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

#!/bin/bash

# Name: OrgHub
# Desc: Organisation Management Hub Deployment Tool
# Auth: github.com/sysvar
#-------------------------------------------------------------------------------------------------------------

# System Variables
NAME=`basename "$0"`
DIR=$(pwd)

# User Variables
#example1=test

# Colours
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
RESET=`tput sgr0`

#--------------------------------------------------------------------------------------------------------------

function banner {
  clear
  cat << "EOF"
      ____               _    _       _ 
     / __ \             | |  | |     | |
    | |  | |_ __ __ _   | |__| |_   _| |__
    | |  | | '__/ _` |  |  __  | | | | '_ \
    | |__| | | | (_| |  | |  | | |_| | |_) |
     \____/|_|  \__, |  |_|  |_|\__,_|_.__/
                 __/ |
                |___/

   -----------------------------------------------------------------------

    Organisation Management Hub Deployment Tool
    Made with Love by github.com/sysvar

   -----------------------------------------------------------------------

EOF
}

function usage {
        echo "    OPERATIONS"
        echo "       -x, --start                   Start Stack"
        echo "       -y, --stop                    Stop Stack"
        echo
        echo "    INSTALL"
        echo "       -a, --all                     Install Everything (Recommended)"
        echo "       -d, --dashy                   Install Only Dashy"
        echo "       -p, --portainer               Install Only Portainer"
        echo "       -u, --uptimekuma              Install Only Uptime Kuma"
        echo "       -i, --pialert                 Install Only Pi Alert"
        echo "       -o, --passbolt                Install Only Passbolt"
        echo "       -b, --bookstack               Install Only Bookstack"
        echo "       -v, --vikunja                 Install Only Vikunja"
        echo "       -n, --nessus                  Install Only Nessus"
        echo "       -c, --cockpit                 Install Only Cockpit"
        echo "       -e, --elk                     Install Only Elastic (ELK)"
        echo "       -h, --help                    Help/Usage Guide"
        echo
        echo "    EXAMPLE USAGE"
        echo "      ${NAME} -a"
        echo
}

#-----------------------------------------------------

function requirements {
  if [ "$EUID" -ne 0 ]; then 
    echo "    ${RED}[-]${RESET} Insufficent Permissions. Run as root." && echo && exit 1
  fi
}

function internet {
  if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then net=1; else echo "    ${RED}[-]${RESET} Internet Check Fail: ICMP" && echo && exit 1; fi
  if ping -q -c 1 -W 1 google.com >/dev/null; then net=1; else echo "    ${RED}[-]${RESET} Internet Check Fail: DNS" && echo && exit 1; fi
  wget -q --tries=1 --timeout=6 --spider http://google.com --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
  if [[ $? -eq 0 ]]; then net=1; else echo "    ${RED}[-]${RESET} Internet Check Fail: HTTP (GET)" && echo && exit 1; fi
}

function software {
  echo "    ${GREEN}[+]${RESET} Pre-Check Working..."
  apt update -qq >/dev/null 2>&1
  pkgs='wget curl git'
  for pkg in $pkgs; do
    status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
    if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
      apt install $pkg -yqq >/dev/null 2>&1
      echo "    ${GREEN}[+]${RESET} Installed Locally: $pkg"
    fi
  done

  pkgs='docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin'
  for pkg in $pkgs; do
    status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
    if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
      echo "    ${GREEN}[+]${RESET} Will Install: $pkg"
      docker_required="yes"
    fi
  done

  if [ "$docker_required" = "yes" ]; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh >/dev/null 2>&1
    rm get-docker.sh >/dev/null 2>&1
    if [[ ! -f "/etc/docker/daemon.json" ]]; then
      cat <<'EOT' >> /etc/docker/daemon.json
{
        "default-address-pools":
        [
                {"base":"100.64.0.0/10","size":24}
        ]
}
EOT
    service docker restart
    fi
  fi
}

function start {
  start=`date +%s`
  echo -e "   ${YELLOW} Starting at $(date) ${RESET}" && echo
}

function end {
  end=`date +%s`
  runtime=$((end-start))
  echo && echo -e "   ${YELLOW} Finished at $(date), Total Duration: $(date -d@$runtime -u +%H:%M:%S) ${RESET}" && echo

  if [ -d "/opt/orgHub" ]; then
    echo "   -----------------------------------------------------------------------"
    echo && echo -e "   ${YELLOW} Installation Information ${RESET}" && echo 
    echo "    Location:  /opt/orgHub"
    echo -e "    Start:     /opt/orgHub/${GREEN}start.sh${RESET}"
    echo -e "    Stop:      /opt/orgHub/${GREEN}stop.sh${RESET}"
    echo && echo && echo -e "   ${YELLOW} Services Information ${RESET}" && echo
    echo "    |---------------------------------|"
    echo -e "    |- ${GREEN}Service${RESET} ------------ ${GREEN}Port${RESET} -----|"
    if [ -d "/opt/orgHub/dashy" ]; then echo -e "    |- Dashy -------------- 80/tcp ---|"; fi
    if [ -d "/etc/cockpit" ]; then echo -e "    |- Cockpit ------------ 1000/tcp -|"; fi
    if [ -d "/opt/orgHub/portainer" ]; then echo -e "    |- Portainer ---------- 1001/tcp -|"; fi
    if [ -d "/opt/orgHub/uptimekuma" ]; then echo -e "    |- Uptime Kuma -------- 1002/tcp -|"; fi
    if [ -d "/opt/orgHub/pialert" ]; then echo -e "    |- Pi Alert ----------- 1003/tcp -|"; fi
    if [ -d "/opt/orgHub/passbolt" ]; then echo -e "    |- Passbolt ----------- 1004/tcp -|"; fi
    if [ -d "/opt/orgHub/bookstack" ]; then echo -e "    |- Bookstack ---------- 1005/tcp -|"; fi
    if [ -d "/opt/orgHub/vikunja" ]; then echo -e "    |- Vikunja ------------ 1006/tcp -|"; fi
    if [ -d "/opt/orgHub/nessus" ]; then echo -e "    |- Nessus ------------- 1007/tcp -|"; fi
    if [ -d "/opt/orgHub/elk" ]; then echo -e "    |- Elastic (ELK) ------ 1008/tcp -|"; fi
    echo "    |---------------------------------|"
    echo && echo "   -----------------------------------------------------------------------" && echo
  fi
}

#-----------------------------------------------------


# Dashy
function dashy {
  SOFTWARE="dashy"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
---
version: "3.8"
services:
  dashy:
    # To build from source, replace 'image: lissy93/dashy' with 'build: .'
    # build: .
    image: lissy93/dashy
    container_name: Dashy
    # Pass in your config file below, by specifying the path on your host machine
    volumes:
      - ./conf.yml:/app/public/conf.yml
    ports:
      - 80:80
    # Set any environmental variables
    environment:
      - NODE_ENV=production
    # Specify your user ID and group ID. You can find this by running `id -u` and `id -g`
    #  - UID=1000
    #  - GID=1000
    # Specify restart policy
    restart: unless-stopped
    # Configure healthchecks
    healthcheck:
      test: ['CMD', 'node', '/app/services/healthcheck']
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    cat <<'EOT' >> $DIRECTORY/creds.txt
manage/manageIT3!
EOT

    cat <<'EOT' >> $DIRECTORY/conf.yml
pageInfo:
  title: OrgHub
  description: Welcome to the hub!
appConfig:
  theme: adventure
  layout: auto
  iconSize: medium
  language: en
  startingView: default
  defaultOpeningMethod: newtab
  statusCheck: false
  statusCheckInterval: 0
  faviconApi: allesedv
  routingMode: history
  enableMultiTasking: false
  widgetsAlwaysUseProxy: false
  webSearch:
    disableWebSearch: false
    searchEngine: duckduckgo
    openingMethod: newtab
    searchBangs: {}
  enableFontAwesome: true
  enableMaterialDesignIcons: false
  hideComponents:
    hideHeading: false
    hideNav: false
    hideSearch: false
    hideSettings: false
    hideFooter: false
  auth:
    enableGuestAccess: true
    users:
      - user: manage
        hash: adb089b97ec68ff2bbdddf07d18acc872274540cd38252b31dd1c5f1c508f9dc
        type: admin
    enableKeycloak: false
  showSplashScreen: false
  preventWriteToDisk: false
  preventLocalSave: false
  disableConfiguration: false
  disableConfigurationForNonAdmin: false
  allowConfigEdit: true
  enableServiceWorker: false
  disableContextMenu: false
  disableUpdateChecks: false
  disableSmartSort: false
  enableErrorReporting: false
sections:
  - name: Quick Links
    icon: fas fa-bolt
    displayData:
      sortBy: default
      rows: 1
      cols: 3
      collapsed: false
      hideForGuests: false
    items:
      - title: Example 1
        description: Short Description
        icon: fas fa-link
        id: 0_1054_example
  - name: Example Section 1
    icon: fas fa-globe
    items:
      - title: Dashy Live
        description: Development a project management links for Dashy
        icon: https://i.ibb.co/qWWpD0v/astro-dab-128.png
        url: https://live.dashy.to/
        target: newtab
        id: 0_1554_dashylive
      - title: GitHub
        description: Source Code, Issues and Pull Requests
        url: https://github.com/lissy93/dashy
        icon: favicon
        id: 1_1554_github
      - title: Docs
        description: Configuring & Usage Documentation
        provider: Dashy.to
        icon: far fa-book
        url: https://dashy.to/docs
        id: 2_1554_docs
      - title: Showcase
        description: See how others are using Dashy
        url: https://github.com/Lissy93/dashy/blob/master/docs/showcase.md
        icon: far fa-grin-hearts
        id: 3_1554_showcase
      - title: Config Guide
        description: See full list of configuration options
        url: https://github.com/Lissy93/dashy/blob/master/docs/configuring.md
        icon: fas fa-wrench
        id: 4_1554_configguide
      - title: Support
        description: Get help with Dashy, raise a bug, or get in contact
        url: https://github.com/Lissy93/dashy/blob/master/.github/SUPPORT.md
        icon: far fa-hands-helping
        id: 5_1554_support
    displayData:
      sortBy: default
      rows: 1
      cols: 1
      collapsed: false
      hideForGuests: false
  - name: Example Section 2
    icon: fas fa-broadcast-tower
    items: []
    displayData:
      sortBy: default
      rows: 1
      cols: 1
      collapsed: false
      hideForGuests: false
EOT

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh" "$DIRECTORY/conf.yml" "$DIRECTORY/creds.txt")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 5 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Cockpit
function cockpit {
  SOFTWARE="cockpit"
  DIRECTORY="/etc/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/cockpit.conf
[WebService]
Origins = https://somedomain1.com https://somedomain2.com:9090
EOT

    apt update -qq >/dev/null 2>&1
    pkgs='cockpit cockpit-podman cockpit-machines'
    for pkg in $pkgs; do
      status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
      if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
        apt install $pkg -yqq >/dev/null 2>&1
        echo "    ${GREEN}[+]${RESET} Installed Locally: $pkg"
      fi
    done
    sed -i 's/9090/1000/g' /usr/lib/systemd/system/cockpit.socket
    systemctl daemon-reload
    systemctl restart cockpit.socket
  else
    echo -e "    ${RED}[-]${RESET} Already Installed Cockpit: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Portainer
function portainer {
  SOFTWARE="portainer"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
version: "3"
services:
  portainer:
    image: portainer/portainer-ce:latest
    ports:
      - 1001:9443
    volumes:
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
  portainer_agent:
    image: portainer/agent:2.17.1
    ports:
      - 9001:9001
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    restart: unless-stopped
volumes:
  data:
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 3 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Uptime Kuma
function uptimekuma {
  SOFTWARE="uptimekuma"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
---
version: "3.8"
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    volumes:
      - ./data:/app/data
    ports:
      - 1002:3001
    # Specify your user ID and group ID. You can find this by running `id -u` and `id -g`
    #  - UID=1000
    #  - GID=1000
    restart: unless-stopped
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 3 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Pi Alert
function pialert {
  SOFTWARE="pialert"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
version: "3"
services:
  pialert:
    container_name: pialert
    image: "jokobsk/pi.alert:latest"
    network_mode: "host"
    restart: unless-stopped
    volumes:
      - ./config:/home/pi/pialert/config
      - ./db:/home/pi/pialert/db
      # (optional) useful for debugging if you have issues setting up the container
      - ./logs:/home/pi/pialert/front/log
    environment:
      - TZ=Europe/London
      - HOST_USER_ID=1000
      - HOST_USER_GID=1000
      - PORT=1003
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 3 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Passbolt
function passbolt {
  SOFTWARE="passbolt"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
version: '3.9'
services:
  db:
    image: mariadb:10.3
    restart: unless-stopped
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "true"
      MYSQL_DATABASE: "passbolt"
      MYSQL_USER: "passbolt"
      MYSQL_PASSWORD: "P4ssb0lt"
    volumes:
      - database_volume:/var/lib/mysql

  passbolt:
    image: passbolt/passbolt:latest-ce
    #Alternatively you can use rootless:
    #image: passbolt/passbolt:latest-ce-non-root
    restart: unless-stopped
    depends_on:
      - db
    environment:
      APP_FULL_BASE_URL: https://127.0.0.1:1004
      DATASOURCES_DEFAULT_HOST: "db"
      DATASOURCES_DEFAULT_USERNAME: "passbolt"
      DATASOURCES_DEFAULT_PASSWORD: "P4ssb0lt"
      DATASOURCES_DEFAULT_DATABASE: "passbolt"
    volumes:
      - gpg_volume:/etc/passbolt/gpg
      - jwt_volume:/etc/passbolt/jwt
    command: ["/usr/bin/wait-for.sh", "-t", "0", "db:3306", "--", "/docker-entrypoint.sh"]
    ports:
    #  - 5001:80
      - 1004:443
    #Alternatively for non-root images:
    # - 80:8080
    # - 443:4433

volumes:
  database_volume:
  gpg_volume:
  jwt_volume:
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    cat <<'EOT' >> $DIRECTORY/finish_setup.sh
docker compose -f /opt/orgHub/passbolt/docker-compose.yml exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake \
  passbolt register_user \
  -u manage@local.com \
  -f Forename \
  -l Lastname \
  -r admin" -s /bin/sh www-data
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh
    chmod +x $DIRECTORY/finish_setup.sh

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh" "$DIRECTORY/finish_setup.sh")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 4 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Bootstack
function bookstack {
  SOFTWARE="bookstack"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
---
version: "2"
services:
  bookstack:
    image: lscr.io/linuxserver/bookstack
    container_name: bookstack
    environment:
      - PUID=1000
      - PGID=1000
      - APP_URL=http://127.0.0.1:1005/
      - DB_HOST=bookstack_db
      - DB_PORT=3306
      - DB_USER=bookstack
      - DB_PASS=b00kstacked!
      - DB_DATABASE=bookstack_app
    volumes:
      - ./data:/config
    ports:
      - 1005:80
    restart: unless-stopped
    depends_on:
      - bookstack_db
  bookstack_db:
    image: lscr.io/linuxserver/mariadb
    container_name: bookstack_db
    environment:
      - PUID=1000
      - PGID=1000
      - MYSQL_ROOT_PASSWORD=REALLYb00kstacked!
      - TZ=Europe/London
      - MYSQL_USER=bookstack
      - MYSQL_PASSWORD=b00kstacked!
      - MYSQL_DATABASE=bookstack_app
    volumes:
      - ./data:/config
    restart: unless-stopped
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    cat <<'EOT' >> $DIRECTORY/creds.txt
admin@admin.com/password
EOT

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh" "$DIRECTORY/creds.txt")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 4 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Vikunja
function vikunja {
  SOFTWARE="vikunja"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
version: '3'

services:
  db:
    image: mariadb:10
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    environment:
      MYSQL_ROOT_PASSWORD: REALLYv1kunja!
      MYSQL_USER: vikunja
      MYSQL_PASSWORD: vikunjaninja
      MYSQL_DATABASE: vikunja
    volumes:
      - ./db:/var/lib/mysql
    restart: unless-stopped
  api:
    image: vikunja/api
    environment:
      VIKUNJA_DATABASE_HOST: db
      VIKUNJA_DATABASE_PASSWORD: vikunjaninja
      VIKUNJA_DATABASE_TYPE: mysql
      VIKUNJA_DATABASE_USER: vikunja
      VIKUNJA_DATABASE_DATABASE: vikunja
      VIKUNJA_SERVICE_JWTSECRET: pastelauctionsuggest
      VIKUNJA_SERVICE_FRONTENDURL: https://127.0.0.1/
    volumes: 
      - ./files:/app/vikunja/files
    depends_on:
      - db
    restart: unless-stopped
  frontend:
    image: vikunja/frontend
    restart: unless-stopped
  proxy:
    image: nginx
    ports:
      - 1006:80
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - api
      - frontend
    restart: unless-stopped
EOT

    mkdir -p $DIRECTORY/nginx
    cat <<'EOT' >> $DIRECTORY/nginx/nginx.conf
server {
    listen 80;

    location / {
        proxy_pass http://frontend:80;
    }

    location ~* ^/(api|dav|\.well-known)/ {
        proxy_pass http://api:3456;
        client_max_body_size 20M;
    }
}
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh" "$DIRECTORY/nginx/nginx.conf")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 4 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Nessus
function nessus {
  SOFTWARE="nessus"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p $DIRECTORY
    cat <<'EOT' >> $DIRECTORY/docker-compose.yml
---
version: "3.1"
services:
  nessus:
    image: tenableofficial/nessus
    container_name: nessus
    ports:
      - 1007:8834
    environment:
      USERNAME: manage
      PASSWORD: manageIT3!
    restart: unless-stopped
EOT

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    FILES=($DIRECTORY/*)
    if [[ ${#FILES[@]} -eq 3 ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}

#-----------------------------------------------------


# ELK Stack (Elastic)
function elk {
  SOFTWARE="elk"
  DIRECTORY="/opt/orgHub/$SOFTWARE"
  if [ ! -d "$DIRECTORY" ]; then
    mkdir -p /opt/orgHub >/dev/null 2>&1
    git -C /opt/orgHub clone https://github.com/deviantony/docker-elk.git >/dev/null 2>&1
    mv /opt/orgHub/docker-elk $DIRECTORY

    cat <<'EOT' >> $DIRECTORY/start.sh
docker compose up -d
EOT

    cat <<'EOT' >> $DIRECTORY/stop.sh
docker compose down
EOT

    chmod +x $DIRECTORY/start.sh
    chmod +x $DIRECTORY/stop.sh

    cat <<'EOT' >> $DIRECTORY/creds.txt
elastic/changeme
EOT

    FILES=("$DIRECTORY/docker-compose.yml" "$DIRECTORY/start.sh" "$DIRECTORY/stop.sh" "$DIRECTORY/creds.txt")
    for FILE in ${FILES[*]}; do
      if [[ ! -f $FILE ]]; then
        echo -e "    ${RED}[-]${RESET} Install Error in $SOFTWARE, $FILES not found!"
      fi
    done

    if [[ -f "$DIRECTORY/docker-compose.yml" ]]; then
      echo -e "    ${GREEN}[+]${RESET} Installed Container: $SOFTWARE"
    fi

  else
    echo -e "    ${RED}[-]${RESET} Already Installed Container: $SOFTWARE"
  fi
}


#-----------------------------------------------------


# Startup
function startup {
  if [ -d "/opt/orgHub" ]; then
    echo -e "    ${GREEN}[+]${RESET} Starting Stack..." && echo
    if [ -d "/opt/orgHub/dashy" ]; then cd /opt/orgHub/dashy && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Dashy"; fi
    if [ -d "/etc/cockpit" ]; then systemctl start cockpit.socket && echo -e "    ${GREEN}[+]${RESET} Started Cockpit"; fi
    if [ -d "/opt/orgHub/portainer" ]; then cd /opt/orgHub/portainer && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Portainer"; fi
    if [ -d "/opt/orgHub/uptimekuma" ]; then cd /opt/orgHub/uptimekuma && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Uptime Kuma"; fi
    if [ -d "/opt/orgHub/pialert" ]; then cd /opt/orgHub/pialert && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Pi Alert"; fi
    if [ -d "/opt/orgHub/passbolt" ]; then cd /opt/orgHub/passbolt && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Passbolt"; fi
    if [ -d "/opt/orgHub/bookstack" ]; then cd /opt/orgHub/bookstack && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Bookstack"; fi
    if [ -d "/opt/orgHub/vikunja" ]; then cd /opt/orgHub/vikunja && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Vikunja"; fi
    if [ -d "/opt/orgHub/nessus" ]; then cd /opt/orgHub/nessus && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Nessus"; fi
    if [ -d "/opt/orgHub/elk" ]; then cd /opt/orgHub/elk && docker compose up -d >/dev/null 2>&1 && echo -e "    ${GREEN}[+]${RESET} Started Elastic (ELK)"; fi
    echo && echo -e "   ${YELLOW} Docker Status ${RESET}" && echo 
    docker ps
  else
    echo -e "    ${RED}[-]${RESET} Stack not installed"
  fi
}

# Shutdown
function shutdown {
  if [ -d "/opt/orgHub" ]; then
    echo -e "    ${GREEN}[+]${RESET} Stopping Stack..." && echo
    if [ -d "/opt/orgHub/dashy" ]; then cd /opt/orgHub/dashy && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Dashy"; fi
    if [ -d "/etc/cockpit" ]; then systemctl stop cockpit.socket && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Cockpit"; fi
    if [ -d "/opt/orgHub/portainer" ]; then cd /opt/orgHub/portainer && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Portainer"; fi
    if [ -d "/opt/orgHub/uptimekuma" ]; then cd /opt/orgHub/uptimekuma && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Uptime Kuma"; fi
    if [ -d "/opt/orgHub/pialert" ]; then cd /opt/orgHub/pialert && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Pi Alert"; fi
    if [ -d "/opt/orgHub/bookstack" ]; then cd /opt/orgHub/bookstack && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Bookstack"; fi
    if [ -d "/opt/orgHub/vikunja" ]; then cd /opt/orgHub/vikunja && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Vikunja"; fi
    if [ -d "/opt/orgHub/passbolt" ]; then cd /opt/orgHub/passbolt && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Passbolt"; fi
    if [ -d "/opt/orgHub/nessus" ]; then cd /opt/orgHub/nessus && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Nessus"; fi
    if [ -d "/opt/orgHub/elk" ]; then cd /opt/orgHub/elk && docker compose down >/dev/null 2>&1 && echo -e "    ${RED}[-]${RESET} Stopped Elastic (ELK)"; fi
    echo && echo -e "   ${YELLOW} Docker Status ${RESET}" && echo 
    echo && docker ps && echo
  else
    echo -e "    ${RED}[-]${RESET} Stack not installed"
  fi
}


#--------------------------------------------------------------------------------------------------------------


# Application Run Order
banner
requirements

for ARG in $*; do
  case $ARG in
    -h|--help) usage;;
    -x|--start) start; startup; end; ;;
    -y|--stop) start; shutdown; end; ;;
    -a|--all) start; internet; software; dashy; portainer; uptimekuma; pialert; bookstack; vikunja; passbolt; nessus; cockpit; elk; end; ;;
    -c|--cockpit) start; internet; software; cockpit; end; ;;
    -d|--dashy) start; internet; software; dashy; end; ;;
    -p|--portainer) start; internet; software; portainer; end; ;;
    -u|--uptimekuma) start; internet; software; uptimekuma; end; ;;
    -i|--pialert) start; internet; software; pialert; end; ;;
    -b|--bookstack) start; internet; software; bookstack; end; ;;
    -v|--vikunja) start; internet; software; vikunja; end; ;;
    -o|--passbolt) start; internet; software; passbolt; end; ;;
    -n|--nessus) start; internet; software; nessus; end; ;;
    -e|--elk) start; internet; software; elk; end; ;;
    *) usage; echo -e "    ${RED}[-]${RESET} Unknown argument $ARG specified" && echo && exit 1 ;;
  esac
done

if [ $# -eq 0 ] ; then
  usage
  echo -e "    ${RED}[-]${RESET} No argument supplied" && echo
  exit 1;
fi

exit 0
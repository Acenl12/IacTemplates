#!/bin/bash

CA_NAME="Tiny"
ROOT_KEY_PASSWORD="smallsteplabs"
EMAIL="carl@smallstep.com"
AWS_ACCOUNT_ID="123123"

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi


case $OS in
Ubuntu)
    apt update && apt install -y jq
    ;;
Amazon*)
    yum install -y jq
    ;;
*)
    ;;
esac

case $(arch) in
x86_64)
    ARCH="amd64"
    ;;
aarch64)
    ARCH="arm64"
    ;;
esac

CA_VERSION=$(curl -s https://api.github.com/repos/smallstep/certificates/releases/latest | jq -r '.tag_name')
STEP_VERSION=$(curl -s https://api.github.com/repos/smallstep/cli/releases/latest | jq -r '.tag_name')

curl -sLO https://github.com/smallstep/cli/releases/download/$STEP_VERSION/step_linux_${STEP_VERSION:1}_$ARCH.tar.gz
tar xvzf step_linux_${STEP_VERSION:1}_$ARCH.tar.gz
cp step_${STEP_VERSION:1}/bin/step /usr/local/bin

curl -sLO https://github.com/smallstep/certificates/releases/download/$CA_VERSION/step-ca_linux_${CA_VERSION:1}_$ARCH.tar.gz
tar -xf step-ca_linux_${CA_VERSION:1}_$ARCH.tar.gz
cp step-ca_${CA_VERSION:1}/bin/step-ca /usr/local/bin
setcap CAP_NET_BIND_SERVICE=+eip $(which step-ca)

useradd --system --home /etc/step-ca --shell /bin/false step

mkdir -p $(step path)
mkdir -p $(step path)/db


mv $(step path) /etc/step-ca
export STEPPATH=/etc/step-ca
echo $ROOT_KEY_PASSWORD > $STEPPATH/password.txt

# Add a service to systemd for our CA.
cat<<EOF > /etc/systemd/system/step-ca.service
[Unit]
Description=step-ca service
Documentation=https://smallstep.com/docs/step-ca
Documentation=https://smallstep.com/docs/step-ca/certificate-authority-server-production
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=30
StartLimitBurst=3
ConditionFileNotEmpty=/etc/step-ca/config/ca.json
ConditionFileNotEmpty=/etc/step-ca/password.txt

[Service]
Type=simple
User=step
Group=step
Environment=STEPPATH=/etc/step-ca
WorkingDirectory=/etc/step-ca
ExecStart=/usr/local/bin/step-ca config/ca.json --password-file password.txt
ExecReload=/bin/kill --signal HUP $MAINPID
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=30
StartLimitBurst=3

; Process capabilities & privileges
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
SecureBits=keep-caps
NoNewPrivileges=yes

; Sandboxing
ProtectSystem=full
RestrictNamespaces=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
PrivateTmp=true
ProtectClock=true
ProtectControlGroups=true
ProtectKernelTunables=true
ProtectKernelLogs=true
ProtectKernelModules=true
LockPersonality=true
RestrictSUIDSGID=true
RemoveIPC=true
RestrictRealtime=true
; confirmed this works, even with YubiKey PIV, and presumably with YubiHSM2:
PrivateDevices=true
MemoryDenyWriteExecute=true
ReadWriteDirectories=/etc/step-ca/db

[Install]
WantedBy=multi-user.target
EOF

LOCAL_HOSTNAME=`curl -s http://169.254.169.254/latest/meta-data/local-hostname`
LOCAL_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
PUBLIC_HOSTNAME=`curl -s http://169.254.169.254/latest/meta-data/public-hostname`
PUBLIC_IP=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
AWS_ACCOUNT_ID=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep accountId | awk '{print $3}' | sed  's/"//g' | sed 's/,//g'`

# Set up our basic CA configuration and generate root keys
step ca init --ssh --name="$CA_NAME" \
     --dns="$LOCAL_IP,$LOCAL_HOSTNAME,$PUBLIC_IP,$PUBLIC_HOSTNAME" \
     --address=":443" --provisioner="$EMAIL" \
     --password-file="$STEPPATH/password.txt"

# Add the AWS provisioner, for host bootstrapping
step ca provisioner add "Amazon Web Services" --type=AWS --ssh \
    --aws-account=$AWS_ACCOUNT_ID

# The sshpop provisioner lets hosts renew their ssh certificates
step ca provisioner add SSHPOP --type=sshpop --ssh

# The ACME provisioner
step ca provisioner add acme --type=acme

echo "export STEPPATH=$STEPPATH" >> /root/.bash_profile


cat <<EOF > /etc/systemd/system/cert-renewer@.service
[Unit]
Description=Certificate renewer for %I
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=oneshot
User=root

Environment=STEPPATH=/etc/step-ca \
            CERT_LOCATION=/etc/step/certs/%i.crt \
            KEY_LOCATION=/etc/step/certs/%i.key

; ExecStartPre checks if the certificate is ready for renewal,
; based on the exit status of the command.
; (In systemd 243 and above, you can use ExecCondition= here.)
ExecStartPre=/usr/bin/bash -c \
  'step certificate inspect \$CERT_LOCATION --format json --roots "\$STEPPATH/certs/root_ca.crt" | \
  jq -e "(((.validity.start | fromdate) + \
          ((.validity.end | fromdate) - (.validity.start | fromdate)) * 0.66) \
           - now) <= 0" > /dev/null'

; ExecStart renews the certificate, if ExecStartPre was successful.
ExecStart=/usr/bin/step ca renew --force \$CERT_LOCATION \$KEY_LOCATION

; Try to reload or restart the systemd service that relies on this cert-renewer
ExecStartPost=-systemctl try-reload-or-restart %i

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/cert-renewer@.timer
[Unit]
Description=Certificate renewal timer for %I

[Timer]
Persistent=true

; Run the timer unit every 5 minutes.
OnCalendar=*:1/5

; Always run the timer on time.
AccuracySec=1us

; Add jitter to prevent a "thundering hurd" of simultaneous certificate renewals.
RandomizedDelaySec=5m

[Install]
WantedBy=timers.target
EOF

chown -R step:step $(step path)

systemctl enable --now step-ca

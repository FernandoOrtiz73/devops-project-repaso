#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. /etc/os-release

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git unzip python3-venv python3-pip docker.io snapd
sudo systemctl enable --now docker
sudo usermod -aG docker "$(id -un)"

sudo python3 -m venv /opt/devitaly-ansible
sudo /opt/devitaly-ansible/bin/python -m pip install 'ansible-core==2.19.15' requests
sudo /opt/devitaly-ansible/bin/ansible-galaxy collection install -r requirements.yml -p /opt/devitaly-collections
sudo chmod -R a+rX /opt/devitaly-ansible /opt/devitaly-collections

tmp_key=$(mktemp)
trap 'rm -f "$tmp_key"' EXIT
curl -fsSL https://apt.releases.hashicorp.com/gpg -o "$tmp_key"
sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg "$tmp_key"
printf 'deb [arch=%s signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com noble main\n' "$(dpkg --print-architecture)" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
sudo apt-get update
sudo apt-get install -y terraform
if ! command -v aws >/dev/null 2>&1; then
  sudo snap install aws-cli --classic
fi
echo 'Done. Log out of Ubuntu and log in again for Docker group membership.'
echo 'In each project terminal: export PATH="/opt/devitaly-ansible/bin:$PATH"'

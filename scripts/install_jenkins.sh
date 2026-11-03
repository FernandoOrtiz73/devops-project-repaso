#!/usr/bin/env bash
set -euo pipefail
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || { echo 'Requires Ubuntu 24.04'; exit 1; }
sudo apt-get update
sudo apt-get install -y fontconfig openjdk-21-jre ca-certificates curl
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o /etc/apt/keyrings/jenkins-keyring.asc
echo 'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
sudo apt-get update
sudo apt-get install -y jenkins
sudo usermod -aG docker jenkins
# Lab-only controller execution: keep UI local to this Ubuntu VM.
sudo mkdir -p /etc/systemd/system/jenkins.service.d
printf '[Service]\nEnvironment="JENKINS_OPTS=--httpListenAddress=127.0.0.1"\n' | sudo tee /etc/systemd/system/jenkins.service.d/lab.conf >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins
echo 'Open http://localhost:8080 inside the Ubuntu VM.'
echo 'Read the initial password locally: sudo cat /var/lib/jenkins/secrets/initialAdminPassword'

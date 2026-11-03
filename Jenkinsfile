pipeline {
    agent { label 'devitaly-lab' }
    options {
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
        skipDefaultCheckout(true)
    }
    parameters {
        string(name: 'EC2_HOST', defaultValue: '', description: 'Confirmed public IPv4 of the new lab EC2 instance')
        string(name: 'DOCKERHUB_USER', defaultValue: 'mecamorfogalvanico238', description: 'Docker Hub username / image namespace')
    }
    environment {
        PATH = "/opt/devitaly-ansible/bin:${env.PATH}"
        ANSIBLE_COLLECTIONS_PATH = '/opt/devitaly-collections'
    }
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Prepare') {
            steps {
                script {
                    if (!(params.DOCKERHUB_USER ==~ /[a-z0-9][a-z0-9_-]*/)) {
                        error('Invalid Docker Hub username')
                    }
                    def revision = sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()
                    env.IMAGE = "${params.DOCKERHUB_USER}/devitaly:${revision}-${env.BUILD_NUMBER}"
                }
                sh '''
                    python3 scripts/make_inventory.py --ip "$EC2_HOST" --output inventory.generated.ini
                    docker version
                    ansible-playbook --version
                    ansible-playbook -i inventory.generated.ini deploy_nginx.yml --syntax-check
                '''
            }
        }
        stage('Build image') {
            steps { sh 'docker build --pull -t "$IMAGE" .' }
        }
        stage('Publish image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials-id', usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_TOKEN')]) {
                    sh '''
                        set +x
                        set -eu
                        export DOCKER_CONFIG="$(mktemp -d)"
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT
                        printf '%s' "$REGISTRY_TOKEN" | docker login -u "$REGISTRY_USER" --password-stdin
                        docker push "$IMAGE"
                    '''
                }
            }
        }
        stage('Deploy and verify HTTP') {
            steps {
                sshagent(['ec2-ssh-credentials-id']) {
                    withCredentials([
                        file(credentialsId: 'ec2-known-hosts', variable: 'SSH_KNOWN_HOSTS'),
                        usernamePassword(credentialsId: 'dockerhub-credentials-id', usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_TOKEN')
                    ]) {
                        sh '''
                            set +x
                            set -eu
                            export DOCKERHUB_USER="$REGISTRY_USER"
                            export DOCKERHUB_TOKEN="$REGISTRY_TOKEN"
                            export ANSIBLE_SSH_COMMON_ARGS="-o UserKnownHostsFile=$SSH_KNOWN_HOSTS -o StrictHostKeyChecking=yes"
                            ansible-playbook -i inventory.generated.ini deploy_nginx.yml -e "image_name=$IMAGE"
                            printf 'Image: %s\nHost: %s\nHTTP/content validation: PASS\n' "$IMAGE" "$EC2_HOST" > deployment.txt
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'deployment.txt', allowEmptyArchive: true
            deleteDir()
        }
        success { echo 'Deployment and HTTP/content validation passed.' }
        failure { echo 'Check the failed stage and its logs.' }
    }
}

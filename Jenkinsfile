pipeline {
    agent none

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        gitlabBuilds(builds: ['ci'])
    }

    parameters {
        string(
            name: 'BTTR_SERVER_REPOSITORY',
            defaultValue: 'git@gitlab:staging/bttr-server.git',
            description: 'Repositório Git que contém mock-api/.'
        )
        string(
            name: 'BTTR_SERVER_BRANCH',
            defaultValue: 'master',
            description: 'Branch do bttr-server usada pelos testes E2E.'
        )
        string(
            name: 'PERF_P95_FRAME_MS',
            defaultValue: '250',
            description: 'Limite inicial do percentil 95 de frames no emulador, em ms.'
        )
        string(
            name: 'PERF_STARTUP_MEDIAN_MS',
            defaultValue: '10000',
            description: 'Limite inicial da mediana de abertura Android, em ms.'
        )
        choice(
            name: 'SECURITY_GATE',
            choices: ['enforce', 'report'],
            description: 'enforce reprova o build em achado de seguranca; ' +
                'report apenas publica os relatorios. Use report para calibrar ' +
                'uma regra nova antes de torna-la bloqueante.'
        )
    }

    environment {
        SECURITY_GATE = "${params.SECURITY_GATE}"
    }

    triggers {
        gitlab(
            triggerOnPush: true,
            triggerOnMergeRequest: true,
            branchFilterType: 'All'
        )
    }

    stages {
        stage('Flutter quality and unit tests') {
            agent any
            stages {
                stage('Checkout') {
                    steps {
                        // Older root-run containers may have left generated
                        // files that Jenkins cannot remove. Repair the bind
                        // mount before deleteDir(); new containers run as the
                        // Jenkins UID and no longer create this condition.
                        sh '''
                            set -eu
                            foreign_path="$(
                                find . -xdev ! -uid "$(id -u)" -print -quit \
                                    2>/dev/null || true
                            )"
                            [ -n "$foreign_path" ] || exit 0
                            echo "Reparando ownership legado a partir de: $foreign_path"

                            host_workspace="$WORKSPACE"
                            if [ -n "${CI_HOST_JENKINS_HOME:-}" ]; then
                                : "${JENKINS_HOME:?JENKINS_HOME deve estar definido no Jenkins}"
                                case "$WORKSPACE" in
                                    "$JENKINS_HOME"/*)
                                        host_workspace="$CI_HOST_JENKINS_HOME/${WORKSPACE#"$JENKINS_HOME"/}"
                                        ;;
                                    *)
                                        echo 'WORKSPACE deve estar dentro de JENKINS_HOME.' >&2
                                        exit 1
                                        ;;
                                esac
                            fi
                            case "$host_workspace" in
                                /*/workspace/*) ;;
                                *)
                                    echo "Workspace recusado para reparo: $host_workspace" >&2
                                    exit 1
                                    ;;
                            esac
                            docker run --rm --user 0:0 \
                                --volume "$host_workspace:/workspace" \
                                --entrypoint chown \
                                ghcr.io/cirruslabs/flutter:3.41.9 \
                                -R "$(id -u):$(id -g)" /workspace
                        '''
                        deleteDir()
                        checkout scm
                        updateGitlabCommitStatus name: 'ci', state: 'running'
                    }
                }

                stage('Dependencies') {
                    steps {
                        gitlabCommitStatus(name: 'dependencies') {
                            sh './scripts/jenkins-compose.sh flutter ./scripts/quality.sh dependencies'
                        }
                    }
                }

                stage('Dart formatter') {
                    steps {
                        gitlabCommitStatus(name: 'dart-format') {
                            sh './scripts/jenkins-compose.sh flutter ./scripts/quality.sh dart-format-check'
                        }
                    }
                }

                stage('Dart lint') {
                    steps {
                        gitlabCommitStatus(name: 'dart-lint') {
                            sh './scripts/jenkins-compose.sh flutter ./scripts/quality.sh dart-lint'
                        }
                    }
                }

                stage('Kotlin lint and format') {
                    steps {
                        gitlabCommitStatus(name: 'kotlin-style') {
                            sh './scripts/jenkins-compose.sh flutter ./scripts/quality.sh kotlin-check'
                        }
                    }
                }

                stage('Swift formatter') {
                    steps {
                        gitlabCommitStatus(name: 'swift-format') {
                            sh './scripts/jenkins-compose.sh swift-format ./scripts/quality.sh swift-format-check'
                        }
                    }
                }

                stage('Swift lint') {
                    steps {
                        gitlabCommitStatus(name: 'swift-lint') {
                            sh './scripts/jenkins-compose.sh swiftlint ./scripts/quality.sh swift-lint'
                        }
                    }
                }

                stage('Unit tests') {
                    steps {
                        gitlabCommitStatus(name: 'tests') {
                            sh './scripts/jenkins-compose.sh flutter ./scripts/quality.sh test-ci'
                        }
                    }
                }

                stage('Coverage') {
                    steps {
                        gitlabCommitStatus(name: 'coverage') {
                            recordCoverage failOnError: true,
                                tools: [[parser: 'LCOV', pattern: 'coverage/lcov.info']],
                                qualityGates: [[
                                    metric: 'LINE',
                                    baseline: 'PROJECT',
                                    threshold: 90.0,
                                    criticality: 'FAILURE'
                                ]]
                        }
                    }
                }

                stage('SonarQube Analysis') {
                    steps {
                        gitlabCommitStatus(name: 'sonarqube') {
                            withSonarQubeEnv('SonarQube Local') {
                                sh '''
                                    if [ -n "${CI_HOST_JENKINS_HOME:-}" ]; then
                                        case "$WORKSPACE" in
                                            "$JENKINS_HOME"/*)
                                                export CI_WORKSPACE="$CI_HOST_JENKINS_HOME/${WORKSPACE#"$JENKINS_HOME"/}"
                                                ;;
                                            *)
                                                echo 'WORKSPACE deve estar dentro de JENKINS_HOME para mapear o caminho no host.' >&2
                                                exit 1
                                                ;;
                                        esac
                                    fi

                                    export CI_UID="$(id -u)" CI_GID="$(id -g)"
                                    export SONAR_TOKEN="$SONAR_AUTH_TOKEN"
                                    export COMPOSE_PROJECT_NAME="bttr-client-flutter-sonarqube-$(printf '%s' "$JOB_NAME" | cksum | cut -d ' ' -f 1)-$BUILD_NUMBER"
                                    trap 'docker compose -f compose.ci.yaml -f compose.jenkins.yaml down --remove-orphans' EXIT
                                    docker compose -f compose.ci.yaml -f compose.jenkins.yaml run --rm -T --no-deps sonar-scanner
                                '''
                            }
                        }
                    }
                }

                stage('Quality Gate') {
                    steps {
                        timeout(time: 10, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }

                stage('Security: secrets') {
                    steps {
                        gitlabCommitStatus(name: 'security-secrets') {
                            sh './scripts/jenkins-compose.sh security ./scripts/security.sh secrets'
                        }
                    }
                }

                stage('Security: dependencies') {
                    steps {
                        gitlabCommitStatus(name: 'security-deps') {
                            // Duas politicas distintas: pubspec.lock reprova
                            // porque vira codigo no aparelho do usuario; a
                            // arvore npm do Appium so reporta, porque nao entra
                            // no artefato distribuido.
                            sh './scripts/jenkins-compose.sh security ./scripts/security.sh deps'
                            sh './scripts/jenkins-compose.sh security ./scripts/security.sh deps-toolchain'
                        }
                    }
                }

                stage('Security: SAST') {
                    steps {
                        gitlabCommitStatus(name: 'security-sast') {
                            sh './scripts/jenkins-compose.sh security ./scripts/security.sh sast'
                        }
                    }
                }

                stage('Security: IaC') {
                    steps {
                        gitlabCommitStatus(name: 'security-iac') {
                            sh './scripts/jenkins-compose.sh security ./scripts/security.sh iac'
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true,
                        artifacts: 'coverage/**,test-results/**'
                    junit allowEmptyResults: true,
                        testResults: 'test-results/TEST-flutter.xml'
                    // enabledForFailure publica os relatorios tambem quando um
                    // estagio de seguranca reprovou — que e justamente quando
                    // eles precisam ser lidos. O veredito ja veio do codigo de
                    // saida da ferramenta; aqui o Jenkins so registra a
                    // tendencia e ancora cada achado no arquivo e na linha.
                    recordIssues(
                        enabledForFailure: true,
                        skipPublishingChecks: true,
                        tools: [
                            sarif(id: 'gitleaks',
                                name: 'Segredos (Gitleaks)',
                                pattern: 'test-results/security/gitleaks*.sarif'),
                            sarif(id: 'osv-scanner',
                                name: 'Dependencias (OSV-Scanner)',
                                pattern: 'test-results/security/osv-scanner-*.sarif'),
                            sarif(id: 'semgrep',
                                name: 'SAST (Semgrep)',
                                pattern: 'test-results/security/semgrep.sarif'),
                            sarif(id: 'trivy',
                                name: 'IaC (Trivy)',
                                pattern: 'test-results/security/trivy-config.sarif'),
                            sarif(id: 'hadolint',
                                name: 'Dockerfile (Hadolint)',
                                pattern: 'test-results/security/hadolint.sarif'),
                        ]
                    )
                }
            }
        }

        stage('Appium Android E2E') {
            agent any
            options { timeout(time: 60, unit: 'MINUTES') }
            steps {
                deleteDir()
                checkout scm
                dir('.ci/bttr-server') {
                    git branch: params.BTTR_SERVER_BRANCH,
                        url: params.BTTR_SERVER_REPOSITORY
                }
                gitlabCommitStatus(name: 'e2e-android') {
                    sh '''
                        export BTTR_MOCK_API_CONTEXT='.ci/bttr-server/mock-api'
                        ./scripts/jenkins-android-e2e.sh
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true,
                        testResults: 'test-results/TEST-e2e-helpers.xml,test-results/TEST-appium-android.xml'
                    archiveArtifacts allowEmptyArchive: true,
                        artifacts: 'test-results/appium-android*,e2e/artifacts/**'
                }
            }
        }

        stage('Android performance') {
            agent any
            options { timeout(time: 75, unit: 'MINUTES') }
            steps {
                deleteDir()
                checkout scm
                dir('.ci/bttr-server') {
                    git branch: params.BTTR_SERVER_BRANCH,
                        url: params.BTTR_SERVER_REPOSITORY
                }
                gitlabCommitStatus(name: 'performance-android') {
                    sh '''
                        export BTTR_MOCK_API_CONTEXT='.ci/bttr-server/mock-api'
                        ./scripts/jenkins-android-e2e.sh performance
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true,
                        testResults: 'test-results/TEST-e2e-helpers.xml,test-results/TEST-performance-android.xml,build/macrobenchmark/outputs/androidTest-results/connected/**/*.xml'
                    archiveArtifacts allowEmptyArchive: true,
                        artifacts: 'test-results/performance/**,test-results/appium-android.log,build/macrobenchmark/outputs/connected_android_test_additional_output/**'
                }
            }
        }
    }

    post {
        success {
            updateGitlabCommitStatus name: 'ci', state: 'success'
        }
        failure {
            updateGitlabCommitStatus name: 'ci', state: 'failed'
        }
        aborted {
            updateGitlabCommitStatus name: 'ci', state: 'canceled'
        }
    }
}

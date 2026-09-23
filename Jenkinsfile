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
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true,
                        artifacts: 'coverage/**,test-results/**'
                    junit allowEmptyResults: true,
                        testResults: 'test-results/TEST-flutter.xml'
                }
            }
        }

        stage('Appium Android E2E') {
            agent { label 'android-e2e' }
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
                        ./scripts/appium-e2e-ci.sh android
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

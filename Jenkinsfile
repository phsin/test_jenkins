pipeline {
    agent any
    
    environment {
        V8_VERSION = "8.3.25.1374"
        TEMPLATE_DB = "D:\\DevOps\\Demo\\SSR\\1Cv8.1CD"
        EXTENSION_SRC = "src/cfe"
        IB_PATH = "./build/ib"
    }
    
    stages {
        stage('Подготовка') {
            steps {
                echo "Подготовка рабочего пространства"
                bat 'if not exist build\\out mkdir build\\out'
            }
        }
        
        stage('Создание ИБ из шаблона') {
            steps {
                echo "Создание информационной базы из шаблона"
                script {
                    if (fileExists("${env.TEMPLATE_DB}")) {
                        bat """
                            chcp 65001 > nul
                            vrunner init-dev --template "${env.TEMPLATE_DB}" --ibconnection "/F${env.IB_PATH}" --settings tools/vrunner.json
                        """
                    } else {
                        bat """
                            chcp 65001 > nul
                            vrunner init-dev --ibconnection "/F${env.IB_PATH}" --settings tools/vrunner.json
                        """
                    }
                }
            }
        }
        
        stage('Сборка и загрузка расширения') {
            steps {
                echo "Сборка и загрузка расширения из исходников"
                bat """
                    chcp 65001 > nul
                    vrunner compileext ${env.EXTENSION_SRC} --ibconnection "/F${env.IB_PATH}" --settings tools/vrunner.json
                """
            }
        }
        
        stage('Синтаксический контроль') {
            steps {
                echo "Выполнение синтаксического контроля"
                bat """
                    chcp 65001 > nul
                    vrunner syntax-check --ibconnection "/F${env.IB_PATH}" --settings tools/vrunner.json
                """
            }
        }
    }
    
    post {
        always {
            echo "Очистка временных файлов"
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'out/syntax-check',
                reportFiles: '*.html',
                reportName: 'Syntax Check Report'
            ])
        }
        success {
            echo "Pipeline выполнен успешно"
        }
        failure {
            echo "Pipeline завершился с ошибкой"
        }
    }
}
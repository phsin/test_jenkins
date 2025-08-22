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
                        echo "Копирование шаблона базы данных"
                        bat """
                            chcp 65001 > nul
                            if exist "${env.IB_PATH}" rmdir /s /q "${env.IB_PATH}"
                            echo D | xcopy /E /I /Y "${env.TEMPLATE_DB}" "${env.IB_PATH}"
                        """
                    } else {
                        echo "Создание новой пустой базы данных"
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
                    vrunner compileext ${env.EXTENSION_SRC} кб99_ЕИС --ibconnection "/F${env.IB_PATH}" --settings tools/vrunner.json
                """
            }
        }
        
        // stage('Синтаксический контроль') {
        //     steps {
        //         echo "Выполнение синтаксического контроля"
        //         bat """
        //             chcp 65001 > nul
        //             vrunner syntax-check --ibconnection "/F${env.IB_PATH}" --settings tools/vrunner.json
        //         """
        //     }
        // }
        
        stage('Start BDD Tests') {
            steps {
                echo "Запуск BDD тестов"
                bat """
                    call test.cmd                 
                """
            }
        }
    }
    
    post {
        always {
            echo "Публикация отчетов"
            script {
                // Публикация отчетов Allure
                if (fileExists('build/out/allure')) {
                    allure([
                        includeProperties: false,
                        jdk: '',
                        properties: [],
                        reportBuildPolicy: 'ALWAYS',
                        results: [[path: 'build/out/allure']]
                    ])
                }
                
                // Публикация синтаксических отчетов
                if (fileExists('out/syntax-check')) {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'out/syntax-check',
                        reportFiles: '*.html',
                        reportName: 'Syntax Check Report'
                    ])
                }
                
                // Публикация результатов тестов
                if (fileExists('build/out/allure')) {
                    publishTestResults testResultsPattern: 'build/out/allure/*.xml'
                }                
                // Архивирование артефактов
                archiveArtifacts artifacts: 'build/**/*.log', allowEmptyArchive: true
                archiveArtifacts artifacts: 'build/out/allure/**/*', allowEmptyArchive: true
            }
        }
        success {
            echo "Pipeline выполнен успешно"
        }
        failure {
            echo "Pipeline завершился с ошибкой"
            script {
                // Отправка email при ошибке
                if (env.CHANGE_ID == null) { // только для основной ветки
                    mail to: 'fa@kb99.pro',
                         subject: "Jenkins Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                         body: """Сборка завершилась с ошибкой.
                         
Проект: ${env.JOB_NAME}
Номер сборки: ${env.BUILD_NUMBER}
URL: ${env.BUILD_URL}

Проверьте логи для получения деталей."""
                }
            }            
        }
    }
}
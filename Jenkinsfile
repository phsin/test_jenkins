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
                bat '''
                    rem Создание основных каталогов
                    if not exist build mkdir build
                    if not exist build\\out mkdir build\\out
                    if not exist build\\out\\allure mkdir build\\out\\allure
                    
                    rem Создание каталогов для логов
                    if not exist build\\logs mkdir build\\logs
                    if not exist build\\logs\\errors mkdir build\\logs\\errors
                    if not exist build\\logs\\client mkdir build\\logs\\client
                    
                    rem Создание каталогов для отчетов
                    if not exist build\\reports mkdir build\\reports
                    if not exist build\\reports\\allure mkdir build\\reports\\allure
                    if not exist build\\reports\\ScreenShots mkdir build\\reports\\ScreenShots
                    if not exist build\\reports\\junit mkdir build\\reports\\junit
                    
                    echo Каталоги созданы
                '''
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
        
        // stage('Обновление из хранилища') {
        //     steps {
        //         echo "Загрузка конфигурации из хранилища"
        //         bat """
        //             chcp 65001 > nul
        //             call build.cmd repo
        //         """
        //     }
        // }
        
        stage('Сборка и загрузка расширения') {
            steps {
                echo "Сборка и загрузка расширения из исходников"
                bat """
                    call build.cmd 
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
                echo "Запуск BDD тестов с подробным логированием"
                script {
                    try {
                        bat """
                            chcp 65001 > nul
                            call test.cmd 
                        """
                    } catch (Exception e) {
                        echo "BDD тесты завершились с ошибками: ${e.getMessage()}"
                        
                        // Выводим содержимое основных логов
                        if (fileExists('build/buildstatus.log')) {
                            echo "=== Содержимое buildstatus.log ==="
                            bat 'type build\\buildstatus.log'
                        }
                        
                        if (fileExists('build/logs/vanessa-execution.log')) {
                            echo "=== Содержимое vanessa-execution.log (последние 50 строк) ==="
                            bat 'powershell "Get-Content build\\logs\\vanessa-execution.log -Tail 50"'
                        }
                        
                        if (fileExists('build/logs/vanessa-console.log')) {
                            echo "=== Содержимое vanessa-console.log (последние 30 строк) ==="
                            bat 'powershell "Get-Content build\\logs\\vanessa-console.log -Tail 30"'
                        }
                        
                        // Список файлов ошибок
                        bat '''
                            echo === Список файлов ошибок ===
                            if exist build\\logs\\errors\\*.* (
                                dir /b build\\logs\\errors\\*.*
                            ) else (
                                echo Файлов ошибок не найдено
                            )
                        '''
                        
                        // Продолжаем выполнение для публикации отчетов
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "Публикация отчетов и сбор статистики"
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
                // Публикация HTML отчета с логами
                if (fileExists('build/logs')) {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'build/logs',
                        reportFiles: '*.log',
                        reportName: 'Vanessa Test Logs',
                        reportTitles: 'Логи тестирования Vanessa'
                    ])
                }
                
                // Архивирование всех артефактов
                archiveArtifacts artifacts: 'build/**/*.log', allowEmptyArchive: true
                archiveArtifacts artifacts: 'build/logs/**/*', allowEmptyArchive: true
                archiveArtifacts artifacts: 'build/out/allure/**/*', allowEmptyArchive: true
                archiveArtifacts artifacts: 'build/reports/**/*', allowEmptyArchive: true
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
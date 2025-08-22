@chcp 65001

@rem формирование файла конфигурации. для включения раскомментируйте код ниже
@rem call vrunner compile --src src/cf --out build/1cv8.cf %*

@rem обновление конфигурации основной разработческой ИБ из хранилища. для включения раскомментируйте код ниже
@rem call vrunner loadrepo %*
@rem call vrunner updatedb %*

@rem собрать внешние обработчики и отчеты в каталоге build
@rem call vrunner compileepf src/epf/МояВнешняяОбработка build %*
@rem call vrunner compileepf src/erf/МойВнешнийОтчет build %*

@rem собрать расширения конфигурации внутри ИБ
@rem call vrunner compileext src/cfe/МоеРасширение МоеРасширение %*
call vrunner compileext .\\src\\cfe кб99_ЕИС --updatedb --settings tools/vrunner.json 

@rem compile cfe
@rem vrunner compileexttocfe -s cfe -o testNew.cfe --ibconnection /F./build/ib --language ru

@rem update cfe
@rem call vrunner updateext кб99_ЕИС --settings tools/vrunner.json


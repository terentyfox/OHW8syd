# OHW8syd - Creating systemd service
1. Написать сервис, мониторящий лог раз в полминуты и ищущий в нём ключевое слово. Файл лога и ключевое слово должны задаваться в /etc/sysconfig/

В каталоге files1 сохранены файлы с путями относительно корня файловой системы:
/etc/sysconfig/watchlog - файл с переменными окружения - искомым словом и файлом для поиска
/var/log/watchlog.log - файл для поиска
/opt/watchlog.sh - скрипт, реализующий поис
/lib/systemd/system/watchlog.service - юнит сервиса
/lib/systemd/system/watchlog.timer - таймер, запускающий юнит с заданной периодичностью.

Комментарии в файле systemdscript.sh

проверка работы:
#tail -f /var/log/messages

В логе с заданной периодичностью появляется запись "I found word, Master!"



2. Для установленного из epel пакета spawn-fcgi заменить init-скрипт на unit-файл с сохранением имени сервиса

редактором sed раскомментированы переменные в файле конфигурации.
Далее создан юнит

3. В unit-файле apache httpd реализовать возможность запуска нескольких инстансов сервера с разными конфигами.
 
Apache HTTP Server
Сначала создан шаблон юнита httpd@.service. Далее собраны конфиги на основе типового httpd.conf
И затем в файлах окружения добавлены ссылки на конфиги.

Файлы настроек лежат в каталоге files2 с сохранением дерева каталогов.

Все юниты запускаются в конце скрипта. 
Перед запуском httpd командой

setenforce 0

отключается SElinux.



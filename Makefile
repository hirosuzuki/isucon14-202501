build:
	cd go && go build -o isuride

deploy-app:
	rsync -av go/isuride isucon1:/home/isucon/webapp/go/isuride
	rsync -av env.sh isucon1:/home/isucon/env.sh
	rsync -av sql/1-schema.sql isucon1:/home/isucon/webapp/sql/1-schema.sql
	ssh isucon1 sudo truncate -c -s 0 /var/log/nginx/access.log
	ssh isucon1 sudo truncate -c -s 0 /tmp/slow.log
	ssh isucon1 sudo truncate -c -s 0 /tmp/isuapp-err.log
	ssh isucon1 sudo truncate -c -s 0 /tmp/isuapp.log
	ssh root@isucon1 systemctl restart isuride-go

deploy-conf:
	rsync -v etc/security/limits.conf root@isucon1:/etc/security/limits.conf
	rsync -v etc/sysctl.conf root@isucon1:/etc/sysctl.conf
	rsync -v etc/nginx/sites-enabled/isuride.conf root@isucon1:/etc/nginx/sites-enabled/isuride.conf
	rsync -v etc/nginx/nginx.conf root@isucon1:/etc/nginx/nginx.conf
	rsync -v etc/mysql/my.cnf root@isucon1:/etc/mysql/my.cnf
	rsync -v etc/systemd/system/isuride-go.service root@isucon1:/etc/systemd/system/isuride-go.service
	rsync -v etc/systemd/system/isuride-matcher.service root@isucon1:/etc/systemd/system/isuride-matcher.service
	ssh root@isucon1 sysctl -p
	ssh root@isucon1 systemctl daemon-reload
	ssh root@isucon1 systemctl restart mysql
	ssh root@isucon1 systemctl restart nginx
	ssh root@isucon1 systemctl restart isuride-go
	ssh root@isucon1 systemctl restart isuride-matcher

install-percona-toolkit:
	sudo apt install -y percona-toolkit

enable-mysql-slowlog:
	ssh isucon1 sudo truncate -c -s 0 /tmp/slow.log
	ssh isucon1 'sudo mysql -e "SET GLOBAL long_query_time = 0; SET GLOBAL slow_query_log = ON; SET GLOBAL slow_query_log_file = \"/tmp/slow.log\";"'

disable-mysql-slowlog:
	ssh isucon1 'sudo mysql -e "SET GLOBAL slow_query_log = OFF"'

get-mysql-slowlog:
	ssh root@isucon1 gzip -c /tmp/slow.log | gzip -dc | pt-query-digest > mysql.digest.txt

install-kataribe:
	go install github.com/matsuu/kataribe@latest

exec-kataribe:
	ssh root@isucon1 gzip -c /var/log/nginx/access.log | gzip -dc | kataribe > kataribe.txt

install-redis:
	ssh root@isucon1 sudo apt install -y redis-server

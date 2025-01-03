build:
	cd go && go build -o isuride

deploy-app:
	rsync -av go/isuride isucon1:/home/isucon/webapp/go/isuride
	rsync -av env.sh isucon1:/home/isucon/env.sh
	rsync -av sql/1-schema.sql isucon1:/home/isucon/webapp/sql/1-schema.sql
	ssh root@isucon1 systemctl restart isuride-go

deploy-conf:
	rsync -v etc/security/limits.conf root@isucon1:/etc/security/limits.conf
	rsync -v etc/sysctl.conf root@isucon1:/etc/sysctl.conf
	rsync -v etc/nginx/sites-enabled/isuride.conf root@isucon1:/etc/nginx/sites-enabled/isuride.conf
	rsync -v etc/nginx/nginx.conf root@isucon1:/etc/nginx/nginx.conf
	rsync -v etc/mysql/my.cnf root@isucon1:/etc/mysql/my.cnf
	rsync -v etc/systemd/system/isuride-go.service root@isucon1:/etc/systemd/system/isuride-go.service
	rsync -v etc/systemd/system/isuride-matcher.service root@isucon1:/etc/systemd/system/isuride-matcher.service
	ssh root@isucon1 systemctl daemon-reload
	ssh root@isucon1 systemctl restart mysql
	ssh root@isucon1 systemctl restart nginx
	ssh root@isucon1 systemctl restart isuride-go
	ssh root@isucon1 systemctl restart isuride-matcher


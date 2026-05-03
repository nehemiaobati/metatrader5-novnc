up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

backup:
	tar -czvf volumes_backup_$(shell date +%Y%m%d).tar.gz volumes/

stream-start:
	./start-stream.sh

stream-stop:
	./stop-stream.sh

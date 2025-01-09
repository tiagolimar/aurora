# Makefile para automatizar setup do projeto PHP com Docker

.PHONY: up install_dependencies generate_proxies migrate_database load_fixtures install_frontend compile_frontend generate_keys

# Inicia os serviços Docker em modo detached
up:
	docker compose up -d

# Para os serviços Docker
stop:
	docker compose stop

# Para e remove os serviços Docker
down:
	docker compose down

# Instala dependências dentro do contêiner PHP
install_dependencies:
	docker compose exec -T php bash -c "composer install"

# Gera os arquivos de Proxies do MongoDB
generate_proxies:
	docker compose exec -T php bash -c "php bin/console doctrine:mongodb:generate:proxies"

# Executa as migrations no banco relacional e no não relacional
migrate_database: migrate_orm migrate_odm

# Executa as migrations no banco de dados relacional
migrate_orm:
	docker compose exec -T php bash -c "php bin/console doctrine:migrations:migrate -n"

# Executa as migrations no banco de dados não relacional
migrate_odm:
	docker compose exec -T php bash -c "php bin/console app:mongo:migrations:execute"

# Executa as fixtures de dados
load_fixtures:
	docker compose exec -T php bash -c "php bin/console doctrine:fixtures:load -n --append --purge-exclusions=city --purge-exclusions=state"

# Instala dependências do frontend
install_frontend:
	docker compose exec -T php bash -c "php bin/console importmap:install"

# Compila os arquivos do frontend
compile_frontend:
	docker compose exec -T php bash -c "php bin/console asset-map:compile"

# Executa as fixtures de dados e os testes de front-end
tests_front: load_fixtures
	docker compose up cypress

# Executa as fixtures de dados e os testes de back-end
tests_back: load_fixtures
	docker compose exec -T php bash -c "php bin/phpunit"

# Limpa o cache do projeto
reset:
	docker compose exec -T php bash -c "php bin/console cache:clear"

# Limpa a cache e o banco
reset-deep:
	rm -rf var/storage
	rm -rf assets/vendor
	rm -rf public/assets
	rm -rf var/cache
	rm -rf var/log
	docker compose exec -T php bash -c "php bin/console cache:clear"
	docker compose exec -T php bash -c "php bin/console doctrine:mongodb:schema:drop"
	docker compose exec -T php bash -c "php bin/console doctrine:mongodb:schema:create"
	docker compose exec -T php bash -c "php bin/console d:d:d -f"
	docker compose exec -T php bash -c "php bin/console d:d:c"
	make migrate_database
	docker compose exec -T php bash -c "php bin/console importmap:install"
	docker compose exec -T php bash -c "php bin/console asset-map:compile"

# Executa o php cs fixer
style:
	docker compose exec -T php bash -c "php bin/console app:code-style"

# Gera as chaves de autenticação JWT
generate_keys:
	docker compose exec -T php bash -c "php bin/console lexik:jwt:generate-keypair --overwrite -n"

# Comando para rodar todos os passos juntos
setup: up install_dependencies reset-deep generate_proxies migrate_database load_fixtures install_frontend compile_frontend generate_keys

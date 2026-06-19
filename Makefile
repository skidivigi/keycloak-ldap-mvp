.PHONY: up down restart logs watch ldap-setup ldap-search clean

up:
	docker compose up -d --force-recreate

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

watch:
	watch docker ps -a

ldap-setup:
	docker cp ldap/init.ldif openldap:/tmp/bootstrap.ldif
	docker exec openldap ldapadd \
		-x \
		-D "cn=admin,dc=company,dc=local" \
		-w admin \
		-f /tmp/bootstrap.ldif

ldap-search:
	docker exec openldap ldapsearch \
		-x \
		-D "cn=admin,dc=company,dc=local" \
		-w admin \
		-b "dc=company,dc=local"

clean:
	docker compose down -v

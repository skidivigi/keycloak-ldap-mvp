# keycloak-freeipa-lab

Учебный стенд для практики с Keycloak:

```text
Postgres → Keycloak → Grafana
              ↑
          optional FreeIPA
```

## Что есть в проекте

```text
keycloak-freeipa-lab/
├── docker-compose.yml
├── docs/*.md
├── keycloak/
│   ├── themes/company/
│   └── realm-export.json
├── grafana/
│   └── grafana.ini
├── freeipa/
│   └── init-freeipa.sh
├── README.md
└── TROUBLESHOOTING.md
```

## Порты

| Сервис | URL |
|---|---|
| Keycloak | http://localhost:8080 |
| Grafana | http://localhost:3000 |
| FreeIPA, optional | http://localhost:8081 / https://localhost:8443 |

## Быстрый запуск

```bash
docker compose up -d
```

Проверка:

```bash
docker compose ps
docker logs -f keycloak
```

## Доступы

### Keycloak admin

```text
URL:      http://localhost:8080
Login:    admin
Password: admin
```

### Realm

```text
Realm: company
```

### Grafana local admin

```text
URL:      http://localhost:3000
Login:    admin
Password: admin
```

### Пользователи Keycloak

| Username | Password | Роль Grafana |
|---|---|---|
| grafana-admin | Admin123456 | Admin |
| grafana-editor | Editor123456 | Editor |
| grafana-viewer | Viewer123456 | Viewer |

## Проверка OIDC-логина

1. Открой Grafana: http://localhost:3000
2. Нажми `Sign in with Keycloak`.
3. Войди пользователем:

```text
grafana-admin / Admin123456
```

4. После входа пользователь должен получить роль `Admin`.

## Как это работает

Grafana настроена как OIDC-клиент Keycloak.

```text
Browser → Grafana → Keycloak login → Grafana callback → token exchange → session
```

В Keycloak есть client:

```text
Client ID: grafana
Client secret: grafana-secret
Redirect URI: http://localhost:3000/login/generic_oauth
```

В токен добавляются:

```text
realm_access.roles
groups
email
profile
```

Grafana читает `realm_access.roles` и мапит роль:

```text
grafana-admin  → Admin
grafana-editor → Editor
default        → Viewer
```

## Custom theme

Тема лежит тут:

```text
keycloak/themes/company/
```

Она подключена в realm import:

```text
loginTheme: company
```

После изменения CSS можно перезапустить Keycloak:

```bash
docker compose restart keycloak
```

Для dev-стенда кэш тем отключён через env:

```text
KC_SPI_THEME_CACHE_THEMES=false
KC_SPI_THEME_CACHE_TEMPLATES=false
```

## Optional: запуск FreeIPA

FreeIPA в контейнере тяжёлый и капризный. Лучше запускать на Linux-хосте или в отдельной VM. На Docker Desktop может не завестись из-за systemd/cgroup/privileged-ограничений.

Запуск:

```bash
docker compose --profile freeipa up -d freeipa
```

Логи:

```bash
docker logs -f freeipa
```

Когда установка завершится, можно создать тестовые группы и пользователей:

```bash
docker cp ./freeipa/init-freeipa.sh freeipa:/data/init-freeipa.sh
docker exec -it freeipa bash /data/init-freeipa.sh
```

## Подключение FreeIPA к Keycloak вручную

Открой:

```text
Keycloak → realm company → User federation → Add LDAP providers
```

Пример настроек:

```text
Vendor: Other
Connection URL: ldap://ipa.company.local:389
Users DN: cn=users,cn=accounts,dc=company,dc=local
Bind DN: uid=admin,cn=users,cn=accounts,dc=company,dc=local
Bind credential: Admin123456
Edit mode: READ_ONLY
Username LDAP attribute: uid
RDN LDAP attribute: uid
UUID LDAP attribute: ipaUniqueID
User object classes: inetOrgPerson, organizationalPerson
Search scope: Subtree
Import users: ON
Sync Registrations: OFF
```

Потом:

```text
User federation → твой LDAP provider → Action → Sync all users
```

## Что тренировать

1. Создать client руками.
2. Сломать redirect URI.
3. Сломать client secret.
4. Посмотреть токен через jwt.io или curl.
5. Добавить новую роль.
6. Добавить mapper.
7. Подключить FreeIPA.
8. Проверить sync users.
9. Поменять тему login-страницы.
10. Разобрать логи Keycloak и Grafana.

## Шаги по воспроизведению указаны в директории docs  
[В директории](./docs/) представлены шаги по воспроизведению 70-80% всего используемого функционала *Keycloak* при администрировании.

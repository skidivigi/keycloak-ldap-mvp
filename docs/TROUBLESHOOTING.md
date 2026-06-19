# TROUBLESHOOTING

## 1. Grafana пишет `login.OAuthLogin(missing saved state)`

Частые причины:

- проблемы с cookie;
- менялся host между `localhost`, `127.0.0.1`, `keycloak`;
- неверный `root_url` в Grafana.

Проверь:

```ini
[server]
root_url = http://localhost:3000/
```

Открывай Grafana именно так:

```text
http://localhost:3000
```

## 2. Keycloak пишет `Invalid parameter: redirect_uri`

Значит Grafana отправила redirect URI, которого нет в client settings.

Проверь в Keycloak:

```text
Clients → grafana → Settings → Valid redirect URIs
```

Должно быть:

```text
http://localhost:3000/login/generic_oauth
```

## 3. Grafana не может обменять code на token

Проверь secret:

```text
Keycloak → Clients → grafana → Credentials
```

Он должен совпадать с:

```ini
client_secret = grafana-secret
```

Также проверь token URL:

```ini
token_url = http://keycloak:8080/realms/company/protocol/openid-connect/token
```

Важно: внутри Docker-сети Grafana обращается к Keycloak по имени сервиса `keycloak`, а браузер — через `localhost`.

## 4. Пользователь вошёл, но получил не ту роль

Проверь роли пользователя:

```text
Users → user → Role mapping
```

Проверь, есть ли роль в токене:

```text
realm_access.roles
```

Проверь Grafana config:

```ini
role_attribute_path = contains(realm_access.roles[*], 'grafana-admin') && 'Admin' || contains(realm_access.roles[*], 'grafana-editor') && 'Editor' || 'Viewer'
```

## 5. Тема не изменилась

Проверь:

```text
Realm settings → Themes → Login theme → company
```

Перезапусти Keycloak:

```bash
docker compose restart keycloak
```

Проверь, что volume подключён:

```bash
docker exec -it keycloak ls -la /opt/keycloak/themes/company
```

## 6. Realm не импортировался

Realm import работает только при первом создании realm. Если realm уже есть в БД, импорт может не примениться.

Самый простой способ пересоздать стенд:

```bash
docker compose down -v
docker compose up -d
```

Осторожно: `-v` удалит volumes Postgres/Grafana/FreeIPA.

## 7. Keycloak не стартует

Смотри логи:

```bash
docker logs -f keycloak
```

Частые причины:

- Postgres ещё не успел подняться;
- ошибка в `realm-export.json`;
- конфликт порта `8080`;
- битый volume.

Проверить порт:

```bash
ss -lntp | grep 8080
```

## 8. FreeIPA не стартует

FreeIPA в контейнере требует больше прав, чем обычный сервис.

Проверь:

```bash
docker logs -f freeipa
```

Частые проблемы:

- Docker Desktop;
- нет privileged;
- проблемы с cgroup;
- занят порт 53/389/636;
- hostname не FQDN.

Проверить занятые порты:

```bash
ss -lntup | egrep ':53|:389|:636|:88|:464'
```

## 9. Keycloak не видит FreeIPA LDAP

Проверь из контейнера Keycloak:

```bash
docker exec -it keycloak bash
```

Внутри:

```bash
getent hosts ipa.company.local
```

Если имени нет — проблема в Docker DNS/aliases.

LDAP URL должен быть:

```text
ldap://ipa.company.local:389
```

## 10. LDAP bind failed

Проверь Bind DN:

```text
uid=admin,cn=users,cn=accounts,dc=company,dc=local
```

Проверь пароль:

```text
Admin123456
```

Проверь, что FreeIPA завершил установку и пользователь admin существует.

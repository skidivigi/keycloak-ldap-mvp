# TROUBLESHOOTING

## 1. Grafana пишет `login.OAuthLogin(missing saved state)`

### Причины

* проблемы с cookie;
* открыт другой URL (`127.0.0.1` вместо `localhost`);
* неверный `root_url`;
* несколько вкладок авторизации одновременно.

### Проверка

Grafana должна открываться через:

```text
http://localhost:3000
```

В `grafana.ini`:

```ini
[server]
root_url = http://localhost:3000/
```

---

## 2. Keycloak пишет `Invalid parameter: redirect_uri`

### Причина

Grafana отправляет callback URL, которого нет в настройках клиента.

### Проверка

```text
Clients
→ grafana
→ Settings
→ Valid Redirect URIs
```

Должно быть:

```text
http://localhost:3000/login/generic_oauth
```

---

## 3. Grafana не может получить token

### Причины

* неверный client secret;
* неверный token endpoint;
* проблемы сети между контейнерами.

### Проверка

```text
Clients
→ grafana
→ Credentials
```

Secret должен совпадать с:

```ini
client_secret = grafana-secret
```

Проверить URL:

```ini
token_url = http://keycloak:8080/realms/company/protocol/openid-connect/token
```

---

## 4. Пользователь вошёл, но получил неправильную роль

### Проверить роль пользователя

```text
Users
→ User
→ Role Mapping
```

---

### Проверить JWT

В токене должен быть:

```json
{
  "realm_access": {
    "roles": [
      "grafana-admin"
    ]
  }
}
```

---

### Проверить Grafana

```ini
role_attribute_path = contains(realm_access.roles[*], 'grafana-admin') && 'Admin' || contains(realm_access.roles[*], 'grafana-editor') && 'Editor' || 'Viewer'
```

---

## 5. Пользователь есть в LDAP, но нет группы в Keycloak

### Симптом

```text
Users импортируются
Groups отсутствуют
```

### Причина

Неправильный Group Mapper.

### Проверить

```text
LDAP Mapper
→ Group Mapper
```

Параметры:

```text
Group Object Classes:
posixGroup

Membership LDAP Attribute:
memberUid

Membership Attribute Type:
UID

User Groups Retrieve Strategy:
LOAD_GROUPS_BY_MEMBER_ATTRIBUTE
```

---

## 6. Пользователь в LDAP группе, но группа не появилась в Keycloak

### Причина

Синхронизация групп не запускалась.

### Решение

```text
User Federation
→ LDAP Provider
→ Synchronize all users
```

или

```text
Synchronize changed users
```

---

## 7. Пользователь попал в группу, но роль не появилась

### Причина

Группе не назначена роль.

### Проверка

```text
Groups
→ grafana-admins
→ Role Mapping
```

Должна быть назначена:

```text
grafana-admin
```

---

## 8. Grafana пишет `User sync failed`

### Причина

Чаще всего отсутствует email.

LDAP пользователь должен содержать:

```text
mail=user@company.local
```

Проверить:

```text
Users
→ User
→ Attributes
```

или напрямую в LDAP.

---

## 9. Grafana пишет `user not found`

### Причина

Пользователь ранее был удалён из Keycloak или Grafana сохранила старый auth_id.

### Решение

Удалить пользователя из Grafana:

```text
Administration
→ Users
→ Delete User
```

После повторного входа пользователь создастся заново.

---

## 10. OTP не появляется

### Проверка

```text
Authentication
→ Required Actions
→ Configure OTP
```

Должно быть:

```text
Enabled
```

Для конкретного пользователя:

```text
Users
→ User
→ Required Actions
```

Должно присутствовать:

```text
Configure OTP
```

---

## 11. WebAuthn не появляется

### Проверка

```text
Authentication
→ Required Actions
→ WebAuthn Register
```

Должно быть:

```text
Enabled
```

---

Проверить credential:

```text
Users
→ User
→ Credentials
```

Ожидается:

```text
Password
WebAuthn
```

---

## 12. Editor всегда получает OTP вместо WebAuthn

### Причина

В Authentication Flow OTP расположен выше WebAuthn.

### Проверка

```text
editor-choice
├── WebAuthn Authenticator
└── OTP Form
```

или наоборот.

Порядок execution влияет на приоритет метода.

---

## 13. Изменения в теме не применяются

### Проверка

```text
Realm Settings
→ Themes
→ Login Theme
```

Должно быть:

```text
company
```

---

Перезапуск:

```bash
docker compose restart keycloak
```

---

Проверить volume:

```bash
docker exec -it keycloak ls -la /opt/keycloak/themes/company
```

---

## 14. Локализация не работает

### Симптом

В `messages_ru.properties` изменены строки, но интерфейс остаётся английским.

### Причина

Realm использует locale:

```text
en
```

а изменения внесены в:

```text
messages_ru.properties
```

---

### Проверка

```text
Realm Settings
→ Localization
```

Параметры:

```text
Internationalization: Enabled
Default Locale: ru
```

---

Либо продублировать строки в:

```text
messages_en.properties
```

---

## 15. Realm import не применяется

### Причина

Realm уже существует в базе данных.

### Решение

Полный пересоздание стенда:

```bash
docker compose down -v
docker compose up -d
```

Внимание:

```text
-v удаляет Postgres volume
```

---

## 16. Keycloak не стартует

Логи:

```bash
docker logs -f keycloak
```

Частые причины:

* Postgres ещё не поднялся;
* ошибка в realm-export.json;
* занят порт 8080;
* повреждён volume.

---

Проверка порта:

```bash
ss -lntp | grep 8080
```

---

## 17. Проверка содержимого JWT

Очень полезно при любой проблеме с ролями.

Получить access token через браузер или DevTools.

Проверить наличие:

```json
{
  "preferred_username": "ivan",
  "email": "ivan@company.local",
  "realm_access": {
    "roles": [
      "grafana-admin"
    ]
  }
}
```

Если claim отсутствует в JWT, приложение его никогда не увидит.

---

## 18. Клиент не видит роли

### Причина

Роль не попала в токен через Client Scope.

### Проверка

```text
Clients
→ grafana
→ Client Scopes
```

или

```text
Clients
→ grafana
→ Client Scopes
→ Evaluate
```

Проверить итоговый JWT и наличие:

```json
realm_access.roles
```

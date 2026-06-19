# Keycloak + OpenLDAP + Grafana Lab

## Цель

Развернуть стенд для изучения:

* LDAP Federation в Keycloak
* OIDC/OAuth2 авторизации
* LDAP групп
* Role Mapping
* User Synchronization
* Troubleshooting Keycloak и Grafana

---

# Архитектура

```text
OpenLDAP
    ↓
Keycloak User Federation
    ↓
Keycloak Groups
    ↓
Realm Roles
    ↓
OIDC Token
    ↓
Grafana
```

Сервисы:

```text
PostgreSQL  - база Keycloak
Keycloak    - Identity Provider
OpenLDAP    - LDAP каталог пользователей
Grafana     - клиент OIDC
```

---

# Этап 1. Развертывание Keycloak

Запущены:

```text
Postgres
Keycloak
Grafana
```

Создан Realm:

```text
company
```

Создан Client:

```text
grafana
```

Параметры клиента:

```text
Protocol: OpenID Connect

Client ID:
grafana

Client Secret:
grafana-secret

Redirect URI:
http://localhost:3000/login/generic_oauth
```

---

# Этап 2. Настройка Grafana OAuth

В Grafana настроен Generic OAuth.

Используем следующие endpoint'ы Keycloak:

```text
Authorization:
http://localhost:8080/realms/company/protocol/openid-connect/auth

Token:
http://keycloak:8080/realms/company/protocol/openid-connect/token

UserInfo:
http://keycloak:8080/realms/company/protocol/openid-connect/userinfo
```

Маппинг ролей:

```ini
role_attribute_path =
contains(realm_access.roles[*], 'grafana-admin')
&& 'Admin'
||
contains(realm_access.roles[*], 'grafana-editor')
&& 'Editor'
||
contains(realm_access.roles[*], 'grafana-viewer')
&& 'Viewer'
||
'Viewer'
```

---

# Этап 3. Настройка OpenLDAP

Структура LDAP:

```text
dc=company,dc=local
├── ou=users
└── ou=groups
```

Созданы пользователи:

```text
ivan
petr
```

Пример пользователя:

```ldif
dn: uid=ivan,ou=users,dc=company,dc=local

objectClass: inetOrgPerson

uid: ivan
cn: Ivan Ivanov
sn: Ivanov

mail: ivan@company.local

userPassword: 123456
```

---

# Этап 4. LDAP Federation

В Keycloak создан LDAP Provider.

Настройки:

```text
Connection URL:
ldap://openldap:389

Bind DN:
cn=admin,dc=company,dc=local

Users DN:
ou=users,dc=company,dc=local

Import Users:
ON

Edit Mode:
READ_ONLY
```

После выполнения:

```text
Sync all users
```

LDAP пользователи появились в Keycloak.

---

# Этап 5. LDAP группы

Созданы группы:

```text
grafana-admins
grafana-viewers
```

Использовалась схема:

```text
objectClass = posixGroup
```

Пример:

```ldif
dn: cn=grafana-admins,ou=groups,dc=company,dc=local

objectClass: posixGroup

cn: grafana-admins

memberUid: ivan
```

```ldif
dn: cn=grafana-viewers,ou=groups,dc=company,dc=local

objectClass: posixGroup

cn: grafana-viewers

memberUid: petr
```

---

# Этап 6. LDAP Group Mapper

Первоначальная настройка не работала.

Причина:

```text
Keycloak ожидал:

groupOfNames
member

Фактически использовалось:

posixGroup
memberUid
```

Исправленная конфигурация:

```text
Mapper Type:
group-ldap-mapper

Group Object Classes:
posixGroup

Membership LDAP Attribute:
memberUid

Membership Attribute Type:
UID

User Groups Retrieve Strategy:
LOAD_GROUPS_BY_MEMBER_ATTRIBUTE
```

После синхронизации группы появились в Keycloak.

---

# Этап 7. Связь групп и ролей

В Keycloak группам назначены роли.

```text
grafana-admins
    ↓
grafana-admin

grafana-viewers
    ↓
grafana-viewer
```

В результате пользователь получает роль автоматически через LDAP группу.

---

# Этап 8. Проверка полного сценария

LDAP:

```text
ivan
    ↓
grafana-admins
```

Keycloak:

```text
grafana-admins
    ↓
grafana-admin
```

OIDC Token:

```json
{
  "realm_access": {
    "roles": [
      "grafana-admin"
    ]
  }
}
```

Grafana:

```text
Role = Admin
```

Аналогично:

```text
petr
    ↓
grafana-viewers
    ↓
grafana-viewer
    ↓
Viewer
```

---

# Найденные проблемы

## Проблема №1

LDAP пользователь не имел email.

Симптом:

```text
User sync failed
```

Логи Grafana:

```text
Error getting email address
```

Решение:

Добавить атрибут:

```ldif
mail: user@example.com
```

---

## Проблема №2

Неверный тип LDAP групп.

Симптом:

```text
Пользователь синхронизируется,
группа не появляется.
```

Причина:

```text
posixGroup
memberUid
```

при настройке под:

```text
groupOfNames
member
```

Решение:

Исправить LDAP Group Mapper.

---

## Проблема №3

Удаление пользователя в Keycloak.

Симптом:

```text
Login failed
User sync failed
```

Причина:

Grafana сохранила старую OAuth-связку пользователя.

После повторной синхронизации LDAP пользователь получил новый внутренний идентификатор в Keycloak.

Решение:

Удалить пользователя через Grafana Admin UI.

```text
Administration
→ Users
→ Delete User
```

После повторного входа Grafana создала пользователя заново.

---

# Итог

В результате был реализован полный enterprise-пайплайн:

```text
OpenLDAP
    ↓
LDAP Federation
    ↓
Keycloak
    ↓
Group Mapping
    ↓
Role Mapping
    ↓
OIDC Token
    ↓
Grafana
```

Отработаны основные задачи администратора Keycloak:

* LDAP Federation
* LDAP Synchronization
* Group Mapping
* Role Mapping
* OIDC Integration
* User Sync
* Troubleshooting OAuth
* Troubleshooting LDAP
* Troubleshooting Grafana
* Работа с токенами и ролями
* Диагностика ошибок авторизации

```
```

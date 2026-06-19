# keycloak-ldap-lab

Учебный стенд для практики с Keycloak, LDAP, OIDC, MFA и Authentication Flows.

```text
OpenLDAP → Keycloak → Grafana
```

---

# Что есть в проекте

```text
keycloak-ldap-lab/
├── docker-compose.yml
├── docs/
│   ├── *.md
├── ldap/
│   └── init.ldif
├── keycloak/
│   ├── themes/company/
│   └── realm-export.json
├── grafana/
│   └── grafana.ini
├── Makefile
└── README.md
```

---

# Архитектура

```text
                ┌──────────┐
                │ OpenLDAP │
                └────┬─────┘
                     │ LDAP
                     ▼
              ┌────────────┐
              │ Keycloak   │
              │ Federation │
              └─────┬──────┘
                    │ OIDC
                    ▼
              ┌────────────┐
              │ Grafana    │
              └────────────┘
```

---

# Порты

| Сервис       | URL                   |
| ------------ | --------------------- |
| Keycloak     | http://localhost:8080 |
| Grafana      | http://localhost:3000 |
| phpLDAPadmin | http://localhost:8082 |
| OpenLDAP     | ldap://localhost:389  |

---

# Быстрый запуск

Запуск стенда:

```bash
docker compose up -d
```

Проверка:

```bash
docker compose ps
docker compose logs -f
```

---

# Доступы

## Keycloak

```text
URL:      http://localhost:8080
Login:    admin
Password: admin
```

---

## Realm

```text
company
```

---

## Grafana

```text
URL:      http://localhost:3000
Login:    admin
Password: admin
```

---

## OpenLDAP

```text
Bind DN:
cn=admin,dc=company,dc=local

Password:
admin
```

---

## phpLDAPadmin

```text
URL:
http://localhost:8082
```

---

# LDAP структура

После импорта LDIF создаётся структура:

```text
dc=company,dc=local
├── ou=users
│   ├── ivan
│   ├── petr
│   └── egor
│
└── ou=groups
    ├── grafana-admins
    ├── grafana-editors
    └── grafana-viewers
```

---

# Загрузка LDAP данных

Импорт структуры:

```bash
make ldap-setup
```

Проверка:

```bash
make ldap-search
```

---

# LDAP группы

Используется тип групп:

```text
posixGroup
```

Пример:

```text
grafana-admins
    └── ivan

grafana-editors
    └── egor

grafana-viewers
    └── petr
```

---

# LDAP Federation

В Keycloak настроен LDAP Provider.

Основные параметры:

```text
Connection URL:
ldap://openldap:389

Users DN:
ou=users,dc=company,dc=local

Bind DN:
cn=admin,dc=company,dc=local

Import Users:
ON

Edit Mode:
READ_ONLY
```

После настройки выполняется:

```text
Sync All Users
```

---

# Авторизация

Схема входа:

```text
Browser
 ↓
Grafana
 ↓
Keycloak
 ↓
OpenLDAP
 ↓
OIDC Token
 ↓
Grafana
```

---

# Роли

LDAP группы импортируются в Keycloak.

Далее группам назначаются Realm Roles:

```text
grafana-admins
    ↓
grafana-admin

grafana-editors
    ↓
grafana-editor

grafana-viewers
    ↓
grafana-viewer
```

---

# Grafana Role Mapping

Grafana получает роли из JWT токена:

```json
{
  "realm_access": {
    "roles": [
      "grafana-admin"
    ]
  }
}
```

Маппинг:

```text
grafana-admin
    ↓
Admin

grafana-editor
    ↓
Editor

default
    ↓
Viewer
```

---

# MFA

В лаборатории реализованы:

```text
Password Authentication
OTP Authentication
WebAuthn Authentication
Role Based MFA
```

---

# Role Based MFA

Настроены разные требования MFA.

```text
Admin
 ↓
Password + WebAuthn

Editor
 ↓
Password + OTP или WebAuthn

Viewer
 ↓
Password only
```

---

# WebAuthn

Поддерживаются:

```text
Windows Hello
Touch ID
Face ID
Passkeys
YubiKey
```

Проверка:

```text
Users
→ Credentials
```

Должен появиться:

```text
WebAuthn Credential
```

---

# Custom Theme

Тема находится:

```text
keycloak/themes/company/
```

Содержит:

```text
login/
├── resources/css
├── messages
└── templates
```

Изучаемые элементы:

```text
CSS
Localization
messages.properties
login.ftl
```

---

# Полезные команды

Запуск:

```bash
make up
```

Остановка:

```bash
make down
```

Просмотр контейнеров:

```bash
make watch
```

LDAP импорт:

```bash
make ldap-setup
```

LDAP поиск:

```bash
make ldap-search
```

Полный сброс:

```bash
make clean
```

---

# Что отрабатывать в лаборатории

## LDAP

* Добавление пользователей
* Добавление групп
* Изменение атрибутов
* Group Mapping
* Federation

## Keycloak

* Realm
* Clients
* Roles
* Groups
* Client Scopes
* Authentication Flows
* OTP
* WebAuthn
* Themes

## OIDC

* Redirect URI
* JWT Token
* Claims
* Scopes
* Mappers

## Troubleshooting

* User Sync Failed
* LDAP Group Mapping
* Invalid Redirect URI
* Missing Email
* MFA Problems
* WebAuthn Problems

---

# Документация

Подробные лабораторные шаги находятся в директории:

```text
docs/
```

Покрываемые темы:

```text
LDAP Federation
LDAP Groups
Role Mapping
OIDC
Grafana Integration
OTP
WebAuthn
Authentication Flows
Role Based MFA
Client Scopes
Theme Customization
Troubleshooting
```

После прохождения всех шагов покрывается большая часть задач, которые обычно встречаются при сопровождении и администрировании Keycloak в корпоративной среде.

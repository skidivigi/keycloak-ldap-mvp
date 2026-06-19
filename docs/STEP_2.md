# Step 2. Multi-Factor Authentication (OTP)

## Цель

Добавить второй фактор аутентификации в Keycloak.

Итоговый сценарий:

```text
LDAP User
    ↓
Password (LDAP)
    ↓
OTP (Keycloak)
    ↓
Grafana
```

---

## Создание отдельного Authentication Flow

Чтобы не изменять стандартный flow Keycloak, был создан новый Browser Flow:

```text
company-browser-otp
```

На основе стандартного:

```text
browser
```

---

## Настройка Flow

Структура flow:

```text
Username Password Form
        ↓
Conditional 2FA
    ├─ Condition - user configured
    ├─ Condition - credential
    └─ OTP Form
```

Параметры:

```text
Username Password Form  → Required
OTP Form                → Required
```

Conditional блок отвечает за проверку наличия настроенного OTP у пользователя.

---

## Назначение Flow

Новый flow назначен для Realm:

```text
Realm Settings
→ Authentication
→ Browser Flow

company-browser-otp
```

После этого все входы через браузер используют новый сценарий аутентификации.

---

## Настройка Required Action

В разделе:

```text
Authentication
→ Required Actions
```

была включена операция:

```text
Configure OTP
```

и установлена как:

```text
Default Action
```

---

## Логика работы

Для нового пользователя:

```text
Логин
    ↓
Пароль
    ↓
OTP отсутствует
    ↓
Настройка OTP
    ↓
Сканирование QR-кода
    ↓
Первый OTP код
    ↓
Успешный вход
```

Для пользователя с уже настроенным OTP:

```text
Логин
    ↓
Пароль
    ↓
OTP код
    ↓
Успешный вход
```

---

## Проверка настройки

После регистрации OTP у пользователя появляются credentials:

```text
Users
→ <user>
→ Credentials
```

Результат:

```text
Password
OTP
```

---

## Поддерживаемые приложения OTP

Для тестирования использовались совместимые TOTP приложения:

```text
Google Authenticator
Microsoft Authenticator
Aegis
Bitwarden
1Password
KeePassXC
```

---

## Итог

Реализована схема корпоративной аутентификации:

```text
OpenLDAP
    ↓
Keycloak Federation
    ↓
Password Authentication
    ↓
OTP Authentication
    ↓
OIDC Token
    ↓
Grafana
```

Пользователь не может получить доступ к Grafana без прохождения второго фактора аутентификации.

# Step 4. MFA Policy by Role / Group

## Цель

Настроить разные сценарии аутентификации в Keycloak в зависимости от роли пользователя.

Итоговая политика:

```text
grafana-admins
    ↓
Password + WebAuthn

grafana-editors
    ↓
Password + OTP или WebAuthn

grafana-viewers
    ↓
Password only
```

---

## Исходная схема

Пользователи приходят из OpenLDAP через Keycloak User Federation.

```text
OpenLDAP
    ↓
Keycloak User Federation
    ↓
LDAP Groups
    ↓
Keycloak Groups
    ↓
Realm Roles
    ↓
Authentication Flow
    ↓
Grafana
```

Используемые группы:

```text
grafana-admins
grafana-editors
grafana-viewers
```

Используемые realm roles:

```text
grafana-admin
grafana-editor
grafana-viewer
```

Связь групп и ролей:

```text
grafana-admins  → grafana-admin
grafana-editors → grafana-editor
grafana-viewers → grafana-viewer
```

---

# Authentication Flow

Создан отдельный Browser Flow:

```text
company-browser-role-mfa
```

Он назначается в realm:

```text
Realm Settings
→ Authentication
→ Browser Flow
→ company-browser-role-mfa
```

---

# Базовая логика

Сначала все пользователи проходят обычную проверку логина и пароля:

```text
Username Password Form
```

Пароль проверяется через LDAP Federation.

После этого Keycloak применяет дополнительные MFA-условия в зависимости от роли пользователя.

---

# Admin Flow

Для администраторов требуется только WebAuthn.

```text
admin-webauthn-required       Conditional
├── Condition - user role     Required
└── WebAuthn Authenticator    Required
```

Настройка условия:

```text
Condition - user role:
grafana-admin
```

Результат:

```text
ivan
    ↓
Password
    ↓
WebAuthn / Passkey
    ↓
Grafana Admin
```

Если у admin-пользователя не зарегистрирован WebAuthn credential, вход не будет завершён.

---

# Editor Flow

Для editor-пользователей разрешены два варианта второго фактора:

```text
OTP
или
WebAuthn
```

Структура flow:

```text
editor-otp-or-webauthn          Conditional
├── Condition - user role       Required
└── editor-choice               Required
    ├── WebAuthn Authenticator  Alternative
    └── OTP Form                Alternative
```

Настройка условия:

```text
Condition - user role:
grafana-editor
```

Результат:

```text
egor
    ↓
Password
    ↓
WebAuthn или OTP
    ↓
Grafana Editor
```

---

## Приоритет второго фактора

Внутри `editor-choice` порядок execution влияет на то, какой метод будет предложен первым.

Если настроено так:

```text
editor-choice
├── WebAuthn Authenticator  Alternative
└── OTP Form                Alternative
```

то Keycloak сначала предложит WebAuthn.

OTP будет доступен как fallback через:

```text
Try another way
```

Если поменять порядок:

```text
editor-choice
├── OTP Form                Alternative
└── WebAuthn Authenticator  Alternative
```

то первым будет предложен OTP.

---

# Viewer Flow

Для viewer-пользователей дополнительный MFA не применяется.

```text
petr
    ↓
Password
    ↓
Grafana Viewer
```

Так как для роли `grafana-viewer` нет отдельного conditional-subflow, пользователь проходит только базовый `Username Password Form`.

---

# Проверка

## Admin

Пользователь:

```text
ivan
```

Группа:

```text
grafana-admins
```

Ожидаемый flow:

```text
Password
↓
WebAuthn
↓
Grafana Admin
```

---

## Editor

Пользователь:

```text
egor
```

Группа:

```text
grafana-editors
```

Ожидаемый flow:

```text
Password
↓
WebAuthn или OTP
↓
Grafana Editor
```

Если у пользователя настроены оба метода, основной метод зависит от порядка execution в `editor-choice`.

---

## Viewer

Пользователь:

```text
petr
```

Группа:

```text
grafana-viewers
```

Ожидаемый flow:

```text
Password
↓
Grafana Viewer
```

---

# Важные нюансы

## 1. MFA зависит от роли

Условие работает не по названию LDAP-группы напрямую, а по роли, которую пользователь получает через группу.

```text
LDAP group
    ↓
Keycloak group
    ↓
Realm role
    ↓
Condition - user role
```

---

## 2. WebAuthn credential должен быть зарегистрирован заранее

Для пользователей, которым требуется WebAuthn, нужно заранее выполнить регистрацию Passkey.

Проверить можно здесь:

```text
Users
→ <user>
→ Credentials
```

Ожидаемый результат:

```text
Password
OTP
WebAuthn
```

---

## 3. OTP должен быть настроен заранее

Если editor должен иметь fallback через OTP, у пользователя должен быть настроен OTP credential.

Проверка:

```text
Users
→ <user>
→ Credentials
```

Ожидаемый результат:

```text
OTP
```

---

## 4. Alternative не всегда означает красивый выбор

Если поставить два execution как `Alternative`, Keycloak выбирает первый доступный метод сверху вниз.

Для возможности переключения используется механизм:

```text
Try another way
```

Поэтому порядок execution важен.

---

# Итог

Реализована ролевая MFA-политика:

```text
Admin
    ↓
Password + WebAuthn

Editor
    ↓
Password + WebAuthn или OTP

Viewer
    ↓
Password only
```

Этот сценарий близок к enterprise-настройкам, где уровень защиты зависит от прав пользователя.

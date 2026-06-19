# Step 3. WebAuthn / Passkeys Authentication

## Цель

Изучить современный способ аутентификации без OTP-кодов на основе стандарта WebAuthn.

Реализовать регистрацию и использование Passkey в Keycloak.

Итоговый сценарий:

```text id="4o6bgt"
OpenLDAP
    ↓
Keycloak Federation
    ↓
Password Authentication
    ↓
WebAuthn Authentication
    ↓
Grafana
```

---

# Что такое WebAuthn

WebAuthn (Web Authentication) — стандарт аутентификации на основе асимметричной криптографии.

При регистрации создаётся пара ключей:

```text id="djlwm4"
Private Key
Public Key
```

Private Key:

```text id="7nuxw6"
Хранится только на устройстве пользователя
```

Public Key:

```text id="vjlwm2"
Хранится в Keycloak
```

В отличие от OTP, общий секрет между сервером и пользователем отсутствует.

---

# Настройка Required Action

В Keycloak включено действие:

```text id="4tb0z2"
Authentication
→ Required Actions
→ WebAuthn Register
```

Параметры:

```text id="g3hbqv"
Enabled = ON
```

---

# Регистрация Passkey

Для тестового пользователя:

```text id="vljjlwm"
Users
→ petr
→ Required Actions
→ WebAuthn Register
```

При следующем входе Keycloak предложил зарегистрировать Passkey.

---

# Используемое устройство

Windows Hello не использовался.

Passkey был сохранён в:

```text id="kgncbo"
iPhone
↓
iCloud Keychain
```

После регистрации Keycloak сохранил публичный ключ пользователя.

---

# Проверка регистрации

После завершения регистрации у пользователя появился новый credential:

```text id="7ye1mu"
Users
→ petr
→ Credentials
```

Результат:

```text id="a2c6x4"
Password
OTP
WebAuthn
```

---

# Процесс аутентификации

При входе происходит следующая последовательность:

```text id="z8dknq"
Grafana
    ↓
Keycloak
    ↓
Запрос challenge
    ↓
Passkey на iPhone
    ↓
FaceID / подтверждение
    ↓
Подпись challenge
    ↓
Keycloak проверяет подпись
    ↓
OIDC Token
    ↓
Grafana
```

---

# Кросс-девайс аутентификация

Passkey был сохранён на телефоне.

Вход выполняется с ПК.

Сценарий:

```text id="wjjlwm"
Browser
    ↓
Use another device
    ↓
QR Code
    ↓
iPhone
    ↓
Face ID
    ↓
Подтверждение входа
```

Bluetooth используется только для подтверждения близости устройств.

Секретные ключи по Bluetooth не передаются.

---

# Отличия OTP и WebAuthn

## OTP

```text id="i9y0fg"
Keycloak
    ↕
Shared Secret
    ↕
Google Authenticator
```

Секрет присутствует на обеих сторонах.

---

## WebAuthn

```text id="vuk49h"
Keycloak
    ↓
Public Key

Пользователь
    ↓
Private Key
```

Private Key никогда не покидает устройство пользователя.

---

# Преимущества WebAuthn

```text id="3fbjlwm"
Нет общих секретов
Нет кодов OTP
Защита от фишинга
Поддержка TouchID
Поддержка FaceID
Поддержка Windows Hello
Поддержка YubiKey
Поддержка Passkeys
```

---

# Итог

Реализована современная схема MFA на базе WebAuthn.

Пользователь может использовать:

```text id="qjlwm5"
iPhone Passkey
Windows Hello
Touch ID
Face ID
YubiKey
```

для подтверждения входа вместо OTP-приложения.

Получен практический опыт настройки:

```text id="6i3o6z"
WebAuthn Register
Passkeys
Required Actions
Credentials
Cross-device authentication
```

в Keycloak.

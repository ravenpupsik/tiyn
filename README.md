# Tiyn

Учёт денег на Flutter.

## Скачать

Готовые APK лежат в [релизе v1.0.0](https://github.com/ravenpupsik/tiyn/releases/tag/v1.0.0):

- [tiyn-classic-1.0.0.apk](https://github.com/ravenpupsik/tiyn/releases/download/v1.0.0/tiyn-classic-1.0.0.apk) — основная версия
- [tiyn-glina-1.0.0.apk](https://github.com/ravenpupsik/tiyn/releases/download/v1.0.0/tiyn-glina-1.0.0.apk) — альтернативный дизайн «Глина»

Это две разные программы, они устанавливаются рядом. Данные между ними не общие: перенос через Настройки → Данные → бэкап и восстановление .json.

## Две версии

В этом репозитории две отдельные версии, каждая собирается сама:

- `classic` — основная, шрифт Doto, красный акцент, `applicationId` `com.moneycash.money_app`, имя «Tiyn»
- `glina` — редизайн «Глина», `applicationId` `com.moneycash.money_app.glina`, имя «Tiyn Глина»

## Сборка

```bash
cd classic && flutter pub get && flutter build apk --release
```

То же для `glina`.

## Важно

При смене версии `versionCode` должен расти, а данные (SharedPreferences) сохраняются. Перед переустановкой сделай бэкап в Настройках.

Бэкап `.json` (`app:"tiyn"`, `version:1`) совместим между версиями.

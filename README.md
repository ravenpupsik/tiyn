# Tiyn

Учёт денег на Flutter.

## Две версии

В этом репозитории две отдельные версии, каждая собирается сама:

- `classic` — основная, шрифт Doto, красный акцент
- `glina` — редизайн «Глина»

У обеих один `applicationId` `com.moneycash.money_app`, поэтому на телефоне одновременно стоит только одна.

## Сборка

```bash
cd classic && flutter pub get && flutter build apk --release
```

То же для `glina`.

## Важно

При смене версии `versionCode` должен расти, а данные (SharedPreferences) сохраняются. Перед переустановкой сделай бэкап в Настройках.

Бэкап `.json` (`app:"tiyn"`, `version:1`) совместим между версиями.

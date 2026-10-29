# Mobil kassa (Flutter)

1C:UNF 3.0 bilan ishlaydigan kassir ilovasi. 1C tomoni: `../HTTPServices` (rasshireniya), yo'riqnoma `../YORIQNOMA.md`.

## Imkoniyatlar
- Kirish: server manzili, login/parol, so'ng organizatsiya, ombor, KKM va narx turi tanlanadi.
- Kassa: nom yoki shtrix-kod bo'yicha qidiruv, savat, to'lov (naqd/karta, qaytim).
- Chekni to'liq urish yoki otlojenniy qoldirish.
- Tovarlar: qidiruv, qoldiq va narx.
- Cheklar: ro'yxat (bugun / 7 kun / 30 kun), chek ustiga bosilsa tovarlar, soni, narxi va summasi; otlojenniy chekni keyin urish mumkin.
- Bluetooth HID skaner: qidiruv maydoni tanlangan bo'lsa, skaner yozgan shtrix-kod + Enter tovarni o'zi savatga qo'shadi.

## Yig'ish
1. Flutter SDK va Android Studio (Android SDK) o'rnating, `flutter doctor` yashil bo'lsin.
2. `app` papkasida: `.\prepare_android.ps1`
3. Tekshirish: `flutter analyze`
4. Telefonda sinash: `flutter run`
5. APK: `flutter build apk --release` (natija: `build\app\outputs\flutter-apk\app-release.apk`)

## Eslatmalar
- Parol chiqishda o'chadi, kirgan paytda sozlamalar bilan birga qurilma xotirasida turadi.
- `http://` manzil uchun skript Android'da ochiq trafikka ruxsat beradi; `https://` ishlatsangiz, `usesCleartextTraffic` ni olib tashlang.

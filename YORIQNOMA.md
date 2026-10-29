# Mobil kassa: 1C tomoni (2-etap)

## 1. Rasshireniyani yuklash
1. Konfigurator: `Konfiguratsiya` > `Konfiguratsiya rasshireniyalari` > `Qo'shish`.
2. `Fayllardan yuklash...` (Загрузить из файлов) tugmasi bilan shu papkani tanlang (`D:\Mob Kassa`).
3. Rasshireniyada "Xavfsiz rejim" va "Himoya" belgilarini olib tashlang, `F7` bilan saqlang, so'ng `F5` bilan bazani yangilang.
4. Foydalanuvchiga `Расш1_ОсновнаяРоль` rolini bering (UNF dagi kassir roli bilan birga).

## 2. Publikatsiya
Konfigurator: `Администрирование` > `Публикация на веб-сервере`. Nom: `unf`. Ro'yxatda `HTTP-сервисы` bo'limida `Расш1_МобильнаяКасса` belgilangan bo'lsin.
Namuna: [Publikatsiya/default.vrd](Publikatsiya/default.vrd). `ib=` qatorini o'z bazangizga moslang.

Autentifikatsiya: Basic (1C foydalanuvchi nomi va paroli).

## 3. Tekshirish (brauzerda)
`https://SERVER/unf/hs/mobkassa/info` ochilsa, JSON ro'yxat (organizatsiya, ombor, kassa, narx turi) chiqadi.

| So'rov | Vazifa |
|---|---|
| `GET /info` | Organizatsiya, ombor, KKM, narx turlari |
| `GET /products?q=cola&warehouse=ID&pricetype=ID` | Nom bo'yicha qidiruv, qoldiq va narx |
| `GET /products?barcode=4780001234567` | Shtrix-kod bo'yicha |
| `GET /receipts?from=2026-10-01&to=2026-10-24` | Cheklar ro'yxati |
| `GET /receipts/{id}` | Chek tarkibi: tovar, soni, narx, summa |
| `POST /receipts` | Chek yaratish. `deferred:true` bo'lsa otlojenniy, aks holda to'liq (provodka) |
| `POST /receipts/{id}/post` | Otlojenniy chekni to'liq urish |
| `GET /top?from=2026-10-01&to=2026-10-24` | Top tovarlar va top sotuvchilar (summalar bilan), jami savdo, cheklar soni, o'rtacha chek |

| `POST /receipts/{id}/return` | Chekni qaytarish (`ЧекККМВозврат`). `lines:[{lineNumber,quantity}]` bo'lsa qisman, bo'sh bo'lsa to'liq |
| `GET /cost?id=GUID` | Zakup narxi (faqat ruxsat berilgan foydalanuvchilarga, aks holda 403) |
| `GET /diag` | Chek va smena rekvizitlari (sozlash uchun) |

## Zakup narxiga ruxsat
Svayp bilan zakup narxini ko'rish faqat registrga kiritilgan foydalanuvchilarga ishlaydi. Registr: **«Доступ к закупочной цене (Mobil kassa)»** (`Расш1_ДоступКЗакупочнойЦене`). Unga foydalanuvchini qo'shing va «Разрешено» belgisini qo'ying. Registrni administrator (to'liq huquq) ochadi: «Все функции» > «Регистры сведений». Oddiy foydalanuvchilarga rasshireniya roli registrga huquq bermaydi.
Zakup narxi sifatida narxlar registridagi nomida «закуп» so'zi bor narx turining oxirgi narxi olinadi (`ШаблонЗакупочногоТипаЦен` funksiyasida o'zgartiriladi).

`/top` faqat provodka qilingan cheklarni hisoblaydi. Sotuvchi sifatida chekning `Ответственный` (yoki `Автор`) rekviziti olinadi; ikkalasi ham yo'q bo'lsa, sotuvchilar ro'yxati bo'sh qaytadi.

`POST /receipts` tanasi:
```json
{"organization":"GUID","warehouse":"GUID","cashRegister":"GUID","priceType":"GUID",
 "deferred":false,"lines":[{"id":"GUID","quantity":2,"price":9500}]}
```

## 4. Muhim eslatmalar
- Obyekt va rekvizit nomlari UNF 3.0 ga qarab yozilgan, lekin sizning bazangizda sinab ko'rilmagan. Xato bo'lsa `/info` yoki `/products` javobidagi `error` matnini yuboring, tuzataman. Barcha nomlar [Module.bsl](HTTPServices/Расш1_МобильнаяКасса/Ext/Module.bsl) ning `Настройки` bo'limida.
- Server chekni 1C da hujjat sifatida yaratadi va provodka qiladi. Fiskal qurilma (KKM) bilan chop etish 1C ning o'zida sozlangan "Чек ККМ" mexanizmiga bog'liq; qurilmaga to'g'ridan-to'g'ri yuborish uchun alohida sozlash kerak bo'lishi mumkin.
- To'lov turi (naqd/karta) hujjatning to'lov maydonlariga hozircha yozilmaydi; birinchi sinovdan keyin maydon nomlarini aniqlab ulaymiz.

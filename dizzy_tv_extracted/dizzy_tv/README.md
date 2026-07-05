# Dizzy.tv — Flutter kino ilovasi

## ✅ Hozir tayyor bo'lgan qism (1-bosqich)

- Loyiha tuzilishi (`lib/models`, `lib/services`, `lib/screens`, `lib/widgets`, `lib/theme`)
- Login (email/parol + Google), Ro'yxatdan o'tish
- Bosh sahifa: banner slider, Trend/Yangi/Mashhur/Tavsiya bo'limlari (Firestore'dan jonli oqim)
- Admin login (alohida, xavfsiz, role tekshiruvi bilan) + Admin dashboard (statistika, so'nggi kinolar)
- Dizzy.tv logotipi ("D" harfli, qizil-qora uslub)

## 🔜 Keyingi bosqichlarda quriladi

- Qidiruv ekrani (filtrlar: janr, yil, reyting, davlat, sifat)
- Kino tafsiloti ekrani + to'liq ekran video pleyer (Cloudflare R2 dan)
- Saqlanganlar, Profil, Sozlamalar ekranlari
- Admin: Kino qo'shish/tahrirlash (poster yuklash, video URL), Banner CRUD, Janr CRUD

---

## 🤖 Android loyihasini yaratish (MUHIM — birinchi marta kerak)

Bu zip faylida faqat Dart kodi (`lib/` papkasi) bor — Android'ning o'zi uchun kerak
bo'ladigan `android/` papkasi hali yo'q. Buni **kompyuteringizda** (Flutter o'rnatilgan
joyda) bir marta quyidagicha yaratasiz:

1. Loyiha papkasiga kiring:
   ```bash
   cd dizzy_tv
   ```
2. Android/iOS papkalarini avtomatik generatsiya qiling (bu `lib/` va `pubspec.yaml`
   ga tegmaydi, faqat yetishmayotgan qismlarni qo'shadi):
   ```bash
   flutter create --org com.dizzytv --project-name dizzy_tv .
   ```
3. `android_setup_files/app/google-services.json` faylini nusxalab,
   `android/app/google-services.json` ga joylashtiring (bu — Firebase'ga ulanish
   uchun tayyor fayl, sizning `isobek-b1c1f` loyihangizdan olingan haqiqiy ma'lumot).
4. `android/build.gradle.kts` (yoki `android/build.gradle`) faylining eng oxiriga
   qo'shing:
   ```kotlin
   buildscript {
       dependencies {
           classpath("com.google.gms:google-services:4.4.2")
       }
   }
   ```
5. `android/app/build.gradle.kts` (yoki `.gradle`) faylining eng yuqorisiga, `plugins {}`
   blokiga qo'shing:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```
6. Shu faylda `applicationId` qatorini toping va shunga o'zgartiring (bizning
   `google-services.json` shu paket nomiga mo'ljallangan):
   ```kotlin
   applicationId = "com.dizzytv.app"
   ```
7. `minSdk` ni kamida 23 ga qo'ying (Firebase talabi):
   ```kotlin
   minSdk = 23
   ```
8. Endi o'rnatish va ishga tushirish:
   ```bash
   flutter pub get
   flutter run
   ```

Agar 2-qadamdagi buyruq xatolik bersa yoki fayllarning aniq joylashuvi (`.gradle`
yoki `.gradle.kts`) farq qilsa — xato matnini menga tashlang, aniq qaysi qatorga
nima yozish kerakligini ko'rsataman.

---



```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
```

`flutterfire configure` sizning Firebase loyihangizni tanlab, `lib/firebase_options.dart`
faylini avtomatik to'g'ri ma'lumotlar bilan almashtiradi.

## 🔥 Firebase sozlamalari

1. **Authentication** → Email/Password va Google Sign-In'ni yoqing.
2. **Firestore Database** → quyidagi kolleksiyalarni yarating:
   - `users` — `{email, name, photoUrl, role, savedMovieIds[], historyMovieIds[]}`
   - `movies` — `{title, description, posterUrl, bannerUrl, videoUrl, year, genres[], country, rating, durationMinutes, quality, viewsCount, isActive, isBanner, isTrending, isNew, isPopular, isRecommended, createdAt}`
   - `genres` — `{name, order}`
3. **Storage** → posterlar va bannerlar shu yerga yuklanadi.

## 👤 Admin hisobini yaratish

Admin login/parol kodda **hech qachon yozilmaydi** — bu xavfsizsiz bo'lardi. Buning
o'rniga admin hisobi Firebase orqali quyidagicha yaratiladi:

1. Firebase Console → Authentication → **Add user**:
   - Email: `admin@dizzytv.uz`
   - Parol: o'zingiz kiriting (masalan kuchli, kamida 10 belgili parol — harf+raqam+belgi)
2. Firestore → `users` kolleksiyasida shu user'ning **UID**'i bilan hujjat yarating:
   ```json
   {
     "email": "admin@dizzytv.uz",
     "name": "Admin",
     "role": "admin",
     "savedMovieIds": [],
     "historyMovieIds": []
   }
   ```
3. Ilovada admin panelga kirish uchun `/admin` route'iga o'ting (masalan sozlamalar
   ekraniga yashirin tugma qo'yamiz keyingi bosqichda, yoki to'g'ridan-to'g'ri
   `Navigator.pushNamed(context, '/admin')`).

`role: "admin"` bo'lmagan hech qanday hisob admin panelga kira olmaydi —
buni `AuthService.adminLogin()` avtomatik tekshiradi va rad etadi.

## 🎬 Cloudflare R2 (videolar)

- Videolarni R2 bucket'ga yuklang, **public URL** yoki signed URL oling.
- Kino qo'shishda shu URL `videoUrl` maydoniga yoziladi.
- Pleyer `video_player` + `chewie` paketlari orqali ishlaydi (to'liq ekran,
  progress bar, resume — keyingi bosqichda qo'shiladi).

---

Savol yoki keyingi bosqichga (qidiruv / kino tafsiloti / video pleyer / to'liq
admin CRUD) o'tishni xohlasangiz — shunchaki ayting.

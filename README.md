# İşini Gör

Kullanıcının işini tarif ettiği, ekibin fiyatlandırdığı, kullanıcının onayladığı
hizmet talep uygulaması. Lastik değişimi, araç bakımı, köpek gezdirme, temizlik,
tesisat gibi işler için.

## Akış

1. Kullanıcı **Google ile giriş** yapar.
2. Bir kategori seçip **işini tanımlar** (başlık, detay, adres, telefon, tarih/saat).
3. Talep kaydedilir → durum **`pending`** (Talep Alındı).
4. Admin panelinden **fiyat girilir** → durum **`priced`**, kullanıcıya
   *"İşiniz tanımlandı"* bildirimi düşer.
5. Kullanıcı **Kabul Et / Reddet** der:
   - Kabul → **`accepted`**, ekip işi üstlenir (`inProgress` → `completed`).
   - Reddet → **`rejected`**, iş kapanır.

Durumlar: `pending` · `priced` · `accepted` · `inProgress` · `completed` ·
`rejected` · `cancelled` — hepsi [lib/models/job.dart](lib/models/job.dart)
içinde, etiket/açıklama/ilerleme değerleriyle.

## Ekranlar

| Ekran | Dosya |
| --- | --- |
| Google ile giriş | [lib/screens/login_screen.dart](lib/screens/login_screen.dart) |
| Alt sekme iskeleti | [lib/screens/shell_screen.dart](lib/screens/shell_screen.dart) |
| Ana sayfa (kategoriler, onay bekleyenler) | [lib/screens/home_tab.dart](lib/screens/home_tab.dart) |
| İş oluşturma formu | [lib/screens/create_job_screen.dart](lib/screens/create_job_screen.dart) |
| İşlerim (Aktif / Geçmiş) | [lib/screens/my_jobs_screen.dart](lib/screens/my_jobs_screen.dart) |
| İş detayı + kabul/reddet + geçmiş | [lib/screens/job_detail_screen.dart](lib/screens/job_detail_screen.dart) |
| Bildirimler | [lib/screens/notifications_screen.dart](lib/screens/notifications_screen.dart) |
| Profil | [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart) |

## Şu anki durum

Veri **bellekte** tutuluyor ([lib/services/job_repository.dart](lib/services/job_repository.dart)),
giriş de taklit ediliyor ([lib/services/auth_service.dart](lib/services/auth_service.dart)).
Uygulama örnek verilerle açılıyor, tüm akış uçtan uca denenebiliyor.

Admin paneli henüz olmadığı için iki geçici yol var:

- Yeni talepler `demoPricingDelay` (8 sn) sonra otomatik fiyatlanır
  (`JobRepository.demoAutoPricing`).
- İş detayında **"Demo: admin fiyat girsin"** butonuyla fiyat elle girilebilir.

Panel yazılınca ikisi de silinecek.

## Firebase'e geçiş

Ekranlar değişmeyecek; sadece iki servisin gövdesi değişecek. Kodda
`TODO(firebase)` ile işaretli yerler:

- `main.dart` → `Firebase.initializeApp`
- `auth_service.dart` → `google_sign_in` + `FirebaseAuth`
- `job_repository.dart` → Firestore `jobs` koleksiyonu ve FCM push

`Job.toMap()` / `Job.fromMap()` ve `AppUser.toMap()` / `fromMap()` zaten
Firestore dokümanı formatında hazır.

## Çalıştırma

```bash
flutter pub get
flutter run

flutter analyze
flutter test
```

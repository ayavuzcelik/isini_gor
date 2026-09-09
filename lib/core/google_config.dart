/// Google Sign-In için Web OAuth istemci kimliği.
///
/// google_sign_in 7.x Android'de bunu zorunlu tutuyor: Firebase'in kabul
/// ettiği idToken ancak bu "server client id" ile üretiliyor.
///
/// Değer Firebase'in Google sağlayıcısı açılınca otomatik oluşturduğu
/// web istemcisinden geliyor; `android/app/google-services.json` içinde
/// `client_type: 3` olan kayıt. Gizli bir bilgi değil, APK içinde zaten
/// dağıtılıyor.
///
/// Projeyi değiştirirsen:
///   `firebase apps:sdkconfig android <appId> --project <projectId>`
const googleServerClientId =
    '728742801164-28c9etfta4bl4olb2ks09egne0g51a6m.apps.googleusercontent.com';

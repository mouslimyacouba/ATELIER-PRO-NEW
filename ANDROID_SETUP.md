# 📱 Configuration Android - AtelierPro

## ✅ Fichiers de Configuration Présents

- ✅ `android/app/google-services.json` - Configuration Firebase Android
- ✅ `android/app/build.gradle.kts` - Configuration build Android
- ✅ `.env` - Variables d'environnement
- ✅ `lib/firebase_options.dart` - Options Firebase

## 🔧 Configuration Requise pour Build Android

### 1️⃣ Installer Java JDK

**Windows** :
```bash
# Via Chocolatey (recommandé)
choco install openjdk

# Ou télécharger depuis :
# https://www.oracle.com/java/technologies/downloads/
```

**Vérifier l'installation** :
```bash
java -version
javac -version
```

**Définir JAVA_HOME** :
```powershell
# Ajouter à Environment Variables
setx JAVA_HOME "C:\Program Files\Java\jdk-17"
```

### 2️⃣ Configuration Android SDK

**Vérifier ANDROID_HOME** :
```bash
echo %ANDROID_HOME%
# Devrait afficher : C:\Users\[user]\AppData\Local\Android\sdk
```

**Si absent** :
```powershell
setx ANDROID_HOME "C:\Users\%USERNAME%\AppData\Local\Android\sdk"
```

### 3️⃣ Vérifier les empreintes de signature Android

```bash
# Depuis la racine du projet
cd android
.\gradlew.bat signingReport
```

Relever les empreintes SHA-1 et SHA-256 des variantes `debug` et `release`.
Le chemin `storeFile` dans `android/key.properties` est relatif au dossier
`android/`; la clé release utilisée dans ce projet est `android/upload-keystore.jks`.

### 4️⃣ Enregistrer les empreintes dans Firebase

1. Aller sur https://console.firebase.google.com
2. Sélectionner projet "atelier-pro-1a9e8"
3. Paramètres → Vos apps → Android app
4. Ajouter les SHA-1 et SHA-256 de chaque certificat réellement utilisé.
   Pour Google Play, ajouter aussi les empreintes du certificat **App signing**
   affiché dans Play Console (il peut être différent de la clé d'upload).
5. Dans Authentication → Méthode de connexion, vérifier que Google est activé.

### 5️⃣ Vérifier google-services.json

Le package Android doit être `com.zinderdigital.atelierpro_mobile`. Le client
OAuth Web doit correspondre à `FIREBASE_WEB_CLIENT_ID` dans `.env`; l'application
l'utilise comme `serverClientId` pour obtenir l'ID token Firebase sur Android.
Le `certificate_hash` d'un ancien `google-services.json` ne remplace pas
l'enregistrement des empreintes actuelles dans Firebase Console / Google Cloud.

```bash
# Le fichier doit être à :
android/app/google-services.json

# Vérifier qu'il contient :
# - project_id: "atelier-pro-1a9e8"
# - package_name: "com.zinderdigital.atelierpro_mobile"
# - API Key
```

### 6️⃣ Build Android

```bash
# Test build debug
flutter build apk --debug

# Build release (si vous avez configuré la clé release)
flutter build apk --release
```

## 🆘 Troubleshooting Android

### ❌ Error: JAVA_HOME is not set

**Solution** :
1. Installer Java JDK
2. Définir JAVA_HOME dans Environment Variables
3. Redémarrer le terminal

### ❌ Erreur : "Gradle build failed"

```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter build apk --debug -v
```

### ❌ Erreur : "Failed to resolve: com.google.gms:google-services"

**Solution** : Vérifier que `google-services.json` existe et est valide

### ❌ Erreur Firebase : "MissingPluginException"

```bash
# Reconstruire l'app
flutter clean
flutter pub get
flutter run  # ou flutter build apk
```

## 📋 Checklist Android

- [x] `.env` présent avec clés Firebase
- [x] `google-services.json` présent
- [x] `firebase_options.dart` créé
- [ ] Java JDK installé
- [ ] JAVA_HOME défini
- [ ] ANDROID_HOME défini
- [ ] SHA-1 debug trouvé avec `gradlew signingReport`
- [ ] SHA-1 ajouté dans Firebase Console
- [ ] Build debug test réussi
- [ ] Test sur émulateur/appareil

## 🚀 Build & Run Android

### Test Debug sur Émulateur

```bash
# Lancer émulateur
emulator -avd Pixel_5_API_30

# Ou lancer via Android Studio : AVD Manager

# Builder et run
flutter run

# Ou
flutter run -d emulator-5554
```

### Test Debug sur Appareil Physique

```bash
# Activer le débogage USB sur l'appareil
# Paramètres → À propos → Appuyer 7x sur "Numéro de build"
# → Paramètres → Options pour développeurs → USB Debugging ON

# Connecter l'appareil via USB

# Lister les appareils
flutter devices

# Run
flutter run -d [device-id]
```

### Build Release APK

```bash
# Compiler en release
flutter build apk --release

# APK générée à :
# build/app/outputs/flutter-apk/app-release.apk

# Installer sur appareil
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 📱 Configuration Google Sign-In Android

Firebase est initialisé ici avec `FirebaseOptions` côté Flutter; le plugin
Gradle `google-services` n'est donc pas appliqué. Ne déduisez pas le certificat
utilisé par l'APK release depuis le `certificate_hash` d'un JSON local. Utilisez
`signingReport`, puis enregistrez les empreintes de la clé release dans Firebase
Console. `FIREBASE_WEB_CLIENT_ID` doit être le client OAuth de type Web du même
projet Firebase.

⚠️ **Important** : le type de build `release` est signé avec la clé release
définie dans `android/key.properties`. N'utilisez pas une clé debug pour une
distribution de production. Après un changement de certificat, Android peut
exiger de désinstaller l'ancienne APK avant d'installer la nouvelle.

## 🔐 Clés de Signature

### Debug (pour développement)

- **Alias** : androiddebugkey
- **Keystore** : `~/.android/debug.keystore`
- **Mot de passe** : android
- **Validité** : Illimitée

### Release (pour production)

- **Fichier** : `android/upload-keystore.jks`
- **Alias** : upload
- **Passwords** : Voir `android/key.properties`

## 📊 Informations Build

| Item | Value |
|------|-------|
| **Package Name** | com.zinderdigital.atelierpro_mobile |
| **Version** | 1.0.0 |
| **Min SDK** | 21 (Android 5.0) |
| **Target SDK** | 34 (Android 14) |
| **Build Type** | Debug / Release |
| **Project ID** | atelier-pro-1a9e8 |

## 🎯 Next Steps

1. **Installer Java JDK** ← PRIORITÉ
2. **Définir JAVA_HOME**
3. **Exécuter `gradlew signingReport`**
4. **Ajouter SHA-1 et SHA-256 debug/release à Firebase**
5. **Test build debug**
6. **Déployer sur appareil**

## 📞 Support

Si vous rencontrez des problèmes :

```bash
# Voir les logs détaillés
flutter run -v

# Ou
flutter build apk --debug -v
```

---

**Note** : La clé release (`upload-keystore.jks`) est déjà configurée pour les builds production (voir `android/key.properties`).

# --- Google ML Kit (text + digital ink recognition) ---
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**

# ML Kit text recognizer language options referenced but not bundled.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# --- WorkManager (ML Kit uses it to download on-device models) ---
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# --- App Startup initializers (WorkManager auto-init runs at app launch) ---
-keep class androidx.startup.** { *; }
-keep class * implements androidx.startup.Initializer { *; }

# --- Room (WorkManager's WorkDatabase is a Room DB whose generated *_Impl
#     classes are loaded by reflection; must not be renamed/removed) ---
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class **_Impl { *; }
-keep @androidx.room.Entity class * { *; }
-dontwarn androidx.room.**

# --- SQLite framework used by Room ---
-keep class androidx.sqlite.** { *; }
-dontwarn androidx.sqlite.**

class BibleTranslation {
  final String id;
  final String label;
  final String assetPath;

  const BibleTranslation({
    required this.id,
    required this.label,
    required this.assetPath,
  });

  static const kjv = BibleTranslation(
    id: 'kjv',
    label: 'KJV',
    assetPath: 'Bible.json',
  );

  static const akjv = BibleTranslation(
    id: 'akjv',
    label: 'AKJV',
    assetPath: 'translations/AKJV.json',
  );

  static const amp = BibleTranslation(
    id: 'amp',
    label: 'AMP',
    assetPath: 'translations/AMP.json',
  );

  static const asv = BibleTranslation(
    id: 'asv',
    label: 'ASV',
    assetPath: 'translations/ASV.json',
  );

  static const brg = BibleTranslation(
    id: 'brg',
    label: 'BRG',
    assetPath: 'translations/BRG.json',
  );

  static const csb = BibleTranslation(
    id: 'csb',
    label: 'CSB',
    assetPath: 'translations/CSB.json',
  );

  static const ehv = BibleTranslation(
    id: 'ehv',
    label: 'EHV',
    assetPath: 'translations/EHV.json',
  );

  static const esv = BibleTranslation(
    id: 'esv',
    label: 'ESV',
    assetPath: 'translations/ESV.json',
  );

  static const all = [
    kjv,
    akjv,
    amp,
    asv,
    brg,
    csb,
    ehv,
    esv,
  ];

  static BibleTranslation fromId(String id) {
    for (final translation in all) {
      if (translation.id == id) {
        return translation;
      }
    }
    return kjv;
  }
}

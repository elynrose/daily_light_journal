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

  static const esvuk = BibleTranslation(
    id: 'esvuk',
    label: 'ESVUK',
    assetPath: 'translations/ESVUK.json',
  );

  static const gnv = BibleTranslation(
    id: 'gnv',
    label: 'GNV',
    assetPath: 'translations/GNV.json',
  );

  static const gw = BibleTranslation(
    id: 'gw',
    label: 'GW',
    assetPath: 'translations/GW.json',
  );

  static const isv = BibleTranslation(
    id: 'isv',
    label: 'ISV',
    assetPath: 'translations/ISV.json',
  );

  static const jub = BibleTranslation(
    id: 'jub',
    label: 'JUB',
    assetPath: 'translations/JUB.json',
  );

  static const kj21 = BibleTranslation(
    id: 'kj21',
    label: 'KJ21',
    assetPath: 'translations/KJ21.json',
  );

  static const leb = BibleTranslation(
    id: 'leb',
    label: 'LEB',
    assetPath: 'translations/LEB.json',
  );

  static const lsb = BibleTranslation(
    id: 'lsb',
    label: 'LSB',
    assetPath: 'translations/LSB.json',
  );

  static const mev = BibleTranslation(
    id: 'mev',
    label: 'MEV',
    assetPath: 'translations/MEV.json',
  );

  static const nasb = BibleTranslation(
    id: 'nasb',
    label: 'NASB',
    assetPath: 'translations/NASB.json',
  );

  static const nasb1995 = BibleTranslation(
    id: 'nasb1995',
    label: 'NASB1995',
    assetPath: 'translations/NASB1995.json',
  );

  static const net = BibleTranslation(
    id: 'net',
    label: 'NET',
    assetPath: 'translations/NET.json',
  );

  static const niv = BibleTranslation(
    id: 'niv',
    label: 'NIV',
    assetPath: 'translations/NIV.json',
  );

  static const nivuk = BibleTranslation(
    id: 'nivuk',
    label: 'NIVUK',
    assetPath: 'translations/NIVUK.json',
  );

  static const nkjv = BibleTranslation(
    id: 'nkjv',
    label: 'NKJV',
    assetPath: 'translations/NKJV.json',
  );

  static const nlt = BibleTranslation(
    id: 'nlt',
    label: 'NLT',
    assetPath: 'translations/NLT.json',
  );

  static const all = [
    akjv,
    amp,
    asv,
    brg,
    csb,
    ehv,
    esv,
    esvuk,
    gnv,
    gw,
    isv,
    jub,
    kj21,
    kjv,
    leb,
    lsb,
    mev,
    nasb,
    nasb1995,
    net,
    niv,
    nivuk,
    nkjv,
    nlt,
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

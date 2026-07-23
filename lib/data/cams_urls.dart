String camCodeFromUrl(String url) {
  final fileName = url.split('/').last;
  return fileName.split('.').first;
}

String buildHistoryUrl(String camCode, DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  final datePart = '${time.year}${two(time.month)}${two(time.day)}';
  final timePart = '${two(time.hour)}${two(time.minute)}';
  return 'https://pogoda.topr.pl/download/history/$datePart/${camCode}_${datePart}_$timePart.jpeg';
}

const Map<String, String> imagesUrls = {
  "Morskie Oko: Rysy": "https://pogoda.topr.pl/download/current/mors.jpeg",
  "Morskie Oko: Mnich": "https://pogoda.topr.pl/download/current/momn.jpeg",
  "Dolina Pięciu Stawów: Stawy": "https://pogoda.topr.pl/download/current/psps.jpeg",
  "Dolina Pięciu Stawów: Granaty": "https://pogoda.topr.pl/download/current/psdb.jpeg",
  "Hala Gąsienicowa: Granaty": "https://pogoda.topr.pl/download/current/hala.jpeg",
  "Hala Gąsienicowa: Kasprowy Wierch": "https://pogoda.topr.pl/download/current/hgkw.jpeg",
  "Kasprowy Wierch: Świnica": "https://pogoda.topr.pl/download/current/kwgs.jpeg",
  "Kasprowy Wierch: Giewont": "https://pogoda.topr.pl/download/current/kwgr.jpeg",
  "Dolina Chochołowska: Wołowiec": "https://pogoda.topr.pl/download/current/dcho.jpeg",
  "Dolina Chochołowska: Kominiarski Wierch": "https://pogoda.topr.pl/download/current/dch2.jpeg",
  "Tatry Wysokie (Czarna Góra)":
  "https://pogoda.topr.pl/download/current/czgr.jpeg",
  "Tatry Zachodnie (Kościelisko)":
  "https://pogoda.topr.pl/download/current/kscw.jpeg",
};
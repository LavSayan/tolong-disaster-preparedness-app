// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'TolongApp';

  @override
  String get tagline => 'Laging handa, laging kalmado.';

  @override
  String get back => 'Bumalik';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get save => 'I-save';

  @override
  String get remove => 'Alisin';

  @override
  String get edit => 'I-edit';

  @override
  String get next => 'Susunod';

  @override
  String get skipForNow => 'Laktawan muna';

  @override
  String get ok => 'OK';

  @override
  String get comingSoon => 'Malapit na';

  @override
  String get notSet => 'Hindi pa nakatakda';

  @override
  String get notShared => 'Hindi ibinahagi';

  @override
  String get yes => 'Oo';

  @override
  String get no => 'Hindi';

  @override
  String get preferNotToSay => 'Ayokong sabihin';

  @override
  String get couldNotLoad => 'Hindi mabasa ang naka-save na data.';

  @override
  String soonFeature(Object feature) {
    return 'Hindi pa available ang $feature. Darating ito sa susunod na update.';
  }

  @override
  String get tabHome => 'Tahanan';

  @override
  String get tabPrepare => 'Paghahanda';

  @override
  String get tabSafePlaces => 'Mga Ligtas na Lugar';

  @override
  String get tabMore => 'Iba pa';

  @override
  String get headerOfflineStatus => 'Offline na status';

  @override
  String get headerAlerts => 'Mga alerto';

  @override
  String get openProfile => 'Buksan ang profile';

  @override
  String get soonOfflineCenter =>
      'Hindi pa available ang offline readiness center.';

  @override
  String get soonAlerts =>
      'Hindi pa nakakonekta ang mga hazard alert. Sundan ang QC DRRMO para sa opisyal na abiso.';

  @override
  String get guestBanner =>
      'Emergency access · hindi naka-sign in · sa teleponong ito lang ang data';

  @override
  String get moodWelcome => 'Mabuhay';

  @override
  String get moodFocused => 'Nakatutok';

  @override
  String get moodHelpful => 'Handang tumulong';

  @override
  String get moodDetermined => 'Determinado';

  @override
  String characterLabel(Object mood) {
    return 'Larawan ng karakter: $mood';
  }

  @override
  String get sceneHomeEyebrow => 'LIGTAS SA BAHAY';

  @override
  String get sceneHomeSub =>
      'Ang kahandaan ng inyong sambahayan, sa isang tingin.';

  @override
  String get sceneGuideEyebrow => 'GABAY SA PAGHAHANDA';

  @override
  String get sceneGuideTitle => 'Malaki ang nagagawa ng maliliit na hakbang.';

  @override
  String get sceneGuideSub =>
      'Unti-unting maging handa, isang checklist sa bawat pagkakataon.';

  @override
  String get sceneMapEyebrow => 'RUTA NG PAGLIKAS';

  @override
  String get sceneMapTitle => 'Hanapin ang daan patungo sa kaligtasan.';

  @override
  String get sceneMapSub =>
      'Tingnan ang mapa ng Quezon City at hanapin ang malapit na evacuation center.';

  @override
  String get greetingMorning => 'Magandang umaga';

  @override
  String get greetingAfternoon => 'Magandang hapon';

  @override
  String get greetingEvening => 'Magandang gabi';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name.';
  }

  @override
  String greetingNoName(Object greeting) {
    return '$greeting.';
  }

  @override
  String homeNextStepsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'May $count mungkahing hakbang para sa iyo.',
      one: 'May 1 mungkahing hakbang para sa iyo.',
      zero: 'Tapos mo na ang mga susunod na hakbang.',
    );
    return '$_temp0';
  }

  @override
  String get householdStatus => 'KALAGAYAN NG SAMBAHAYAN';

  @override
  String get readinessWell => 'Handang-handa na.';

  @override
  String get readinessGetting => 'Malapit nang maging handa.';

  @override
  String get readinessStart => 'Simulan na natin.';

  @override
  String waterCoverageSummary(num count, Object days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao',
      one: '1 tao',
    );
    return 'Sapat ang tubig nang $days araw para sa $_temp0.';
  }

  @override
  String get readinessNoWater =>
      'Magdagdag ng tubig sa iyong supplies para makita kung ilang araw ka sakop.';

  @override
  String get viewReadiness => 'Tingnan ang kahandaan ng sambahayan';

  @override
  String readinessScoreSemantics(Object score) {
    return 'Readiness score: $score porsiyento';
  }

  @override
  String get nextStepsEyebrow => 'MGA SUSUNOD NA HAKBANG';

  @override
  String get nextStepsTitle => 'Gawin nating simple.';

  @override
  String get nextStepsHelp => 'Tungkol sa mga hakbang na ito';

  @override
  String get nextStepsHelpText =>
      'Galing ang mga shortcut at mungkahing ito sa naka-save mong checklist, supplies, contacts at detalye ng sambahayan.';

  @override
  String get quickGoBag => 'Go-bag checklist';

  @override
  String quickGoBagMeta(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bagay na ilalagay',
      one: '1 bagay na ilalagay',
      zero: 'Kumpleto na',
    );
    return '$_temp0';
  }

  @override
  String get quickSafePlaces => 'Mga ligtas na lugar';

  @override
  String get quickSafePlacesMeta => 'Mapa at mga center';

  @override
  String get quickSupplies => 'Saklaw ng mga Suplay';

  @override
  String quickSuppliesWater(Object days) {
    return 'Tubig: $days araw';
  }

  @override
  String get quickSuppliesEmpty => 'Idagdag ang iyong supplies';

  @override
  String get quickHousehold => 'Sambahayan';

  @override
  String get quickHouseholdSetUp => 'I-set up ang sambahayan';

  @override
  String householdPeople(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao',
      one: '1 tao',
    );
    return '$_temp0';
  }

  @override
  String householdPeopleWithPets(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao',
      one: '1 tao',
    );
    return '$_temp0 · may alaga';
  }

  @override
  String get homeFooter => 'Naka-save sa teleponong ito ang iyong data';

  @override
  String get alertFloodAdvisory => 'ABISO SA BAHA';

  @override
  String get alertDemoTag => 'DEMO · HINDI LIVE';

  @override
  String get alertDemoTitle =>
      'Halimbawa: tumataas ang tubig malapit sa Ilog Marikina.';

  @override
  String get alertDemoBody =>
      'Halimbawa lang ito ng magiging hitsura ng mga abiso. Hindi pa nakakonekta ang mga live na alerto.';

  @override
  String get alertOpenSafePlaces => 'Buksan ang mga ligtas na lugar';

  @override
  String get alertDismiss => 'Isara ang alerto';

  @override
  String get soundPlay => 'Patugtugin ang babala';

  @override
  String get soundPlaying => 'Tumutunog ang babala';

  @override
  String get tagNotRealData => 'HINDI TOTOONG DATA';

  @override
  String get tagPreview => 'PREVIEW';

  @override
  String get mapStartNavigation => 'Simulan ang nabigasyon';

  @override
  String get mapYou => 'Ikaw';

  @override
  String get mapZoomIn => 'Palakihin';

  @override
  String get mapZoomOut => 'Paliitin';

  @override
  String get mapMyLocation => 'Ipakita ang aking lokasyon';

  @override
  String get mapResetView => 'Ipakita ang buong Quezon City';

  @override
  String get mapDemoBanner => 'DEMO DATA · HINDI BERIPIKADO ANG MGA CENTER';

  @override
  String get mapLabel => 'Mapa ng Quezon City na may mga evacuation center';

  @override
  String get locLocating => 'Hinahanap ang iyong lokasyon…';

  @override
  String get locDenied =>
      'Hindi pinayagan ang lokasyon. Puwede mo pa ring tingnan ang mapa at listahan ng mga center.';

  @override
  String get locDeniedForever =>
      'Naka-block ang lokasyon para sa TolongApp. Puwede mo itong payagan sa Android settings.';

  @override
  String get locOpenSettings => 'Buksan ang settings';

  @override
  String get locServiceOff => 'Naka-off ang lokasyon ng iyong telepono.';

  @override
  String get locTurnOn => 'I-on';

  @override
  String get locFailed =>
      'Hindi makuha ang iyong lokasyon. Subukan ulit, mas mainam kung malapit sa bintana o nasa labas.';

  @override
  String get locOutside =>
      'Mukhang nasa labas ka ng Quezon City. Para sa Quezon City lang ang impormasyon sa paglikas ng TolongApp.';

  @override
  String get locApproxArea =>
      'Tantiya lang ang sakop na lugar hangga\'t hindi pa naidaragdag ang opisyal na hangganan ng lungsod.';

  @override
  String get centersTitle => 'Mga evacuation center';

  @override
  String get centersDemoNote =>
      'Mga halimbawang punto lang ito para sa paggawa ng app, hindi totoong evacuation center. Papalitan ito ng opisyal na data ng QC DRRMO.';

  @override
  String get centerNearest => 'PINAKAMALAPIT NA CENTER';

  @override
  String get centerSelected => 'NAPILING CENTER';

  @override
  String get centerTapHint =>
      'I-tap ang marker sa mapa o pumili ng center sa listahan.';

  @override
  String centerDistance(Object km) {
    return 'Mga $km km ang tuwid na layo (hindi ruta ng paglalakad)';
  }

  @override
  String get centerAddress => 'Address';

  @override
  String get centerBarangay => 'Barangay';

  @override
  String get centerType => 'Uri ng pasilidad';

  @override
  String get centerAccessibility => 'Accessibility';

  @override
  String get centerCapacity => 'Kapasidad';

  @override
  String get centerFacilities => 'Pasilidad';

  @override
  String get centerStatus => 'Kalagayan';

  @override
  String get centerSource => 'Pinagkunan';

  @override
  String get centerLastVerified => 'Huling beripikasyon';

  @override
  String get notVerified => 'Hindi beripikado';

  @override
  String get tolTitle => 'Tol';

  @override
  String get tolSubtitle => 'Ang iyong kasama sa paghahanda';

  @override
  String get tolOpen => 'Makipag-chat kay Tol';

  @override
  String get tolModeOnline => 'Online AI';

  @override
  String get tolModeOffline => 'Offline na gabay';

  @override
  String get tolOfflineReason =>
      'Kailangan ng account at internet ang online AI. Makakatulong pa rin si Tol mula sa naka-save sa teleponong ito.';

  @override
  String get tolWelcome =>
      'Kumusta, ako si Tol! Tanungin mo ako kung paano ihahanda ang inyong sambahayan. Hindi ako opisyal na serbisyo sa emergency. Kung nasa panganib ka, tumawag sa 911.';

  @override
  String get tolInputHint => 'Magtanong kay Tol tungkol sa paghahanda…';

  @override
  String get tolSend => 'Ipadala';

  @override
  String get tolTyping => 'Nag-iisip si Tol…';

  @override
  String get tolAiLabel =>
      'Gawa ng AI · maaaring mali · hindi opisyal na abiso';

  @override
  String get tolOfflineLabel =>
      'Offline na gabay mula sa data sa teleponong ito';

  @override
  String get tolOnlineFailed =>
      'Hindi maabot si Tol online, kaya offline na gabay ito.';

  @override
  String get tolRetryOnline => 'Subukan ulit online';

  @override
  String get tolClear => 'Burahin ang usapan';

  @override
  String get tolClearTitle => 'Burahin ang usapan?';

  @override
  String get tolClearBody =>
      'Aalisin sa teleponong ito ang usapan ninyo ni Tol.';

  @override
  String get tolShareContext =>
      'Payagan si Tol na gamitin ang buod ng aking sambahayan';

  @override
  String get tolShareContextSub =>
      'Laki ng sambahayan, sino ang kasama, barangay, kahandaan at kulang na supplies. Hindi kailanman ang pangalan o numero ng telepono.';

  @override
  String get tolSuggestGoBag => 'Ano ang dapat kong ilagay sa go-bag?';

  @override
  String get tolSuggestWater => 'Ilang araw ang sakop ng aming tubig?';

  @override
  String get tolSuggestStart =>
      'Ano ang una kong dapat gawin para maging handa?';

  @override
  String get tolSuggestFlood => 'Paano maghanda sa baha?';

  @override
  String get tolOffEmergency =>
      'Kung ikaw o may kasama kang nasa panganib ngayon, tumawag sa 911 o humingi ng tulong sa mga nasa paligid. Lumipat sa mataas na lugar kung ligtas, at sundin ang inyong barangay at QC DRRMO.';

  @override
  String get tolOffAlerts =>
      'Wala akong live na abiso sa panahon o panganib. Tingnan ang opisyal na channel ng PAGASA at QC DRRMO para sa kasalukuyang abiso.';

  @override
  String tolOffGoBag(Object done, Object items, Object total) {
    return '$done sa $total na bagay ang nasa iyong go-bag. Susunod na ilalagay: $items.';
  }

  @override
  String get tolOffGoBagDone =>
      'Kumpleto na ang iyong go-bag checklist. Balikan ito buwan-buwan at palitan ang nagamit o expired.';

  @override
  String tolOffWater(num count, Object days, Object target) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao',
      one: '1 tao',
    );
    return 'Sapat ang naka-imbak mong tubig nang mga $days araw para sa $_temp0. $target araw ang iyong target.';
  }

  @override
  String get tolOffWaterNone =>
      'Hindi ka pa nakapagdagdag ng inuming tubig sa Saklaw ng mga Suplay. Idagdag ito roon at sasabihin ko kung ilang araw ito sasapat.';

  @override
  String tolOffFood(num count, Object days, Object target) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao',
      one: '1 tao',
    );
    return 'Sapat ang naka-imbak mong pagkain nang mga $days araw para sa $_temp0. $target araw ang iyong target.';
  }

  @override
  String get tolOffFoodNone =>
      'Hindi ka pa nakapagdagdag ng pagkain (bilang ng kain) sa Saklaw ng mga Suplay. Idagdag ito roon at sasabihin ko kung ilang araw ito sasapat.';

  @override
  String tolOffExpiry(Object expired, Object soon) {
    return 'Expired: $expired. Mag-e-expire sa loob ng 30 araw: $soon.';
  }

  @override
  String get tolOffExpiryNone =>
      'Walang naka-save na suplay na expired o mag-e-expire sa susunod na 30 araw.';

  @override
  String tolOffReadiness(Object score, Object tip) {
    return '$score% ang iyong readiness score. Magandang susunod na hakbang: $tip';
  }

  @override
  String tolOffReadinessNoTip(Object score) {
    return '$score% ang iyong readiness score. Walang kailangang madaliin ngayon. Panatilihing sariwa ang supplies.';
  }

  @override
  String get tolOffEvacuation =>
      'Buksan ang Mga Ligtas na Lugar para makita ang mapa. Halimbawang data pa lang ang mga evacuation center doon at hindi beripikado, kaya sundin ang QC DRRMO at ang inyong barangay para sa opisyal na evacuation center.';

  @override
  String tolOffContacts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'May $count emergency contact kang naka-save.',
      one: 'May 1 emergency contact kang naka-save. Magdagdag ng reserba.',
      zero:
          'Wala ka pang naka-save na emergency contact. Idagdag sila sa Profile at sambahayan.',
    );
    return '$_temp0';
  }

  @override
  String tolOffGuideReady(Object category) {
    return 'Buksan ang gabay para sa $category sa Gabay sa sakuna. Naka-save ito para mabasa kahit offline.';
  }

  @override
  String tolOffGuideSoon(Object category) {
    return 'Hindi pa nasusulat ang gabay para sa $category. Sa ngayon, sundin ang opisyal na payo ng QC DRRMO, PAGASA at PHIVOLCS.';
  }

  @override
  String get tolOffGreeting =>
      'Kumusta! Naka-offline mode ako, kaya ang naka-save lang sa teleponong ito ang magagamit ko. Itanong mo ang tungkol sa go-bag, tubig at pagkain, mag-e-expire na gamit, readiness score, emergency contacts, mga ligtas na lugar o ang gabay.';

  @override
  String get tolOffFallback =>
      'Hindi ko ito matugma nang offline. Makakatulong ako sa iyong go-bag, tubig at pagkain, mag-e-expire na gamit, readiness score, emergency contacts, mga ligtas na lugar at ang gabay.';

  @override
  String get orcTitle => 'Offline na kahandaan';

  @override
  String get orcIntro =>
      'Ang magagawa pa rin ng TolongApp sa teleponong ito kahit walang internet.';

  @override
  String orcReadyCount(Object ready, Object total) {
    return '$ready sa $total ang handa nang offline';
  }

  @override
  String get orcMap => 'Mapa ng kalye';

  @override
  String get orcAreaData => 'Hangganan at mga barangay ng Quezon City';

  @override
  String get orcAreaDataBody =>
      'Nasa app na: ang balangkas ng lungsod at lahat ng 142 barangay para sa paghahanap.';

  @override
  String get orcCenters => 'Mga evacuation center';

  @override
  String orcCentersBody(Object count) {
    return '$count center ang nasa app. Halimbawa lang para sa development, hindi beripikado.';
  }

  @override
  String get orcAlerts => 'Mga hazard alert';

  @override
  String get orcAlertsBody =>
      'Wala pang nakakonektang pinagkukunan ng alerto, kaya walang naka-save na alerto. Sundan ang QC DRRMO at PAGASA para sa opisyal na abiso.';

  @override
  String get orcGuidebook => 'Gabay sa sakuna';

  @override
  String orcGuidebookBody(Object ready, Object total) {
    return '$ready sa $total gabay ang may laman. Nasa app ang mga gabay at gumagana kahit offline.';
  }

  @override
  String get orcHousehold => 'Data ng iyong sambahayan';

  @override
  String get orcHouseholdBody =>
      'Naka-save nang naka-encrypt sa teleponong ito ang profile, contacts, supplies at checklist.';

  @override
  String get orcTol => 'Offline na tulong ni Tol';

  @override
  String get orcTolBody =>
      'Hindi pa available. Darating ang offline na gabay kasama ng Tol assistant.';

  @override
  String get orcSync => 'Backup ng account';

  @override
  String get orcSyncGuest =>
      'Emergency access: sa teleponong ito lang ang data at hindi naba-backup.';

  @override
  String get orcSyncOff =>
      'Hindi pa naka-set up ang backup ng account sa build na ito.';

  @override
  String get orcSyncNever => 'Hindi pa naba-backup.';

  @override
  String orcSyncLast(Object time) {
    return 'Huling na-backup $time.';
  }

  @override
  String orcSyncPending(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'May $count pagbabagong naghihintay i-upload.',
      one: 'May 1 pagbabagong naghihintay i-upload.',
      zero: 'Naka-backup na ang lahat.',
    );
    return '$_temp0';
  }

  @override
  String get orcSyncError =>
      'Hindi natuloy ang huling backup. Kusa itong susubukan ulit.';

  @override
  String get orcSyncing => 'Nagba-backup…';

  @override
  String get orcSyncNow => 'I-backup ngayon';

  @override
  String orcStorage(Object size) {
    return 'Laki ng offline na mapa: $size MB';
  }

  @override
  String get guidebookEyebrow => 'ALAMIN ANG GAGAWIN';

  @override
  String get guidebookTitle => 'Gabay sa sakuna';

  @override
  String get guidebookSeeAll => 'Tingnan lahat';

  @override
  String get guidebookIntro =>
      'Paisa-isang hakbang na gabay para sa mga karaniwang panganib sa Quezon City. Babanggitin ng bawat gabay ang opisyal na pinagkunan nito at naka-save sa app para mabasa kahit offline.';

  @override
  String guideSectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bahagi',
      one: '1 bahagi',
      zero: 'Malapit na',
    );
    return '$_temp0';
  }

  @override
  String guideComingSoon(Object category) {
    return 'Malapit na ang gabay sa paghahanda para sa $category.';
  }

  @override
  String get guideVisualSoon =>
      'Dito ilalagay ang may-larawang paisa-isang hakbang mula sa opisyal na pinagkunan.';

  @override
  String get guideOffline => 'Naka-save sa app · gumagana kahit offline';

  @override
  String guideSource(Object source) {
    return 'Pinagkunan: $source';
  }

  @override
  String get guideBefore => 'Bago';

  @override
  String get guideDuring => 'Habang';

  @override
  String get guideAfter => 'Pagkatapos';

  @override
  String get guideGeneral => 'Pangkalahatan';

  @override
  String get brgySearch => 'Maghanap ng barangay';

  @override
  String get brgySearchHint => 'I-type ang pangalan ng barangay';

  @override
  String get brgyNoMatch =>
      'Walang barangay sa Quezon City na tugma sa pangalang iyan.';

  @override
  String get brgyClear => 'Alisin ang barangay';

  @override
  String brgyShowing(Object name) {
    return 'Barangay $name';
  }

  @override
  String get brgyInvalid =>
      'Pumili ng barangay mula sa listahan ng Quezon City.';

  @override
  String get brgySource =>
      'Listahan ng barangay at hangganan ng lungsod: OpenStreetMap (142 barangay, tugma sa PSA).';

  @override
  String centersFromBarangay(Object name) {
    return 'Sinusukat ang layo mula sa gitna ng Barangay $name.';
  }

  @override
  String get offTitle => 'Offline na mapa';

  @override
  String get offIntro =>
      'I-save sa teleponong ito ang mapa ng Quezon City para lumabas pa rin kahit walang internet.';

  @override
  String get offIncludes =>
      'Kasama ang mga kalye at lugar sa buong Quezon City. Nasa app na ang mga evacuation center, barangay at hangganan ng lungsod.';

  @override
  String get offNotIncluded =>
      'Hindi pa kasama: pagpaplano ng bagong ruta nang offline at live na alerto.';

  @override
  String offEstimate(Object tiles) {
    return 'Mga $tiles map tile. Hanggang 3,000 bawat download ang pinapayagan ng OpenFreeMap.';
  }

  @override
  String get offWifi => 'Gumamit ng Wi-Fi kung maaari.';

  @override
  String get offStatusNone => 'Hindi pa na-download';

  @override
  String offStatusDownloading(Object percent) {
    return 'Nagda-download… $percent%';
  }

  @override
  String offStatusDone(Object date, Object size) {
    return 'Na-download noong $date · $size MB';
  }

  @override
  String get offStatusFailed =>
      'Hindi natapos ang download. Tingnan ang iyong koneksyon at subukan ulit.';

  @override
  String get offUnsupported =>
      'Gumagana ang offline na mapa sa Android app, hindi sa web preview.';

  @override
  String get offDownload => 'I-download ang mapa ng Quezon City';

  @override
  String get offRetry => 'Subukan ulit';

  @override
  String get offDelete => 'Burahin ang offline na mapa';

  @override
  String get offDeleteTitle => 'Burahin ang offline na mapa?';

  @override
  String get offDeleteBody =>
      'Kakailanganin ulit ng internet ang mapa hangga\'t hindi mo ito nada-download.';

  @override
  String get offDeleted => 'Nabura ang offline na mapa.';

  @override
  String get hazardTitle => 'Modelled na baha';

  @override
  String get hazardButton => 'Mapa ng panganib';

  @override
  String get hazardLegendTitle => 'Ano ang ibig sabihin ng mga kulay';

  @override
  String get hazardLegendNote =>
      'Mga modelled na senaryo mula sa Project NOAH, hindi aktuwal na kalagayan. Wala rito sa nagsasaad kung may nagsisimulang baha ngayon.';

  @override
  String get hazardLowerExposure =>
      'Mas malalim ang kulay, mas mataas ang modelled na pagkasamana sa senaryong ito. Hindi ito garantisya ng kaligtasan.';

  @override
  String get hazardGroupFlood => 'Lalim ng tubig';

  @override
  String get hazardGroupLandslide => 'Pagguho ng bundok';

  @override
  String get hazardGroupStormSurge =>
      'Pagbugso ng tubig alang-alang sa baybayin';

  @override
  String get hazardGroupDebrisFlow => 'Pagbagsak ng lupa at baha';

  @override
  String get hazardSeverity1 => 'Mababa';

  @override
  String get hazardSeverity2 => 'Katamtaman';

  @override
  String get hazardSeverity3 => 'Mataas';

  @override
  String get hazardSeverity4 => 'Napakataas';

  @override
  String get hazardNoData =>
      'Walang modelled na datos para sa hazards na ito sa Quezon City.';

  @override
  String get hazardUnavailableGeneric =>
      'Hindi magsimula ang mapa ng panganib sa device na ito. gumana pa rin ang iba pang bahagi ng mapa.';

  @override
  String get hazardCoverageGap =>
      'Hindi mo-model ng NOAH ang lindol at sunog, kaya hindi ipinapakita rito.';

  @override
  String get hazardSource =>
      'Pinagmulan: Project NOAH na mapa ng baha, pagguho ng bundok, pagbugso ng tubig at pagbagsak ng lupa, pinaliit sa Quezon City.';

  @override
  String get routeShow => 'Ipakita ang ruta';

  @override
  String get routeProfileWalking => 'Paglalakad';

  @override
  String get routeProfileWheelchair => 'Wheelchair';

  @override
  String get routeWheelchairNote =>
      'Umaasa ang ruta para sa wheelchair sa accessibility tags ng OpenStreetMap, na maaaring kulang sa Quezon City.';

  @override
  String get routeLoading => 'Hinahanap ang ruta…';

  @override
  String routeSummary(Object km, Object minutes) {
    return '$km km · mga $minutes minuto';
  }

  @override
  String get routeNeedsLocation =>
      'Payagan ang iyong lokasyon para magsimula ang ruta kung nasaan ka.';

  @override
  String get routeErrNotConfigured =>
      'Hindi pa naka-set up ang pagpaplano ng ruta sa build na ito. Kailangan nito ang Supabase route service.';

  @override
  String get routeErrNetwork =>
      'Hindi maabot ang route service. Tingnan ang iyong internet.';

  @override
  String get routeErrNoRoute =>
      'Walang nahanap na ruta mula sa iyong lokasyon papunta sa center na ito.';

  @override
  String get routeErrOutside =>
      'Sa loob lang ng Quezon City available ang mga ruta.';

  @override
  String get routeErrQuota =>
      'Abala ang route service. Subukan ulit pagkalipas ng isang minuto.';

  @override
  String get routeErrUnknown =>
      'May nangyaring mali sa pagpaplano ng ruta. Subukan ulit.';

  @override
  String get routeDisclaimer =>
      'Pinakamaikling ruta batay sa road data ng OpenStreetMap. Hindi nito alam ang kasalukuyang baha o saradong kalsada. Sundin ang opisyal na abiso.';

  @override
  String get navTitle => 'Nabigasyon';

  @override
  String get navPreviewNote =>
      'Preview ng ruta kasama ang iyong live na lokasyon. Hindi ito turn-by-turn na gabay.';

  @override
  String navRemaining(Object km, Object name) {
    return '$km km papunta sa $name (tuwid na layo)';
  }

  @override
  String get navOffRoute =>
      'Baka nalihis ka sa ruta. Bumalik patungo sa berdeng linya.';

  @override
  String navArrived(Object name) {
    return 'Nakarating ka na malapit sa $name.';
  }

  @override
  String get navEnd => 'Tapusin ang nabigasyon';

  @override
  String get navWaiting => 'Hinihintay ang iyong lokasyon…';

  @override
  String get navLocationLost =>
      'Huminto ang update ng lokasyon. Tiyaking naka-on ang lokasyon.';

  @override
  String get typeSchool => 'Paaralan';

  @override
  String get typeCoveredCourt => 'Covered court';

  @override
  String get typeBarangayHall => 'Barangay hall';

  @override
  String get typeOther => 'Ibang pasilidad';

  @override
  String get prepareMiniGuideEyebrow => 'ANG IYONG GO-BAG';

  @override
  String get prepareMiniGuideTitle => 'Gawing madaling bitbitin ang iyong kit';

  @override
  String get prepareIntro =>
      'Pagsama-samahin ang mahahalagang gamit sa isang waterproof na bag. I-tap ang bagay kapag nailagay na. Awtomatikong nase-save ang progreso.';

  @override
  String preparePacked(Object done, Object total) {
    return '$done sa $total ang nailagay';
  }

  @override
  String prepareSavedAt(Object time) {
    return 'Naka-save sa teleponong ito · $time';
  }

  @override
  String get prepareAddItem => 'Magdagdag';

  @override
  String get prepareReset => 'I-reset ang checklist';

  @override
  String get prepareResetTitle => 'I-reset ang checklist?';

  @override
  String get prepareResetBody =>
      'Aalisin ang lahat ng check. Mananatili ang mga idinagdag at in-edit mong item.';

  @override
  String get prepareResetConfirm => 'I-reset';

  @override
  String get prepareResetDone => 'Na-reset ang checklist.';

  @override
  String get suggestedChildren => 'Para sa mga bata';

  @override
  String get suggestedSeniors => 'Para sa senior';

  @override
  String get suggestedPets => 'Para sa alaga';

  @override
  String get suggestedAssistance => 'Para sa may pangangailangan';

  @override
  String get customTag => 'Idinagdag mo';

  @override
  String get itemEditorAdd => 'Magdagdag ng item';

  @override
  String get itemEditorEdit => 'I-edit ang item';

  @override
  String get itemEditorName => 'Item';

  @override
  String get itemEditorCategory => 'Kategorya';

  @override
  String get itemNameRequired => 'Pakilagay ang pangalan ng item.';

  @override
  String get removeItemTitle => 'Alisin ang item?';

  @override
  String removeItemBody(Object name) {
    return 'Aalisin ang \"$name\" sa iyong checklist.';
  }

  @override
  String itemActions(Object name) {
    return 'Mga aksyon para sa $name';
  }

  @override
  String get recommendationsEyebrow => 'MUNGKAHI PARA SA IYO';

  @override
  String get recommendationsTitle => 'Ano ang susunod na gagawin';

  @override
  String get recommendationsEmpty =>
      'Walang kailangang madaliin. Panatilihing sariwa ang supplies at balikan ang checklist buwan-buwan.';

  @override
  String get catWaterFood => 'Tubig at pagkain';

  @override
  String get catFirstAidMeds => 'First aid at gamot';

  @override
  String get catLightPower => 'Flashlight at baterya';

  @override
  String get catClothing => 'Damit';

  @override
  String get catHygiene => 'Pang-kalinisan';

  @override
  String get catDocuments => 'Mahahalagang dokumento';

  @override
  String get catCommunication => 'Pang-komunikasyon';

  @override
  String get catSpecialNeeds => 'Espesyal na pangangailangan ng sambahayan';

  @override
  String get tplWater => 'Inuming tubig';

  @override
  String get tplFood => 'Pagkaing handa nang kainin';

  @override
  String get tplCanOpener => 'Manual na abrelata';

  @override
  String get tplFirstAidKit => 'First aid kit';

  @override
  String get tplMedicines => 'Reseta at maintenance na gamot';

  @override
  String get tplMasks => 'Face mask';

  @override
  String get tplFlashlight => 'Flashlight';

  @override
  String get tplBatteries => 'Ekstrang baterya';

  @override
  String get tplPowerBank => 'Naka-charge na power bank at kable';

  @override
  String get tplClothes => 'Pamalit na damit';

  @override
  String get tplRainGear => 'Kapote o poncho';

  @override
  String get tplBlanket => 'Kumot o emergency foil blanket';

  @override
  String get tplToiletries => 'Toiletries (sabon, sipilyo, alcohol)';

  @override
  String get tplSanitary => 'Napkin at tissue';

  @override
  String get tplDocuments =>
      'Kopya ng ID at dokumento sa waterproof na lalagyan';

  @override
  String get tplCash => 'Cash na barya at maliliit na bill';

  @override
  String get tplContactList => 'Nakasulat na listahan ng emergency contacts';

  @override
  String get tplWhistle => 'Pito';

  @override
  String get tplRadio => 'Radyong de-baterya';

  @override
  String get tplInfantSupplies => 'Diaper, gatas o formula para sa sanggol';

  @override
  String get tplChildComfort => 'Paboritong laruan o gamit ng bata';

  @override
  String get tplSeniorMeds => 'Maintenance na gamot at reseta ng senior';

  @override
  String get tplMobilityAids => 'Salamin, hearing aid o gamit sa paglalakad';

  @override
  String get tplPetSupplies => 'Pagkain, tubig at mangkok ng alaga';

  @override
  String get tplPetCarrier => 'Tali o carrier at vaccination record ng alaga';

  @override
  String get tplAssistiveDevices => 'Assistive device at ekstrang baterya';

  @override
  String recRemoveExpired(Object name) {
    return 'Expired na ang $name. Palitan ito.';
  }

  @override
  String recAddWater(Object days, Object liters) {
    return 'Magdagdag ng mga $liters L na tubig para sa $days araw.';
  }

  @override
  String recAddFood(Object days, Object meals) {
    return 'Magdagdag ng mga $meals kain para sa $days araw.';
  }

  @override
  String get recAddFirstContact =>
      'Magdagdag ng kahit isang emergency contact.';

  @override
  String get recAddBackupContact =>
      'Magdagdag ng isa pang emergency contact bilang reserba.';

  @override
  String get recSetUpHousehold =>
      'Sabihin kung sino ang kasama mo sa bahay para tumpak ang tantiya.';

  @override
  String get recSetBarangay => 'Idagdag ang iyong barangay sa profile.';

  @override
  String recPack(Object item) {
    return 'Kulang pa sa iyong go-bag: $item.';
  }

  @override
  String recAddCategory(Object category) {
    return 'Magdagdag ng suplay: $category.';
  }

  @override
  String recExpiringSoon(num days, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Mag-e-expire ang $name sa loob ng $days araw.',
      one: 'Mag-e-expire bukas ang $name.',
      zero: 'Mag-e-expire ngayong araw ang $name.',
    );
    return '$_temp0';
  }

  @override
  String get supWater => 'Inuming tubig';

  @override
  String get supFood => 'Pagkain';

  @override
  String get supMedicine => 'Gamot';

  @override
  String get supFirstAid => 'First aid';

  @override
  String get supHygiene => 'Pang-kalinisan';

  @override
  String get supLighting => 'Ilaw at baterya';

  @override
  String get supOther => 'Iba pang mahahalaga';

  @override
  String get unitLiters => 'litro';

  @override
  String get unitMilliliters => 'mL';

  @override
  String get unitGallons => 'galon';

  @override
  String get unitBottles => 'bote';

  @override
  String get unitMeals => 'kain';

  @override
  String get unitPacks => 'pakete';

  @override
  String get unitCans => 'lata';

  @override
  String get unitPieces => 'piraso';

  @override
  String get unitTablets => 'tableta';

  @override
  String get unitBoxes => 'kahon';

  @override
  String get unitKilograms => 'kg';

  @override
  String get suppliesTitle => 'Saklaw ng mga Suplay';

  @override
  String suppliesEstimateNote(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tao',
      one: '1 tao',
    );
    return 'Tantiya para sa $_temp0 batay sa iyong target. Gabay ito sa paghahanda, hindi garantiya.';
  }

  @override
  String get suppliesHouseholdUnknown =>
      'Hindi pa nakatakda ang laki ng sambahayan, kaya 1 tao ang ginamit sa tantiya.';

  @override
  String get suppliesWater => 'Tubig';

  @override
  String get suppliesFood => 'Pagkain';

  @override
  String coverageDays(Object days) {
    return '$days araw';
  }

  @override
  String coverageTarget(Object days) {
    return 'Target: $days araw';
  }

  @override
  String coverageWaterStored(Object liters, Object perDay) {
    return '$liters L ang naka-imbak · kailangan ng $perDay L bawat araw';
  }

  @override
  String coverageFoodStored(Object meals, Object perDay) {
    return '$meals kain ang naka-imbak · kailangan ng $perDay kain bawat araw';
  }

  @override
  String coverageShortWater(Object liters) {
    return 'Kulang ng $liters L';
  }

  @override
  String coverageShortFood(Object meals) {
    return 'Kulang ng $meals kain';
  }

  @override
  String get coverageMet => 'Naabot ang target';

  @override
  String coverageUnknownItems(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'May $count item na hindi pa nabibilang: ilagay ang dami bawat unit.',
      one: 'May 1 item na hindi pa nabibilang: ilagay ang dami bawat unit.',
    );
    return '$_temp0';
  }

  @override
  String get suppliesEssentials => 'Mahahalaga';

  @override
  String essentialCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get essentialNone => 'Wala pa';

  @override
  String get suppliesInventory => 'Imbentaryo';

  @override
  String get suppliesEmpty =>
      'Wala pang supplies. Idagdag ang mga mayroon ka na sa bahay.';

  @override
  String get suppliesAdd => 'Magdagdag ng suplay';

  @override
  String get expiredTag => 'Expired';

  @override
  String expiresOn(Object date) {
    return 'Mag-e-expire sa $date';
  }

  @override
  String get expiresSoonTag => 'Malapit nang mag-expire';

  @override
  String lastsAbout(Object days) {
    return 'Tatagal nang mga $days araw';
  }

  @override
  String get suppliesHowTitle => 'Paano kinukuwenta ang tantiya';

  @override
  String get suppliesHowBody =>
      'Araw ng tubig = litrong naka-imbak ÷ (bilang ng tao × litro bawat tao bawat araw). Araw ng pagkain = bilang ng kain ÷ (bilang ng tao × kain bawat tao bawat araw). Hindi binibilang ang expired. Sa supply score, 30% ang tubig at 30% ang pagkain (batay sa araw na sakop kumpara sa target), dagdag na tig-10% kung may gamot, first aid, pang-kalinisan at ilaw. Mababago ang target sa Mga Setting.';

  @override
  String get supplyEditorAdd => 'Magdagdag ng suplay';

  @override
  String get supplyEditorEdit => 'I-edit ang suplay';

  @override
  String get supplyName => 'Pangalan';

  @override
  String get supplyCategory => 'Kategorya';

  @override
  String get supplyQuantity => 'Dami';

  @override
  String get supplyUnit => 'Unit';

  @override
  String supplyPerUnitWater(Object unit) {
    return 'Litro sa isang ($unit)';
  }

  @override
  String supplyPerUnitFood(Object unit) {
    return 'Bilang ng kain sa isang ($unit)';
  }

  @override
  String get supplyPerUnitHelp =>
      'Kailangan ito para maisama ang item sa tantiya.';

  @override
  String get supplyDailyUse => 'Gamit bawat araw (opsyonal)';

  @override
  String supplyDailyUseHelp(Object unit) {
    return 'Ilang $unit ang nagagamit ng sambahayan bawat araw';
  }

  @override
  String get supplyExpiry => 'Petsa ng expiration (opsyonal)';

  @override
  String get supplyExpiryNone => 'Walang petsa ng expiration';

  @override
  String get supplyExpiryPick => 'Pumili ng petsa';

  @override
  String get supplyExpiryClear => 'Alisin ang petsa';

  @override
  String get quantityInvalid => 'Maglagay ng numerong higit sa 0.';

  @override
  String get numberInvalid => 'Maglagay ng tamang numero.';

  @override
  String get removeSupplyTitle => 'Alisin ang suplay?';

  @override
  String removeSupplyBody(Object name) {
    return 'Aalisin ang \"$name\" sa iyong imbentaryo.';
  }

  @override
  String get supplySaved => 'Na-save ang suplay.';

  @override
  String get readinessTitle => 'Kahandaan ng sambahayan';

  @override
  String get readinessHowTitle => 'Paano kinukuwenta ang score';

  @override
  String get readinessHowBody =>
      'Pinagsasama ng score ang apat na bahagi: go-bag checklist (40%), saklaw ng supplies (30%), emergency contacts (15%, buo kapag may 2 contact) at profile ng sambahayan (15%: detalye ng sambahayan at barangay). Batay ito sa naitala mo sa app. Hindi ito garantiya ng kaligtasan.';

  @override
  String get areaGoBag => 'Go-bag checklist';

  @override
  String get areaSupplies => 'Saklaw ng mga Suplay';

  @override
  String get areaContacts => 'Mga Kontak sa Emergency';

  @override
  String get areaHousehold => 'Profile ng sambahayan';

  @override
  String areaPoints(Object max, Object points) {
    return '$points sa $max puntos';
  }

  @override
  String areaGoBagDetail(Object done, Object total) {
    return '$done sa $total ang nailagay';
  }

  @override
  String areaSuppliesDetail(Object food, Object water) {
    return 'Tubig $water araw · Pagkain $food araw';
  }

  @override
  String areaContactsDetail(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contact',
      one: '1 contact',
      zero: 'Wala pang contact',
    );
    return '$_temp0';
  }

  @override
  String get householdDetailsSaved => 'Naka-save ang detalye ng sambahayan';

  @override
  String get householdDetailsMissing => 'Kulang ang detalye ng sambahayan';

  @override
  String get barangaySet => 'Nakatakda ang barangay';

  @override
  String get barangayMissing => 'Wala pang barangay';

  @override
  String get readinessNextActions => 'Mga mungkahing susunod na hakbang';

  @override
  String get openChecklist => 'Buksan ang checklist';

  @override
  String get openSupplies => 'Buksan ang supplies';

  @override
  String get openHousehold => 'Buksan ang sambahayan';

  @override
  String get moreProfile => 'Profile at sambahayan';

  @override
  String get moreContacts => 'Mga Kontak sa Emergency';

  @override
  String get moreReadiness => 'Kahandaan ng sambahayan';

  @override
  String get moreSupplies => 'Saklaw ng mga Suplay';

  @override
  String get moreGuidebook => 'Gabay sa sakuna';

  @override
  String get moreOffline => 'Offline na kahandaan';

  @override
  String get moreSettings => 'Mga Setting';

  @override
  String get disclaimer =>
      'Pantulong sa paghahanda ang TolongApp, hindi opisyal na serbisyo sa emergency. Sa oras ng emergency, sundin ang abiso ng Quezon City DRRMO at ng pambansang ahensya.';

  @override
  String get logOut => 'Mag-log out';

  @override
  String get leaveGuest => 'Umalis sa emergency access';

  @override
  String get signOutTitle => 'Mag-log out?';

  @override
  String get signOutBody =>
      'Mananatili sa teleponong ito ang impormasyon ng iyong sambahayan, kaya nandito pa rin ito pag nag-log in ka ulit.';

  @override
  String get leaveGuestTitle => 'Umalis sa emergency access?';

  @override
  String get leaveGuestBody =>
      'Babalik ka sa welcome screen. Mananatili sa teleponong ito ang data na idinagdag mo sa emergency access.';

  @override
  String get leave => 'Umalis';

  @override
  String get welcomeMeetTol => 'KILALANIN SI TOL';

  @override
  String get welcomeTitle => 'Nagsisimula sa paghahanda ang iyong kaligtasan.';

  @override
  String get welcomeBody =>
      'Tinutulungan ng TolongApp ang inyong sambahayan sa Quezon City na maghanda sa baha, bagyo at lindol, paisa-isang hakbang. Gagabayan ka ni Tol, ang iyong kasama sa paghahanda.';

  @override
  String get welcomeNotConfigured =>
      'Hindi pa naka-configure ang online accounts sa build na ito, kaya hindi pa gagana ang pag-sign up at pag-log in. Gumagana ang emergency access sa device na ito.';

  @override
  String get createAccount => 'Gumawa ng account';

  @override
  String get logIn => 'Mag-log in';

  @override
  String get emergencyAccess => 'Emergency access nang walang account';

  @override
  String get guestSheetTitle => 'Emergency access';

  @override
  String get guestSheetBody =>
      'Gamitin ang TolongApp nang walang account. Sa teleponong ito lang mase-save ang idaragdag mo at hindi ito naba-backup o naisi-sync. Hindi ipapakita rito ang data ng iyong account, kung mayroon ka.';

  @override
  String get guestContinue => 'Magpatuloy nang walang account';

  @override
  String get loginTitle => 'Maligayang pagbabalik.';

  @override
  String get loginSubtitle =>
      'Mag-log in para makita ang kahandaan ng iyong sambahayan.';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Nakalimutan ang password?';

  @override
  String get newHere => 'Bago ka rito? Gumawa ng account';

  @override
  String get showPassword => 'Ipakita ang password';

  @override
  String get hidePassword => 'Itago ang password';

  @override
  String get registerTitle => 'Gumawa ng iyong account.';

  @override
  String get registerSubtitle =>
      'Ang kailangan lang ng TolongApp para i-personalize ang iyong paghahanda ang hinihingi namin.';

  @override
  String get fullName => 'Buong pangalan';

  @override
  String get confirmPassword => 'Kumpirmahin ang password';

  @override
  String get age => 'Edad';

  @override
  String get barangay => 'Barangay';

  @override
  String get barangayHelper => 'Ang iyong barangay sa Quezon City';

  @override
  String get privacyAccept =>
      'Nabasa ko ang privacy notice at sumasang-ayon ako sa paggamit ng aking data.';

  @override
  String get privacyAcceptRequired => 'Pakitanggap para makapagpatuloy.';

  @override
  String get readPrivacy => 'Basahin ang privacy notice';

  @override
  String get haveAccount => 'May account na? Mag-log in';

  @override
  String get checkEmailTitle => 'Tingnan ang iyong email';

  @override
  String checkEmailBody(Object email) {
    return 'Nagpadala kami ng verification link sa $email. Buksan ito sa teleponong ito, saka mag-log in.';
  }

  @override
  String get forgotTitle => 'I-reset ang iyong password.';

  @override
  String get forgotSubtitle =>
      'Ilagay ang email ng iyong account at magpapadala kami ng reset link.';

  @override
  String get sendResetLink => 'Ipadala ang reset link';

  @override
  String get sendAgain => 'Ipadala ulit';

  @override
  String get resetSent =>
      'Kung may account ang email na iyon, paparating na ang reset link. Buksan ito sa teleponong ito.';

  @override
  String get resetTitle => 'Pumili ng bagong password.';

  @override
  String get newPassword => 'Bagong password';

  @override
  String get confirmNewPassword => 'Kumpirmahin ang bagong password';

  @override
  String get saveNewPassword => 'I-save ang bagong password';

  @override
  String get passwordUpdated => 'Na-update ang password.';

  @override
  String get errNotConfigured =>
      'Hindi pa naka-set up ang online accounts sa build na ito. Magagamit mo pa rin ang emergency access.';

  @override
  String get errNetwork =>
      'Hindi maabot ang server. Tingnan ang iyong internet at subukan ulit.';

  @override
  String get errInvalidCredentials => 'Mali ang email o password.';

  @override
  String get errEmailNotConfirmed =>
      'Paki-verify muna ang iyong email. Hanapin ang link sa iyong inbox.';

  @override
  String get errAlreadyRegistered =>
      'May account na ang email na ito. Subukang mag-log in.';

  @override
  String get errRateLimited =>
      'Masyadong maraming subok. Maghintay sandali at subukan ulit.';

  @override
  String get errWeakPassword => 'Pumili ng mas matibay na password.';

  @override
  String get errUnknown =>
      'May nangyaring mali. Tingnan ang iyong koneksyon at subukan ulit.';

  @override
  String get valNameRequired => 'Pakilagay ang iyong pangalan.';

  @override
  String get valNameTooLong => 'Masyadong mahaba ang pangalan.';

  @override
  String get valEmailRequired => 'Pakilagay ang iyong email.';

  @override
  String get valEmailInvalid => 'Mukhang mali ang email address.';

  @override
  String get valPasswordShort => 'Gumamit ng kahit 8 character.';

  @override
  String get valPasswordMix => 'Lagyan ng kahit isang letra at isang numero.';

  @override
  String get valPasswordRequired => 'Pakilagay ang iyong password.';

  @override
  String get valPasswordMismatch => 'Hindi magkapareho ang password.';

  @override
  String get valAgeRequired => 'Pakilagay ang iyong edad.';

  @override
  String get valAgeRange => 'Maglagay ng edad mula 1 hanggang 120.';

  @override
  String get valPhoneRequired => 'Pakilagay ang numero ng telepono.';

  @override
  String get valPhoneInvalid =>
      'Maglagay ng PH mobile (09XX XXX XXXX) o landline sa Metro Manila.';

  @override
  String valRequired(Object field) {
    return 'Kailangan ang $field.';
  }

  @override
  String get privacyTitle => 'Privacy notice';

  @override
  String get privacyDraft => 'Draft para sa academic prototype ng TolongApp';

  @override
  String get privacyCollectTitle => 'Ano ang kinokolekta namin';

  @override
  String get privacyCollectBody =>
      'Ang iyong pangalan, email, edad at barangay sa Quezon City. Sa setup, puwede mo ring idagdag ang laki ng sambahayan, opsyonal na pangangailangan sa tulong, alaga at emergency contacts. Puwedeng laktawan ang mga opsyonal na tanong.';

  @override
  String get privacyWhyTitle => 'Bakit';

  @override
  String get privacyWhyBody =>
      'Para i-personalize ang checklist, tantiya ng supplies at mungkahi sa paglikas para sa inyong sambahayan.';

  @override
  String get privacyWhereTitle => 'Saan ito naka-imbak';

  @override
  String get privacyWhereBody =>
      'Unang sine-save nang naka-encrypt ang lahat sa teleponong ito. Kung may account ka, naba-backup din ang iyong profile, detalye ng sambahayan, emergency contacts, supplies at checklist sa aming Supabase database, protektado para ikaw lang ang makabasa. Sa emergency access, walang lumalabas sa telepono.';

  @override
  String get privacyNotTitle => 'Ang hindi namin ginagawa';

  @override
  String get privacyNotBody =>
      'Hindi namin ibinebenta o ibinabahagi sa advertiser ang iyong data. Hindi opisyal na serbisyo sa emergency ang TolongApp; laging sundin ang abiso ng Quezon City DRRMO at pambansang ahensya.';

  @override
  String get privacyChoicesTitle => 'Ang iyong mga pagpipilian';

  @override
  String get privacyChoicesBody =>
      'Puwede mong i-edit ang iyong impormasyon anumang oras, burahin ang data sa teleponong ito, at burahin ang account mo sa Mga Setting.';

  @override
  String onbStep(Object current, Object total) {
    return 'HAKBANG $current SA $total';
  }

  @override
  String get onbAboutTitle => 'Kilalanin ka namin.';

  @override
  String get onbAboutSub =>
      'Makakatulong ito para maiangkop ni Tol ang mga payo sa iyo at sa iyong barangay.';

  @override
  String get onbHouseholdTitle => 'Sino ang kasama mo sa bahay?';

  @override
  String get onbHouseholdSub =>
      'Nakadepende sa laki ng sambahayan kung gaano karaming tubig at pagkain ang dapat ihanda.';

  @override
  String get onbSkipOptional => 'Laktawan ang mga opsyonal na tanong';

  @override
  String get onbContactsTitle => 'Sino ang dapat tawagan?';

  @override
  String get onbContactsSub =>
      'Idagdag ang mga taong tatawagan mo sa emergency. Sa teleponong ito lang mase-save.';

  @override
  String get onbNoContacts =>
      'Wala pang contact. Puwede mo rin silang idagdag mamaya sa iyong profile.';

  @override
  String get addContact => 'Magdagdag ng contact';

  @override
  String get onbPrefsTitle => 'Ang iyong mga kagustuhan.';

  @override
  String get onbPrefsSub =>
      'Hihingi ng pahintulot ang Android sa unang beses na kailanganin ito ng isang feature. Mababago mo ito mamaya sa Mga Setting.';

  @override
  String get prefReminders => 'Paalala sa paghahanda';

  @override
  String get prefRemindersSub => 'Paalala na tingnan ang supplies at go-bag';

  @override
  String get prefLocation => 'Gamitin ang aking lokasyon';

  @override
  String get prefLocationSub => 'Para mahanap ang malapit na evacuation center';

  @override
  String get prefOffline => 'Offline na impormasyon sa emergency';

  @override
  String get prefOfflineSub =>
      'I-download ang mapa at gabay kapag available na';

  @override
  String onbWelcomeTitleName(Object name) {
    return 'Maligayang pagdating sa TolongApp, $name!';
  }

  @override
  String get onbWelcomeTitle => 'Maligayang pagdating sa TolongApp!';

  @override
  String get onbWelcomeBody =>
      'Kumusta, ako si Tol. Tutulungan kitang buuin ang iyong go-bag, bantayan ang supplies, at malaman kung saan pupunta kapag kailangang umalis ng bahay. Magsimula tayo sa maliliit na hakbang.';

  @override
  String get continueToDashboard => 'Tumuloy sa dashboard';

  @override
  String get setupProgress => 'Progreso ng setup';

  @override
  String get name => 'Pangalan';

  @override
  String get preferredLanguage => 'Gustong wika';

  @override
  String get adults => 'Matanda (adult)';

  @override
  String get adultsCaption => 'Edad 18–59, kasama ka';

  @override
  String get children => 'Bata';

  @override
  String get childrenCaption => 'Wala pang 18';

  @override
  String get seniors => 'Senior citizen';

  @override
  String get seniorsCaption => '60 pataas';

  @override
  String fewerOf(Object label) {
    return 'Bawasan: $label';
  }

  @override
  String moreOf(Object label) {
    return 'Dagdagan: $label';
  }

  @override
  String householdSizeLabel(Object count) {
    return 'Laki ng sambahayan: $count';
  }

  @override
  String get petsQuestion => 'May alaga ba? (opsyonal)';

  @override
  String get assistanceLabel => 'Pangangailangan sa tulong (opsyonal)';

  @override
  String get assistanceHelper =>
      'hal. naka-wheelchair, may araw-araw na gamot. Iwanang blangko kung gusto mo.';

  @override
  String get contactAddTitle => 'Magdagdag ng emergency contact';

  @override
  String get contactEditTitle => 'I-edit ang contact';

  @override
  String get relationship => 'Relasyon';

  @override
  String get relationshipHint => 'hal. Kapatid, Kapitbahay';

  @override
  String get phone => 'Numero ng telepono';

  @override
  String get phoneHint => '0917 123 4567';

  @override
  String get saveContact => 'I-save ang contact';

  @override
  String get removeContactTitle => 'Alisin ang contact?';

  @override
  String removeContactBody(Object name) {
    return 'Aalisin si $name sa iyong emergency contacts.';
  }

  @override
  String editNamed(Object name) {
    return 'I-edit si $name';
  }

  @override
  String removeNamed(Object name) {
    return 'Alisin si $name';
  }

  @override
  String get profileTitle => 'Profile at sambahayan';

  @override
  String get profileGuestNote =>
      'Emergency access: sa teleponong ito lang naka-save ang impormasyong ito at hindi naba-backup.';

  @override
  String get sectionYou => 'IKAW';

  @override
  String get sectionHousehold => 'SAMBAHAYAN';

  @override
  String get sectionContacts => 'MGA KONTAK SA EMERGENCY';

  @override
  String get language => 'Wika';

  @override
  String get notSetUpYet => 'Hindi pa naka-set up.';

  @override
  String get pets => 'Alaga';

  @override
  String get assistanceNeeds => 'Pangangailangan sa tulong';

  @override
  String get noContactsYet => 'Wala pang contact.';

  @override
  String get editDetailsTitle => 'I-edit ang iyong detalye.';

  @override
  String get editHouseholdTitle => 'I-edit ang iyong sambahayan.';

  @override
  String get profileSaved => 'Na-save ang profile.';

  @override
  String get householdSaved => 'Na-save ang sambahayan.';

  @override
  String get settingsTitle => 'Mga Setting';

  @override
  String get setAccount => 'Account';

  @override
  String get setProfile => 'Impormasyon ng profile';

  @override
  String get setChangePassword => 'Palitan ang password';

  @override
  String get setChangePasswordSub =>
      'Padadalhan ka namin ng reset link sa email';

  @override
  String setChangePasswordSent(Object email) {
    return 'Naipadala ang reset link sa $email.';
  }

  @override
  String get setDeleteAccount => 'Burahin ang account';

  @override
  String get setDeleteTitle => 'Burahin ang iyong account?';

  @override
  String get setDeleteBody =>
      'Permanenteng mabubura ang iyong TolongApp account at profile sa aming server, at aalisin ang data ng sambahayan sa teleponong ito. Hindi na ito maibabalik.';

  @override
  String get setDeleteDone => 'Nabura na ang iyong account.';

  @override
  String get setGuestAccountNote =>
      'Gumagamit ka ng emergency access. Gumawa ng account para ma-backup ang iyong profile.';

  @override
  String get setPreferences => 'Kagustuhan sa app';

  @override
  String get setReduceMotion => 'Bawasan ang galaw';

  @override
  String get setReduceMotionSub => 'Patayin ang mga pandekorasyong animation';

  @override
  String get setTextSize => 'Laki ng teksto';

  @override
  String get textNormal => 'Karaniwan';

  @override
  String get textLarge => 'Malaki';

  @override
  String get textLarger => 'Mas malaki';

  @override
  String get setTargets => 'Mga target sa paghahanda';

  @override
  String get setTargetsSub => 'Ginagamit sa tantiya ng saklaw ng supplies';

  @override
  String get setWaterTarget => 'Tubig bawat tao bawat araw (L)';

  @override
  String get setWaterTargetSub =>
      'Default na 3.8 L (mga 1 galon), isang malawakang ginagamit na gabay';

  @override
  String get setMealsTarget => 'Kain bawat tao bawat araw';

  @override
  String get setDaysTarget => 'Ilang araw ang paghahandaan';

  @override
  String get setDaysTargetSub => 'Default na 3 araw (72-hour kit)';

  @override
  String get setNotifications => 'Mga notification';

  @override
  String get setNotificationsNote =>
      'Naka-save ang iyong mga pinili. Magsisimula ang mga paalala kapag naidagdag na ang notifications sa susunod na update.';

  @override
  String get setReminders => 'Paalala sa paghahanda';

  @override
  String get setExpiry => 'Paalala sa expiration';

  @override
  String get setHazard => 'Notification ng hazard alert';

  @override
  String get setLocation => 'Lokasyon at mapa';

  @override
  String get setLocationNote =>
      'Hihingi ng pahintulot ang Android pagdating ng live na mapa.';

  @override
  String get setDefaultBarangay => 'Default na barangay';

  @override
  String get setOfflineMaps => 'Offline na mapa';

  @override
  String get setPrivacy => 'Privacy at data';

  @override
  String get setPrivacyNotice => 'Privacy notice';

  @override
  String get setStorage => 'Saan naka-imbak ang iyong data';

  @override
  String get setStorageAccount =>
      'Unang sine-save nang naka-encrypt ang lahat sa teleponong ito, kaya gumagana kahit offline. Kapag online ka, naba-backup ang iyong profile, detalye ng sambahayan, contacts, supplies at checklist sa iyong account sa Supabase, kung saan ikaw lang ang makakabasa.';

  @override
  String get setStorageGuest => 'Sa teleponong ito lang naka-imbak ang lahat.';

  @override
  String get setClearLocal => 'Burahin ang data sa teleponong ito';

  @override
  String get setClearLocalSub =>
      'Aalisin ang sambahayan, contacts, supplies at checklist sa teleponong ito';

  @override
  String get setClearTitle => 'Burahin ang data sa teleponong ito?';

  @override
  String get setClearBody =>
      'Aalisin sa teleponong ito ang detalye ng sambahayan, contacts, supplies at progreso ng checklist. Mananatili ang iyong account, at maaaring bumalik ang anumang naka-backup na rito sa susunod na pag-sync.';

  @override
  String get setClearConfirm => 'Burahin';

  @override
  String get setCleared => 'Nabura ang data sa teleponong ito.';

  @override
  String get setInfo => 'Impormasyon';

  @override
  String get setAbout => 'Tungkol sa TolongApp';

  @override
  String get setAboutBody =>
      'Ang TolongApp ay isang akademikong proyekto sa paghahanda sa sakuna para sa mga sambahayan sa Quezon City, ginawa nina Brizuela, Dela Calzada at Lambot para sa CS 403 sa Technological Institute of the Philippines.';

  @override
  String get setVersion => 'Bersyon';

  @override
  String get setDataSources => 'Pinagkunan ng data';

  @override
  String get setDataSourcesBody =>
      'Sumusunod ang mga target sa supplies sa malawakang inilathalang gabay sa paghahanda at mababago sa itaas. Ililista ng hazard alerts, mapa at evacuation centers ang kanilang pinagkunan kapag nakakonekta na.';

  @override
  String get setMapAttribution => 'Kredito ng mapa';

  @override
  String get setMapAttributionBody =>
      'Map tiles: OpenFreeMap, © OpenMapTiles. Map data, hangganan ng Quezon City at listahan ng barangay © OpenStreetMap contributors (ODbL). Routing: openrouteservice.org by HeiGIT. Rendering: MapLibre. Mga halimbawa lang para sa development ang mga evacuation center na ipinapakita ngayon, hindi opisyal na data.';

  @override
  String get setDisclaimer => 'Paalala sa emergency';

  @override
  String get setLicenses => 'Mga open-source na lisensya';
}

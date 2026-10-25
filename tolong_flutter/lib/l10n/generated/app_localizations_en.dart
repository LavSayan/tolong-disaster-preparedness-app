// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TolongApp';

  @override
  String get tagline => 'Stay ready, stay calm.';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get edit => 'Edit';

  @override
  String get next => 'Next';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get ok => 'OK';

  @override
  String get notSet => 'Not set';

  @override
  String get notShared => 'Not shared';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get couldNotLoad => 'Couldn\'t read saved data.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabPrepare => 'Prepare';

  @override
  String get tabSafePlaces => 'Safe places';

  @override
  String get tabMore => 'More';

  @override
  String get headerOfflineStatus => 'Offline status';

  @override
  String get headerAlerts => 'Alerts';

  @override
  String get openProfile => 'Open profile';

  @override
  String get guestBanner =>
      'Emergency access · not signed in · data stays on this phone';

  @override
  String get moodWelcome => 'Welcome';

  @override
  String get moodFocused => 'Focused';

  @override
  String get moodHelpful => 'Helpful';

  @override
  String get moodDetermined => 'Determined';

  @override
  String characterLabel(Object mood) {
    return '$mood character illustration';
  }

  @override
  String get sceneHomeEyebrow => 'SAFE AT HOME';

  @override
  String get sceneHomeSub => 'Your household\'s preparedness at a glance.';

  @override
  String get sceneGuideEyebrow => 'PREPAREDNESS GUIDE';

  @override
  String get sceneGuideTitle => 'Small steps make a big difference.';

  @override
  String get sceneGuideSub => 'Build confidence one checklist at a time.';

  @override
  String get sceneMapEyebrow => 'EVACUATION ROUTE';

  @override
  String get sceneMapTitle => 'Find your way to safety.';

  @override
  String get sceneMapSub =>
      'Explore the Quezon City map and find evacuation centers near you.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

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
      other: 'You have $count suggested next steps.',
      one: 'You have 1 suggested next step.',
      zero: 'You\'re caught up on next steps.',
    );
    return '$_temp0';
  }

  @override
  String get householdStatus => 'HOUSEHOLD STATUS';

  @override
  String get readinessWell => 'Well prepared.';

  @override
  String get readinessGetting => 'Getting there.';

  @override
  String get readinessStart => 'Let\'s get started.';

  @override
  String waterCoverageSummary(num count, Object days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'Water covers $days days for $_temp0.';
  }

  @override
  String get readinessNoWater =>
      'Add water to your supplies to see how many days you\'re covered.';

  @override
  String get viewReadiness => 'View household readiness';

  @override
  String readinessScoreSemantics(Object score) {
    return 'Readiness score $score percent';
  }

  @override
  String get nextStepsEyebrow => 'YOUR NEXT STEPS';

  @override
  String get nextStepsTitle => 'Keep it simple.';

  @override
  String get nextStepsHelp => 'About these steps';

  @override
  String get nextStepsHelpText =>
      'These shortcuts and suggestions come from your saved checklist, supplies, contacts and household details.';

  @override
  String get quickGoBag => 'Go-bag checklist';

  @override
  String quickGoBagMeta(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items to pack',
      one: '1 item to pack',
      zero: 'All packed',
    );
    return '$_temp0';
  }

  @override
  String get quickSafePlaces => 'Safe places';

  @override
  String get quickSafePlacesMeta => 'Map and centers';

  @override
  String get quickSupplies => 'Supply coverage';

  @override
  String quickSuppliesWater(Object days) {
    return 'Water: $days days';
  }

  @override
  String get quickSuppliesEmpty => 'Add your supplies';

  @override
  String get quickHousehold => 'Household';

  @override
  String get quickHouseholdSetUp => 'Set up your household';

  @override
  String householdPeople(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String householdPeopleWithPets(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0 · pets';
  }

  @override
  String get homeFooter => 'Your data is saved on this phone';

  @override
  String get alertTypeFlood => 'FLOOD ADVISORY';

  @override
  String get alertTypeEarthquake => 'EARTHQUAKE ADVISORY';

  @override
  String get alertTypeFire => 'FIRE ADVISORY';

  @override
  String get alertSeverityAdvisory => 'Advisory';

  @override
  String get alertSeverityWarning => 'Warning';

  @override
  String get alertSeveritySevere => 'Severe';

  @override
  String get alertSimulatedTag => 'SIMULATED · NOT LIVE';

  @override
  String get alertSimulatedNote =>
      'A simulated scenario from the demo tools, not a real emergency message. Follow QC DRRMO and PAGASA for official advisories.';

  @override
  String get alertOpenSafePlaces => 'Open safe places';

  @override
  String get alertDismiss => 'Dismiss alert';

  @override
  String get demoBannerActive =>
      'Demo overrides active — the location, advisory, route or weights on this screen are simulated.';

  @override
  String get demoOpenTools => 'Open demo tools';

  @override
  String get soundPlay => 'Play warning sound';

  @override
  String get soundPlaying => 'Warning sound playing';

  @override
  String get tagNotRealData => 'NOT REAL DATA';

  @override
  String get tagPreview => 'PREVIEW';

  @override
  String get mapStartNavigation => 'Start navigation';

  @override
  String get mapYou => 'You';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get mapMyLocation => 'Show my location';

  @override
  String get mapResetView => 'Show all of Quezon City';

  @override
  String get mapDemoBanner => 'DEMO DATA · CENTERS NOT VERIFIED';

  @override
  String get mapLabel => 'Map of Quezon City with evacuation centers';

  @override
  String get locLocating => 'Finding your location…';

  @override
  String get locDenied =>
      'Location permission was denied. You can still browse the map and the list of centers.';

  @override
  String get locDeniedForever =>
      'Location is blocked for TolongApp. You can allow it in Android settings.';

  @override
  String get locOpenSettings => 'Open settings';

  @override
  String get locServiceOff => 'Your phone\'s location is turned off.';

  @override
  String get locTurnOn => 'Turn on';

  @override
  String get locFailed =>
      'Couldn\'t get your location. Try again, ideally near a window or outdoors.';

  @override
  String get locOutside =>
      'You seem to be outside Quezon City. TolongApp\'s evacuation information covers Quezon City only.';

  @override
  String get locApproxArea =>
      'The service area is approximate until the official city boundary is added.';

  @override
  String get centersTitle => 'Evacuation centers';

  @override
  String get centersDemoNote =>
      'These are sample points for building the app, not real evacuation centers. Follow QC DRRMO and your barangay for official evacuation center locations.';

  @override
  String get centerNearest => 'NEAREST CENTER';

  @override
  String get centerSelected => 'SELECTED CENTER';

  @override
  String get centerTapHint =>
      'Tap a marker on the map or pick a center from the list.';

  @override
  String centerDistance(Object km) {
    return 'About $km km away in a straight line (not a walking route)';
  }

  @override
  String get centerAddress => 'Address';

  @override
  String get centerBarangay => 'Barangay';

  @override
  String get centerType => 'Facility type';

  @override
  String get centerAccessibility => 'Accessibility';

  @override
  String get centerCapacity => 'Capacity';

  @override
  String get centerFacilities => 'Facilities';

  @override
  String get centerStatus => 'Status';

  @override
  String get centerSource => 'Source';

  @override
  String get centerLastVerified => 'Last verified';

  @override
  String get notVerified => 'Not verified';

  @override
  String get rankNote =>
      'Ranked for your situation by a modelled score: exposure, travel time and accessibility. This is not a safety verdict and it does not know live conditions.';

  @override
  String get rankWeightsTitle => 'RANKED CENTERS';

  @override
  String get rankWeightsLabel => 'Weights';

  @override
  String get rankWeightsTrained => 'Trained weights v1';

  @override
  String get rankWeightsDefault => 'Default weights';

  @override
  String get rankExposureLabel => 'Modelled exposure';

  @override
  String rankExposureValue(Object value) {
    return '$value of 1.00';
  }

  @override
  String get rankExposureUnknown =>
      'No hazard reading at this point — treated as neutral';

  @override
  String get rankTravelLabel => 'Travel time';

  @override
  String rankTravelEstimated(Object minutes) {
    return '≈ $minutes min · estimated';
  }

  @override
  String rankTravelByRoute(Object minutes) {
    return '$minutes min · route';
  }

  @override
  String rankScore(Object score) {
    return 'Score $score / 100';
  }

  @override
  String get rankAccessibilityLabel => 'Wheelchair data';

  @override
  String get rankAccessibilityNeutral => 'Not checked yet — treated as neutral';

  @override
  String get rankAccessibilityVerified => 'Checked with a wheelchair route';

  @override
  String get rankAccessibilityFailed =>
      'The wheelchair route could not be planned — counted as unavailable';

  @override
  String get rankAccessibilityWalking =>
      'Not part of the score in walking mode';

  @override
  String get rankDistanceFallback =>
      'Hazard data is unavailable, so centers are listed by distance.';

  @override
  String get tolTitle => 'Tol';

  @override
  String get tolSubtitle => 'Your preparedness companion';

  @override
  String get tolOpen => 'Chat with Tol';

  @override
  String get tolModeOnline => 'Online AI';

  @override
  String get tolModeOffline => 'Offline guidance';

  @override
  String get tolOfflineReason =>
      'Online AI needs an account and internet. Tol can still help from what\'s saved on this phone.';

  @override
  String get tolWelcome =>
      'Hi, I\'m Tol! Ask me how to get your household ready. I\'m not an official emergency service. If you\'re in danger, call 911.';

  @override
  String get tolInputHint => 'Ask Tol about preparing…';

  @override
  String get tolSend => 'Send';

  @override
  String get tolTyping => 'Tol is thinking…';

  @override
  String get tolAiLabel =>
      'AI-generated · may be wrong · not an official advisory';

  @override
  String get tolOfflineLabel =>
      'Offline guidance from data saved on this phone';

  @override
  String get tolOnlineFailed =>
      'Couldn\'t reach Tol online, so this is offline guidance.';

  @override
  String get tolRetryOnline => 'Try online again';

  @override
  String get tolClear => 'Clear conversation';

  @override
  String get tolClearTitle => 'Clear conversation?';

  @override
  String get tolClearBody =>
      'Your chat with Tol will be removed from this phone.';

  @override
  String get tolShareContext => 'Let Tol use my household summary';

  @override
  String get tolShareContextSub =>
      'Household size, who\'s in it, barangay, readiness and missing supplies. Never names or phone numbers.';

  @override
  String get tolSuggestGoBag => 'What should I pack in my go-bag?';

  @override
  String get tolSuggestWater => 'How many days of water do we have?';

  @override
  String get tolSuggestStart => 'What should I do first to get ready?';

  @override
  String get tolSuggestFlood => 'How do I prepare for a flood?';

  @override
  String get tolOffEmergency =>
      'If you or someone near you is in danger right now, call 911 or alert people nearby. Move to higher ground if it\'s safe to do so, and follow your barangay officials and QC DRRMO.';

  @override
  String get tolOffAlerts =>
      'I don\'t have live weather or hazard alerts. Please check PAGASA and QC DRRMO\'s official channels for current advisories.';

  @override
  String tolOffGoBag(Object done, Object items, Object total) {
    return 'Your go-bag has $done of $total items packed. Next to pack: $items.';
  }

  @override
  String get tolOffGoBagDone =>
      'Your go-bag checklist is complete. Review it every month and replace anything used or expired.';

  @override
  String tolOffWater(num count, Object days, Object target) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'Your stored water covers about $days days for $_temp0. Your target is $target days.';
  }

  @override
  String get tolOffWaterNone =>
      'You haven\'t added drinking water to Supply coverage yet. Add it there and I can tell you how many days it covers.';

  @override
  String tolOffFood(num count, Object days, Object target) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'Your stored food covers about $days days for $_temp0. Your target is $target days.';
  }

  @override
  String get tolOffFoodNone =>
      'You haven\'t added food in meals to Supply coverage yet. Add it there and I can tell you how many days it covers.';

  @override
  String tolOffExpiry(Object expired, Object soon) {
    return 'Expired: $expired. Expiring within 30 days: $soon.';
  }

  @override
  String get tolOffExpiryNone =>
      'None of your saved supplies are expired or expiring in the next 30 days.';

  @override
  String tolOffReadiness(Object score, Object tip) {
    return 'Your readiness score is $score%. A good next step: $tip';
  }

  @override
  String tolOffReadinessNoTip(Object score) {
    return 'Your readiness score is $score%. Nothing urgent right now. Keep your supplies fresh.';
  }

  @override
  String get tolOffEvacuation =>
      'Open Safe places to see the map. The evacuation centers there are still sample data, not verified, so follow QC DRRMO and your barangay for official evacuation centers.';

  @override
  String tolOffContacts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count emergency contacts saved.',
      one: 'You have 1 emergency contact saved. Consider adding a backup.',
      zero:
          'You haven\'t saved any emergency contacts yet. Add them in Profile & household.',
    );
    return '$_temp0';
  }

  @override
  String tolOffGuideSoon(Object category) {
    return 'I don\'t have a written $category guide yet. For now, follow official advice from QC DRRMO, PAGASA and PHIVOLCS.';
  }

  @override
  String get tolGuideNameFlood => 'flood';

  @override
  String get tolGuideNameEarthquake => 'earthquake';

  @override
  String get tolGuideNameFire => 'fire';

  @override
  String get tolGuideNameTyphoon => 'typhoon';

  @override
  String get tolGuideNameFirstAid => 'first aid';

  @override
  String get tolOffGreeting =>
      'Hi! I\'m in offline mode, so I can only use what\'s saved on this phone. Ask me about your go-bag, water and food supplies, expiring items, readiness score, emergency contacts or safe places.';

  @override
  String get tolOffFallback =>
      'I couldn\'t match that offline. I can help with your go-bag, water and food supplies, expiring items, readiness score, emergency contacts and safe places.';

  @override
  String get orcTitle => 'Offline readiness';

  @override
  String get orcIntro =>
      'What TolongApp can still do on this phone without internet.';

  @override
  String orcReadyCount(Object ready, Object total) {
    return '$ready of $total ready offline';
  }

  @override
  String get orcMap => 'Street map';

  @override
  String get orcAreaData => 'Quezon City boundary and barangays';

  @override
  String get orcAreaDataBody =>
      'Built into the app: the city outline and all 142 barangays for search.';

  @override
  String get orcCenters => 'Evacuation centers';

  @override
  String orcCentersBody(Object count) {
    return '$count centers built into the app. Development sample only, not verified.';
  }

  @override
  String get orcHousehold => 'Your household data';

  @override
  String get orcHouseholdBody =>
      'Profile, contacts, supplies and checklist are saved encrypted on this phone.';

  @override
  String get orcSync => 'Account backup';

  @override
  String get orcSyncGuest =>
      'Emergency access: data stays on this phone and is not backed up.';

  @override
  String get orcSyncOff => 'Account backup isn\'t set up in this build.';

  @override
  String get orcSyncNever => 'Not backed up yet.';

  @override
  String orcSyncLast(Object time) {
    return 'Last backed up $time.';
  }

  @override
  String orcSyncPending(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to upload.',
      one: '1 change waiting to upload.',
      zero: 'Everything is backed up.',
    );
    return '$_temp0';
  }

  @override
  String get orcSyncError =>
      'The last backup attempt failed. It will retry automatically.';

  @override
  String get orcSyncing => 'Backing up…';

  @override
  String get orcSyncNow => 'Back up now';

  @override
  String orcStorage(Object size) {
    return 'Offline map storage: $size MB';
  }

  @override
  String get brgySearch => 'Search barangay';

  @override
  String get brgySearchHint => 'Type a barangay name';

  @override
  String get brgyNoMatch => 'No Quezon City barangay matches that name.';

  @override
  String get brgyClear => 'Clear barangay';

  @override
  String brgyShowing(Object name) {
    return 'Barangay $name';
  }

  @override
  String get brgyInvalid => 'Choose a barangay from the Quezon City list.';

  @override
  String get brgySource =>
      'Barangay list and city boundary: OpenStreetMap (142 barangays, matching PSA).';

  @override
  String centersFromBarangay(Object name) {
    return 'Distances are measured from the center of Barangay $name.';
  }

  @override
  String get offTitle => 'Offline map';

  @override
  String get offIntro =>
      'Save the Quezon City street map on this phone so it still shows without internet.';

  @override
  String get offIncludes =>
      'Includes streets and places across Quezon City. Evacuation centers, barangays and the city boundary are already built into the app.';

  @override
  String offEstimate(Object tiles) {
    return 'About $tiles map tiles. OpenFreeMap allows up to 3,000 per download.';
  }

  @override
  String get offWifi => 'Use Wi-Fi if you can.';

  @override
  String get offStatusNone => 'Not downloaded';

  @override
  String offStatusDownloading(Object percent) {
    return 'Downloading… $percent%';
  }

  @override
  String offStatusDone(Object date, Object size) {
    return 'Downloaded $date · $size MB';
  }

  @override
  String get offStatusFailed =>
      'The download didn\'t finish. Check your connection and try again.';

  @override
  String get offUnsupported =>
      'Offline maps work in the Android app, not in the web preview.';

  @override
  String get offDownload => 'Download Quezon City map';

  @override
  String get offRetry => 'Try again';

  @override
  String get offDelete => 'Delete offline map';

  @override
  String get offDeleteTitle => 'Delete the offline map?';

  @override
  String get offDeleteBody =>
      'The map will need internet again until you download it.';

  @override
  String get offDeleted => 'Offline map deleted.';

  @override
  String get hazardTitle => 'Modelled hazard';

  @override
  String get hazardButton => 'Hazard map';

  @override
  String get hazardLegendTitle => 'What the colours mean';

  @override
  String get hazardLegendNote =>
      'Modelled scenarios from Project NOAH, not live conditions. Nothing here shows whether a flood is happening now.';

  @override
  String get hazardLowerExposure =>
      'Areas shaded more deeply are modelled to have higher exposure in the stated scenario. This is not a safety guarantee.';

  @override
  String get hazardGroupFlood => 'Flood depth';

  @override
  String get hazardGroupLandslide => 'Landslide';

  @override
  String get hazardGroupStormSurge => 'Storm surge';

  @override
  String get hazardGroupDebrisFlow => 'Debris flow';

  @override
  String get hazardSeverity1 => 'Low';

  @override
  String get hazardSeverity2 => 'Moderate';

  @override
  String get hazardSeverity3 => 'High';

  @override
  String get hazardSeverity4 => 'Very high';

  @override
  String get hazardNoData => 'No modelled data for this hazard in Quezon City.';

  @override
  String get hazardNothingDrawn =>
      'The map has the data for this hazard but could not draw any of it. This looks like an app problem, not evidence that the hazard is absent.';

  @override
  String get hazardUnavailableGeneric =>
      'The hazard map couldn\'t start on this device. The rest of the map still works.';

  @override
  String get hazardCoverageGap =>
      'NOAH does not model earthquakes or fire, so those hazards are not shown here.';

  @override
  String get hazardSource =>
      'Source: Project NOAH flood, landslide, storm surge and debris-flow maps, clipped to Quezon City.';

  @override
  String get routeShow => 'Show route';

  @override
  String get routeProfileWalking => 'Walking';

  @override
  String get routeProfileWheelchair => 'Wheelchair';

  @override
  String get routeWheelchairNote =>
      'Wheelchair routes rely on OpenStreetMap accessibility tags, which can be incomplete in Quezon City.';

  @override
  String get routeLoading => 'Finding a route…';

  @override
  String routeSummary(Object km, Object minutes) {
    return '$km km · about $minutes min';
  }

  @override
  String get routeNeedsLocation =>
      'Allow your location so the route can start from where you are.';

  @override
  String get routeErrNotConfigured =>
      'Route planning is not configured in this build. It needs the Supabase route service.';

  @override
  String get routeErrNetwork =>
      'Can\'t reach the route service. Check your internet connection.';

  @override
  String get routeErrNoRoute =>
      'No route found between your location and this center.';

  @override
  String get routeErrOutside => 'Routes are only available inside Quezon City.';

  @override
  String get routeErrQuota =>
      'The route service is busy. Please try again in a minute.';

  @override
  String get routeErrUnknown =>
      'Something went wrong while planning the route. Please try again.';

  @override
  String get routeDisclaimer =>
      'Shortest route from OpenStreetMap road data. It does not know about current floods or road closures. Follow official advisories.';

  @override
  String get navTitle => 'Navigation';

  @override
  String get navPreviewNote =>
      'Route preview with your live location. This is not turn-by-turn guidance.';

  @override
  String navRemaining(Object km, Object name) {
    return '$km km to $name in a straight line';
  }

  @override
  String get navOffRoute =>
      'You may be off the route. Head back toward the green line.';

  @override
  String navArrived(Object name) {
    return 'You\'ve arrived near $name.';
  }

  @override
  String get navEnd => 'End navigation';

  @override
  String get navWaiting => 'Waiting for your location…';

  @override
  String get navLocationLost =>
      'Location updates stopped. Check that location is turned on.';

  @override
  String get typeSchool => 'School';

  @override
  String get typeCoveredCourt => 'Covered court';

  @override
  String get typeBarangayHall => 'Barangay hall';

  @override
  String get typeOther => 'Other facility';

  @override
  String get prepareMiniGuideEyebrow => 'YOUR GO-BAG';

  @override
  String get prepareMiniGuideTitle => 'Make your kit easy to grab';

  @override
  String get prepareIntro =>
      'Keep essentials together in one waterproof bag. Tap an item when it\'s packed. Progress saves automatically.';

  @override
  String preparePacked(Object done, Object total) {
    return '$done of $total packed';
  }

  @override
  String prepareSavedAt(Object time) {
    return 'Saved on this phone · $time';
  }

  @override
  String get prepareAddItem => 'Add item';

  @override
  String get prepareReset => 'Reset checklist';

  @override
  String get prepareResetTitle => 'Reset checklist?';

  @override
  String get prepareResetBody =>
      'All items will be unchecked. Your custom items and edits are kept.';

  @override
  String get prepareResetConfirm => 'Reset';

  @override
  String get prepareResetDone => 'Checklist reset.';

  @override
  String get suggestedChildren => 'For children';

  @override
  String get suggestedSeniors => 'For seniors';

  @override
  String get suggestedPets => 'For pets';

  @override
  String get suggestedAssistance => 'For assistance needs';

  @override
  String get customTag => 'Custom';

  @override
  String get itemEditorAdd => 'Add checklist item';

  @override
  String get itemEditorEdit => 'Edit item';

  @override
  String get itemEditorName => 'Item';

  @override
  String get itemEditorCategory => 'Category';

  @override
  String get itemNameRequired => 'Please enter an item name.';

  @override
  String get removeItemTitle => 'Remove item?';

  @override
  String removeItemBody(Object name) {
    return '\"$name\" will be removed from your checklist.';
  }

  @override
  String itemActions(Object name) {
    return 'Actions for $name';
  }

  @override
  String get recommendationsEyebrow => 'RECOMMENDED FOR YOU';

  @override
  String get recommendationsTitle => 'What to do next';

  @override
  String get recommendationsEmpty =>
      'Nothing urgent. Keep supplies fresh and review your checklist every month.';

  @override
  String get catWaterFood => 'Water and food';

  @override
  String get catFirstAidMeds => 'First aid and medication';

  @override
  String get catLightPower => 'Flashlights and batteries';

  @override
  String get catClothing => 'Clothing';

  @override
  String get catHygiene => 'Hygiene supplies';

  @override
  String get catDocuments => 'Important documents';

  @override
  String get catCommunication => 'Communication tools';

  @override
  String get catSpecialNeeds => 'Special household needs';

  @override
  String get tplWater => 'Drinking water';

  @override
  String get tplFood => 'Ready-to-eat food';

  @override
  String get tplCanOpener => 'Manual can opener';

  @override
  String get tplFirstAidKit => 'First aid kit';

  @override
  String get tplMedicines => 'Prescription and maintenance medicines';

  @override
  String get tplMasks => 'Face masks';

  @override
  String get tplFlashlight => 'Flashlight';

  @override
  String get tplBatteries => 'Extra batteries';

  @override
  String get tplPowerBank => 'Charged power bank and cable';

  @override
  String get tplClothes => 'Change of clothes';

  @override
  String get tplRainGear => 'Raincoat or poncho';

  @override
  String get tplBlanket => 'Blanket or emergency foil blanket';

  @override
  String get tplToiletries => 'Toiletries (soap, toothbrush, alcohol)';

  @override
  String get tplSanitary => 'Sanitary pads and tissues';

  @override
  String get tplDocuments => 'Copies of IDs and documents in a waterproof bag';

  @override
  String get tplCash => 'Cash in small bills and coins';

  @override
  String get tplContactList => 'Written list of emergency contacts';

  @override
  String get tplWhistle => 'Whistle';

  @override
  String get tplRadio => 'Battery-powered radio';

  @override
  String get tplInfantSupplies => 'Diapers, milk or formula for infants';

  @override
  String get tplChildComfort => 'Comfort item or toy for children';

  @override
  String get tplSeniorMeds =>
      'Seniors\' maintenance medicines and prescriptions';

  @override
  String get tplMobilityAids => 'Glasses, hearing aids or mobility aids';

  @override
  String get tplPetSupplies => 'Pet food, water and bowl';

  @override
  String get tplPetCarrier => 'Leash or carrier and pet vaccination records';

  @override
  String get tplAssistiveDevices => 'Assistive devices and spare batteries';

  @override
  String recRemoveExpired(Object name) {
    return '$name has expired. Replace it.';
  }

  @override
  String recAddWater(Object days, Object liters) {
    return 'Add about $liters L of water to cover $days days.';
  }

  @override
  String recAddFood(Object days, Object meals) {
    return 'Add about $meals meals to cover $days days.';
  }

  @override
  String get recAddFirstContact => 'Add at least one emergency contact.';

  @override
  String get recAddBackupContact =>
      'Add one more emergency contact as a backup.';

  @override
  String get recSetUpHousehold =>
      'Tell us who lives with you for accurate estimates.';

  @override
  String get recSetBarangay => 'Add your barangay to your profile.';

  @override
  String recPack(Object item) {
    return 'Your go-bag still needs: $item.';
  }

  @override
  String recAddCategory(Object category) {
    return 'Add supplies: $category.';
  }

  @override
  String recExpiringSoon(num days, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$name expires in $days days.',
      one: '$name expires tomorrow.',
      zero: '$name expires today.',
    );
    return '$_temp0';
  }

  @override
  String get supWater => 'Drinking water';

  @override
  String get supFood => 'Food';

  @override
  String get supMedicine => 'Medicines';

  @override
  String get supFirstAid => 'First aid';

  @override
  String get supHygiene => 'Hygiene supplies';

  @override
  String get supLighting => 'Lighting and batteries';

  @override
  String get supOther => 'Other essentials';

  @override
  String get unitLiters => 'liters';

  @override
  String get unitMilliliters => 'mL';

  @override
  String get unitGallons => 'gallons';

  @override
  String get unitBottles => 'bottles';

  @override
  String get unitMeals => 'meals';

  @override
  String get unitPacks => 'packs';

  @override
  String get unitCans => 'cans';

  @override
  String get unitPieces => 'pieces';

  @override
  String get unitTablets => 'tablets';

  @override
  String get unitBoxes => 'boxes';

  @override
  String get unitKilograms => 'kg';

  @override
  String get suppliesTitle => 'Supply coverage';

  @override
  String suppliesEstimateNote(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'Estimates for $_temp0 using your targets. They\'re a planning guide, not a guarantee.';
  }

  @override
  String get suppliesHouseholdUnknown =>
      'Household size isn\'t set, so estimates assume 1 person.';

  @override
  String get suppliesWater => 'Water';

  @override
  String get suppliesFood => 'Food';

  @override
  String coverageDays(Object days) {
    return '$days days';
  }

  @override
  String coverageTarget(Object days) {
    return 'Target: $days days';
  }

  @override
  String coverageWaterStored(Object liters, Object perDay) {
    return '$liters L stored · needs $perDay L a day';
  }

  @override
  String coverageFoodStored(Object meals, Object perDay) {
    return '$meals meals stored · needs $perDay meals a day';
  }

  @override
  String coverageShortWater(Object liters) {
    return 'Short by $liters L';
  }

  @override
  String coverageShortFood(Object meals) {
    return 'Short by $meals meals';
  }

  @override
  String get coverageMet => 'Target met';

  @override
  String coverageUnknownItems(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items aren\'t counted yet: add their amount per unit.',
      one: '1 item isn\'t counted yet: add its amount per unit.',
    );
    return '$_temp0';
  }

  @override
  String get suppliesEssentials => 'Essentials';

  @override
  String essentialCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get essentialNone => 'None yet';

  @override
  String get suppliesInventory => 'Inventory';

  @override
  String get suppliesEmpty =>
      'No supplies yet. Add what you already have at home.';

  @override
  String get suppliesAdd => 'Add supply';

  @override
  String get expiredTag => 'Expired';

  @override
  String expiresOn(Object date) {
    return 'Expires $date';
  }

  @override
  String get expiresSoonTag => 'Expires soon';

  @override
  String lastsAbout(Object days) {
    return 'Lasts about $days days';
  }

  @override
  String get suppliesHowTitle => 'How estimates work';

  @override
  String get suppliesHowBody =>
      'Water days = liters stored ÷ (people × liters per person per day). Food days = meals stored ÷ (people × meals per person per day). Expired items are not counted. The supply score gives water 30% and food 30% (based on days covered against your target), plus 10% each for having medicines, first aid, hygiene supplies and lighting. Change targets in Settings.';

  @override
  String get supplyEditorAdd => 'Add supply';

  @override
  String get supplyEditorEdit => 'Edit supply';

  @override
  String get supplyName => 'Name';

  @override
  String get supplyCategory => 'Category';

  @override
  String get supplyQuantity => 'Quantity';

  @override
  String get supplyUnit => 'Unit';

  @override
  String supplyPerUnitWater(Object unit) {
    return 'Liters in one ($unit)';
  }

  @override
  String supplyPerUnitFood(Object unit) {
    return 'Meals in one ($unit)';
  }

  @override
  String get supplyPerUnitHelp =>
      'Needed to include this item in the coverage estimate.';

  @override
  String get supplyDailyUse => 'Daily use (optional)';

  @override
  String supplyDailyUseHelp(Object unit) {
    return 'How many $unit your household uses per day';
  }

  @override
  String get supplyExpiry => 'Expiration date (optional)';

  @override
  String get supplyExpiryNone => 'No expiration date';

  @override
  String get supplyExpiryPick => 'Pick date';

  @override
  String get supplyExpiryClear => 'Clear date';

  @override
  String get quantityInvalid => 'Enter a number greater than 0.';

  @override
  String get numberInvalid => 'Enter a valid number.';

  @override
  String get removeSupplyTitle => 'Remove supply?';

  @override
  String removeSupplyBody(Object name) {
    return '\"$name\" will be removed from your inventory.';
  }

  @override
  String get supplySaved => 'Supply saved.';

  @override
  String get readinessTitle => 'Household readiness';

  @override
  String get readinessHowTitle => 'How the score works';

  @override
  String get readinessHowBody =>
      'The score adds up four parts: go-bag checklist (40%), supply coverage (30%), emergency contacts (15%, full at 2 contacts) and household profile (15%: household details and barangay). It reflects what you\'ve recorded in the app. It is not a guarantee of safety.';

  @override
  String get areaGoBag => 'Go-bag checklist';

  @override
  String get areaSupplies => 'Supply coverage';

  @override
  String get areaContacts => 'Emergency contacts';

  @override
  String get areaHousehold => 'Household profile';

  @override
  String areaPoints(Object max, Object points) {
    return '$points of $max points';
  }

  @override
  String areaGoBagDetail(Object done, Object total) {
    return '$done of $total items packed';
  }

  @override
  String areaSuppliesDetail(Object food, Object water) {
    return 'Water $water days · Food $food days';
  }

  @override
  String areaContactsDetail(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '1 contact',
      zero: 'No contacts yet',
    );
    return '$_temp0';
  }

  @override
  String get householdDetailsSaved => 'Household details saved';

  @override
  String get householdDetailsMissing => 'Household details missing';

  @override
  String get barangaySet => 'Barangay set';

  @override
  String get barangayMissing => 'Barangay missing';

  @override
  String get readinessNextActions => 'Recommended next actions';

  @override
  String get openChecklist => 'Open checklist';

  @override
  String get openSupplies => 'Open supplies';

  @override
  String get openHousehold => 'Open household';

  @override
  String get moreProfile => 'Profile & household';

  @override
  String get moreContacts => 'Emergency contacts';

  @override
  String get moreReadiness => 'Household readiness';

  @override
  String get moreSupplies => 'Supply coverage';

  @override
  String get moreOffline => 'Offline readiness';

  @override
  String get moreSettings => 'Settings';

  @override
  String get disclaimer =>
      'TolongApp is a preparedness aid, not an official emergency service. In an emergency, follow Quezon City DRRMO and national advisories.';

  @override
  String get logOut => 'Log out';

  @override
  String get leaveGuest => 'Leave emergency access';

  @override
  String get signOutTitle => 'Log out?';

  @override
  String get signOutBody =>
      'Your household information stays on this phone so it\'s still there when you log back in.';

  @override
  String get leaveGuestTitle => 'Leave emergency access?';

  @override
  String get leaveGuestBody =>
      'You\'ll return to the welcome screen. Data you added in emergency access stays on this phone.';

  @override
  String get leave => 'Leave';

  @override
  String get welcomeMeetTol => 'MEET TOL';

  @override
  String get welcomeTitle => 'Your safety starts with preparation.';

  @override
  String get welcomeBody =>
      'TolongApp helps your household in Quezon City get ready for floods, typhoons and earthquakes, one small step at a time. Tol, your preparedness companion, will guide you.';

  @override
  String get welcomeNotConfigured =>
      'Online accounts are not configured in this build, so sign-up and login are unavailable. Emergency access works on this device.';

  @override
  String get createAccount => 'Create account';

  @override
  String get logIn => 'Log in';

  @override
  String get emergencyAccess => 'Emergency access without an account';

  @override
  String get guestSheetTitle => 'Emergency access';

  @override
  String get guestSheetBody =>
      'Use TolongApp without an account. Anything you add stays only on this phone and is not backed up or synced. Your account data, if you have one, is not shown in this mode.';

  @override
  String get guestContinue => 'Continue without account';

  @override
  String get loginTitle => 'Welcome back.';

  @override
  String get loginSubtitle => 'Log in to see your household\'s preparedness.';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newHere => 'New here? Create an account';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerTitle => 'Create your account.';

  @override
  String get registerSubtitle =>
      'We only ask for what TolongApp needs to personalize your preparedness.';

  @override
  String get fullName => 'Full name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get age => 'Age';

  @override
  String get barangay => 'Barangay';

  @override
  String get barangayHelper => 'Your Quezon City barangay';

  @override
  String get privacyAccept =>
      'I have read the privacy notice and agree to how my data is used.';

  @override
  String get privacyAcceptRequired => 'Please accept to continue.';

  @override
  String get readPrivacy => 'Read the privacy notice';

  @override
  String get haveAccount => 'Already have an account? Log in';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String checkEmailBody(Object email) {
    return 'We sent a verification link to $email. Open it on this phone, then log in.';
  }

  @override
  String get forgotTitle => 'Reset your password.';

  @override
  String get forgotSubtitle =>
      'Enter your account email and we\'ll send you a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get sendAgain => 'Send again';

  @override
  String get resetSent =>
      'If an account exists for that email, a reset link is on its way. Open it on this phone.';

  @override
  String get resetTitle => 'Choose a new password.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get saveNewPassword => 'Save new password';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get errNotConfigured =>
      'Online accounts are not configured in this build. You can still use emergency access.';

  @override
  String get errNetwork =>
      'Can\'t reach the server. Check your internet connection and try again.';

  @override
  String get errInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get errEmailNotConfirmed =>
      'Please verify your email first. Check your inbox for the link.';

  @override
  String get errAlreadyRegistered =>
      'An account with this email already exists. Try logging in.';

  @override
  String get errRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errWeakPassword => 'Please choose a stronger password.';

  @override
  String get errUnknown =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get valNameRequired => 'Please enter your name.';

  @override
  String get valNameTooLong => 'Name is too long.';

  @override
  String get valEmailRequired => 'Please enter your email.';

  @override
  String get valEmailInvalid => 'That email address doesn\'t look right.';

  @override
  String get valPasswordShort => 'Use at least 8 characters.';

  @override
  String get valPasswordMix => 'Include at least one letter and one number.';

  @override
  String get valPasswordRequired => 'Please enter your password.';

  @override
  String get valPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get valAgeRequired => 'Please enter your age.';

  @override
  String get valAgeRange => 'Enter an age between 1 and 120.';

  @override
  String get valPhoneRequired => 'Please enter a phone number.';

  @override
  String get valPhoneInvalid =>
      'Enter a PH mobile (09XX XXX XXXX) or Metro Manila landline.';

  @override
  String valRequired(Object field) {
    return '$field is required.';
  }

  @override
  String get privacyTitle => 'Privacy notice';

  @override
  String get privacyDraft => 'Draft for the TolongApp academic prototype';

  @override
  String get privacyCollectTitle => 'What we collect';

  @override
  String get privacyCollectBody =>
      'Your name, email, age and Quezon City barangay. During setup you may also add household size, optional assistance needs, pets and emergency contacts. Optional questions can be skipped.';

  @override
  String get privacyWhyTitle => 'Why';

  @override
  String get privacyWhyBody =>
      'To personalize preparedness checklists, supply estimates and evacuation suggestions for your household.';

  @override
  String get privacyWhereTitle => 'Where it is stored';

  @override
  String get privacyWhereBody =>
      'Everything is saved encrypted on this phone first. If you have an account, your profile, household details, emergency contacts, supplies and checklist are also backed up to our Supabase database, protected so only you can read them. In emergency access, nothing leaves the phone.';

  @override
  String get privacyNotTitle => 'What we don\'t do';

  @override
  String get privacyNotBody =>
      'We don\'t sell your data or share it with advertisers. TolongApp is not an official emergency service; always follow advisories from Quezon City DRRMO and national agencies.';

  @override
  String get privacyChoicesTitle => 'Your choices';

  @override
  String get privacyChoicesBody =>
      'You can edit your information at any time, clear the data on this phone, and delete your account from Settings.';

  @override
  String onbStep(Object current, Object total) {
    return 'STEP $current OF $total';
  }

  @override
  String get onbAboutTitle => 'Tell us about you.';

  @override
  String get onbAboutSub =>
      'This helps Tol tailor tips to you and your barangay.';

  @override
  String get onbHouseholdTitle => 'Who lives with you?';

  @override
  String get onbHouseholdSub =>
      'Household size shapes how much water and food you should prepare.';

  @override
  String get onbSkipOptional => 'Skip the optional questions';

  @override
  String get onbContactsTitle => 'Who should we call?';

  @override
  String get onbContactsSub =>
      'Add people you would contact in an emergency. Saved only on this phone.';

  @override
  String get onbNoContacts =>
      'No contacts yet. You can also add them later from your profile.';

  @override
  String get addContact => 'Add a contact';

  @override
  String get onbPrefsTitle => 'Your preferences.';

  @override
  String get onbPrefsSub =>
      'Android will ask for permission the first time a feature needs it. You can change these later in Settings.';

  @override
  String get prefLocation => 'Use my location';

  @override
  String get prefLocationSub => 'To find evacuation centers near you';

  @override
  String get prefOffline => 'Offline emergency information';

  @override
  String get prefOfflineSub =>
      'Download maps and guides when they become available';

  @override
  String onbWelcomeTitleName(Object name) {
    return 'Welcome to TolongApp, $name!';
  }

  @override
  String get onbWelcomeTitle => 'Welcome to TolongApp!';

  @override
  String get onbWelcomeBody =>
      'Hi, I\'m Tol. I\'ll help you build your go-bag, keep track of supplies, and know where to go when you need to leave home. Let\'s start with small steps.';

  @override
  String get continueToDashboard => 'Continue to dashboard';

  @override
  String get setupProgress => 'Setup progress';

  @override
  String get name => 'Name';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get adults => 'Adults';

  @override
  String get adultsCaption => 'Ages 18–59, including you';

  @override
  String get children => 'Children';

  @override
  String get childrenCaption => 'Under 18';

  @override
  String get seniors => 'Senior citizens';

  @override
  String get seniorsCaption => '60 and above';

  @override
  String fewerOf(Object label) {
    return 'Fewer $label';
  }

  @override
  String moreOf(Object label) {
    return 'More $label';
  }

  @override
  String householdSizeLabel(Object count) {
    return 'Household size: $count';
  }

  @override
  String get petsQuestion => 'Any pets? (optional)';

  @override
  String get assistanceLabel => 'Assistance needs (optional)';

  @override
  String get assistanceHelper =>
      'e.g. wheelchair user, needs daily medication. Leave blank if you prefer.';

  @override
  String get contactAddTitle => 'Add emergency contact';

  @override
  String get contactEditTitle => 'Edit contact';

  @override
  String get relationship => 'Relationship';

  @override
  String get relationshipHint => 'e.g. Sister, Neighbor';

  @override
  String get phone => 'Phone number';

  @override
  String get phoneHint => '0917 123 4567';

  @override
  String get saveContact => 'Save contact';

  @override
  String get removeContactTitle => 'Remove contact?';

  @override
  String removeContactBody(Object name) {
    return '$name will be removed from your emergency contacts.';
  }

  @override
  String editNamed(Object name) {
    return 'Edit $name';
  }

  @override
  String removeNamed(Object name) {
    return 'Remove $name';
  }

  @override
  String get profileTitle => 'Profile & household';

  @override
  String get profileGuestNote =>
      'Emergency access: this information is saved only on this phone and is not backed up.';

  @override
  String get sectionYou => 'YOU';

  @override
  String get sectionHousehold => 'HOUSEHOLD';

  @override
  String get sectionContacts => 'EMERGENCY CONTACTS';

  @override
  String get language => 'Language';

  @override
  String get notSetUpYet => 'Not set up yet.';

  @override
  String get pets => 'Pets';

  @override
  String get assistanceNeeds => 'Assistance needs';

  @override
  String get noContactsYet => 'No contacts yet.';

  @override
  String get editDetailsTitle => 'Edit your details.';

  @override
  String get editHouseholdTitle => 'Edit your household.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get householdSaved => 'Household saved.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get setAccount => 'Account';

  @override
  String get setProfile => 'Profile information';

  @override
  String get setChangePassword => 'Change password';

  @override
  String get setChangePasswordSub => 'We\'ll email you a reset link';

  @override
  String setChangePasswordSent(Object email) {
    return 'Reset link sent to $email.';
  }

  @override
  String get setDeleteAccount => 'Delete account';

  @override
  String get setDeleteTitle => 'Delete your account?';

  @override
  String get setDeleteBody =>
      'This permanently deletes your TolongApp account and profile from our server and removes your household data from this phone. This can\'t be undone.';

  @override
  String get setDeleteDone => 'Your account was deleted.';

  @override
  String get setGuestAccountNote =>
      'You\'re using emergency access. Create an account to back up your profile.';

  @override
  String get setPreferences => 'App preferences';

  @override
  String get setReduceMotion => 'Reduce motion';

  @override
  String get setReduceMotionSub => 'Turn off decorative animations';

  @override
  String get setTextSize => 'Text size';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get textLarger => 'Larger';

  @override
  String get setTargets => 'Preparedness targets';

  @override
  String get setTargetsSub => 'Used for supply coverage estimates';

  @override
  String get setWaterTarget => 'Water per person per day (L)';

  @override
  String get setWaterTargetSub =>
      'Default 3.8 L (about 1 gallon), a widely used guideline';

  @override
  String get setMealsTarget => 'Meals per person per day';

  @override
  String get setDaysTarget => 'Days to prepare for';

  @override
  String get setDaysTargetSub => 'Default 3 days (a 72-hour kit)';

  @override
  String get setLocation => 'Location and maps';

  @override
  String get setLocationNote =>
      'Android will ask for permission when the live map arrives.';

  @override
  String get setDefaultBarangay => 'Default barangay';

  @override
  String get setOfflineMaps => 'Offline maps';

  @override
  String get setPrivacy => 'Privacy and data';

  @override
  String get setPrivacyNotice => 'Privacy notice';

  @override
  String get setStorage => 'Where your data is stored';

  @override
  String get setStorageAccount =>
      'Everything is saved encrypted on this phone first, so it works offline. When you\'re online, your profile, household details, contacts, supplies and checklist are backed up to your account in Supabase, where only you can read them.';

  @override
  String get setStorageGuest => 'Everything is stored only on this phone.';

  @override
  String get setClearLocal => 'Clear data on this phone';

  @override
  String get setClearLocalSub =>
      'Removes household, contacts, supplies and checklist from this phone';

  @override
  String get setClearTitle => 'Clear data on this phone?';

  @override
  String get setClearBody =>
      'Household details, contacts, supplies and checklist progress will be removed from this phone. Your account stays, and anything already backed up to it can return the next time it syncs.';

  @override
  String get setClearConfirm => 'Clear';

  @override
  String get setCleared => 'Data on this phone was cleared.';

  @override
  String get setInfo => 'Information';

  @override
  String get setAbout => 'About TolongApp';

  @override
  String get setAboutBody =>
      'TolongApp is an academic disaster-preparedness project for households in Quezon City, made by Brizuela, Dela Calzada and Lambot for CS 403 at the Technological Institute of the Philippines.';

  @override
  String get setVersion => 'Version';

  @override
  String get setDataSources => 'Data sources';

  @override
  String get setDataSourcesBody =>
      'Supply targets follow widely published preparedness guidelines and can be changed above. Evacuation centers currently shown are development samples, not official data.';

  @override
  String get setMapAttribution => 'Map attribution';

  @override
  String get setMapAttributionBody =>
      'Map tiles: OpenFreeMap, © OpenMapTiles. Map data, Quezon City boundary and barangay list © OpenStreetMap contributors (ODbL). Routing: openrouteservice.org by HeiGIT. Rendering: MapLibre. Evacuation centers currently shown are development samples, not official data.';

  @override
  String get setDisclaimer => 'Emergency disclaimer';

  @override
  String get setLicenses => 'Open-source licenses';
}

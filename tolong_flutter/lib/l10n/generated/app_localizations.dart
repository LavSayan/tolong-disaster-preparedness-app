import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TolongApp'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Stay ready, stay calm.'**
  String get tagline;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @notShared.
  ///
  /// In en, this message translates to:
  /// **'Not shared'**
  String get notShared;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read saved data.'**
  String get couldNotLoad;

  /// No description provided for @soonFeature.
  ///
  /// In en, this message translates to:
  /// **'{feature} isn\'t available yet. It\'s planned for a later update.'**
  String soonFeature(Object feature);

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabPrepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get tabPrepare;

  /// No description provided for @tabSafePlaces.
  ///
  /// In en, this message translates to:
  /// **'Safe places'**
  String get tabSafePlaces;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// No description provided for @headerOfflineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline status'**
  String get headerOfflineStatus;

  /// No description provided for @headerAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get headerAlerts;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @soonOfflineCenter.
  ///
  /// In en, this message translates to:
  /// **'The offline readiness center isn\'t available yet.'**
  String get soonOfflineCenter;

  /// No description provided for @soonAlerts.
  ///
  /// In en, this message translates to:
  /// **'Hazard alerts aren\'t connected yet. Follow QC DRRMO for official advisories.'**
  String get soonAlerts;

  /// No description provided for @guestBanner.
  ///
  /// In en, this message translates to:
  /// **'Emergency access · not signed in · data stays on this phone'**
  String get guestBanner;

  /// No description provided for @moodWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get moodWelcome;

  /// No description provided for @moodFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get moodFocused;

  /// No description provided for @moodHelpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get moodHelpful;

  /// No description provided for @moodDetermined.
  ///
  /// In en, this message translates to:
  /// **'Determined'**
  String get moodDetermined;

  /// No description provided for @characterLabel.
  ///
  /// In en, this message translates to:
  /// **'{mood} character illustration'**
  String characterLabel(Object mood);

  /// No description provided for @sceneHomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'SAFE AT HOME'**
  String get sceneHomeEyebrow;

  /// No description provided for @sceneHomeSub.
  ///
  /// In en, this message translates to:
  /// **'Your household\'s preparedness at a glance.'**
  String get sceneHomeSub;

  /// No description provided for @sceneGuideEyebrow.
  ///
  /// In en, this message translates to:
  /// **'PREPAREDNESS GUIDE'**
  String get sceneGuideEyebrow;

  /// No description provided for @sceneGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Small steps make a big difference.'**
  String get sceneGuideTitle;

  /// No description provided for @sceneGuideSub.
  ///
  /// In en, this message translates to:
  /// **'Build confidence one checklist at a time.'**
  String get sceneGuideSub;

  /// No description provided for @sceneMapEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EVACUATION ROUTE'**
  String get sceneMapEyebrow;

  /// No description provided for @sceneMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your way to safety.'**
  String get sceneMapTitle;

  /// No description provided for @sceneMapSub.
  ///
  /// In en, this message translates to:
  /// **'Explore the Quezon City map and find evacuation centers near you.'**
  String get sceneMapSub;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}.'**
  String greetingWithName(Object greeting, Object name);

  /// No description provided for @greetingNoName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}.'**
  String greetingNoName(Object greeting);

  /// No description provided for @homeNextStepsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{You\'re caught up on next steps.} =1{You have 1 suggested next step.} other{You have {count} suggested next steps.}}'**
  String homeNextStepsCount(num count);

  /// No description provided for @householdStatus.
  ///
  /// In en, this message translates to:
  /// **'HOUSEHOLD STATUS'**
  String get householdStatus;

  /// No description provided for @readinessWell.
  ///
  /// In en, this message translates to:
  /// **'Well prepared.'**
  String get readinessWell;

  /// No description provided for @readinessGetting.
  ///
  /// In en, this message translates to:
  /// **'Getting there.'**
  String get readinessGetting;

  /// No description provided for @readinessStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started.'**
  String get readinessStart;

  /// No description provided for @waterCoverageSummary.
  ///
  /// In en, this message translates to:
  /// **'Water covers {days} days for {count, plural, =1{1 person} other{{count} people}}.'**
  String waterCoverageSummary(num count, Object days);

  /// No description provided for @readinessNoWater.
  ///
  /// In en, this message translates to:
  /// **'Add water to your supplies to see how many days you\'re covered.'**
  String get readinessNoWater;

  /// No description provided for @viewReadiness.
  ///
  /// In en, this message translates to:
  /// **'View household readiness'**
  String get viewReadiness;

  /// No description provided for @readinessScoreSemantics.
  ///
  /// In en, this message translates to:
  /// **'Readiness score {score} percent'**
  String readinessScoreSemantics(Object score);

  /// No description provided for @nextStepsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR NEXT STEPS'**
  String get nextStepsEyebrow;

  /// No description provided for @nextStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep it simple.'**
  String get nextStepsTitle;

  /// No description provided for @nextStepsHelp.
  ///
  /// In en, this message translates to:
  /// **'About these steps'**
  String get nextStepsHelp;

  /// No description provided for @nextStepsHelpText.
  ///
  /// In en, this message translates to:
  /// **'These shortcuts and suggestions come from your saved checklist, supplies, contacts and household details.'**
  String get nextStepsHelpText;

  /// No description provided for @quickGoBag.
  ///
  /// In en, this message translates to:
  /// **'Go-bag checklist'**
  String get quickGoBag;

  /// No description provided for @quickGoBagMeta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All packed} =1{1 item to pack} other{{count} items to pack}}'**
  String quickGoBagMeta(num count);

  /// No description provided for @quickSafePlaces.
  ///
  /// In en, this message translates to:
  /// **'Safe places'**
  String get quickSafePlaces;

  /// No description provided for @quickSafePlacesMeta.
  ///
  /// In en, this message translates to:
  /// **'Map and centers'**
  String get quickSafePlacesMeta;

  /// No description provided for @quickSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supply coverage'**
  String get quickSupplies;

  /// No description provided for @quickSuppliesWater.
  ///
  /// In en, this message translates to:
  /// **'Water: {days} days'**
  String quickSuppliesWater(Object days);

  /// No description provided for @quickSuppliesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add your supplies'**
  String get quickSuppliesEmpty;

  /// No description provided for @quickHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get quickHousehold;

  /// No description provided for @quickHouseholdSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up your household'**
  String get quickHouseholdSetUp;

  /// No description provided for @householdPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String householdPeople(num count);

  /// No description provided for @householdPeopleWithPets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}} · pets'**
  String householdPeopleWithPets(num count);

  /// No description provided for @homeFooter.
  ///
  /// In en, this message translates to:
  /// **'Your data is saved on this phone'**
  String get homeFooter;

  /// No description provided for @alertFloodAdvisory.
  ///
  /// In en, this message translates to:
  /// **'FLOOD ADVISORY'**
  String get alertFloodAdvisory;

  /// No description provided for @alertDemoTag.
  ///
  /// In en, this message translates to:
  /// **'DEMO · NOT LIVE'**
  String get alertDemoTag;

  /// No description provided for @alertDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Example: rising water near Marikina River.'**
  String get alertDemoTitle;

  /// No description provided for @alertDemoBody.
  ///
  /// In en, this message translates to:
  /// **'This sample shows how advisories will look. Live alerts aren\'t connected yet.'**
  String get alertDemoBody;

  /// No description provided for @alertOpenSafePlaces.
  ///
  /// In en, this message translates to:
  /// **'Open safe places'**
  String get alertOpenSafePlaces;

  /// No description provided for @alertDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss alert'**
  String get alertDismiss;

  /// No description provided for @soundPlay.
  ///
  /// In en, this message translates to:
  /// **'Play warning sound'**
  String get soundPlay;

  /// No description provided for @soundPlaying.
  ///
  /// In en, this message translates to:
  /// **'Warning sound playing'**
  String get soundPlaying;

  /// No description provided for @tagNotRealData.
  ///
  /// In en, this message translates to:
  /// **'NOT REAL DATA'**
  String get tagNotRealData;

  /// No description provided for @tagPreview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get tagPreview;

  /// No description provided for @mapStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get mapStartNavigation;

  /// No description provided for @mapYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get mapYou;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @mapMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Show my location'**
  String get mapMyLocation;

  /// No description provided for @mapResetView.
  ///
  /// In en, this message translates to:
  /// **'Show all of Quezon City'**
  String get mapResetView;

  /// No description provided for @mapDemoBanner.
  ///
  /// In en, this message translates to:
  /// **'DEMO DATA · CENTERS NOT VERIFIED'**
  String get mapDemoBanner;

  /// No description provided for @mapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map of Quezon City with evacuation centers'**
  String get mapLabel;

  /// No description provided for @locLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locLocating;

  /// No description provided for @locDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. You can still browse the map and the list of centers.'**
  String get locDenied;

  /// No description provided for @locDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for TolongApp. You can allow it in Android settings.'**
  String get locDeniedForever;

  /// No description provided for @locOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locOpenSettings;

  /// No description provided for @locServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s location is turned off.'**
  String get locServiceOff;

  /// No description provided for @locTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get locTurnOn;

  /// No description provided for @locFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Try again, ideally near a window or outdoors.'**
  String get locFailed;

  /// No description provided for @locOutside.
  ///
  /// In en, this message translates to:
  /// **'You seem to be outside Quezon City. TolongApp\'s evacuation information covers Quezon City only.'**
  String get locOutside;

  /// No description provided for @locApproxArea.
  ///
  /// In en, this message translates to:
  /// **'The service area is approximate until the official city boundary is added.'**
  String get locApproxArea;

  /// No description provided for @centersTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuation centers'**
  String get centersTitle;

  /// No description provided for @centersDemoNote.
  ///
  /// In en, this message translates to:
  /// **'These are sample points for building the app, not real evacuation centers. Official QC DRRMO data will replace them.'**
  String get centersDemoNote;

  /// No description provided for @centerNearest.
  ///
  /// In en, this message translates to:
  /// **'NEAREST CENTER'**
  String get centerNearest;

  /// No description provided for @centerSelected.
  ///
  /// In en, this message translates to:
  /// **'SELECTED CENTER'**
  String get centerSelected;

  /// No description provided for @centerTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a marker on the map or pick a center from the list.'**
  String get centerTapHint;

  /// No description provided for @centerDistance.
  ///
  /// In en, this message translates to:
  /// **'About {km} km away in a straight line (not a walking route)'**
  String centerDistance(Object km);

  /// No description provided for @centerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get centerAddress;

  /// No description provided for @centerBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get centerBarangay;

  /// No description provided for @centerType.
  ///
  /// In en, this message translates to:
  /// **'Facility type'**
  String get centerType;

  /// No description provided for @centerAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get centerAccessibility;

  /// No description provided for @centerCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get centerCapacity;

  /// No description provided for @centerFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get centerFacilities;

  /// No description provided for @centerStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get centerStatus;

  /// No description provided for @centerSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get centerSource;

  /// No description provided for @centerLastVerified.
  ///
  /// In en, this message translates to:
  /// **'Last verified'**
  String get centerLastVerified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerified;

  /// No description provided for @tolTitle.
  ///
  /// In en, this message translates to:
  /// **'Tol'**
  String get tolTitle;

  /// No description provided for @tolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your preparedness companion'**
  String get tolSubtitle;

  /// No description provided for @tolOpen.
  ///
  /// In en, this message translates to:
  /// **'Chat with Tol'**
  String get tolOpen;

  /// No description provided for @tolModeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online AI'**
  String get tolModeOnline;

  /// No description provided for @tolModeOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline guidance'**
  String get tolModeOffline;

  /// No description provided for @tolOfflineReason.
  ///
  /// In en, this message translates to:
  /// **'Online AI needs an account and internet. Tol can still help from what\'s saved on this phone.'**
  String get tolOfflineReason;

  /// No description provided for @tolWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Tol! Ask me how to get your household ready. I\'m not an official emergency service. If you\'re in danger, call 911.'**
  String get tolWelcome;

  /// No description provided for @tolInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask Tol about preparing…'**
  String get tolInputHint;

  /// No description provided for @tolSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get tolSend;

  /// No description provided for @tolTyping.
  ///
  /// In en, this message translates to:
  /// **'Tol is thinking…'**
  String get tolTyping;

  /// No description provided for @tolAiLabel.
  ///
  /// In en, this message translates to:
  /// **'AI-generated · may be wrong · not an official advisory'**
  String get tolAiLabel;

  /// No description provided for @tolOfflineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline guidance from data saved on this phone'**
  String get tolOfflineLabel;

  /// No description provided for @tolOnlineFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Tol online, so this is offline guidance.'**
  String get tolOnlineFailed;

  /// No description provided for @tolRetryOnline.
  ///
  /// In en, this message translates to:
  /// **'Try online again'**
  String get tolRetryOnline;

  /// No description provided for @tolClear.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get tolClear;

  /// No description provided for @tolClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation?'**
  String get tolClearTitle;

  /// No description provided for @tolClearBody.
  ///
  /// In en, this message translates to:
  /// **'Your chat with Tol will be removed from this phone.'**
  String get tolClearBody;

  /// No description provided for @tolShareContext.
  ///
  /// In en, this message translates to:
  /// **'Let Tol use my household summary'**
  String get tolShareContext;

  /// No description provided for @tolShareContextSub.
  ///
  /// In en, this message translates to:
  /// **'Household size, who\'s in it, barangay, readiness and missing supplies. Never names or phone numbers.'**
  String get tolShareContextSub;

  /// No description provided for @tolSuggestGoBag.
  ///
  /// In en, this message translates to:
  /// **'What should I pack in my go-bag?'**
  String get tolSuggestGoBag;

  /// No description provided for @tolSuggestWater.
  ///
  /// In en, this message translates to:
  /// **'How many days of water do we have?'**
  String get tolSuggestWater;

  /// No description provided for @tolSuggestStart.
  ///
  /// In en, this message translates to:
  /// **'What should I do first to get ready?'**
  String get tolSuggestStart;

  /// No description provided for @tolSuggestFlood.
  ///
  /// In en, this message translates to:
  /// **'How do I prepare for a flood?'**
  String get tolSuggestFlood;

  /// No description provided for @tolOffEmergency.
  ///
  /// In en, this message translates to:
  /// **'If you or someone near you is in danger right now, call 911 or alert people nearby. Move to higher ground if it\'s safe to do so, and follow your barangay officials and QC DRRMO.'**
  String get tolOffEmergency;

  /// No description provided for @tolOffAlerts.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have live weather or hazard alerts. Please check PAGASA and QC DRRMO\'s official channels for current advisories.'**
  String get tolOffAlerts;

  /// No description provided for @tolOffGoBag.
  ///
  /// In en, this message translates to:
  /// **'Your go-bag has {done} of {total} items packed. Next to pack: {items}.'**
  String tolOffGoBag(Object done, Object items, Object total);

  /// No description provided for @tolOffGoBagDone.
  ///
  /// In en, this message translates to:
  /// **'Your go-bag checklist is complete. Review it every month and replace anything used or expired.'**
  String get tolOffGoBagDone;

  /// No description provided for @tolOffWater.
  ///
  /// In en, this message translates to:
  /// **'Your stored water covers about {days} days for {count, plural, =1{1 person} other{{count} people}}. Your target is {target} days.'**
  String tolOffWater(num count, Object days, Object target);

  /// No description provided for @tolOffWaterNone.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added drinking water to Supply coverage yet. Add it there and I can tell you how many days it covers.'**
  String get tolOffWaterNone;

  /// No description provided for @tolOffFood.
  ///
  /// In en, this message translates to:
  /// **'Your stored food covers about {days} days for {count, plural, =1{1 person} other{{count} people}}. Your target is {target} days.'**
  String tolOffFood(num count, Object days, Object target);

  /// No description provided for @tolOffFoodNone.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added food in meals to Supply coverage yet. Add it there and I can tell you how many days it covers.'**
  String get tolOffFoodNone;

  /// No description provided for @tolOffExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expired: {expired}. Expiring within 30 days: {soon}.'**
  String tolOffExpiry(Object expired, Object soon);

  /// No description provided for @tolOffExpiryNone.
  ///
  /// In en, this message translates to:
  /// **'None of your saved supplies are expired or expiring in the next 30 days.'**
  String get tolOffExpiryNone;

  /// No description provided for @tolOffReadiness.
  ///
  /// In en, this message translates to:
  /// **'Your readiness score is {score}%. A good next step: {tip}'**
  String tolOffReadiness(Object score, Object tip);

  /// No description provided for @tolOffReadinessNoTip.
  ///
  /// In en, this message translates to:
  /// **'Your readiness score is {score}%. Nothing urgent right now. Keep your supplies fresh.'**
  String tolOffReadinessNoTip(Object score);

  /// No description provided for @tolOffEvacuation.
  ///
  /// In en, this message translates to:
  /// **'Open Safe places to see the map. The evacuation centers there are still sample data, not verified, so follow QC DRRMO and your barangay for official evacuation centers.'**
  String get tolOffEvacuation;

  /// No description provided for @tolOffContacts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{You haven\'t saved any emergency contacts yet. Add them in Profile & household.} =1{You have 1 emergency contact saved. Consider adding a backup.} other{You have {count} emergency contacts saved.}}'**
  String tolOffContacts(num count);

  /// No description provided for @tolOffGuideReady.
  ///
  /// In en, this message translates to:
  /// **'Open the {category} guide in the Disaster guidebook. It\'s saved for offline reading.'**
  String tolOffGuideReady(Object category);

  /// No description provided for @tolOffGuideSoon.
  ///
  /// In en, this message translates to:
  /// **'The {category} guide isn\'t written yet. For now, follow official advice from QC DRRMO, PAGASA and PHIVOLCS.'**
  String tolOffGuideSoon(Object category);

  /// No description provided for @tolOffGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m in offline mode, so I can only use what\'s saved on this phone. Ask me about your go-bag, water and food supplies, expiring items, readiness score, emergency contacts, safe places or the guidebook.'**
  String get tolOffGreeting;

  /// No description provided for @tolOffFallback.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t match that offline. I can help with your go-bag, water and food supplies, expiring items, readiness score, emergency contacts, safe places and the guidebook.'**
  String get tolOffFallback;

  /// No description provided for @orcTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline readiness'**
  String get orcTitle;

  /// No description provided for @orcIntro.
  ///
  /// In en, this message translates to:
  /// **'What TolongApp can still do on this phone without internet.'**
  String get orcIntro;

  /// No description provided for @orcReadyCount.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} ready offline'**
  String orcReadyCount(Object ready, Object total);

  /// No description provided for @orcMap.
  ///
  /// In en, this message translates to:
  /// **'Street map'**
  String get orcMap;

  /// No description provided for @orcAreaData.
  ///
  /// In en, this message translates to:
  /// **'Quezon City boundary and barangays'**
  String get orcAreaData;

  /// No description provided for @orcAreaDataBody.
  ///
  /// In en, this message translates to:
  /// **'Built into the app: the city outline and all 142 barangays for search.'**
  String get orcAreaDataBody;

  /// No description provided for @orcCenters.
  ///
  /// In en, this message translates to:
  /// **'Evacuation centers'**
  String get orcCenters;

  /// No description provided for @orcCentersBody.
  ///
  /// In en, this message translates to:
  /// **'{count} centers built into the app. Development sample only, not verified.'**
  String orcCentersBody(Object count);

  /// No description provided for @orcAlerts.
  ///
  /// In en, this message translates to:
  /// **'Hazard alerts'**
  String get orcAlerts;

  /// No description provided for @orcAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'No alert source is connected yet, so there are no saved alerts. Follow QC DRRMO and PAGASA for official advisories.'**
  String get orcAlertsBody;

  /// No description provided for @orcGuidebook.
  ///
  /// In en, this message translates to:
  /// **'Disaster guidebook'**
  String get orcGuidebook;

  /// No description provided for @orcGuidebookBody.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} guides have content. Guides are built into the app and work offline.'**
  String orcGuidebookBody(Object ready, Object total);

  /// No description provided for @orcHousehold.
  ///
  /// In en, this message translates to:
  /// **'Your household data'**
  String get orcHousehold;

  /// No description provided for @orcHouseholdBody.
  ///
  /// In en, this message translates to:
  /// **'Profile, contacts, supplies and checklist are saved encrypted on this phone.'**
  String get orcHouseholdBody;

  /// No description provided for @orcTol.
  ///
  /// In en, this message translates to:
  /// **'Tol offline help'**
  String get orcTol;

  /// No description provided for @orcTolBody.
  ///
  /// In en, this message translates to:
  /// **'Not available yet. Offline guidance arrives with the Tol assistant.'**
  String get orcTolBody;

  /// No description provided for @orcSync.
  ///
  /// In en, this message translates to:
  /// **'Account backup'**
  String get orcSync;

  /// No description provided for @orcSyncGuest.
  ///
  /// In en, this message translates to:
  /// **'Emergency access: data stays on this phone and is not backed up.'**
  String get orcSyncGuest;

  /// No description provided for @orcSyncOff.
  ///
  /// In en, this message translates to:
  /// **'Account backup isn\'t set up in this build.'**
  String get orcSyncOff;

  /// No description provided for @orcSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Not backed up yet.'**
  String get orcSyncNever;

  /// No description provided for @orcSyncLast.
  ///
  /// In en, this message translates to:
  /// **'Last backed up {time}.'**
  String orcSyncLast(Object time);

  /// No description provided for @orcSyncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everything is backed up.} =1{1 change waiting to upload.} other{{count} changes waiting to upload.}}'**
  String orcSyncPending(num count);

  /// No description provided for @orcSyncError.
  ///
  /// In en, this message translates to:
  /// **'The last backup attempt failed. It will retry automatically.'**
  String get orcSyncError;

  /// No description provided for @orcSyncing.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get orcSyncing;

  /// No description provided for @orcSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get orcSyncNow;

  /// No description provided for @orcStorage.
  ///
  /// In en, this message translates to:
  /// **'Offline map storage: {size} MB'**
  String orcStorage(Object size);

  /// No description provided for @guidebookEyebrow.
  ///
  /// In en, this message translates to:
  /// **'LEARN WHAT TO DO'**
  String get guidebookEyebrow;

  /// No description provided for @guidebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Disaster guidebook'**
  String get guidebookTitle;

  /// No description provided for @guidebookSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get guidebookSeeAll;

  /// No description provided for @guidebookIntro.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step guidance for common hazards in Quezon City. Every guide will cite its official source and is saved in the app for offline reading.'**
  String get guidebookIntro;

  /// No description provided for @guideSectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Coming soon} =1{1 section} other{{count} sections}}'**
  String guideSectionCount(num count);

  /// No description provided for @guideComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{category} preparedness guide coming soon.'**
  String guideComingSoon(Object category);

  /// No description provided for @guideVisualSoon.
  ///
  /// In en, this message translates to:
  /// **'Visual, step-by-step instructions from official sources will be added here.'**
  String get guideVisualSoon;

  /// No description provided for @guideOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved in the app · works offline'**
  String get guideOffline;

  /// No description provided for @guideSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String guideSource(Object source);

  /// No description provided for @guideBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get guideBefore;

  /// No description provided for @guideDuring.
  ///
  /// In en, this message translates to:
  /// **'During'**
  String get guideDuring;

  /// No description provided for @guideAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get guideAfter;

  /// No description provided for @guideGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get guideGeneral;

  /// No description provided for @brgySearch.
  ///
  /// In en, this message translates to:
  /// **'Search barangay'**
  String get brgySearch;

  /// No description provided for @brgySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type a barangay name'**
  String get brgySearchHint;

  /// No description provided for @brgyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No Quezon City barangay matches that name.'**
  String get brgyNoMatch;

  /// No description provided for @brgyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear barangay'**
  String get brgyClear;

  /// No description provided for @brgyShowing.
  ///
  /// In en, this message translates to:
  /// **'Barangay {name}'**
  String brgyShowing(Object name);

  /// No description provided for @brgyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a barangay from the Quezon City list.'**
  String get brgyInvalid;

  /// No description provided for @brgySource.
  ///
  /// In en, this message translates to:
  /// **'Barangay list and city boundary: OpenStreetMap (142 barangays, matching PSA).'**
  String get brgySource;

  /// No description provided for @centersFromBarangay.
  ///
  /// In en, this message translates to:
  /// **'Distances are measured from the center of Barangay {name}.'**
  String centersFromBarangay(Object name);

  /// No description provided for @offTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline map'**
  String get offTitle;

  /// No description provided for @offIntro.
  ///
  /// In en, this message translates to:
  /// **'Save the Quezon City street map on this phone so it still shows without internet.'**
  String get offIntro;

  /// No description provided for @offIncludes.
  ///
  /// In en, this message translates to:
  /// **'Includes streets and places across Quezon City. Evacuation centers, barangays and the city boundary are already built into the app.'**
  String get offIncludes;

  /// No description provided for @offNotIncluded.
  ///
  /// In en, this message translates to:
  /// **'Not included yet: planning new routes offline and live alerts.'**
  String get offNotIncluded;

  /// No description provided for @offEstimate.
  ///
  /// In en, this message translates to:
  /// **'About {tiles} map tiles. OpenFreeMap allows up to 3,000 per download.'**
  String offEstimate(Object tiles);

  /// No description provided for @offWifi.
  ///
  /// In en, this message translates to:
  /// **'Use Wi-Fi if you can.'**
  String get offWifi;

  /// No description provided for @offStatusNone.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get offStatusNone;

  /// No description provided for @offStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String offStatusDownloading(Object percent);

  /// No description provided for @offStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {date} · {size} MB'**
  String offStatusDone(Object date, Object size);

  /// No description provided for @offStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'The download didn\'t finish. Check your connection and try again.'**
  String get offStatusFailed;

  /// No description provided for @offUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Offline maps work in the Android app, not in the web preview.'**
  String get offUnsupported;

  /// No description provided for @offDownload.
  ///
  /// In en, this message translates to:
  /// **'Download Quezon City map'**
  String get offDownload;

  /// No description provided for @offRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get offRetry;

  /// No description provided for @offDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete offline map'**
  String get offDelete;

  /// No description provided for @offDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the offline map?'**
  String get offDeleteTitle;

  /// No description provided for @offDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The map will need internet again until you download it.'**
  String get offDeleteBody;

  /// No description provided for @offDeleted.
  ///
  /// In en, this message translates to:
  /// **'Offline map deleted.'**
  String get offDeleted;

  /// No description provided for @routeShow.
  ///
  /// In en, this message translates to:
  /// **'Show route'**
  String get routeShow;

  /// No description provided for @routeProfileWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get routeProfileWalking;

  /// No description provided for @routeProfileWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair'**
  String get routeProfileWheelchair;

  /// No description provided for @routeWheelchairNote.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair routes rely on OpenStreetMap accessibility tags, which can be incomplete in Quezon City.'**
  String get routeWheelchairNote;

  /// No description provided for @routeLoading.
  ///
  /// In en, this message translates to:
  /// **'Finding a route…'**
  String get routeLoading;

  /// No description provided for @routeSummary.
  ///
  /// In en, this message translates to:
  /// **'{km} km · about {minutes} min'**
  String routeSummary(Object km, Object minutes);

  /// No description provided for @routeNeedsLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow your location so the route can start from where you are.'**
  String get routeNeedsLocation;

  /// No description provided for @routeErrNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Route planning isn\'t set up in this build yet. It needs the Supabase route service.'**
  String get routeErrNotConfigured;

  /// No description provided for @routeErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the route service. Check your internet connection.'**
  String get routeErrNetwork;

  /// No description provided for @routeErrNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route found between your location and this center.'**
  String get routeErrNoRoute;

  /// No description provided for @routeErrOutside.
  ///
  /// In en, this message translates to:
  /// **'Routes are only available inside Quezon City.'**
  String get routeErrOutside;

  /// No description provided for @routeErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The route service is busy. Please try again in a minute.'**
  String get routeErrQuota;

  /// No description provided for @routeErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while planning the route. Please try again.'**
  String get routeErrUnknown;

  /// No description provided for @routeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Shortest route from OpenStreetMap road data. It does not know about current floods or road closures. Follow official advisories.'**
  String get routeDisclaimer;

  /// No description provided for @navTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navTitle;

  /// No description provided for @navPreviewNote.
  ///
  /// In en, this message translates to:
  /// **'Route preview with your live location. This is not turn-by-turn guidance.'**
  String get navPreviewNote;

  /// No description provided for @navRemaining.
  ///
  /// In en, this message translates to:
  /// **'{km} km to {name} in a straight line'**
  String navRemaining(Object km, Object name);

  /// No description provided for @navOffRoute.
  ///
  /// In en, this message translates to:
  /// **'You may be off the route. Head back toward the green line.'**
  String get navOffRoute;

  /// No description provided for @navArrived.
  ///
  /// In en, this message translates to:
  /// **'You\'ve arrived near {name}.'**
  String navArrived(Object name);

  /// No description provided for @navEnd.
  ///
  /// In en, this message translates to:
  /// **'End navigation'**
  String get navEnd;

  /// No description provided for @navWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your location…'**
  String get navWaiting;

  /// No description provided for @navLocationLost.
  ///
  /// In en, this message translates to:
  /// **'Location updates stopped. Check that location is turned on.'**
  String get navLocationLost;

  /// No description provided for @typeSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get typeSchool;

  /// No description provided for @typeCoveredCourt.
  ///
  /// In en, this message translates to:
  /// **'Covered court'**
  String get typeCoveredCourt;

  /// No description provided for @typeBarangayHall.
  ///
  /// In en, this message translates to:
  /// **'Barangay hall'**
  String get typeBarangayHall;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other facility'**
  String get typeOther;

  /// No description provided for @prepareMiniGuideEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR GO-BAG'**
  String get prepareMiniGuideEyebrow;

  /// No description provided for @prepareMiniGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Make your kit easy to grab'**
  String get prepareMiniGuideTitle;

  /// No description provided for @prepareIntro.
  ///
  /// In en, this message translates to:
  /// **'Keep essentials together in one waterproof bag. Tap an item when it\'s packed. Progress saves automatically.'**
  String get prepareIntro;

  /// No description provided for @preparePacked.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} packed'**
  String preparePacked(Object done, Object total);

  /// No description provided for @prepareSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone · {time}'**
  String prepareSavedAt(Object time);

  /// No description provided for @prepareAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get prepareAddItem;

  /// No description provided for @prepareReset.
  ///
  /// In en, this message translates to:
  /// **'Reset checklist'**
  String get prepareReset;

  /// No description provided for @prepareResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset checklist?'**
  String get prepareResetTitle;

  /// No description provided for @prepareResetBody.
  ///
  /// In en, this message translates to:
  /// **'All items will be unchecked. Your custom items and edits are kept.'**
  String get prepareResetBody;

  /// No description provided for @prepareResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get prepareResetConfirm;

  /// No description provided for @prepareResetDone.
  ///
  /// In en, this message translates to:
  /// **'Checklist reset.'**
  String get prepareResetDone;

  /// No description provided for @suggestedChildren.
  ///
  /// In en, this message translates to:
  /// **'For children'**
  String get suggestedChildren;

  /// No description provided for @suggestedSeniors.
  ///
  /// In en, this message translates to:
  /// **'For seniors'**
  String get suggestedSeniors;

  /// No description provided for @suggestedPets.
  ///
  /// In en, this message translates to:
  /// **'For pets'**
  String get suggestedPets;

  /// No description provided for @suggestedAssistance.
  ///
  /// In en, this message translates to:
  /// **'For assistance needs'**
  String get suggestedAssistance;

  /// No description provided for @customTag.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customTag;

  /// No description provided for @itemEditorAdd.
  ///
  /// In en, this message translates to:
  /// **'Add checklist item'**
  String get itemEditorAdd;

  /// No description provided for @itemEditorEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get itemEditorEdit;

  /// No description provided for @itemEditorName.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemEditorName;

  /// No description provided for @itemEditorCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get itemEditorCategory;

  /// No description provided for @itemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an item name.'**
  String get itemNameRequired;

  /// No description provided for @removeItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove item?'**
  String get removeItemTitle;

  /// No description provided for @removeItemBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed from your checklist.'**
  String removeItemBody(Object name);

  /// No description provided for @itemActions.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String itemActions(Object name);

  /// No description provided for @recommendationsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED FOR YOU'**
  String get recommendationsEyebrow;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'What to do next'**
  String get recommendationsTitle;

  /// No description provided for @recommendationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing urgent. Keep supplies fresh and review your checklist every month.'**
  String get recommendationsEmpty;

  /// No description provided for @catWaterFood.
  ///
  /// In en, this message translates to:
  /// **'Water and food'**
  String get catWaterFood;

  /// No description provided for @catFirstAidMeds.
  ///
  /// In en, this message translates to:
  /// **'First aid and medication'**
  String get catFirstAidMeds;

  /// No description provided for @catLightPower.
  ///
  /// In en, this message translates to:
  /// **'Flashlights and batteries'**
  String get catLightPower;

  /// No description provided for @catClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get catClothing;

  /// No description provided for @catHygiene.
  ///
  /// In en, this message translates to:
  /// **'Hygiene supplies'**
  String get catHygiene;

  /// No description provided for @catDocuments.
  ///
  /// In en, this message translates to:
  /// **'Important documents'**
  String get catDocuments;

  /// No description provided for @catCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication tools'**
  String get catCommunication;

  /// No description provided for @catSpecialNeeds.
  ///
  /// In en, this message translates to:
  /// **'Special household needs'**
  String get catSpecialNeeds;

  /// No description provided for @tplWater.
  ///
  /// In en, this message translates to:
  /// **'Drinking water'**
  String get tplWater;

  /// No description provided for @tplFood.
  ///
  /// In en, this message translates to:
  /// **'Ready-to-eat food'**
  String get tplFood;

  /// No description provided for @tplCanOpener.
  ///
  /// In en, this message translates to:
  /// **'Manual can opener'**
  String get tplCanOpener;

  /// No description provided for @tplFirstAidKit.
  ///
  /// In en, this message translates to:
  /// **'First aid kit'**
  String get tplFirstAidKit;

  /// No description provided for @tplMedicines.
  ///
  /// In en, this message translates to:
  /// **'Prescription and maintenance medicines'**
  String get tplMedicines;

  /// No description provided for @tplMasks.
  ///
  /// In en, this message translates to:
  /// **'Face masks'**
  String get tplMasks;

  /// No description provided for @tplFlashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get tplFlashlight;

  /// No description provided for @tplBatteries.
  ///
  /// In en, this message translates to:
  /// **'Extra batteries'**
  String get tplBatteries;

  /// No description provided for @tplPowerBank.
  ///
  /// In en, this message translates to:
  /// **'Charged power bank and cable'**
  String get tplPowerBank;

  /// No description provided for @tplClothes.
  ///
  /// In en, this message translates to:
  /// **'Change of clothes'**
  String get tplClothes;

  /// No description provided for @tplRainGear.
  ///
  /// In en, this message translates to:
  /// **'Raincoat or poncho'**
  String get tplRainGear;

  /// No description provided for @tplBlanket.
  ///
  /// In en, this message translates to:
  /// **'Blanket or emergency foil blanket'**
  String get tplBlanket;

  /// No description provided for @tplToiletries.
  ///
  /// In en, this message translates to:
  /// **'Toiletries (soap, toothbrush, alcohol)'**
  String get tplToiletries;

  /// No description provided for @tplSanitary.
  ///
  /// In en, this message translates to:
  /// **'Sanitary pads and tissues'**
  String get tplSanitary;

  /// No description provided for @tplDocuments.
  ///
  /// In en, this message translates to:
  /// **'Copies of IDs and documents in a waterproof bag'**
  String get tplDocuments;

  /// No description provided for @tplCash.
  ///
  /// In en, this message translates to:
  /// **'Cash in small bills and coins'**
  String get tplCash;

  /// No description provided for @tplContactList.
  ///
  /// In en, this message translates to:
  /// **'Written list of emergency contacts'**
  String get tplContactList;

  /// No description provided for @tplWhistle.
  ///
  /// In en, this message translates to:
  /// **'Whistle'**
  String get tplWhistle;

  /// No description provided for @tplRadio.
  ///
  /// In en, this message translates to:
  /// **'Battery-powered radio'**
  String get tplRadio;

  /// No description provided for @tplInfantSupplies.
  ///
  /// In en, this message translates to:
  /// **'Diapers, milk or formula for infants'**
  String get tplInfantSupplies;

  /// No description provided for @tplChildComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort item or toy for children'**
  String get tplChildComfort;

  /// No description provided for @tplSeniorMeds.
  ///
  /// In en, this message translates to:
  /// **'Seniors\' maintenance medicines and prescriptions'**
  String get tplSeniorMeds;

  /// No description provided for @tplMobilityAids.
  ///
  /// In en, this message translates to:
  /// **'Glasses, hearing aids or mobility aids'**
  String get tplMobilityAids;

  /// No description provided for @tplPetSupplies.
  ///
  /// In en, this message translates to:
  /// **'Pet food, water and bowl'**
  String get tplPetSupplies;

  /// No description provided for @tplPetCarrier.
  ///
  /// In en, this message translates to:
  /// **'Leash or carrier and pet vaccination records'**
  String get tplPetCarrier;

  /// No description provided for @tplAssistiveDevices.
  ///
  /// In en, this message translates to:
  /// **'Assistive devices and spare batteries'**
  String get tplAssistiveDevices;

  /// No description provided for @recRemoveExpired.
  ///
  /// In en, this message translates to:
  /// **'{name} has expired. Replace it.'**
  String recRemoveExpired(Object name);

  /// No description provided for @recAddWater.
  ///
  /// In en, this message translates to:
  /// **'Add about {liters} L of water to cover {days} days.'**
  String recAddWater(Object days, Object liters);

  /// No description provided for @recAddFood.
  ///
  /// In en, this message translates to:
  /// **'Add about {meals} meals to cover {days} days.'**
  String recAddFood(Object days, Object meals);

  /// No description provided for @recAddFirstContact.
  ///
  /// In en, this message translates to:
  /// **'Add at least one emergency contact.'**
  String get recAddFirstContact;

  /// No description provided for @recAddBackupContact.
  ///
  /// In en, this message translates to:
  /// **'Add one more emergency contact as a backup.'**
  String get recAddBackupContact;

  /// No description provided for @recSetUpHousehold.
  ///
  /// In en, this message translates to:
  /// **'Tell us who lives with you for accurate estimates.'**
  String get recSetUpHousehold;

  /// No description provided for @recSetBarangay.
  ///
  /// In en, this message translates to:
  /// **'Add your barangay to your profile.'**
  String get recSetBarangay;

  /// No description provided for @recPack.
  ///
  /// In en, this message translates to:
  /// **'Your go-bag still needs: {item}.'**
  String recPack(Object item);

  /// No description provided for @recAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add supplies: {category}.'**
  String recAddCategory(Object category);

  /// No description provided for @recExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{{name} expires today.} =1{{name} expires tomorrow.} other{{name} expires in {days} days.}}'**
  String recExpiringSoon(num days, Object name);

  /// No description provided for @supWater.
  ///
  /// In en, this message translates to:
  /// **'Drinking water'**
  String get supWater;

  /// No description provided for @supFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get supFood;

  /// No description provided for @supMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get supMedicine;

  /// No description provided for @supFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get supFirstAid;

  /// No description provided for @supHygiene.
  ///
  /// In en, this message translates to:
  /// **'Hygiene supplies'**
  String get supHygiene;

  /// No description provided for @supLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting and batteries'**
  String get supLighting;

  /// No description provided for @supOther.
  ///
  /// In en, this message translates to:
  /// **'Other essentials'**
  String get supOther;

  /// No description provided for @unitLiters.
  ///
  /// In en, this message translates to:
  /// **'liters'**
  String get unitLiters;

  /// No description provided for @unitMilliliters.
  ///
  /// In en, this message translates to:
  /// **'mL'**
  String get unitMilliliters;

  /// No description provided for @unitGallons.
  ///
  /// In en, this message translates to:
  /// **'gallons'**
  String get unitGallons;

  /// No description provided for @unitBottles.
  ///
  /// In en, this message translates to:
  /// **'bottles'**
  String get unitBottles;

  /// No description provided for @unitMeals.
  ///
  /// In en, this message translates to:
  /// **'meals'**
  String get unitMeals;

  /// No description provided for @unitPacks.
  ///
  /// In en, this message translates to:
  /// **'packs'**
  String get unitPacks;

  /// No description provided for @unitCans.
  ///
  /// In en, this message translates to:
  /// **'cans'**
  String get unitCans;

  /// No description provided for @unitPieces.
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get unitPieces;

  /// No description provided for @unitTablets.
  ///
  /// In en, this message translates to:
  /// **'tablets'**
  String get unitTablets;

  /// No description provided for @unitBoxes.
  ///
  /// In en, this message translates to:
  /// **'boxes'**
  String get unitBoxes;

  /// No description provided for @unitKilograms.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKilograms;

  /// No description provided for @suppliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Supply coverage'**
  String get suppliesTitle;

  /// No description provided for @suppliesEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Estimates for {count, plural, =1{1 person} other{{count} people}} using your targets. They\'re a planning guide, not a guarantee.'**
  String suppliesEstimateNote(num count);

  /// No description provided for @suppliesHouseholdUnknown.
  ///
  /// In en, this message translates to:
  /// **'Household size isn\'t set, so estimates assume 1 person.'**
  String get suppliesHouseholdUnknown;

  /// No description provided for @suppliesWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get suppliesWater;

  /// No description provided for @suppliesFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get suppliesFood;

  /// No description provided for @coverageDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String coverageDays(Object days);

  /// No description provided for @coverageTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: {days} days'**
  String coverageTarget(Object days);

  /// No description provided for @coverageWaterStored.
  ///
  /// In en, this message translates to:
  /// **'{liters} L stored · needs {perDay} L a day'**
  String coverageWaterStored(Object liters, Object perDay);

  /// No description provided for @coverageFoodStored.
  ///
  /// In en, this message translates to:
  /// **'{meals} meals stored · needs {perDay} meals a day'**
  String coverageFoodStored(Object meals, Object perDay);

  /// No description provided for @coverageShortWater.
  ///
  /// In en, this message translates to:
  /// **'Short by {liters} L'**
  String coverageShortWater(Object liters);

  /// No description provided for @coverageShortFood.
  ///
  /// In en, this message translates to:
  /// **'Short by {meals} meals'**
  String coverageShortFood(Object meals);

  /// No description provided for @coverageMet.
  ///
  /// In en, this message translates to:
  /// **'Target met'**
  String get coverageMet;

  /// No description provided for @coverageUnknownItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item isn\'t counted yet: add its amount per unit.} other{{count} items aren\'t counted yet: add their amount per unit.}}'**
  String coverageUnknownItems(num count);

  /// No description provided for @suppliesEssentials.
  ///
  /// In en, this message translates to:
  /// **'Essentials'**
  String get suppliesEssentials;

  /// No description provided for @essentialCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String essentialCount(num count);

  /// No description provided for @essentialNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get essentialNone;

  /// No description provided for @suppliesInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get suppliesInventory;

  /// No description provided for @suppliesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No supplies yet. Add what you already have at home.'**
  String get suppliesEmpty;

  /// No description provided for @suppliesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add supply'**
  String get suppliesAdd;

  /// No description provided for @expiredTag.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredTag;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(Object date);

  /// No description provided for @expiresSoonTag.
  ///
  /// In en, this message translates to:
  /// **'Expires soon'**
  String get expiresSoonTag;

  /// No description provided for @lastsAbout.
  ///
  /// In en, this message translates to:
  /// **'Lasts about {days} days'**
  String lastsAbout(Object days);

  /// No description provided for @suppliesHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How estimates work'**
  String get suppliesHowTitle;

  /// No description provided for @suppliesHowBody.
  ///
  /// In en, this message translates to:
  /// **'Water days = liters stored ÷ (people × liters per person per day). Food days = meals stored ÷ (people × meals per person per day). Expired items are not counted. The supply score gives water 30% and food 30% (based on days covered against your target), plus 10% each for having medicines, first aid, hygiene supplies and lighting. Change targets in Settings.'**
  String get suppliesHowBody;

  /// No description provided for @supplyEditorAdd.
  ///
  /// In en, this message translates to:
  /// **'Add supply'**
  String get supplyEditorAdd;

  /// No description provided for @supplyEditorEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit supply'**
  String get supplyEditorEdit;

  /// No description provided for @supplyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get supplyName;

  /// No description provided for @supplyCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supplyCategory;

  /// No description provided for @supplyQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get supplyQuantity;

  /// No description provided for @supplyUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get supplyUnit;

  /// No description provided for @supplyPerUnitWater.
  ///
  /// In en, this message translates to:
  /// **'Liters in one ({unit})'**
  String supplyPerUnitWater(Object unit);

  /// No description provided for @supplyPerUnitFood.
  ///
  /// In en, this message translates to:
  /// **'Meals in one ({unit})'**
  String supplyPerUnitFood(Object unit);

  /// No description provided for @supplyPerUnitHelp.
  ///
  /// In en, this message translates to:
  /// **'Needed to include this item in the coverage estimate.'**
  String get supplyPerUnitHelp;

  /// No description provided for @supplyDailyUse.
  ///
  /// In en, this message translates to:
  /// **'Daily use (optional)'**
  String get supplyDailyUse;

  /// No description provided for @supplyDailyUseHelp.
  ///
  /// In en, this message translates to:
  /// **'How many {unit} your household uses per day'**
  String supplyDailyUseHelp(Object unit);

  /// No description provided for @supplyExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiration date (optional)'**
  String get supplyExpiry;

  /// No description provided for @supplyExpiryNone.
  ///
  /// In en, this message translates to:
  /// **'No expiration date'**
  String get supplyExpiryNone;

  /// No description provided for @supplyExpiryPick.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get supplyExpiryPick;

  /// No description provided for @supplyExpiryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get supplyExpiryClear;

  /// No description provided for @quantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than 0.'**
  String get quantityInvalid;

  /// No description provided for @numberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get numberInvalid;

  /// No description provided for @removeSupplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove supply?'**
  String get removeSupplyTitle;

  /// No description provided for @removeSupplyBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed from your inventory.'**
  String removeSupplyBody(Object name);

  /// No description provided for @supplySaved.
  ///
  /// In en, this message translates to:
  /// **'Supply saved.'**
  String get supplySaved;

  /// No description provided for @readinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Household readiness'**
  String get readinessTitle;

  /// No description provided for @readinessHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How the score works'**
  String get readinessHowTitle;

  /// No description provided for @readinessHowBody.
  ///
  /// In en, this message translates to:
  /// **'The score adds up four parts: go-bag checklist (40%), supply coverage (30%), emergency contacts (15%, full at 2 contacts) and household profile (15%: household details and barangay). It reflects what you\'ve recorded in the app. It is not a guarantee of safety.'**
  String get readinessHowBody;

  /// No description provided for @areaGoBag.
  ///
  /// In en, this message translates to:
  /// **'Go-bag checklist'**
  String get areaGoBag;

  /// No description provided for @areaSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supply coverage'**
  String get areaSupplies;

  /// No description provided for @areaContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get areaContacts;

  /// No description provided for @areaHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household profile'**
  String get areaHousehold;

  /// No description provided for @areaPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} of {max} points'**
  String areaPoints(Object max, Object points);

  /// No description provided for @areaGoBagDetail.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} items packed'**
  String areaGoBagDetail(Object done, Object total);

  /// No description provided for @areaSuppliesDetail.
  ///
  /// In en, this message translates to:
  /// **'Water {water} days · Food {food} days'**
  String areaSuppliesDetail(Object food, Object water);

  /// No description provided for @areaContactsDetail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No contacts yet} =1{1 contact} other{{count} contacts}}'**
  String areaContactsDetail(num count);

  /// No description provided for @householdDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Household details saved'**
  String get householdDetailsSaved;

  /// No description provided for @householdDetailsMissing.
  ///
  /// In en, this message translates to:
  /// **'Household details missing'**
  String get householdDetailsMissing;

  /// No description provided for @barangaySet.
  ///
  /// In en, this message translates to:
  /// **'Barangay set'**
  String get barangaySet;

  /// No description provided for @barangayMissing.
  ///
  /// In en, this message translates to:
  /// **'Barangay missing'**
  String get barangayMissing;

  /// No description provided for @readinessNextActions.
  ///
  /// In en, this message translates to:
  /// **'Recommended next actions'**
  String get readinessNextActions;

  /// No description provided for @openChecklist.
  ///
  /// In en, this message translates to:
  /// **'Open checklist'**
  String get openChecklist;

  /// No description provided for @openSupplies.
  ///
  /// In en, this message translates to:
  /// **'Open supplies'**
  String get openSupplies;

  /// No description provided for @openHousehold.
  ///
  /// In en, this message translates to:
  /// **'Open household'**
  String get openHousehold;

  /// No description provided for @moreProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile & household'**
  String get moreProfile;

  /// No description provided for @moreContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get moreContacts;

  /// No description provided for @moreReadiness.
  ///
  /// In en, this message translates to:
  /// **'Household readiness'**
  String get moreReadiness;

  /// No description provided for @moreSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supply coverage'**
  String get moreSupplies;

  /// No description provided for @moreGuidebook.
  ///
  /// In en, this message translates to:
  /// **'Disaster guidebook'**
  String get moreGuidebook;

  /// No description provided for @moreOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline readiness'**
  String get moreOffline;

  /// No description provided for @moreSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get moreSettings;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'TolongApp is a preparedness aid, not an official emergency service. In an emergency, follow Quezon City DRRMO and national advisories.'**
  String get disclaimer;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @leaveGuest.
  ///
  /// In en, this message translates to:
  /// **'Leave emergency access'**
  String get leaveGuest;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your household information stays on this phone so it\'s still there when you log back in.'**
  String get signOutBody;

  /// No description provided for @leaveGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave emergency access?'**
  String get leaveGuestTitle;

  /// No description provided for @leaveGuestBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll return to the welcome screen. Data you added in emergency access stays on this phone.'**
  String get leaveGuestBody;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @welcomeMeetTol.
  ///
  /// In en, this message translates to:
  /// **'MEET TOL'**
  String get welcomeMeetTol;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety starts with preparation.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'TolongApp helps your household in Quezon City get ready for floods, typhoons and earthquakes, one small step at a time. Tol, your preparedness companion, will guide you.'**
  String get welcomeBody;

  /// No description provided for @welcomeNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Online accounts aren\'t configured in this build, so sign-up and login won\'t work yet. Emergency access works on this device.'**
  String get welcomeNotConfigured;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @emergencyAccess.
  ///
  /// In en, this message translates to:
  /// **'Emergency access without an account'**
  String get emergencyAccess;

  /// No description provided for @guestSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency access'**
  String get guestSheetTitle;

  /// No description provided for @guestSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Use TolongApp without an account. Anything you add stays only on this phone and is not backed up or synced. Your account data, if you have one, is not shown in this mode.'**
  String get guestSheetBody;

  /// No description provided for @guestContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get guestContinue;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your household\'s preparedness.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHere;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account.'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We only ask for what TolongApp needs to personalize your preparedness.'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @barangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get barangay;

  /// No description provided for @barangayHelper.
  ///
  /// In en, this message translates to:
  /// **'Your Quezon City barangay'**
  String get barangayHelper;

  /// No description provided for @privacyAccept.
  ///
  /// In en, this message translates to:
  /// **'I have read the privacy notice and agree to how my data is used.'**
  String get privacyAccept;

  /// No description provided for @privacyAcceptRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept to continue.'**
  String get privacyAcceptRequired;

  /// No description provided for @readPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Read the privacy notice'**
  String get readPrivacy;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccount;

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Open it on this phone, then log in.'**
  String checkEmailBody(Object email);

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password.'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we\'ll send you a reset link.'**
  String get forgotSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @sendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get sendAgain;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, a reset link is on its way. Open it on this phone.'**
  String get resetSent;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password.'**
  String get resetTitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @saveNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get saveNewPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdated;

  /// No description provided for @errNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Online accounts aren\'t set up in this build yet. You can still use emergency access.'**
  String get errNotConfigured;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your internet connection and try again.'**
  String get errNetwork;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first. Check your inbox for the link.'**
  String get errEmailNotConfirmed;

  /// No description provided for @errAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Try logging in.'**
  String get errAlreadyRegistered;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errRateLimited;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Please choose a stronger password.'**
  String get errWeakPassword;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get errUnknown;

  /// No description provided for @valNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get valNameRequired;

  /// No description provided for @valNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long.'**
  String get valNameTooLong;

  /// No description provided for @valEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get valEmailRequired;

  /// No description provided for @valEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right.'**
  String get valEmailInvalid;

  /// No description provided for @valPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get valPasswordShort;

  /// No description provided for @valPasswordMix.
  ///
  /// In en, this message translates to:
  /// **'Include at least one letter and one number.'**
  String get valPasswordMix;

  /// No description provided for @valPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get valPasswordRequired;

  /// No description provided for @valPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get valPasswordMismatch;

  /// No description provided for @valAgeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age.'**
  String get valAgeRequired;

  /// No description provided for @valAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Enter an age between 1 and 120.'**
  String get valAgeRange;

  /// No description provided for @valPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number.'**
  String get valPhoneRequired;

  /// No description provided for @valPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a PH mobile (09XX XXX XXXX) or Metro Manila landline.'**
  String get valPhoneInvalid;

  /// No description provided for @valRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String valRequired(Object field);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get privacyTitle;

  /// No description provided for @privacyDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft for the TolongApp academic prototype'**
  String get privacyDraft;

  /// No description provided for @privacyCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get privacyCollectTitle;

  /// No description provided for @privacyCollectBody.
  ///
  /// In en, this message translates to:
  /// **'Your name, email, age and Quezon City barangay. During setup you may also add household size, optional assistance needs, pets and emergency contacts. Optional questions can be skipped.'**
  String get privacyCollectBody;

  /// No description provided for @privacyWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get privacyWhyTitle;

  /// No description provided for @privacyWhyBody.
  ///
  /// In en, this message translates to:
  /// **'To personalize preparedness checklists, supply estimates and evacuation suggestions for your household.'**
  String get privacyWhyBody;

  /// No description provided for @privacyWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where it is stored'**
  String get privacyWhereTitle;

  /// No description provided for @privacyWhereBody.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved encrypted on this phone first. If you have an account, your profile, household details, emergency contacts, supplies and checklist are also backed up to our Supabase database, protected so only you can read them. In emergency access, nothing leaves the phone.'**
  String get privacyWhereBody;

  /// No description provided for @privacyNotTitle.
  ///
  /// In en, this message translates to:
  /// **'What we don\'t do'**
  String get privacyNotTitle;

  /// No description provided for @privacyNotBody.
  ///
  /// In en, this message translates to:
  /// **'We don\'t sell your data or share it with advertisers. TolongApp is not an official emergency service; always follow advisories from Quezon City DRRMO and national agencies.'**
  String get privacyNotBody;

  /// No description provided for @privacyChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get privacyChoicesTitle;

  /// No description provided for @privacyChoicesBody.
  ///
  /// In en, this message translates to:
  /// **'You can edit your information at any time, clear the data on this phone, and delete your account from Settings.'**
  String get privacyChoicesBody;

  /// No description provided for @onbStep.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} OF {total}'**
  String onbStep(Object current, Object total);

  /// No description provided for @onbAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you.'**
  String get onbAboutTitle;

  /// No description provided for @onbAboutSub.
  ///
  /// In en, this message translates to:
  /// **'This helps Tol tailor tips to you and your barangay.'**
  String get onbAboutSub;

  /// No description provided for @onbHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Who lives with you?'**
  String get onbHouseholdTitle;

  /// No description provided for @onbHouseholdSub.
  ///
  /// In en, this message translates to:
  /// **'Household size shapes how much water and food you should prepare.'**
  String get onbHouseholdSub;

  /// No description provided for @onbSkipOptional.
  ///
  /// In en, this message translates to:
  /// **'Skip the optional questions'**
  String get onbSkipOptional;

  /// No description provided for @onbContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Who should we call?'**
  String get onbContactsTitle;

  /// No description provided for @onbContactsSub.
  ///
  /// In en, this message translates to:
  /// **'Add people you would contact in an emergency. Saved only on this phone.'**
  String get onbContactsSub;

  /// No description provided for @onbNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet. You can also add them later from your profile.'**
  String get onbNoContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add a contact'**
  String get addContact;

  /// No description provided for @onbPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your preferences.'**
  String get onbPrefsTitle;

  /// No description provided for @onbPrefsSub.
  ///
  /// In en, this message translates to:
  /// **'Android will ask for permission the first time a feature needs it. You can change these later in Settings.'**
  String get onbPrefsSub;

  /// No description provided for @prefReminders.
  ///
  /// In en, this message translates to:
  /// **'Preparedness reminders'**
  String get prefReminders;

  /// No description provided for @prefRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Reminders to check supplies and your go-bag'**
  String get prefRemindersSub;

  /// No description provided for @prefLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get prefLocation;

  /// No description provided for @prefLocationSub.
  ///
  /// In en, this message translates to:
  /// **'To find evacuation centers near you'**
  String get prefLocationSub;

  /// No description provided for @prefOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline emergency information'**
  String get prefOffline;

  /// No description provided for @prefOfflineSub.
  ///
  /// In en, this message translates to:
  /// **'Download maps and guides when they become available'**
  String get prefOfflineSub;

  /// No description provided for @onbWelcomeTitleName.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TolongApp, {name}!'**
  String onbWelcomeTitleName(Object name);

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TolongApp!'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Tol. I\'ll help you build your go-bag, keep track of supplies, and know where to go when you need to leave home. Let\'s start with small steps.'**
  String get onbWelcomeBody;

  /// No description provided for @continueToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Continue to dashboard'**
  String get continueToDashboard;

  /// No description provided for @setupProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup progress'**
  String get setupProgress;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @adultsCaption.
  ///
  /// In en, this message translates to:
  /// **'Ages 18–59, including you'**
  String get adultsCaption;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @childrenCaption.
  ///
  /// In en, this message translates to:
  /// **'Under 18'**
  String get childrenCaption;

  /// No description provided for @seniors.
  ///
  /// In en, this message translates to:
  /// **'Senior citizens'**
  String get seniors;

  /// No description provided for @seniorsCaption.
  ///
  /// In en, this message translates to:
  /// **'60 and above'**
  String get seniorsCaption;

  /// No description provided for @fewerOf.
  ///
  /// In en, this message translates to:
  /// **'Fewer {label}'**
  String fewerOf(Object label);

  /// No description provided for @moreOf.
  ///
  /// In en, this message translates to:
  /// **'More {label}'**
  String moreOf(Object label);

  /// No description provided for @householdSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Household size: {count}'**
  String householdSizeLabel(Object count);

  /// No description provided for @petsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Any pets? (optional)'**
  String get petsQuestion;

  /// No description provided for @assistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistance needs (optional)'**
  String get assistanceLabel;

  /// No description provided for @assistanceHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. wheelchair user, needs daily medication. Leave blank if you prefer.'**
  String get assistanceHelper;

  /// No description provided for @contactAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contact'**
  String get contactAddTitle;

  /// No description provided for @contactEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get contactEditTitle;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @relationshipHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sister, Neighbor'**
  String get relationshipHint;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'0917 123 4567'**
  String get phoneHint;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get saveContact;

  /// No description provided for @removeContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove contact?'**
  String get removeContactTitle;

  /// No description provided for @removeContactBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from your emergency contacts.'**
  String removeContactBody(Object name);

  /// No description provided for @editNamed.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editNamed(Object name);

  /// No description provided for @removeNamed.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeNamed(Object name);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & household'**
  String get profileTitle;

  /// No description provided for @profileGuestNote.
  ///
  /// In en, this message translates to:
  /// **'Emergency access: this information is saved only on this phone and is not backed up.'**
  String get profileGuestNote;

  /// No description provided for @sectionYou.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get sectionYou;

  /// No description provided for @sectionHousehold.
  ///
  /// In en, this message translates to:
  /// **'HOUSEHOLD'**
  String get sectionHousehold;

  /// No description provided for @sectionContacts.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY CONTACTS'**
  String get sectionContacts;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notSetUpYet.
  ///
  /// In en, this message translates to:
  /// **'Not set up yet.'**
  String get notSetUpYet;

  /// No description provided for @pets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get pets;

  /// No description provided for @assistanceNeeds.
  ///
  /// In en, this message translates to:
  /// **'Assistance needs'**
  String get assistanceNeeds;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet.'**
  String get noContactsYet;

  /// No description provided for @editDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit your details.'**
  String get editDetailsTitle;

  /// No description provided for @editHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit your household.'**
  String get editHouseholdTitle;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @householdSaved.
  ///
  /// In en, this message translates to:
  /// **'Household saved.'**
  String get householdSaved;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @setAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get setAccount;

  /// No description provided for @setProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile information'**
  String get setProfile;

  /// No description provided for @setChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get setChangePassword;

  /// No description provided for @setChangePasswordSub.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a reset link'**
  String get setChangePasswordSub;

  /// No description provided for @setChangePasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}.'**
  String setChangePasswordSent(Object email);

  /// No description provided for @setDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get setDeleteAccount;

  /// No description provided for @setDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get setDeleteTitle;

  /// No description provided for @setDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your TolongApp account and profile from our server and removes your household data from this phone. This can\'t be undone.'**
  String get setDeleteBody;

  /// No description provided for @setDeleteDone.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get setDeleteDone;

  /// No description provided for @setGuestAccountNote.
  ///
  /// In en, this message translates to:
  /// **'You\'re using emergency access. Create an account to back up your profile.'**
  String get setGuestAccountNote;

  /// No description provided for @setPreferences.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get setPreferences;

  /// No description provided for @setReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get setReduceMotion;

  /// No description provided for @setReduceMotionSub.
  ///
  /// In en, this message translates to:
  /// **'Turn off decorative animations'**
  String get setReduceMotionSub;

  /// No description provided for @setTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get setTextSize;

  /// No description provided for @textNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textLarge;

  /// No description provided for @textLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textLarger;

  /// No description provided for @setTargets.
  ///
  /// In en, this message translates to:
  /// **'Preparedness targets'**
  String get setTargets;

  /// No description provided for @setTargetsSub.
  ///
  /// In en, this message translates to:
  /// **'Used for supply coverage estimates'**
  String get setTargetsSub;

  /// No description provided for @setWaterTarget.
  ///
  /// In en, this message translates to:
  /// **'Water per person per day (L)'**
  String get setWaterTarget;

  /// No description provided for @setWaterTargetSub.
  ///
  /// In en, this message translates to:
  /// **'Default 3.8 L (about 1 gallon), a widely used guideline'**
  String get setWaterTargetSub;

  /// No description provided for @setMealsTarget.
  ///
  /// In en, this message translates to:
  /// **'Meals per person per day'**
  String get setMealsTarget;

  /// No description provided for @setDaysTarget.
  ///
  /// In en, this message translates to:
  /// **'Days to prepare for'**
  String get setDaysTarget;

  /// No description provided for @setDaysTargetSub.
  ///
  /// In en, this message translates to:
  /// **'Default 3 days (a 72-hour kit)'**
  String get setDaysTargetSub;

  /// No description provided for @setNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get setNotifications;

  /// No description provided for @setNotificationsNote.
  ///
  /// In en, this message translates to:
  /// **'Your choices are saved. Reminders start once notifications are added in a later update.'**
  String get setNotificationsNote;

  /// No description provided for @setReminders.
  ///
  /// In en, this message translates to:
  /// **'Preparedness reminders'**
  String get setReminders;

  /// No description provided for @setExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiration reminders'**
  String get setExpiry;

  /// No description provided for @setHazard.
  ///
  /// In en, this message translates to:
  /// **'Hazard alert notifications'**
  String get setHazard;

  /// No description provided for @setLocation.
  ///
  /// In en, this message translates to:
  /// **'Location and maps'**
  String get setLocation;

  /// No description provided for @setLocationNote.
  ///
  /// In en, this message translates to:
  /// **'Android will ask for permission when the live map arrives.'**
  String get setLocationNote;

  /// No description provided for @setDefaultBarangay.
  ///
  /// In en, this message translates to:
  /// **'Default barangay'**
  String get setDefaultBarangay;

  /// No description provided for @setOfflineMaps.
  ///
  /// In en, this message translates to:
  /// **'Offline maps'**
  String get setOfflineMaps;

  /// No description provided for @setPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get setPrivacy;

  /// No description provided for @setPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get setPrivacyNotice;

  /// No description provided for @setStorage.
  ///
  /// In en, this message translates to:
  /// **'Where your data is stored'**
  String get setStorage;

  /// No description provided for @setStorageAccount.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved encrypted on this phone first, so it works offline. When you\'re online, your profile, household details, contacts, supplies and checklist are backed up to your account in Supabase, where only you can read them.'**
  String get setStorageAccount;

  /// No description provided for @setStorageGuest.
  ///
  /// In en, this message translates to:
  /// **'Everything is stored only on this phone.'**
  String get setStorageGuest;

  /// No description provided for @setClearLocal.
  ///
  /// In en, this message translates to:
  /// **'Clear data on this phone'**
  String get setClearLocal;

  /// No description provided for @setClearLocalSub.
  ///
  /// In en, this message translates to:
  /// **'Removes household, contacts, supplies and checklist from this phone'**
  String get setClearLocalSub;

  /// No description provided for @setClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear data on this phone?'**
  String get setClearTitle;

  /// No description provided for @setClearBody.
  ///
  /// In en, this message translates to:
  /// **'Household details, contacts, supplies and checklist progress will be removed from this phone. Your account stays, and anything already backed up to it can return the next time it syncs.'**
  String get setClearBody;

  /// No description provided for @setClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get setClearConfirm;

  /// No description provided for @setCleared.
  ///
  /// In en, this message translates to:
  /// **'Data on this phone was cleared.'**
  String get setCleared;

  /// No description provided for @setInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get setInfo;

  /// No description provided for @setAbout.
  ///
  /// In en, this message translates to:
  /// **'About TolongApp'**
  String get setAbout;

  /// No description provided for @setAboutBody.
  ///
  /// In en, this message translates to:
  /// **'TolongApp is an academic disaster-preparedness project for households in Quezon City, made by Brizuela, Dela Calzada and Lambot for CS 403 at the Technological Institute of the Philippines.'**
  String get setAboutBody;

  /// No description provided for @setVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get setVersion;

  /// No description provided for @setDataSources.
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get setDataSources;

  /// No description provided for @setDataSourcesBody.
  ///
  /// In en, this message translates to:
  /// **'Supply targets follow widely published preparedness guidelines and can be changed above. Hazard alerts, maps and evacuation centers will list their sources once connected.'**
  String get setDataSourcesBody;

  /// No description provided for @setMapAttribution.
  ///
  /// In en, this message translates to:
  /// **'Map attribution'**
  String get setMapAttribution;

  /// No description provided for @setMapAttributionBody.
  ///
  /// In en, this message translates to:
  /// **'Map tiles: OpenFreeMap, © OpenMapTiles. Map data, Quezon City boundary and barangay list © OpenStreetMap contributors (ODbL). Routing: openrouteservice.org by HeiGIT. Rendering: MapLibre. Evacuation centers currently shown are development samples, not official data.'**
  String get setMapAttributionBody;

  /// No description provided for @setDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Emergency disclaimer'**
  String get setDisclaimer;

  /// No description provided for @setLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get setLicenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

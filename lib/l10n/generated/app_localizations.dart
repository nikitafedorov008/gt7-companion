import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ru'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get general;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get audio;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @uiGtMenu.
  ///
  /// In en, this message translates to:
  /// **'GT Menu'**
  String get uiGtMenu;

  /// No description provided for @uiSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get uiSystemDefault;

  /// No description provided for @uiInterfaceSounds.
  ///
  /// In en, this message translates to:
  /// **'Interface sounds'**
  String get uiInterfaceSounds;

  /// No description provided for @uiAmbientMusic.
  ///
  /// In en, this message translates to:
  /// **'Ambient music'**
  String get uiAmbientMusic;

  /// No description provided for @uiMusicCredits.
  ///
  /// In en, this message translates to:
  /// **'Music credits'**
  String get uiMusicCredits;

  /// No description provided for @uiSourcesAndLicences.
  ///
  /// In en, this message translates to:
  /// **'Sources and licences'**
  String get uiSourcesAndLicences;

  /// No description provided for @uiApplicationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Application language'**
  String get uiApplicationLanguage;

  /// No description provided for @uiChooseTheLanguageUsedThroughoutTheApp.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used throughout the app.'**
  String get uiChooseTheLanguageUsedThroughoutTheApp;

  /// No description provided for @uiChangesApplyImmediatelyAndAreSavedOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Changes apply immediately and are saved on this device.'**
  String get uiChangesApplyImmediatelyAndAreSavedOnThisDevice;

  /// No description provided for @uiFollowTheLanguageOfYourDevice.
  ///
  /// In en, this message translates to:
  /// **'Follow the language of your device.'**
  String get uiFollowTheLanguageOfYourDevice;

  /// No description provided for @uiUnsupportedSystemLanguagesUseEnglish.
  ///
  /// In en, this message translates to:
  /// **'Unsupported system languages use English.'**
  String get uiUnsupportedSystemLanguagesUseEnglish;

  /// No description provided for @uiMenuMusicAndInterfaceFeedback.
  ///
  /// In en, this message translates to:
  /// **'Menu music and interface feedback.'**
  String get uiMenuMusicAndInterfaceFeedback;

  /// No description provided for @uiMusicAndEffectsKeepTheirExistingBalancedLevels.
  ///
  /// In en, this message translates to:
  /// **'Music and effects keep their existing balanced levels.'**
  String get uiMusicAndEffectsKeepTheirExistingBalancedLevels;

  /// No description provided for @uiCouldNotRestoreApplicationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Could not restore application preferences.'**
  String get uiCouldNotRestoreApplicationPreferences;

  /// No description provided for @uiCouldNotSaveApplicationPreferencesPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not save application preferences. Please retry.'**
  String get uiCouldNotSaveApplicationPreferencesPleaseRetry;

  /// No description provided for @uiGranTurismo7Companion.
  ///
  /// In en, this message translates to:
  /// **'Gran Turismo 7 Companion'**
  String get uiGranTurismo7Companion;

  /// No description provided for @uiGt7Companion.
  ///
  /// In en, this message translates to:
  /// **'GT7 Companion'**
  String get uiGt7Companion;

  /// No description provided for @uiBrandCentral.
  ///
  /// In en, this message translates to:
  /// **'Brand Central'**
  String get uiBrandCentral;

  /// No description provided for @uiBeyondTheApex.
  ///
  /// In en, this message translates to:
  /// **'Beyond the Apex'**
  String get uiBeyondTheApex;

  /// No description provided for @uiGtAuto.
  ///
  /// In en, this message translates to:
  /// **'GT Auto'**
  String get uiGtAuto;

  /// No description provided for @uiTheGranTurismoMagazine.
  ///
  /// In en, this message translates to:
  /// **'The Gran Turismo Magazine'**
  String get uiTheGranTurismoMagazine;

  /// No description provided for @uiAllGt7Cars.
  ///
  /// In en, this message translates to:
  /// **'All GT7 cars'**
  String get uiAllGt7Cars;

  /// No description provided for @uiAllMarques.
  ///
  /// In en, this message translates to:
  /// **'All marques'**
  String get uiAllMarques;

  /// No description provided for @uiAllRegions.
  ///
  /// In en, this message translates to:
  /// **'All regions'**
  String get uiAllRegions;

  /// No description provided for @uiAmerica.
  ///
  /// In en, this message translates to:
  /// **'America'**
  String get uiAmerica;

  /// No description provided for @uiNorthAmerica.
  ///
  /// In en, this message translates to:
  /// **'North America'**
  String get uiNorthAmerica;

  /// No description provided for @uiEurope.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get uiEurope;

  /// No description provided for @uiAsiaPacific.
  ///
  /// In en, this message translates to:
  /// **'Asia-Pacific'**
  String get uiAsiaPacific;

  /// No description provided for @uiOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get uiOther;

  /// No description provided for @uiJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get uiJapan;

  /// No description provided for @uiChina.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get uiChina;

  /// No description provided for @uiSouthKorea.
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get uiSouthKorea;

  /// No description provided for @uiUS.
  ///
  /// In en, this message translates to:
  /// **'U.S.'**
  String get uiUS;

  /// No description provided for @uiUnitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get uiUnitedStates;

  /// No description provided for @uiUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get uiUnitedKingdom;

  /// No description provided for @uiGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get uiGermany;

  /// No description provided for @uiFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get uiFrance;

  /// No description provided for @uiItaly.
  ///
  /// In en, this message translates to:
  /// **'Italy'**
  String get uiItaly;

  /// No description provided for @uiSweden.
  ///
  /// In en, this message translates to:
  /// **'Sweden'**
  String get uiSweden;

  /// No description provided for @uiAustria.
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get uiAustria;

  /// No description provided for @uiCzechRepublic.
  ///
  /// In en, this message translates to:
  /// **'Czech Republic'**
  String get uiCzechRepublic;

  /// No description provided for @uiSelectAManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Select a manufacturer'**
  String get uiSelectAManufacturer;

  /// No description provided for @uiSelectARegion.
  ///
  /// In en, this message translates to:
  /// **'Select a region'**
  String get uiSelectARegion;

  /// No description provided for @uiSearchBrandsOrCars.
  ///
  /// In en, this message translates to:
  /// **'Search brands or cars'**
  String get uiSearchBrandsOrCars;

  /// No description provided for @uiSearchTheOfficialCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Search the official catalogue'**
  String get uiSearchTheOfficialCatalogue;

  /// No description provided for @uiChooseACar.
  ///
  /// In en, this message translates to:
  /// **'Choose a car'**
  String get uiChooseACar;

  /// No description provided for @uiChangeCar.
  ///
  /// In en, this message translates to:
  /// **'Change car'**
  String get uiChangeCar;

  /// No description provided for @uiClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get uiClearSearch;

  /// No description provided for @uiClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get uiClear;

  /// No description provided for @uiCloseBrandCentral.
  ///
  /// In en, this message translates to:
  /// **'Close Brand Central'**
  String get uiCloseBrandCentral;

  /// No description provided for @uiBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get uiBack;

  /// No description provided for @uiBackToShowroom.
  ///
  /// In en, this message translates to:
  /// **'Back to showroom'**
  String get uiBackToShowroom;

  /// No description provided for @uiViewFullImage.
  ///
  /// In en, this message translates to:
  /// **'View full image'**
  String get uiViewFullImage;

  /// No description provided for @uiPreviousPhoto.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get uiPreviousPhoto;

  /// No description provided for @uiNextPhoto.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get uiNextPhoto;

  /// No description provided for @uiRetryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Retry photo'**
  String get uiRetryPhoto;

  /// No description provided for @uiRetryGallery.
  ///
  /// In en, this message translates to:
  /// **'Retry gallery'**
  String get uiRetryGallery;

  /// No description provided for @uiRetryCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Retry catalogue'**
  String get uiRetryCatalogue;

  /// No description provided for @uiRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get uiRetry;

  /// No description provided for @uiLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get uiLoading;

  /// No description provided for @uiLoadingCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Loading catalogue…'**
  String get uiLoadingCatalogue;

  /// No description provided for @uiCatalogueUnavailablePleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Catalogue unavailable. Please retry.'**
  String get uiCatalogueUnavailablePleaseRetry;

  /// No description provided for @uiGalleryUnavailableYourCatalogueAndHistoryAreStillAvailable.
  ///
  /// In en, this message translates to:
  /// **'Gallery unavailable. Your catalogue and history are still available.'**
  String get uiGalleryUnavailableYourCatalogueAndHistoryAreStillAvailable;

  /// No description provided for @uiNoMatchesTryAnotherNameOrRegion.
  ///
  /// In en, this message translates to:
  /// **'No matches. Try another name or region.'**
  String get uiNoMatchesTryAnotherNameOrRegion;

  /// No description provided for @uiNoCarsMatchThisSearch.
  ///
  /// In en, this message translates to:
  /// **'No cars match this search.'**
  String get uiNoCarsMatchThisSearch;

  /// No description provided for @uiNoOfficialDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No official description available.'**
  String get uiNoOfficialDescriptionAvailable;

  /// No description provided for @uiOfficialCataloguePreview.
  ///
  /// In en, this message translates to:
  /// **'Official catalogue preview'**
  String get uiOfficialCataloguePreview;

  /// No description provided for @uiOfficialGranTurismoCarCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Official Gran Turismo car catalogue'**
  String get uiOfficialGranTurismoCarCatalogue;

  /// No description provided for @uiOfficialPhotography.
  ///
  /// In en, this message translates to:
  /// **'Official photography'**
  String get uiOfficialPhotography;

  /// No description provided for @uiPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get uiPhotoUnavailable;

  /// No description provided for @uiHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get uiHistory;

  /// No description provided for @uiSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get uiSpecifications;

  /// No description provided for @uiGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get uiGallery;

  /// No description provided for @uiTheGalleryIsLoadingOrUnavailableUseRetryGalleryTo.
  ///
  /// In en, this message translates to:
  /// **'The gallery is loading or unavailable. Use Retry gallery to try again.'**
  String get uiTheGalleryIsLoadingOrUnavailableUseRetryGalleryTo;

  /// No description provided for @uiOpenOfficialSource.
  ///
  /// In en, this message translates to:
  /// **'Open official source'**
  String get uiOpenOfficialSource;

  /// No description provided for @uiOpenOfficialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open official website'**
  String get uiOpenOfficialWebsite;

  /// No description provided for @uiOpenOriginal.
  ///
  /// In en, this message translates to:
  /// **'Open original'**
  String get uiOpenOriginal;

  /// No description provided for @uiCouldNotOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Could not open source.'**
  String get uiCouldNotOpenSource;

  /// No description provided for @uiCouldNotOpenTheWebsitePleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not open the website. Please retry.'**
  String get uiCouldNotOpenTheWebsitePleaseRetry;

  /// No description provided for @uiSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get uiSource;

  /// No description provided for @uiSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get uiSources;

  /// No description provided for @uiOfficialGt7Catalogue.
  ///
  /// In en, this message translates to:
  /// **'Official GT7 catalogue'**
  String get uiOfficialGt7Catalogue;

  /// No description provided for @uiOfficialGt7CarList.
  ///
  /// In en, this message translates to:
  /// **'Official GT7 Car List'**
  String get uiOfficialGt7CarList;

  /// No description provided for @uiEnglishUsUsUnits.
  ///
  /// In en, this message translates to:
  /// **'English (US) · US units'**
  String get uiEnglishUsUsUnits;

  /// No description provided for @uiCarDataPhotographyPolyphonyDigitalGranTurismoComThisCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Car data & photography: Polyphony Digital / gran-turismo.com.\nThis catalogue includes all listed GT7 cars; availability in the game varies.'**
  String get uiCarDataPhotographyPolyphonyDigitalGranTurismoComThisCatalogue;

  /// No description provided for @uiNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get uiNameAZ;

  /// No description provided for @uiPerformancePoints.
  ///
  /// In en, this message translates to:
  /// **'Performance points'**
  String get uiPerformancePoints;

  /// No description provided for @uiCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get uiCategory;

  /// No description provided for @uiClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get uiClass;

  /// No description provided for @uiMaximumPower.
  ///
  /// In en, this message translates to:
  /// **'Maximum power'**
  String get uiMaximumPower;

  /// No description provided for @uiMaximumTorque.
  ///
  /// In en, this message translates to:
  /// **'Maximum torque'**
  String get uiMaximumTorque;

  /// No description provided for @uiPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get uiPower;

  /// No description provided for @uiPowerHp.
  ///
  /// In en, this message translates to:
  /// **'Power · HP'**
  String get uiPowerHp;

  /// No description provided for @uiTorque.
  ///
  /// In en, this message translates to:
  /// **'Torque'**
  String get uiTorque;

  /// No description provided for @uiTorqueKgfM.
  ///
  /// In en, this message translates to:
  /// **'Torque · kgf·m'**
  String get uiTorqueKgfM;

  /// No description provided for @uiWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get uiWeight;

  /// No description provided for @uiWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight · kg'**
  String get uiWeightKg;

  /// No description provided for @uiDisplacement.
  ///
  /// In en, this message translates to:
  /// **'Displacement'**
  String get uiDisplacement;

  /// No description provided for @uiDrivetrain.
  ///
  /// In en, this message translates to:
  /// **'Drivetrain'**
  String get uiDrivetrain;

  /// No description provided for @uiAspiration.
  ///
  /// In en, this message translates to:
  /// **'Aspiration'**
  String get uiAspiration;

  /// No description provided for @uiLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get uiLength;

  /// No description provided for @uiWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get uiWidth;

  /// No description provided for @uiHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get uiHeight;

  /// No description provided for @uiEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get uiEngine;

  /// No description provided for @uiEngineDimensions.
  ///
  /// In en, this message translates to:
  /// **'Engine & dimensions'**
  String get uiEngineDimensions;

  /// No description provided for @uiVehicleSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Vehicle specifications'**
  String get uiVehicleSpecifications;

  /// No description provided for @uiVehiclePassport.
  ///
  /// In en, this message translates to:
  /// **'Vehicle passport'**
  String get uiVehiclePassport;

  /// No description provided for @uiServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get uiServices;

  /// No description provided for @uiUsedCarDealer.
  ///
  /// In en, this message translates to:
  /// **'Used car dealer'**
  String get uiUsedCarDealer;

  /// No description provided for @uiUsedCars.
  ///
  /// In en, this message translates to:
  /// **'Used Cars'**
  String get uiUsedCars;

  /// No description provided for @uiUsedCarDealership.
  ///
  /// In en, this message translates to:
  /// **'USED CAR DEALERSHIP'**
  String get uiUsedCarDealership;

  /// No description provided for @uiLegendaryCarDealer.
  ///
  /// In en, this message translates to:
  /// **'Legendary car dealer'**
  String get uiLegendaryCarDealer;

  /// No description provided for @uiLegendCars.
  ///
  /// In en, this message translates to:
  /// **'Legend Cars'**
  String get uiLegendCars;

  /// No description provided for @uiLimitedStock.
  ///
  /// In en, this message translates to:
  /// **'LIMITED STOCK'**
  String get uiLimitedStock;

  /// No description provided for @uiSoldOut.
  ///
  /// In en, this message translates to:
  /// **'SOLD OUT'**
  String get uiSoldOut;

  /// No description provided for @uiStock.
  ///
  /// In en, this message translates to:
  /// **'STOCK'**
  String get uiStock;

  /// No description provided for @uiErrorLoadingLegendCarData.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Legend Car Data'**
  String get uiErrorLoadingLegendCarData;

  /// No description provided for @uiErrorLoadingUsedCarData.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Used Car Data'**
  String get uiErrorLoadingUsedCarData;

  /// No description provided for @uiWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get uiWorkshop;

  /// No description provided for @uiCarCatalogueCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Car catalogue could not be loaded.'**
  String get uiCarCatalogueCouldNotBeLoaded;

  /// No description provided for @uiRefreshWorkshopData.
  ///
  /// In en, this message translates to:
  /// **'Refresh workshop data'**
  String get uiRefreshWorkshopData;

  /// No description provided for @uiEngineSwaps.
  ///
  /// In en, this message translates to:
  /// **'Engine swaps'**
  String get uiEngineSwaps;

  /// No description provided for @uiPartsBody.
  ///
  /// In en, this message translates to:
  /// **'Parts & body'**
  String get uiPartsBody;

  /// No description provided for @uiBuildPlan.
  ///
  /// In en, this message translates to:
  /// **'Build plan'**
  String get uiBuildPlan;

  /// No description provided for @uiYourPreparationChecklist.
  ///
  /// In en, this message translates to:
  /// **'Your preparation checklist'**
  String get uiYourPreparationChecklist;

  /// No description provided for @uiSelectedCarStock.
  ///
  /// In en, this message translates to:
  /// **'Selected car / stock'**
  String get uiSelectedCarStock;

  /// No description provided for @uiGarageGtAuto.
  ///
  /// In en, this message translates to:
  /// **'Garage / GT Auto'**
  String get uiGarageGtAuto;

  /// No description provided for @uiCommunityData.
  ///
  /// In en, this message translates to:
  /// **'Community data'**
  String get uiCommunityData;

  /// No description provided for @uiCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get uiCompatibility;

  /// No description provided for @uiCompatibilityComparison.
  ///
  /// In en, this message translates to:
  /// **'Compatibility & comparison'**
  String get uiCompatibilityComparison;

  /// No description provided for @uiCompatibleEngine.
  ///
  /// In en, this message translates to:
  /// **'Compatible engine'**
  String get uiCompatibleEngine;

  /// No description provided for @uiCompatibleAddToPlan.
  ///
  /// In en, this message translates to:
  /// **'Compatible · add to plan'**
  String get uiCompatibleAddToPlan;

  /// No description provided for @uiGtplusComparison.
  ///
  /// In en, this message translates to:
  /// **'GTPlus comparison'**
  String get uiGtplusComparison;

  /// No description provided for @uiStockSwap.
  ///
  /// In en, this message translates to:
  /// **'Stock → Swap'**
  String get uiStockSwap;

  /// No description provided for @uiAddToBuildPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to build plan'**
  String get uiAddToBuildPlan;

  /// No description provided for @uiInBuildPlan.
  ///
  /// In en, this message translates to:
  /// **'In build plan'**
  String get uiInBuildPlan;

  /// No description provided for @uiBuildNotes.
  ///
  /// In en, this message translates to:
  /// **'Build notes'**
  String get uiBuildNotes;

  /// No description provided for @uiSpecialParts.
  ///
  /// In en, this message translates to:
  /// **'Special parts'**
  String get uiSpecialParts;

  /// No description provided for @uiSpecialUpgrades.
  ///
  /// In en, this message translates to:
  /// **'Special upgrades'**
  String get uiSpecialUpgrades;

  /// No description provided for @uiInGameCost.
  ///
  /// In en, this message translates to:
  /// **'In-game cost'**
  String get uiInGameCost;

  /// No description provided for @uiNotDocumented.
  ///
  /// In en, this message translates to:
  /// **'Not documented'**
  String get uiNotDocumented;

  /// No description provided for @uiNotCompatible.
  ///
  /// In en, this message translates to:
  /// **'Not compatible'**
  String get uiNotCompatible;

  /// No description provided for @uiAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get uiAllowed;

  /// No description provided for @uiSavedEngineSourceCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Saved engine · source currently unavailable'**
  String get uiSavedEngineSourceCurrentlyUnavailable;

  /// No description provided for @uiLocalStorage.
  ///
  /// In en, this message translates to:
  /// **'Local storage'**
  String get uiLocalStorage;

  /// No description provided for @uiSavedOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get uiSavedOnThisDevice;

  /// No description provided for @uiYourPlanIsEmptyAddAnEngineFromEngineSwaps.
  ///
  /// In en, this message translates to:
  /// **'Your plan is empty. Add an engine from Engine swaps or choose compatible special parts.'**
  String get uiYourPlanIsEmptyAddAnEngineFromEngineSwaps;

  /// No description provided for @uiThisIsYourPreparationChecklistNotTheInstalledStateOf.
  ///
  /// In en, this message translates to:
  /// **'This is your preparation checklist, not the installed state of the game. PP and combined part effects must be checked in GT7.'**
  String get uiThisIsYourPreparationChecklistNotTheInstalledStateOf;

  /// No description provided for @uiCompatibilityRefersToTheStockCarEngineSwapsCanChange.
  ///
  /// In en, this message translates to:
  /// **'Compatibility refers to the stock car; engine swaps can change available upgrades. Regular tuning-shop parts and wide-body availability are not covered. Blank cells are unknown.'**
  String get uiCompatibilityRefersToTheStockCarEngineSwapsCanChange;

  /// No description provided for @uiNoConfirmedSwapRecordsForThisCarInTheCurrent.
  ///
  /// In en, this message translates to:
  /// **'No confirmed swap records for this car in the current source. This does not establish incompatibility.'**
  String get uiNoConfirmedSwapRecordsForThisCarInTheCurrent;

  /// No description provided for @uiAdditionalEngineAndDimensionDataIsNotDocumentedForThis.
  ///
  /// In en, this message translates to:
  /// **'Additional engine and dimension data is not documented for this car.'**
  String get uiAdditionalEngineAndDimensionDataIsNotDocumentedForThis;

  /// No description provided for @uiThisCarHasNoUniquelyMatchedRecordInTheSpecial.
  ///
  /// In en, this message translates to:
  /// **'This car has no uniquely matched record in the special-parts source. Compatibility is unknown.'**
  String get uiThisCarHasNoUniquelyMatchedRecordInTheSpecial;

  /// No description provided for @uiGtplusStockAndSwapFiguresAreComparedWithinTheSame.
  ///
  /// In en, this message translates to:
  /// **'GTPlus stock and swap figures are compared within the same source. Official catalogue values may differ. Plan here; install in GT7.'**
  String get uiGtplusStockAndSwapFiguresAreComparedWithinTheSame;

  /// No description provided for @uiTheGameTracksTheseThreePerCarTheAppCannot.
  ///
  /// In en, this message translates to:
  /// **'The game tracks these three per car. The app cannot read them '**
  String get uiTheGameTracksTheseThreePerCarTheAppCannot;

  /// No description provided for @uiItHasNoAccessToYourSave.
  ///
  /// In en, this message translates to:
  /// **'— it has no access to your save.'**
  String get uiItHasNoAccessToYourSave;

  /// No description provided for @uiCouldNotRestoreSavedWorkshopPlans.
  ///
  /// In en, this message translates to:
  /// **'Could not restore saved workshop plans.'**
  String get uiCouldNotRestoreSavedWorkshopPlans;

  /// No description provided for @uiPlanChangesCouldNotBeSavedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Plan changes could not be saved. Try again.'**
  String get uiPlanChangesCouldNotBeSavedTryAgain;

  /// No description provided for @uiTyresRaceRequirementsSettings.
  ///
  /// In en, this message translates to:
  /// **'Tyres, race requirements, settings…'**
  String get uiTyresRaceRequirementsSettings;

  /// No description provided for @uiWideBody.
  ///
  /// In en, this message translates to:
  /// **'Wide body'**
  String get uiWideBody;

  /// No description provided for @uiOilChange.
  ///
  /// In en, this message translates to:
  /// **'Oil change'**
  String get uiOilChange;

  /// No description provided for @uiEngineOverhaul.
  ///
  /// In en, this message translates to:
  /// **'Engine overhaul'**
  String get uiEngineOverhaul;

  /// No description provided for @uiRestoreBodyRigidity.
  ///
  /// In en, this message translates to:
  /// **'Restore body rigidity'**
  String get uiRestoreBodyRigidity;

  /// No description provided for @uiMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get uiMileage;

  /// No description provided for @uiEngineCondition.
  ///
  /// In en, this message translates to:
  /// **'Engine condition'**
  String get uiEngineCondition;

  /// No description provided for @uiBodyRigidity.
  ///
  /// In en, this message translates to:
  /// **'Body rigidity'**
  String get uiBodyRigidity;

  /// No description provided for @uiDailyRaces.
  ///
  /// In en, this message translates to:
  /// **'Daily races'**
  String get uiDailyRaces;

  /// No description provided for @uiNextWeek.
  ///
  /// In en, this message translates to:
  /// **'NEXT WEEK'**
  String get uiNextWeek;

  /// No description provided for @uiPast.
  ///
  /// In en, this message translates to:
  /// **'PAST'**
  String get uiPast;

  /// No description provided for @uiFuture.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get uiFuture;

  /// No description provided for @uiActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get uiActive;

  /// No description provided for @uiEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get uiEnded;

  /// No description provided for @uiNoDailyRacesFound.
  ///
  /// In en, this message translates to:
  /// **'No daily races found.'**
  String get uiNoDailyRacesFound;

  /// No description provided for @uiRegulations.
  ///
  /// In en, this message translates to:
  /// **'Regulations'**
  String get uiRegulations;

  /// No description provided for @uiNoOfLaps.
  ///
  /// In en, this message translates to:
  /// **'No. of Laps'**
  String get uiNoOfLaps;

  /// No description provided for @uiEntrants.
  ///
  /// In en, this message translates to:
  /// **'Entrants'**
  String get uiEntrants;

  /// No description provided for @uiEntrantsByCountry.
  ///
  /// In en, this message translates to:
  /// **'Entrants by country'**
  String get uiEntrantsByCountry;

  /// No description provided for @uiEntrantsByRating.
  ///
  /// In en, this message translates to:
  /// **'Entrants by rating'**
  String get uiEntrantsByRating;

  /// No description provided for @uiGtshLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'GTSh leaderboard'**
  String get uiGtshLeaderboard;

  /// No description provided for @uiField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get uiField;

  /// No description provided for @uiLeader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get uiLeader;

  /// No description provided for @uiTop100.
  ///
  /// In en, this message translates to:
  /// **'Top 100'**
  String get uiTop100;

  /// No description provided for @uiTop1000.
  ///
  /// In en, this message translates to:
  /// **'Top 1000'**
  String get uiTop1000;

  /// No description provided for @uiTyreCompound.
  ///
  /// In en, this message translates to:
  /// **'Tyre compound'**
  String get uiTyreCompound;

  /// No description provided for @uiTyreWear.
  ///
  /// In en, this message translates to:
  /// **'Tyre wear'**
  String get uiTyreWear;

  /// No description provided for @uiFuelUse.
  ///
  /// In en, this message translates to:
  /// **'Fuel use'**
  String get uiFuelUse;

  /// No description provided for @uiRefuelling.
  ///
  /// In en, this message translates to:
  /// **'Refuelling'**
  String get uiRefuelling;

  /// No description provided for @uiConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get uiConfiguration;

  /// No description provided for @uiCarSetup.
  ///
  /// In en, this message translates to:
  /// **'Car setup'**
  String get uiCarSetup;

  /// No description provided for @uiStartType.
  ///
  /// In en, this message translates to:
  /// **'Start type'**
  String get uiStartType;

  /// No description provided for @uiFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get uiFixed;

  /// No description provided for @uiApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get uiApplied;

  /// No description provided for @uiBopApplied.
  ///
  /// In en, this message translates to:
  /// **'BoP Applied'**
  String get uiBopApplied;

  /// No description provided for @uiNoRaceEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No race events found'**
  String get uiNoRaceEventsFound;

  /// No description provided for @uiRecentRaces.
  ///
  /// In en, this message translates to:
  /// **'Recent Races'**
  String get uiRecentRaces;

  /// No description provided for @uiSignInToSeeYourRaceHistory.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your race history'**
  String get uiSignInToSeeYourRaceHistory;

  /// No description provided for @uiWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get uiWishlist;

  /// No description provided for @uiSavedCarsAndFavorites.
  ///
  /// In en, this message translates to:
  /// **'Saved cars and favorites'**
  String get uiSavedCarsAndFavorites;

  /// No description provided for @uiProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get uiProfile;

  /// No description provided for @uiSignInWithPlaystation.
  ///
  /// In en, this message translates to:
  /// **'Sign in with PlayStation'**
  String get uiSignInWithPlaystation;

  /// No description provided for @uiSignInViaPsn.
  ///
  /// In en, this message translates to:
  /// **'Sign in via PSN'**
  String get uiSignInViaPsn;

  /// No description provided for @uiConnectYourPsnAccountToSeeYourGt7ProfileStats.
  ///
  /// In en, this message translates to:
  /// **'Connect your PSN account to see your GT7 profile, stats, and race history.'**
  String get uiConnectYourPsnAccountToSeeYourGt7ProfileStats;

  /// No description provided for @uiAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get uiAboutMe;

  /// No description provided for @uiFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get uiFollowing;

  /// No description provided for @uiFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get uiFollowers;

  /// No description provided for @uiFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get uiFriends;

  /// No description provided for @uiRaces.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get uiRaces;

  /// No description provided for @uiWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get uiWins;

  /// No description provided for @uiTop5Finishes.
  ///
  /// In en, this message translates to:
  /// **'Top 5 finishes'**
  String get uiTop5Finishes;

  /// No description provided for @uiGoldFinishes.
  ///
  /// In en, this message translates to:
  /// **'Gold finishes'**
  String get uiGoldFinishes;

  /// No description provided for @uiSilverFinishes.
  ///
  /// In en, this message translates to:
  /// **'Silver finishes'**
  String get uiSilverFinishes;

  /// No description provided for @uiBronzeFinishes.
  ///
  /// In en, this message translates to:
  /// **'Bronze finishes'**
  String get uiBronzeFinishes;

  /// No description provided for @uiDriverRating.
  ///
  /// In en, this message translates to:
  /// **'Driver rating'**
  String get uiDriverRating;

  /// No description provided for @uiSafetyRating.
  ///
  /// In en, this message translates to:
  /// **'Safety rating'**
  String get uiSafetyRating;

  /// No description provided for @uiCollectionLevel.
  ///
  /// In en, this message translates to:
  /// **'Collection level'**
  String get uiCollectionLevel;

  /// No description provided for @uiCarCollection.
  ///
  /// In en, this message translates to:
  /// **'Car collection'**
  String get uiCarCollection;

  /// No description provided for @uiCarsPurchased.
  ///
  /// In en, this message translates to:
  /// **'Cars purchased'**
  String get uiCarsPurchased;

  /// No description provided for @uiCreditsEarned.
  ///
  /// In en, this message translates to:
  /// **'Credits earned'**
  String get uiCreditsEarned;

  /// No description provided for @uiSpentOnCars.
  ///
  /// In en, this message translates to:
  /// **'Spent on cars'**
  String get uiSpentOnCars;

  /// No description provided for @uiSpentOnTuning.
  ///
  /// In en, this message translates to:
  /// **'Spent on tuning'**
  String get uiSpentOnTuning;

  /// No description provided for @uiSpentOnCustomisation.
  ///
  /// In en, this message translates to:
  /// **'Spent on customisation'**
  String get uiSpentOnCustomisation;

  /// No description provided for @uiCarLife.
  ///
  /// In en, this message translates to:
  /// **'Car Life'**
  String get uiCarLife;

  /// No description provided for @uiDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get uiDriving;

  /// No description provided for @uiGamePlay.
  ///
  /// In en, this message translates to:
  /// **'Game Play'**
  String get uiGamePlay;

  /// No description provided for @uiGtWorld.
  ///
  /// In en, this message translates to:
  /// **'GT World'**
  String get uiGtWorld;

  /// No description provided for @uiSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get uiSport;

  /// No description provided for @uiSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get uiSocial;

  /// No description provided for @uiTotalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total distance'**
  String get uiTotalDistance;

  /// No description provided for @uiFuelUsed.
  ///
  /// In en, this message translates to:
  /// **'Fuel used'**
  String get uiFuelUsed;

  /// No description provided for @uiAverageConsumption.
  ///
  /// In en, this message translates to:
  /// **'Average consumption'**
  String get uiAverageConsumption;

  /// No description provided for @uiTimeDriving.
  ///
  /// In en, this message translates to:
  /// **'Time driving'**
  String get uiTimeDriving;

  /// No description provided for @uiDaysOnline.
  ///
  /// In en, this message translates to:
  /// **'Days online'**
  String get uiDaysOnline;

  /// No description provided for @uiPhotosTaken.
  ///
  /// In en, this message translates to:
  /// **'Photos taken'**
  String get uiPhotosTaken;

  /// No description provided for @uiPlayTime.
  ///
  /// In en, this message translates to:
  /// **'Play time'**
  String get uiPlayTime;

  /// No description provided for @uiCircuitExperience.
  ///
  /// In en, this message translates to:
  /// **'Circuit experience'**
  String get uiCircuitExperience;

  /// No description provided for @uiDriftPoints.
  ///
  /// In en, this message translates to:
  /// **'Drift points'**
  String get uiDriftPoints;

  /// No description provided for @uiLicence.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get uiLicence;

  /// No description provided for @uiCleanRaces.
  ///
  /// In en, this message translates to:
  /// **'Clean races'**
  String get uiCleanRaces;

  /// No description provided for @uiFastestLaps.
  ///
  /// In en, this message translates to:
  /// **'Fastest laps'**
  String get uiFastestLaps;

  /// No description provided for @uiPolePositions.
  ///
  /// In en, this message translates to:
  /// **'Pole positions'**
  String get uiPolePositions;

  /// No description provided for @uiSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get uiSignOut;

  /// No description provided for @uiSignInToPlaystation.
  ///
  /// In en, this message translates to:
  /// **'Sign in to PlayStation'**
  String get uiSignInToPlaystation;

  /// No description provided for @uiOpeningSignIn.
  ///
  /// In en, this message translates to:
  /// **'Opening sign-in…'**
  String get uiOpeningSignIn;

  /// No description provided for @uiConnectingToPlaystation.
  ///
  /// In en, this message translates to:
  /// **'Connecting to PlayStation…'**
  String get uiConnectingToPlaystation;

  /// No description provided for @uiFinishingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Finishing sign-in…'**
  String get uiFinishingSignIn;

  /// No description provided for @uiLoadingProfileImages.
  ///
  /// In en, this message translates to:
  /// **'Loading profile images…'**
  String get uiLoadingProfileImages;

  /// No description provided for @uiLoginDetectedExtractingToken.
  ///
  /// In en, this message translates to:
  /// **'Login detected! Extracting token…'**
  String get uiLoginDetectedExtractingToken;

  /// No description provided for @uiSuccessRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Success! Redirecting…'**
  String get uiSuccessRedirecting;

  /// No description provided for @uiPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get uiPleaseWait;

  /// No description provided for @uiShowThePage.
  ///
  /// In en, this message translates to:
  /// **'Show the page'**
  String get uiShowThePage;

  /// No description provided for @uiShowTrace.
  ///
  /// In en, this message translates to:
  /// **'Show trace'**
  String get uiShowTrace;

  /// No description provided for @uiCopyTraceToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy trace to clipboard'**
  String get uiCopyTraceToClipboard;

  /// No description provided for @uiClearingSession.
  ///
  /// In en, this message translates to:
  /// **'Clearing session…'**
  String get uiClearingSession;

  /// No description provided for @uiSessionClearedReloadingSignInPage.
  ///
  /// In en, this message translates to:
  /// **'Session cleared — reloading sign-in page'**
  String get uiSessionClearedReloadingSignInPage;

  /// No description provided for @uiSignOutOfTheSiteAndReload.
  ///
  /// In en, this message translates to:
  /// **'Sign out of the site and reload'**
  String get uiSignOutOfTheSiteAndReload;

  /// No description provided for @uiTracePsnSignInPages.
  ///
  /// In en, this message translates to:
  /// **'Trace PSN sign-in pages'**
  String get uiTracePsnSignInPages;

  /// No description provided for @uiPsnLoginFlow.
  ///
  /// In en, this message translates to:
  /// **'PSN login flow'**
  String get uiPsnLoginFlow;

  /// No description provided for @uiTelemetry.
  ///
  /// In en, this message translates to:
  /// **'TELEMETRY'**
  String get uiTelemetry;

  /// No description provided for @uiConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get uiConnect;

  /// No description provided for @uiDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get uiDisconnect;

  /// No description provided for @uiPlaystationIp.
  ///
  /// In en, this message translates to:
  /// **'PlayStation IP'**
  String get uiPlaystationIp;

  /// No description provided for @uiEnterIp.
  ///
  /// In en, this message translates to:
  /// **'Enter IP'**
  String get uiEnterIp;

  /// No description provided for @uiInvalidIp.
  ///
  /// In en, this message translates to:
  /// **'Invalid IP'**
  String get uiInvalidIp;

  /// No description provided for @uiFindPlaystation.
  ///
  /// In en, this message translates to:
  /// **'Find PlayStation'**
  String get uiFindPlaystation;

  /// No description provided for @uiDemoTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Demo telemetry'**
  String get uiDemoTelemetry;

  /// No description provided for @uiOpenDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open dashboard'**
  String get uiOpenDashboard;

  /// No description provided for @uiNotConnectedToGt7.
  ///
  /// In en, this message translates to:
  /// **'Not connected to GT7'**
  String get uiNotConnectedToGt7;

  /// No description provided for @uiNoPacketsReceivedYet.
  ///
  /// In en, this message translates to:
  /// **'No packets received yet.'**
  String get uiNoPacketsReceivedYet;

  /// No description provided for @uiScanForPlaystation.
  ///
  /// In en, this message translates to:
  /// **'Scan for PlayStation'**
  String get uiScanForPlaystation;

  /// No description provided for @uiQuickScanArp.
  ///
  /// In en, this message translates to:
  /// **'Quick Scan (ARP)'**
  String get uiQuickScanArp;

  /// No description provided for @uiScanningNetwork.
  ///
  /// In en, this message translates to:
  /// **'Scanning network...'**
  String get uiScanningNetwork;

  /// No description provided for @uiDeepScanningNetworkThisMayTake1030Seconds.
  ///
  /// In en, this message translates to:
  /// **'Deep scanning network (this may take 10-30 seconds)...'**
  String get uiDeepScanningNetworkThisMayTake1030Seconds;

  /// No description provided for @uiScanningLocalNetworkForPlaystationDevices.
  ///
  /// In en, this message translates to:
  /// **'Scanning local network for PlayStation devices...'**
  String get uiScanningLocalNetworkForPlaystationDevices;

  /// No description provided for @uiNoDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get uiNoDevicesFound;

  /// No description provided for @uiMakeSureYourPlaystationIsOnAndConnectedToThe.
  ///
  /// In en, this message translates to:
  /// **'Make sure your PlayStation is on and connected to the same network'**
  String get uiMakeSureYourPlaystationIsOnAndConnectedToThe;

  /// No description provided for @uiPacket.
  ///
  /// In en, this message translates to:
  /// **'PACKET'**
  String get uiPacket;

  /// No description provided for @uiSeeUdpservicePackettype.
  ///
  /// In en, this message translates to:
  /// **'(SEE UdpService.packetType)'**
  String get uiSeeUdpservicePackettype;

  /// No description provided for @ui296BytesPositionRotationLapTimesNoSteering.
  ///
  /// In en, this message translates to:
  /// **'296 bytes: position, rotation, lap times — no steering'**
  String get ui296BytesPositionRotationLapTimesNoSteering;

  /// No description provided for @ui316BytesAddsSteeringAngleAndGForces.
  ///
  /// In en, this message translates to:
  /// **'316 bytes: adds steering angle and g-forces'**
  String get ui316BytesAddsSteeringAngleAndGForces;

  /// No description provided for @ui368BytesAddsSurfacesAndCarCategory.
  ///
  /// In en, this message translates to:
  /// **'368 bytes: adds surfaces and car category'**
  String get ui368BytesAddsSurfacesAndCarCategory;

  /// No description provided for @uiConnected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get uiConnected;

  /// No description provided for @uiConnecting.
  ///
  /// In en, this message translates to:
  /// **'CONNECTING'**
  String get uiConnecting;

  /// No description provided for @uiOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get uiOffline;

  /// No description provided for @uiLinkError.
  ///
  /// In en, this message translates to:
  /// **'LINK ERROR'**
  String get uiLinkError;

  /// No description provided for @uiError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get uiError;

  /// No description provided for @uiDemo.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get uiDemo;

  /// No description provided for @uiLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get uiLive;

  /// No description provided for @uiData.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get uiData;

  /// No description provided for @uiNoData.
  ///
  /// In en, this message translates to:
  /// **'NO DATA'**
  String get uiNoData;

  /// No description provided for @uiWaitingForTelemetry.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR TELEMETRY'**
  String get uiWaitingForTelemetry;

  /// No description provided for @uiPosition.
  ///
  /// In en, this message translates to:
  /// **'POSITION'**
  String get uiPosition;

  /// No description provided for @uiLap.
  ///
  /// In en, this message translates to:
  /// **'LAP'**
  String get uiLap;

  /// No description provided for @uiLaps.
  ///
  /// In en, this message translates to:
  /// **'LAPS'**
  String get uiLaps;

  /// No description provided for @uiBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get uiBest;

  /// No description provided for @uiLast.
  ///
  /// In en, this message translates to:
  /// **'LAST'**
  String get uiLast;

  /// No description provided for @uiSessionBest.
  ///
  /// In en, this message translates to:
  /// **'SESSION BEST'**
  String get uiSessionBest;

  /// No description provided for @uiTheFastestLapOfTheSession.
  ///
  /// In en, this message translates to:
  /// **'THE FASTEST LAP OF THE SESSION'**
  String get uiTheFastestLapOfTheSession;

  /// No description provided for @uiTheoreticalBestNeedsSectorTimesWhichGt7DoesNotSend.
  ///
  /// In en, this message translates to:
  /// **'THEORETICAL BEST NEEDS SECTOR TIMES, WHICH GT7 DOES NOT SEND'**
  String get uiTheoreticalBestNeedsSectorTimesWhichGt7DoesNotSend;

  /// No description provided for @uiWaitingForACompletedLap.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR A COMPLETED LAP'**
  String get uiWaitingForACompletedLap;

  /// No description provided for @uiNoReferenceLapYet.
  ///
  /// In en, this message translates to:
  /// **'NO REFERENCE LAP YET'**
  String get uiNoReferenceLapYet;

  /// No description provided for @uiReferenceTimes.
  ///
  /// In en, this message translates to:
  /// **'Reference times'**
  String get uiReferenceTimes;

  /// No description provided for @uiBestLap.
  ///
  /// In en, this message translates to:
  /// **'Best Lap'**
  String get uiBestLap;

  /// No description provided for @uiThrottle.
  ///
  /// In en, this message translates to:
  /// **'THROTTLE'**
  String get uiThrottle;

  /// No description provided for @uiBrake.
  ///
  /// In en, this message translates to:
  /// **'BRAKE'**
  String get uiBrake;

  /// No description provided for @uiThrottleBrake.
  ///
  /// In en, this message translates to:
  /// **'THROTTLE / BRAKE'**
  String get uiThrottleBrake;

  /// No description provided for @uiThr.
  ///
  /// In en, this message translates to:
  /// **'THR'**
  String get uiThr;

  /// No description provided for @uiBrk.
  ///
  /// In en, this message translates to:
  /// **'BRK'**
  String get uiBrk;

  /// No description provided for @uiBrk314.
  ///
  /// In en, this message translates to:
  /// **'BRK %'**
  String get uiBrk314;

  /// No description provided for @uiGear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get uiGear;

  /// No description provided for @uiFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get uiFuel;

  /// No description provided for @uiTank.
  ///
  /// In en, this message translates to:
  /// **'TANK'**
  String get uiTank;

  /// No description provided for @uiPerLap.
  ///
  /// In en, this message translates to:
  /// **'PER LAP'**
  String get uiPerLap;

  /// No description provided for @uiRemaining.
  ///
  /// In en, this message translates to:
  /// **'REMAINING'**
  String get uiRemaining;

  /// No description provided for @uiStint.
  ///
  /// In en, this message translates to:
  /// **'STINT'**
  String get uiStint;

  /// No description provided for @uiWheel.
  ///
  /// In en, this message translates to:
  /// **'Wheel'**
  String get uiWheel;

  /// No description provided for @uiWheelbase.
  ///
  /// In en, this message translates to:
  /// **'WHEELBASE'**
  String get uiWheelbase;

  /// No description provided for @uiLeftWheelbase.
  ///
  /// In en, this message translates to:
  /// **'LEFT WHEELBASE'**
  String get uiLeftWheelbase;

  /// No description provided for @uiRideHeight.
  ///
  /// In en, this message translates to:
  /// **'RIDE HEIGHT'**
  String get uiRideHeight;

  /// No description provided for @uiGrip.
  ///
  /// In en, this message translates to:
  /// **'GRIP'**
  String get uiGrip;

  /// No description provided for @uiElev.
  ///
  /// In en, this message translates to:
  /// **'ELEV'**
  String get uiElev;

  /// No description provided for @uiElevation.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION'**
  String get uiElevation;

  /// No description provided for @uiElevationProfile.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION PROFILE'**
  String get uiElevationProfile;

  /// No description provided for @uiTempsPressures.
  ///
  /// In en, this message translates to:
  /// **'TEMPS & PRESSURES'**
  String get uiTempsPressures;

  /// No description provided for @uiTyresVehicle.
  ///
  /// In en, this message translates to:
  /// **'TYRES & VEHICLE'**
  String get uiTyresVehicle;

  /// No description provided for @uiTyres.
  ///
  /// In en, this message translates to:
  /// **'TYRES'**
  String get uiTyres;

  /// No description provided for @uiTyreSets.
  ///
  /// In en, this message translates to:
  /// **'Tyre sets'**
  String get uiTyreSets;

  /// No description provided for @uiOil.
  ///
  /// In en, this message translates to:
  /// **'OIL'**
  String get uiOil;

  /// No description provided for @uiOilPress.
  ///
  /// In en, this message translates to:
  /// **'OIL PRESS'**
  String get uiOilPress;

  /// No description provided for @uiWater.
  ///
  /// In en, this message translates to:
  /// **'WATER'**
  String get uiWater;

  /// No description provided for @uiOilTemp.
  ///
  /// In en, this message translates to:
  /// **'Oil Temp'**
  String get uiOilTemp;

  /// No description provided for @uiWaterTemp.
  ///
  /// In en, this message translates to:
  /// **'Water Temp'**
  String get uiWaterTemp;

  /// No description provided for @uiDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get uiDamage;

  /// No description provided for @uiPitStops.
  ///
  /// In en, this message translates to:
  /// **'Pit stops'**
  String get uiPitStops;

  /// No description provided for @uiSlipstream.
  ///
  /// In en, this message translates to:
  /// **'Slipstream'**
  String get uiSlipstream;

  /// No description provided for @uiBoost.
  ///
  /// In en, this message translates to:
  /// **'BOOST'**
  String get uiBoost;

  /// No description provided for @uiCharge.
  ///
  /// In en, this message translates to:
  /// **'CHARGE'**
  String get uiCharge;

  /// No description provided for @uiElectric.
  ///
  /// In en, this message translates to:
  /// **'ELECTRIC'**
  String get uiElectric;

  /// No description provided for @uiElectricDrivetrain.
  ///
  /// In en, this message translates to:
  /// **'ELECTRIC DRIVETRAIN'**
  String get uiElectricDrivetrain;

  /// No description provided for @uiEnergyRecovery.
  ///
  /// In en, this message translates to:
  /// **'ENERGY RECOVERY'**
  String get uiEnergyRecovery;

  /// No description provided for @uiEngaged.
  ///
  /// In en, this message translates to:
  /// **'ENGAGED'**
  String get uiEngaged;

  /// No description provided for @uiOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get uiOff;

  /// No description provided for @uiEnabled.
  ///
  /// In en, this message translates to:
  /// **'ENABLED'**
  String get uiEnabled;

  /// No description provided for @uiPreAidInput.
  ///
  /// In en, this message translates to:
  /// **'PRE-AID INPUT'**
  String get uiPreAidInput;

  /// No description provided for @uiAids.
  ///
  /// In en, this message translates to:
  /// **'AIDS'**
  String get uiAids;

  /// No description provided for @uiWaitingForInputData.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR INPUT DATA'**
  String get uiWaitingForInputData;

  /// No description provided for @uiSteering.
  ///
  /// In en, this message translates to:
  /// **'STEERING'**
  String get uiSteering;

  /// No description provided for @uiMotion.
  ///
  /// In en, this message translates to:
  /// **'MOTION'**
  String get uiMotion;

  /// No description provided for @uiDriftAngle.
  ///
  /// In en, this message translates to:
  /// **'DRIFT ANGLE'**
  String get uiDriftAngle;

  /// No description provided for @uiBodyRoll.
  ///
  /// In en, this message translates to:
  /// **'BODY ROLL'**
  String get uiBodyRoll;

  /// No description provided for @uiBodyPitch.
  ///
  /// In en, this message translates to:
  /// **'BODY PITCH'**
  String get uiBodyPitch;

  /// No description provided for @uiLongitudinal.
  ///
  /// In en, this message translates to:
  /// **'LONGITUDINAL'**
  String get uiLongitudinal;

  /// No description provided for @uiLateral.
  ///
  /// In en, this message translates to:
  /// **'LATERAL'**
  String get uiLateral;

  /// No description provided for @uiLat.
  ///
  /// In en, this message translates to:
  /// **'LAT'**
  String get uiLat;

  /// No description provided for @uiAcc.
  ///
  /// In en, this message translates to:
  /// **'ACC'**
  String get uiAcc;

  /// No description provided for @uiAccelerating.
  ///
  /// In en, this message translates to:
  /// **'ACCELERATING'**
  String get uiAccelerating;

  /// No description provided for @uiBraking.
  ///
  /// In en, this message translates to:
  /// **'BRAKING'**
  String get uiBraking;

  /// No description provided for @uiSliding.
  ///
  /// In en, this message translates to:
  /// **'SLIDING'**
  String get uiSliding;

  /// No description provided for @uiUndersteer.
  ///
  /// In en, this message translates to:
  /// **'UNDERSTEER'**
  String get uiUndersteer;

  /// No description provided for @uiOversteer.
  ///
  /// In en, this message translates to:
  /// **'OVERSTEER'**
  String get uiOversteer;

  /// No description provided for @uiLeaningLeft.
  ///
  /// In en, this message translates to:
  /// **'LEANING LEFT'**
  String get uiLeaningLeft;

  /// No description provided for @uiLeaningRight.
  ///
  /// In en, this message translates to:
  /// **'LEANING RIGHT'**
  String get uiLeaningRight;

  /// No description provided for @uiToTheLeft.
  ///
  /// In en, this message translates to:
  /// **'TO THE LEFT'**
  String get uiToTheLeft;

  /// No description provided for @uiToTheRight.
  ///
  /// In en, this message translates to:
  /// **'TO THE RIGHT'**
  String get uiToTheRight;

  /// No description provided for @uiTooCloseToCall.
  ///
  /// In en, this message translates to:
  /// **'TOO CLOSE TO CALL'**
  String get uiTooCloseToCall;

  /// No description provided for @uiLeftOfTravel.
  ///
  /// In en, this message translates to:
  /// **'LEFT OF TRAVEL'**
  String get uiLeftOfTravel;

  /// No description provided for @uiRightOfTravel.
  ///
  /// In en, this message translates to:
  /// **'RIGHT OF TRAVEL'**
  String get uiRightOfTravel;

  /// No description provided for @uiNose.
  ///
  /// In en, this message translates to:
  /// **'NOSE'**
  String get uiNose;

  /// No description provided for @uiNoseUp.
  ///
  /// In en, this message translates to:
  /// **'NOSE UP'**
  String get uiNoseUp;

  /// No description provided for @uiNoseDown.
  ///
  /// In en, this message translates to:
  /// **'NOSE DOWN'**
  String get uiNoseDown;

  /// No description provided for @uiNoseLeft.
  ///
  /// In en, this message translates to:
  /// **'NOSE LEFT'**
  String get uiNoseLeft;

  /// No description provided for @uiNoseRight.
  ///
  /// In en, this message translates to:
  /// **'NOSE RIGHT'**
  String get uiNoseRight;

  /// No description provided for @uiNoLoadData.
  ///
  /// In en, this message translates to:
  /// **'NO LOAD DATA'**
  String get uiNoLoadData;

  /// No description provided for @uiNoSurfaceData.
  ///
  /// In en, this message translates to:
  /// **'NO SURFACE DATA'**
  String get uiNoSurfaceData;

  /// No description provided for @uiNotInThisPacket.
  ///
  /// In en, this message translates to:
  /// **'NOT IN THIS PACKET'**
  String get uiNotInThisPacket;

  /// No description provided for @uiPacketAHasNoAttitude.
  ///
  /// In en, this message translates to:
  /// **'PACKET A HAS NO ATTITUDE'**
  String get uiPacketAHasNoAttitude;

  /// No description provided for @uiGearRatios.
  ///
  /// In en, this message translates to:
  /// **'GEAR RATIOS'**
  String get uiGearRatios;

  /// No description provided for @uiGearRatiosNotInThisPacket.
  ///
  /// In en, this message translates to:
  /// **'GEAR RATIOS NOT IN THIS PACKET'**
  String get uiGearRatiosNotInThisPacket;

  /// No description provided for @uiTrackMap.
  ///
  /// In en, this message translates to:
  /// **'TRACK MAP'**
  String get uiTrackMap;

  /// No description provided for @uiRoute.
  ///
  /// In en, this message translates to:
  /// **'ROUTE'**
  String get uiRoute;

  /// No description provided for @uiNorthUp.
  ///
  /// In en, this message translates to:
  /// **'NORTH UP'**
  String get uiNorthUp;

  /// No description provided for @uiHeadingUp.
  ///
  /// In en, this message translates to:
  /// **'HEADING UP'**
  String get uiHeadingUp;

  /// No description provided for @uiNoRouteYetGt7SendsTheCarSPositionIn.
  ///
  /// In en, this message translates to:
  /// **'NO ROUTE YET — GT7 SENDS THE CAR\'S POSITION IN EVERY PACKET, '**
  String get uiNoRouteYetGt7SendsTheCarSPositionIn;

  /// No description provided for @uiSoTheMapAppearsAsSoonAsYouMove.
  ///
  /// In en, this message translates to:
  /// **'SO THE MAP APPEARS AS SOON AS YOU MOVE'**
  String get uiSoTheMapAppearsAsSoonAsYouMove;

  /// No description provided for @uiItIsBuiltByDrivingNoCourseDataNoRivals.
  ///
  /// In en, this message translates to:
  /// **'IT IS BUILT BY DRIVING — NO COURSE DATA, NO RIVALS. GT7 SENDS NO TRACK '**
  String get uiItIsBuiltByDrivingNoCourseDataNoRivals;

  /// No description provided for @uiIdSoTheCircuitIsNamedOnlyWhenADriven.
  ///
  /// In en, this message translates to:
  /// **'ID, SO THE CIRCUIT IS NAMED ONLY WHEN A DRIVEN LAP MATCHES ONE'**
  String get uiIdSoTheCircuitIsNamedOnlyWhenADriven;

  /// No description provided for @uiNoElevationYetTheProfileNeedsADrivenLap.
  ///
  /// In en, this message translates to:
  /// **'NO ELEVATION YET — THE PROFILE NEEDS A DRIVEN LAP'**
  String get uiNoElevationYetTheProfileNeedsADrivenLap;

  /// No description provided for @uiTheProfileComesFromTheCarSHeightInEvery.
  ///
  /// In en, this message translates to:
  /// **'THE PROFILE COMES FROM THE CAR\'S HEIGHT IN EVERY PACKET — '**
  String get uiTheProfileComesFromTheCarSHeightInEvery;

  /// No description provided for @uiItAppearsAsSoonAsYouMove.
  ///
  /// In en, this message translates to:
  /// **'IT APPEARS AS SOON AS YOU MOVE'**
  String get uiItAppearsAsSoonAsYouMove;

  /// No description provided for @uiTheRouteComesFromThePositionGt7SendsInEvery.
  ///
  /// In en, this message translates to:
  /// **'THE ROUTE COMES FROM THE POSITION GT7 SENDS IN EVERY PACKET (X/Z), SO '**
  String get uiTheRouteComesFromThePositionGt7SendsInEvery;

  /// No description provided for @uiTheLoadVectorAndTheBodyAttitudeComeFromPacket.
  ///
  /// In en, this message translates to:
  /// **'THE LOAD VECTOR AND THE BODY ATTITUDE COME FROM PACKET '**
  String get uiTheLoadVectorAndTheBodyAttitudeComeFromPacket;

  /// No description provided for @uiLoadAndAttitudeAreNotInPacketAAskThe.
  ///
  /// In en, this message translates to:
  /// **'LOAD AND ATTITUDE ARE NOT IN PACKET A — ASK THE '**
  String get uiLoadAndAttitudeAreNotInPacketAAskThe;

  /// No description provided for @uiConsoleForHeartbeatBOrC.
  ///
  /// In en, this message translates to:
  /// **'CONSOLE FOR HEARTBEAT B OR C '**
  String get uiConsoleForHeartbeatBOrC;

  /// No description provided for @uiBodyAngleTakenFromThePacketSRotationQuaternion.
  ///
  /// In en, this message translates to:
  /// **'BODY ANGLE TAKEN FROM THE PACKET\'S ROTATION QUATERNION — '**
  String get uiBodyAngleTakenFromThePacketSRotationQuaternion;

  /// No description provided for @uiExactNoCalibrationNeeded.
  ///
  /// In en, this message translates to:
  /// **'EXACT, NO CALIBRATION NEEDED'**
  String get uiExactNoCalibrationNeeded;

  /// No description provided for @uiDriveALittleFurtherTheSlipAngleNeedsTwoPoints.
  ///
  /// In en, this message translates to:
  /// **'DRIVE A LITTLE FURTHER: THE SLIP ANGLE NEEDS TWO POINTS'**
  String get uiDriveALittleFurtherTheSlipAngleNeedsTwoPoints;

  /// No description provided for @uiNeedsADriveToMeasureThePacketSYawUnit.
  ///
  /// In en, this message translates to:
  /// **'NEEDS A DRIVE TO MEASURE THE PACKET\'S YAW UNIT'**
  String get uiNeedsADriveToMeasureThePacketSYawUnit;

  /// No description provided for @uiMeasuringThePacketSYawUnitFromTheDrive.
  ///
  /// In en, this message translates to:
  /// **'MEASURING THE PACKET\'S YAW UNIT FROM THE DRIVE…'**
  String get uiMeasuringThePacketSYawUnitFromTheDrive;

  /// No description provided for @uiNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'NO PHOTO'**
  String get uiNoPhoto;

  /// No description provided for @ui10SWindow.
  ///
  /// In en, this message translates to:
  /// **'10 S WINDOW'**
  String get ui10SWindow;

  /// No description provided for @uiSpeedRpm.
  ///
  /// In en, this message translates to:
  /// **'SPEED / RPM'**
  String get uiSpeedRpm;

  /// No description provided for @uiSpeed.
  ///
  /// In en, this message translates to:
  /// **'SPEED →'**
  String get uiSpeed;

  /// No description provided for @uiRpm.
  ///
  /// In en, this message translates to:
  /// **'RPM ↑'**
  String get uiRpm;

  /// No description provided for @uiTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get uiTime;

  /// No description provided for @uiPoints.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get uiPoints;

  /// No description provided for @uiStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get uiStart;

  /// No description provided for @uiPositiveAccelerating.
  ///
  /// In en, this message translates to:
  /// **'positive = accelerating'**
  String get uiPositiveAccelerating;

  /// No description provided for @uiPositiveToTheRight.
  ///
  /// In en, this message translates to:
  /// **'positive = to the right'**
  String get uiPositiveToTheRight;

  /// No description provided for @uiX1000Rpm.
  ///
  /// In en, this message translates to:
  /// **'x1000 rpm'**
  String get uiX1000Rpm;

  /// No description provided for @uiKmH.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get uiKmH;

  /// No description provided for @uiKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get uiKm;

  /// No description provided for @uiMm.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get uiMm;

  /// No description provided for @uiM.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get uiM;

  /// No description provided for @uiL.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get uiL;

  /// No description provided for @uiLKm.
  ///
  /// In en, this message translates to:
  /// **'L/km'**
  String get uiLKm;

  /// No description provided for @uiRadS.
  ///
  /// In en, this message translates to:
  /// **'rad/s'**
  String get uiRadS;

  /// No description provided for @uiNm.
  ///
  /// In en, this message translates to:
  /// **'Nm'**
  String get uiNm;

  /// No description provided for @uiTarmac.
  ///
  /// In en, this message translates to:
  /// **'TARMAC'**
  String get uiTarmac;

  /// No description provided for @uiKerb.
  ///
  /// In en, this message translates to:
  /// **'KERB'**
  String get uiKerb;

  /// No description provided for @uiDirt.
  ///
  /// In en, this message translates to:
  /// **'DIRT'**
  String get uiDirt;

  /// No description provided for @uiSand.
  ///
  /// In en, this message translates to:
  /// **'SAND'**
  String get uiSand;

  /// No description provided for @uiGrass.
  ///
  /// In en, this message translates to:
  /// **'GRASS'**
  String get uiGrass;

  /// No description provided for @uiSnow.
  ///
  /// In en, this message translates to:
  /// **'SNOW'**
  String get uiSnow;

  /// No description provided for @uiOffTrack.
  ///
  /// In en, this message translates to:
  /// **'OFF TRACK'**
  String get uiOffTrack;

  /// No description provided for @uiUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get uiUnknown;

  /// No description provided for @uiContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get uiContents;

  /// No description provided for @uiNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get uiNext;

  /// No description provided for @uiPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get uiPrevious;

  /// No description provided for @uiIllustrationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Illustration unavailable'**
  String get uiIllustrationUnavailable;

  /// No description provided for @uiBeyondTheApexIllustration.
  ///
  /// In en, this message translates to:
  /// **'Beyond the Apex illustration'**
  String get uiBeyondTheApexIllustration;

  /// No description provided for @uiNoEventsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No events available.'**
  String get uiNoEventsAvailable;

  /// No description provided for @uiNoOfficialDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No official data available.'**
  String get uiNoOfficialDataAvailable;

  /// No description provided for @uiFailedToLoadDailyRaces.
  ///
  /// In en, this message translates to:
  /// **'Failed to load daily races'**
  String get uiFailedToLoadDailyRaces;

  /// No description provided for @uiCouldNotLoadContentsCheckYourConnectionAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load contents. Check your connection and retry.'**
  String get uiCouldNotLoadContentsCheckYourConnectionAndRetry;

  /// No description provided for @uiCouldNotLoadArticlePleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load article. Please retry.'**
  String get uiCouldNotLoadArticlePleaseRetry;

  /// No description provided for @uiScreenA.
  ///
  /// In en, this message translates to:
  /// **'Screen A'**
  String get uiScreenA;

  /// No description provided for @uiScreenB.
  ///
  /// In en, this message translates to:
  /// **'Screen B'**
  String get uiScreenB;

  /// No description provided for @uiPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'powered by'**
  String get uiPoweredBy;

  /// No description provided for @uiPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get uiPrivacy;

  /// No description provided for @uiLicences.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get uiLicences;

  /// No description provided for @uiChangeRegion.
  ///
  /// In en, this message translates to:
  /// **'Change region'**
  String get uiChangeRegion;

  /// No description provided for @uiDonor.
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get uiDonor;

  /// No description provided for @uiRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get uiRemove;

  /// No description provided for @uiFetched.
  ///
  /// In en, this message translates to:
  /// **'fetched'**
  String get uiFetched;

  /// No description provided for @uiUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get uiUpdated;

  /// No description provided for @uiSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get uiSuggested;

  /// No description provided for @uiCorners.
  ///
  /// In en, this message translates to:
  /// **'corners'**
  String get uiCorners;

  /// No description provided for @uiCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get uiCar;

  /// No description provided for @uiTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get uiTrack;

  /// No description provided for @uiKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get uiKg;

  /// No description provided for @uiPts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get uiPts;

  /// No description provided for @uiMiles.
  ///
  /// In en, this message translates to:
  /// **'miles'**
  String get uiMiles;

  /// No description provided for @uiMi.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get uiMi;

  /// No description provided for @uiCpuEstimatedTopSpeed.
  ///
  /// In en, this message translates to:
  /// **'Estimated top speed'**
  String get uiCpuEstimatedTopSpeed;

  /// No description provided for @carCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} car} other{{count} cars}}'**
  String carCount(num count);

  /// No description provided for @marqueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} marque} other{{count} marques}}'**
  String marqueCount(num count);

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} result} other{{count} results}}'**
  String resultCount(num count);

  /// No description provided for @uiAddedInUpdate.
  ///
  /// In en, this message translates to:
  /// **'Added in update {version}'**
  String uiAddedInUpdate(String version);

  /// No description provided for @uiFoundDevices.
  ///
  /// In en, this message translates to:
  /// **'Found {count} device(s). Tap to select.'**
  String uiFoundDevices(String count);

  /// No description provided for @uiTopSpeedHint.
  ///
  /// In en, this message translates to:
  /// **'TOP SPEED EST. {speed} KM/H'**
  String uiTopSpeedHint(String speed);

  /// No description provided for @uiPacketNoG.
  ///
  /// In en, this message translates to:
  /// **'PACKET {packet} HAS NO G — ASK FOR B OR C'**
  String uiPacketNoG(String packet);

  /// No description provided for @uiNoAidData.
  ///
  /// In en, this message translates to:
  /// **'NO AID DATA IN PACKET {packet}'**
  String uiNoAidData(String packet);

  /// No description provided for @uiCarNotInCatalogue.
  ///
  /// In en, this message translates to:
  /// **'CAR ID {id} IS NOT IN THE CATALOGUE'**
  String uiCarNotInCatalogue(String id);

  /// No description provided for @uiGhostLap.
  ///
  /// In en, this message translates to:
  /// **'GHOST: LAP {lap} OF THE SESSION'**
  String uiGhostLap(String lap);

  /// No description provided for @uiWorkshopSummary.
  ///
  /// In en, this message translates to:
  /// **'GT AUTO / GT7 COMPANION · {cars} cars · {swaps} confirmed swap records'**
  String uiWorkshopSummary(String cars, String swaps);

  /// No description provided for @uiEntrantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entrants'**
  String uiEntrantsCount(String count);

  /// No description provided for @uiMoreCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more, '**
  String uiMoreCount(String count);

  /// No description provided for @uiEventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events  ·  newest first'**
  String uiEventsCount(String count);

  /// No description provided for @uiCopiedTrace.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} trace lines'**
  String uiCopiedTrace(String count);

  /// No description provided for @uiRaceLabel.
  ///
  /// In en, this message translates to:
  /// **'RACE {label}'**
  String uiRaceLabel(String label);

  /// No description provided for @uiErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String uiErrorDetails(String details);

  /// No description provided for @uiAdditional000.
  ///
  /// In en, this message translates to:
  /// **'Car data & photography: Polyphony Digital / gran-turismo.com.\nGTPlus · GT7 Info · GTDB · DG-Edge · GTSh.\nNatural Earth: public domain.'**
  String get uiAdditional000;

  /// No description provided for @uiAdditional001.
  ///
  /// In en, this message translates to:
  /// **'CONDITIONS'**
  String get uiAdditional001;

  /// No description provided for @uiAdditional002.
  ///
  /// In en, this message translates to:
  /// **'The game tracks these three per car. The app cannot read them — it has no access to your save.'**
  String get uiAdditional002;

  /// No description provided for @uiAdditional003.
  ///
  /// In en, this message translates to:
  /// **'COLLECTING…'**
  String get uiAdditional003;

  /// No description provided for @uiAdditional004.
  ///
  /// In en, this message translates to:
  /// **'NO ROUTE YET — GT7 SENDS THE CAR\'S POSITION IN EVERY PACKET, SO THE MAP APPEARS AS SOON AS YOU MOVE'**
  String get uiAdditional004;

  /// No description provided for @uiAdditional005.
  ///
  /// In en, this message translates to:
  /// **'THE PROFILE COMES FROM THE CAR\'S HEIGHT IN EVERY PACKET — IT APPEARS AS SOON AS YOU MOVE'**
  String get uiAdditional005;

  /// No description provided for @uiAdditional006.
  ///
  /// In en, this message translates to:
  /// **'FROM POSITION Y (0x08), WHERE THE CAR ACTUALLY IS — THE FASTEST LAP OF THE SESSION'**
  String get uiAdditional006;

  /// No description provided for @uiAdditional007.
  ///
  /// In en, this message translates to:
  /// **'LIVE VS BEST'**
  String get uiAdditional007;

  /// No description provided for @uiAdditional008.
  ///
  /// In en, this message translates to:
  /// **'THE ROUTE COMES FROM THE POSITION GT7 SENDS IN EVERY PACKET (X/Z), SO IT IS BUILT BY DRIVING — NO COURSE DATA, NO RIVALS. GT7 SENDS NO TRACK ID, SO THE CIRCUIT IS NAMED ONLY WHEN A DRIVEN LAP MATCHES ONE'**
  String get uiAdditional008;

  /// No description provided for @uiAdditional009.
  ///
  /// In en, this message translates to:
  /// **'GT7 SHOWROOM'**
  String get uiAdditional009;

  /// No description provided for @uiAdditional010.
  ///
  /// In en, this message translates to:
  /// **'Anti-bot will reject the sign-in — research only'**
  String get uiAdditional010;

  /// No description provided for @uiAdditional011.
  ///
  /// In en, this message translates to:
  /// **'Maintenance & Servicing'**
  String get uiAdditional011;

  /// No description provided for @uiAdditional012.
  ///
  /// In en, this message translates to:
  /// **'Check your car\'s cleanliness and body condition, and request a car wash, oil change, engine overhaul or body rigidity restoration work.'**
  String get uiAdditional012;

  /// No description provided for @uiAdditional013.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get uiAdditional013;

  /// No description provided for @uiAdditional014.
  ///
  /// In en, this message translates to:
  /// **'Car Wash'**
  String get uiAdditional014;

  /// No description provided for @uiAdditional015.
  ///
  /// In en, this message translates to:
  /// **'Remove dirt and debris so that your car shines like new.'**
  String get uiAdditional015;

  /// No description provided for @uiAdditional016.
  ///
  /// In en, this message translates to:
  /// **'The longer you drive a car, the more its oil degrades, which in turn will make its engine run slower.'**
  String get uiAdditional016;

  /// No description provided for @uiAdditional017.
  ///
  /// In en, this message translates to:
  /// **'When an oil change is not enough to restore an under-performing engine, an overhaul will bring it back.'**
  String get uiAdditional017;

  /// No description provided for @uiAdditional018.
  ///
  /// In en, this message translates to:
  /// **'Restore Rigidity'**
  String get uiAdditional018;

  /// No description provided for @uiAdditional019.
  ///
  /// In en, this message translates to:
  /// **'Constant driving deforms the body over time. Restore the rigidity of your car\'s chassis here.'**
  String get uiAdditional019;

  /// No description provided for @uiAdditional020.
  ///
  /// In en, this message translates to:
  /// **'Modification'**
  String get uiAdditional020;

  /// No description provided for @uiAdditional021.
  ///
  /// In en, this message translates to:
  /// **'Install a wide body kit.'**
  String get uiAdditional021;

  /// No description provided for @uiAdditional022.
  ///
  /// In en, this message translates to:
  /// **'Engine Swap'**
  String get uiAdditional022;

  /// No description provided for @uiAdditional023.
  ///
  /// In en, this message translates to:
  /// **'Unlocked at Collector Level 50. A car that has undergone an engine swap cannot undergo another.'**
  String get uiAdditional023;

  /// No description provided for @uiAdditional024.
  ///
  /// In en, this message translates to:
  /// **'Customise Cars'**
  String get uiAdditional024;

  /// No description provided for @uiAdditional025.
  ///
  /// In en, this message translates to:
  /// **'Personalise your cars with new wheels, a fresh coat of paint or custom external parts. Parts differ for each car.'**
  String get uiAdditional025;

  /// No description provided for @uiAdditional026.
  ///
  /// In en, this message translates to:
  /// **'Wheels'**
  String get uiAdditional026;

  /// No description provided for @uiAdditional027.
  ///
  /// In en, this message translates to:
  /// **'Purchase wheels made by different brands from around the world.'**
  String get uiAdditional027;

  /// No description provided for @uiAdditional028.
  ///
  /// In en, this message translates to:
  /// **'Paint Colour'**
  String get uiAdditional028;

  /// No description provided for @uiAdditional029.
  ///
  /// In en, this message translates to:
  /// **'Purchase paint in a wide spectrum of colour and texture.'**
  String get uiAdditional029;

  /// No description provided for @uiAdditional030.
  ///
  /// In en, this message translates to:
  /// **'Custom Parts'**
  String get uiAdditional030;

  /// No description provided for @uiAdditional031.
  ///
  /// In en, this message translates to:
  /// **'Purchase front spoilers, wings and other external parts.'**
  String get uiAdditional031;

  /// No description provided for @uiAdditional032.
  ///
  /// In en, this message translates to:
  /// **'Racing Items'**
  String get uiAdditional032;

  /// No description provided for @uiAdditional033.
  ///
  /// In en, this message translates to:
  /// **'Purchase bonnet pins, roll cages and other racing items.'**
  String get uiAdditional033;

  /// No description provided for @uiAdditional034.
  ///
  /// In en, this message translates to:
  /// **'Purchase light bulbs, number plates, front grills and caliper colours.'**
  String get uiAdditional034;

  /// No description provided for @uiAdditional035.
  ///
  /// In en, this message translates to:
  /// **'Livery Editor'**
  String get uiAdditional035;

  /// No description provided for @uiAdditional036.
  ///
  /// In en, this message translates to:
  /// **'Change the colours of your cars and apply decals to create your own unique liveries.'**
  String get uiAdditional036;

  /// No description provided for @uiAdditional037.
  ///
  /// In en, this message translates to:
  /// **'Save Style'**
  String get uiAdditional037;

  /// No description provided for @uiAdditional038.
  ///
  /// In en, this message translates to:
  /// **'Save and share any piece of modified content.'**
  String get uiAdditional038;

  /// No description provided for @uiAdditional039.
  ///
  /// In en, this message translates to:
  /// **'Load Style'**
  String get uiAdditional039;

  /// No description provided for @uiAdditional040.
  ///
  /// In en, this message translates to:
  /// **'Apply styles you have downloaded from the Discover feature.'**
  String get uiAdditional040;

  /// No description provided for @uiAdditional041.
  ///
  /// In en, this message translates to:
  /// **'Driving Gear'**
  String get uiAdditional041;

  /// No description provided for @uiAdditional042.
  ///
  /// In en, this message translates to:
  /// **'Change the colours of your helmets and racing suits, or apply decals, to create your own unique driving gear.'**
  String get uiAdditional042;

  /// No description provided for @uiAdditional043.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get uiAdditional043;

  /// No description provided for @uiAdditional044.
  ///
  /// In en, this message translates to:
  /// **'Change your helmet or racing suit. Helmets are rewarded for increasing your Collector Level.'**
  String get uiAdditional044;

  /// No description provided for @uiAdditional045.
  ///
  /// In en, this message translates to:
  /// **'Design your own helmet or racing suit.'**
  String get uiAdditional045;

  /// No description provided for @uiAdditional046.
  ///
  /// In en, this message translates to:
  /// **'Ultra-High RPM Turbo'**
  String get uiAdditional046;

  /// No description provided for @uiAdditional047.
  ///
  /// In en, this message translates to:
  /// **'High-RPM S Supercharger'**
  String get uiAdditional047;

  /// No description provided for @uiAdditional048.
  ///
  /// In en, this message translates to:
  /// **'Titanium Connecting Rods and Pistons'**
  String get uiAdditional048;

  /// No description provided for @uiAdditional049.
  ///
  /// In en, this message translates to:
  /// **'Bore Up S'**
  String get uiAdditional049;

  /// No description provided for @uiAdditional050.
  ///
  /// In en, this message translates to:
  /// **'Stroke Up S'**
  String get uiAdditional050;

  /// No description provided for @uiAdditional051.
  ///
  /// In en, this message translates to:
  /// **'High Lift Camshaft S'**
  String get uiAdditional051;

  /// No description provided for @uiAdditional052.
  ///
  /// In en, this message translates to:
  /// **'Carbon Propeller Shaft'**
  String get uiAdditional052;

  /// No description provided for @uiAdditional053.
  ///
  /// In en, this message translates to:
  /// **'Stage 5 Weight Reduction'**
  String get uiAdditional053;

  /// No description provided for @uiAdditional054.
  ///
  /// In en, this message translates to:
  /// **'Scan failed'**
  String get uiAdditional054;

  /// No description provided for @uiAdditional055.
  ///
  /// In en, this message translates to:
  /// **'GRAPH ERROR'**
  String get uiAdditional055;

  /// No description provided for @uiAdditional056.
  ///
  /// In en, this message translates to:
  /// **'STEERING · PACKET'**
  String get uiAdditional056;

  /// No description provided for @uiAdditional057.
  ///
  /// In en, this message translates to:
  /// **'OPTIONS'**
  String get uiAdditional057;

  /// No description provided for @uiAdditional059.
  ///
  /// In en, this message translates to:
  /// **'% REMAINING'**
  String get uiAdditional059;

  /// No description provided for @uiAdditional060.
  ///
  /// In en, this message translates to:
  /// **'Token extraction failed'**
  String get uiAdditional060;

  /// No description provided for @uiAdditional061.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get uiAdditional061;

  /// No description provided for @uiPressure.
  ///
  /// In en, this message translates to:
  /// **'PRESS'**
  String get uiPressure;

  /// No description provided for @uiHorsepower.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get uiHorsepower;

  /// No description provided for @uiPounds.
  ///
  /// In en, this message translates to:
  /// **'lbs.'**
  String get uiPounds;

  /// No description provided for @uiCubicCentimetres.
  ///
  /// In en, this message translates to:
  /// **'cc'**
  String get uiCubicCentimetres;

  /// No description provided for @uiKilogramForceMetres.
  ///
  /// In en, this message translates to:
  /// **'kgfm'**
  String get uiKilogramForceMetres;

  /// No description provided for @uiNoMotionPacketA.
  ///
  /// In en, this message translates to:
  /// **'LOAD AND ATTITUDE ARE NOT IN PACKET A — ASK THE CONSOLE FOR HEARTBEAT B OR C (SEE UdpService.packetType)'**
  String get uiNoMotionPacketA;

  /// No description provided for @uiBodyQuaternion.
  ///
  /// In en, this message translates to:
  /// **'BODY ANGLE TAKEN FROM THE PACKET\'S ROTATION QUATERNION — EXACT, NO CALIBRATION NEEDED'**
  String get uiBodyQuaternion;

  /// No description provided for @uiDeltaIsolatedLap.
  ///
  /// In en, this message translates to:
  /// **'DELTA TO BEST, ISOLATED LAP TIME'**
  String get uiDeltaIsolatedLap;

  /// No description provided for @uiUnifiedCarError.
  ///
  /// In en, this message translates to:
  /// **'Error loading unified car data'**
  String get uiUnifiedCarError;

  /// No description provided for @uiFromCredits.
  ///
  /// In en, this message translates to:
  /// **'from Cr.'**
  String get uiFromCredits;

  /// No description provided for @uiMotionPacket.
  ///
  /// In en, this message translates to:
  /// **'THE LOAD VECTOR AND THE BODY ATTITUDE COME FROM PACKET {packet}; STEERING AND DRIFT ARE ON THE CAR\'S CARD BELOW'**
  String uiMotionPacket(String packet);

  /// No description provided for @uiYawCalibration.
  ///
  /// In en, this message translates to:
  /// **'YAW UNIT MEASURED AT {scale} RAD/PACKET ({degrees}°)'**
  String uiYawCalibration(String scale, String degrees);

  /// No description provided for @uiMatchedLap.
  ///
  /// In en, this message translates to:
  /// **'MATCHED FROM THE LAP · {length} km · {corners} CORNERS · {confidence}%'**
  String uiMatchedLap(String length, String corners, String confidence);

  /// No description provided for @uiAmbiguousTrack.
  ///
  /// In en, this message translates to:
  /// **'ALSO FITS {track} — TOO CLOSE TO CALL'**
  String uiAmbiguousTrack(String track);

  /// No description provided for @telemetryConnectPlayStation.
  ///
  /// In en, this message translates to:
  /// **'Connect PlayStation'**
  String get telemetryConnectPlayStation;

  /// No description provided for @telemetryConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect your PlayStation to view your drive.'**
  String get telemetryConnectDescription;

  /// No description provided for @telemetryDemoDescription.
  ///
  /// In en, this message translates to:
  /// **'Demo drive · simulated telemetry'**
  String get telemetryDemoDescription;

  /// No description provided for @telemetryConnectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get telemetryConnectionSettings;

  /// No description provided for @telemetryNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get telemetryNotConnected;

  /// No description provided for @telemetryNetworkHelp.
  ///
  /// In en, this message translates to:
  /// **'Start GT7 on your PlayStation. Connect both devices to the same local network and enter the console’s IP address.'**
  String get telemetryNetworkHelp;

  /// No description provided for @telemetryPacketFormat.
  ///
  /// In en, this message translates to:
  /// **'Telemetry format'**
  String get telemetryPacketFormat;

  /// No description provided for @telemetryPacketA.
  ///
  /// In en, this message translates to:
  /// **'A · 296 bytes. Basic vehicle and lap data; no steering or g-forces.'**
  String get telemetryPacketA;

  /// No description provided for @telemetryPacketB.
  ///
  /// In en, this message translates to:
  /// **'B · 316 bytes. Adds steering input and g-forces.'**
  String get telemetryPacketB;

  /// No description provided for @telemetryPacketExtended.
  ///
  /// In en, this message translates to:
  /// **'~ · 344 bytes. Adds filtered inputs, wheel torque and energy recovery.'**
  String get telemetryPacketExtended;

  /// No description provided for @telemetryPacketC.
  ///
  /// In en, this message translates to:
  /// **'C · 368 bytes. Recommended: all fields, including front-wheel angles and tyre surfaces.'**
  String get telemetryPacketC;

  /// No description provided for @telemetryPacketHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose another format only for diagnostics. Changing it during a connection pauses requests for about 3 seconds.'**
  String get telemetryPacketHelp;

  /// No description provided for @telemetrySaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get telemetrySaveSettings;

  /// No description provided for @telemetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Telemetry'**
  String get telemetryTitle;

  /// No description provided for @telemetryPlatforms.
  ///
  /// In en, this message translates to:
  /// **'GT7 platforms'**
  String get telemetryPlatforms;

  /// No description provided for @telemetryAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic connection'**
  String get telemetryAutoTitle;

  /// No description provided for @telemetryAutoHelp.
  ///
  /// In en, this message translates to:
  /// **'Find and connect to an active PlayStation while the app is in the foreground.'**
  String get telemetryAutoHelp;

  /// No description provided for @telemetryAutoIosHelp.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, enter the console IP once. The confirmed address is reused automatically; broadcast discovery is unavailable in this build.'**
  String get telemetryAutoIosHelp;

  /// No description provided for @telemetrySearch.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get telemetrySearch;

  /// No description provided for @telemetrySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding PlayStation'**
  String get telemetrySearchTitle;

  /// No description provided for @telemetryWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GT7'**
  String get telemetryWaiting;

  /// No description provided for @telemetryWaitingHelp.
  ///
  /// In en, this message translates to:
  /// **'Start GT7 on your console. Waiting for telemetry.'**
  String get telemetryWaitingHelp;

  /// No description provided for @telemetryLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get telemetryLive;

  /// No description provided for @telemetryLost.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get telemetryLost;

  /// No description provided for @telemetryLostHelp.
  ///
  /// In en, this message translates to:
  /// **'No fresh telemetry. Check GT7 and your connection.'**
  String get telemetryLostHelp;

  /// No description provided for @telemetryManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get telemetryManual;

  /// No description provided for @telemetryNotFound.
  ///
  /// In en, this message translates to:
  /// **'No active console found'**
  String get telemetryNotFound;

  /// No description provided for @telemetryChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose console'**
  String get telemetryChoose;

  /// No description provided for @telemetryChooseHelp.
  ///
  /// In en, this message translates to:
  /// **'Several consoles found. Choose yours.'**
  String get telemetryChooseHelp;

  /// No description provided for @telemetryMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get telemetryMore;

  /// No description provided for @telemetryInstruments.
  ///
  /// In en, this message translates to:
  /// **'Instruments'**
  String get telemetryInstruments;

  /// No description provided for @telemetryOpen.
  ///
  /// In en, this message translates to:
  /// **'Open telemetry'**
  String get telemetryOpen;

  /// No description provided for @telemetryRetry.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get telemetryRetry;

  /// No description provided for @telemetryUnknownCar.
  ///
  /// In en, this message translates to:
  /// **'Unknown car'**
  String get telemetryUnknownCar;

  /// No description provided for @telemetrySettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'PlayStation connection and automatic discovery.'**
  String get telemetrySettingsDescription;

  /// No description provided for @telemetryPacketShort.
  ///
  /// In en, this message translates to:
  /// **'Packet'**
  String get telemetryPacketShort;

  /// No description provided for @telemetryDemoBadge.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get telemetryDemoBadge;

  /// No description provided for @telemetryIdleHelp.
  ///
  /// In en, this message translates to:
  /// **'GT7 telemetry on your local network.'**
  String get telemetryIdleHelp;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// Generated from app_en.arb; new screens use typed getters directly.
// This adapter keeps data-driven legacy labels outside domain-model localization.
import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';
export 'generated/app_localizations.dart';

extension UiLocaleContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      lookupAppLocalizations(
        Locale(
          Localizations.maybeLocaleOf(this)?.languageCode == 'ru' ? 'ru' : 'en',
        ),
      );
  String tr(String message) => l10n.uiText(message);
}

extension UiMessages on AppLocalizations {
  String uiText(String source) {
    if (!localeName.startsWith('ru')) {
      return source;
    }
    final trimmed = source.trim();
    final normalized = trimmed.toLowerCase();
    final translated = switch (normalized) {
      "% remaining" => uiAdditional059,
      "(see udpservice.packettype)" => uiSeeUdpservicePackettype,
      "10 s window" => ui10SWindow,
      "296 bytes: position, rotation, lap times — no steering" =>
        ui296BytesPositionRotationLapTimesNoSteering,
      "316 bytes: adds steering angle and g-forces" =>
        ui316BytesAddsSteeringAngleAndGForces,
      "368 bytes: adds surfaces and car category" =>
        ui368BytesAddsSurfacesAndCarCategory,
      "about me" => uiAboutMe,
      "about the app" => about,
      "acc" => uiAcc,
      "accelerating" => uiAccelerating,
      "active" => uiActive,
      "add to build plan" => uiAddToBuildPlan,
      "additional engine and dimension data is not documented for this car." =>
        uiAdditionalEngineAndDimensionDataIsNotDocumentedForThis,
      "aids" => uiAids,
      "all gt7 cars" => uiAllGt7Cars,
      "all marques" => uiAllMarques,
      "all regions" => uiAllRegions,
      "allowed" => uiAllowed,
      "ambient music" => uiAmbientMusic,
      "america" => uiAmerica,
      "anti-bot will reject the sign-in — research only" => uiAdditional010,
      "application language" => uiApplicationLanguage,
      "applied" => uiApplied,
      "apply styles you have downloaded from the discover feature." =>
        uiAdditional040,
      "asia-pacific" => uiAsiaPacific,
      "aspiration" => uiAspiration,
      "austria" => uiAustria,
      "average consumption" => uiAverageConsumption,
      "back" => uiBack,
      "back to showroom" => uiBackToShowroom,
      "best" => uiBest,
      "best lap" => uiBestLap,
      "beyond the apex" => uiBeyondTheApex,
      "beyond the apex illustration" => uiBeyondTheApexIllustration,
      "body angle taken from the packet's rotation quaternion —" =>
        uiBodyAngleTakenFromThePacketSRotationQuaternion,
      "body angle taken from the packet's rotation quaternion — exact, no calibration needed" =>
        uiBodyQuaternion,
      "body pitch" => uiBodyPitch,
      "body rigidity" => uiBodyRigidity,
      "body roll" => uiBodyRoll,
      "boost" => uiBoost,
      "bop applied" => uiBopApplied,
      "bore up s" => uiAdditional049,
      "brake" => uiBrake,
      "braking" => uiBraking,
      "brand central" => uiBrandCentral,
      "brk" => uiBrk,
      "brk %" => uiBrk314,
      "bronze finishes" => uiBronzeFinishes,
      "build notes" => uiBuildNotes,
      "build plan" => uiBuildPlan,
      "car" => uiCar,
      "car catalogue could not be loaded." => uiCarCatalogueCouldNotBeLoaded,
      "car collection" => uiCarCollection,
      "car data & photography: polyphony digital / gran-turismo.com.\ngtplus · gt7 info · gtdb · dg-edge · gtsh.\nnatural earth: public domain." =>
        uiAdditional000,
      "car data & photography: polyphony digital / gran-turismo.com.\nthis catalogue includes all listed gt7 cars; availability in the game varies." =>
        uiCarDataPhotographyPolyphonyDigitalGranTurismoComThisCatalogue,
      "car life" => uiCarLife,
      "car setup" => uiCarSetup,
      "car wash" => uiAdditional014,
      "carbon propeller shaft" => uiAdditional052,
      "cars purchased" => uiCarsPurchased,
      "catalogue unavailable. please retry." =>
        uiCatalogueUnavailablePleaseRetry,
      "category" => uiCategory,
      "cc" => uiCubicCentimetres,
      "change" => uiAdditional043,
      "change car" => uiChangeCar,
      "change region" => uiChangeRegion,
      "change the colours of your cars and apply decals to create your own unique liveries." =>
        uiAdditional036,
      "change the colours of your helmets and racing suits, or apply decals, to create your own unique driving gear." =>
        uiAdditional042,
      "change your helmet or racing suit. helmets are rewarded for increasing your collector level." =>
        uiAdditional044,
      "changes apply immediately and are saved on this device." =>
        uiChangesApplyImmediatelyAndAreSavedOnThisDevice,
      "charge" => uiCharge,
      "check your car's cleanliness and body condition, and request a car wash, oil change, engine overhaul or body rigidity restoration work." =>
        uiAdditional012,
      "china" => uiChina,
      "choose a car" => uiChooseACar,
      "choose the language used throughout the app." =>
        uiChooseTheLanguageUsedThroughoutTheApp,
      "circuit experience" => uiCircuitExperience,
      "class" => uiClass,
      "clean races" => uiCleanRaces,
      "clear" => uiClear,
      "clear search" => uiClearSearch,
      "clearing session…" => uiClearingSession,
      "close" => close,
      "close brand central" => uiCloseBrandCentral,
      "collecting…" => uiAdditional003,
      "collection level" => uiCollectionLevel,
      "community data" => uiCommunityData,
      "compatibility" => uiCompatibility,
      "compatibility & comparison" => uiCompatibilityComparison,
      "compatibility refers to the stock car; engine swaps can change available upgrades. regular tuning-shop parts and wide-body availability are not covered. blank cells are unknown." =>
        uiCompatibilityRefersToTheStockCarEngineSwapsCanChange,
      "compatible engine" => uiCompatibleEngine,
      "compatible · add to plan" => uiCompatibleAddToPlan,
      "conditions" => uiAdditional001,
      "configuration" => uiConfiguration,
      "connect" => uiConnect,
      "connect your psn account to see your gt7 profile, stats, and race history." =>
        uiConnectYourPsnAccountToSeeYourGt7ProfileStats,
      "connected" => uiConnected,
      "connecting" => uiConnecting,
      "connecting to playstation…" => uiConnectingToPlaystation,
      "console for heartbeat b or c" => uiConsoleForHeartbeatBOrC,
      "constant driving deforms the body over time. restore the rigidity of your car's chassis here." =>
        uiAdditional019,
      "contents" => uiContents,
      "copy trace to clipboard" => uiCopyTraceToClipboard,
      "corners" => uiCorners,
      "could not load article. please retry." =>
        uiCouldNotLoadArticlePleaseRetry,
      "could not load contents. check your connection and retry." =>
        uiCouldNotLoadContentsCheckYourConnectionAndRetry,
      "could not open source." => uiCouldNotOpenSource,
      "could not open the website. please retry." =>
        uiCouldNotOpenTheWebsitePleaseRetry,
      "could not restore application preferences." =>
        uiCouldNotRestoreApplicationPreferences,
      "could not restore saved workshop plans." =>
        uiCouldNotRestoreSavedWorkshopPlans,
      "could not save application preferences. please retry." =>
        uiCouldNotSaveApplicationPreferencesPleaseRetry,
      "credits earned" => uiCreditsEarned,
      "custom parts" => uiAdditional030,
      "customise cars" => uiAdditional024,
      "czech republic" => uiCzechRepublic,
      "daily races" => uiDailyRaces,
      "damage" => uiDamage,
      "data" => uiData,
      "days online" => uiDaysOnline,
      "deep scanning network (this may take 10-30 seconds)..." =>
        uiDeepScanningNetworkThisMayTake1030Seconds,
      "delta to best, isolated lap time" => uiDeltaIsolatedLap,
      "demo" => uiDemo,
      "demo telemetry" => uiDemoTelemetry,
      "design your own helmet or racing suit." => uiAdditional045,
      "dirt" => uiDirt,
      "disconnect" => uiDisconnect,
      "displacement" => uiDisplacement,
      "donor" => uiDonor,
      "drift angle" => uiDriftAngle,
      "drift points" => uiDriftPoints,
      "drive a little further: the slip angle needs two points" =>
        uiDriveALittleFurtherTheSlipAngleNeedsTwoPoints,
      "driver rating" => uiDriverRating,
      "drivetrain" => uiDrivetrain,
      "driving" => uiDriving,
      "driving gear" => uiAdditional041,
      "electric" => uiElectric,
      "electric drivetrain" => uiElectricDrivetrain,
      "elev" => uiElev,
      "elevation" => uiElevation,
      "elevation profile" => uiElevationProfile,
      "enabled" => uiEnabled,
      "ended" => uiEnded,
      "energy recovery" => uiEnergyRecovery,
      "engaged" => uiEngaged,
      "engine" => uiEngine,
      "engine & dimensions" => uiEngineDimensions,
      "engine condition" => uiEngineCondition,
      "engine overhaul" => uiEngineOverhaul,
      "engine swap" => uiAdditional022,
      "engine swaps" => uiEngineSwaps,
      "english (us) · us units" => uiEnglishUsUsUnits,
      "enter ip" => uiEnterIp,
      "entrants" => uiEntrants,
      "entrants by country" => uiEntrantsByCountry,
      "entrants by rating" => uiEntrantsByRating,
      "error" => uiError,
      "error loading legend car data" => uiErrorLoadingLegendCarData,
      "error loading unified car data" => uiUnifiedCarError,
      "error loading used car data" => uiErrorLoadingUsedCarData,
      "estimated top speed" => uiCpuEstimatedTopSpeed,
      "europe" => uiEurope,
      "exact, no calibration needed" => uiExactNoCalibrationNeeded,
      "failed to load daily races" => uiFailedToLoadDailyRaces,
      "fastest laps" => uiFastestLaps,
      "fetched" => uiFetched,
      "field" => uiField,
      "find playstation" => uiFindPlaystation,
      "finishing sign-in…" => uiFinishingSignIn,
      "fixed" => uiFixed,
      "follow the language of your device." => uiFollowTheLanguageOfYourDevice,
      "followers" => uiFollowers,
      "following" => uiFollowing,
      "france" => uiFrance,
      "friends" => uiFriends,
      "from cr." => uiFromCredits,
      "from position y (0x08), where the car actually is — the fastest lap of the session" =>
        uiAdditional006,
      "fuel" => uiFuel,
      "fuel use" => uiFuelUse,
      "fuel used" => uiFuelUsed,
      "future" => uiFuture,
      "gallery" => uiGallery,
      "gallery unavailable. your catalogue and history are still available." =>
        uiGalleryUnavailableYourCatalogueAndHistoryAreStillAvailable,
      "game play" => uiGamePlay,
      "garage / gt auto" => uiGarageGtAuto,
      "gear" => uiGear,
      "gear ratios" => uiGearRatios,
      "gear ratios not in this packet" => uiGearRatiosNotInThisPacket,
      "germany" => uiGermany,
      "global" => general,
      "gold finishes" => uiGoldFinishes,
      "gran turismo 7 companion" => uiGranTurismo7Companion,
      "graph error" => uiAdditional055,
      "grass" => uiGrass,
      "grip" => uiGrip,
      "gt auto" => uiGtAuto,
      "gt menu" => uiGtMenu,
      "gt world" => uiGtWorld,
      "gt7 companion" => uiGt7Companion,
      "gt7 showroom" => uiAdditional009,
      "gtplus comparison" => uiGtplusComparison,
      "gtplus stock and swap figures are compared within the same source. official catalogue values may differ. plan here; install in gt7." =>
        uiGtplusStockAndSwapFiguresAreComparedWithinTheSame,
      "gtsh leaderboard" => uiGtshLeaderboard,
      "heading up" => uiHeadingUp,
      "height" => uiHeight,
      "high lift camshaft s" => uiAdditional051,
      "high-rpm s supercharger" => uiAdditional047,
      "history" => uiHistory,
      "home" => home,
      "hp" => uiHorsepower,
      "id, so the circuit is named only when a driven lap matches one" =>
        uiIdSoTheCircuitIsNamedOnlyWhenADriven,
      "illustration unavailable" => uiIllustrationUnavailable,
      "in build plan" => uiInBuildPlan,
      "in-game cost" => uiInGameCost,
      "install a wide body kit." => uiAdditional021,
      "interface sounds" => uiInterfaceSounds,
      "invalid ip" => uiInvalidIp,
      "it appears as soon as you move" => uiItAppearsAsSoonAsYouMove,
      "it is built by driving — no course data, no rivals. gt7 sends no track" =>
        uiItIsBuiltByDrivingNoCourseDataNoRivals,
      "italy" => uiItaly,
      "japan" => uiJapan,
      "kerb" => uiKerb,
      "kg" => uiKg,
      "kgfm" => uiKilogramForceMetres,
      "km" => uiKm,
      "km/h" => uiKmH,
      "l" => uiL,
      "l/km" => uiLKm,
      "language" => language,
      "lap" => uiLap,
      "laps" => uiLaps,
      "last" => uiLast,
      "lat" => uiLat,
      "lateral" => uiLateral,
      "lbs." => uiPounds,
      "leader" => uiLeader,
      "leaning left" => uiLeaningLeft,
      "leaning right" => uiLeaningRight,
      "left of travel" => uiLeftOfTravel,
      "left wheelbase" => uiLeftWheelbase,
      "legend cars" => uiLegendCars,
      "legendary car dealer" => uiLegendaryCarDealer,
      "length" => uiLength,
      "licence" => uiLicence,
      "licences" => uiLicences,
      "limited stock" => uiLimitedStock,
      "link error" => uiLinkError,
      "live" => uiLive,
      "live vs best" => uiAdditional007,
      "livery editor" => uiAdditional035,
      "load and attitude are not in packet a — ask the" =>
        uiLoadAndAttitudeAreNotInPacketAAskThe,
      "load and attitude are not in packet a — ask the console for heartbeat b or c (see udpservice.packettype)" =>
        uiNoMotionPacketA,
      "load style" => uiAdditional039,
      "loading" => uiLoading,
      "loading catalogue…" => uiLoadingCatalogue,
      "loading profile images…" => uiLoadingProfileImages,
      "local storage" => uiLocalStorage,
      "login detected! extracting token…" => uiLoginDetectedExtractingToken,
      "longitudinal" => uiLongitudinal,
      "m" => uiM,
      "maintenance" => uiAdditional013,
      "maintenance & servicing" => uiAdditional011,
      "make sure your playstation is on and connected to the same network" =>
        uiMakeSureYourPlaystationIsOnAndConnectedToThe,
      "maximum power" => uiMaximumPower,
      "maximum torque" => uiMaximumTorque,
      "measuring the packet's yaw unit from the drive…" =>
        uiMeasuringThePacketSYawUnitFromTheDrive,
      "menu music and interface feedback." => uiMenuMusicAndInterfaceFeedback,
      "mi" => uiMi,
      "mileage" => uiMileage,
      "miles" => uiMiles,
      "mm" => uiMm,
      "modification" => uiAdditional020,
      "motion" => uiMotion,
      "music and effects keep their existing balanced levels." =>
        uiMusicAndEffectsKeepTheirExistingBalancedLevels,
      "music credits" => uiMusicCredits,
      "name a–z" => uiNameAZ,
      "needs a drive to measure the packet's yaw unit" =>
        uiNeedsADriveToMeasureThePacketSYawUnit,
      "next" => uiNext,
      "next photo" => uiNextPhoto,
      "next week" => uiNextWeek,
      "nm" => uiNm,
      "no cars match this search." => uiNoCarsMatchThisSearch,
      "no confirmed swap records for this car in the current source. this does not establish incompatibility." =>
        uiNoConfirmedSwapRecordsForThisCarInTheCurrent,
      "no daily races found." => uiNoDailyRacesFound,
      "no data" => uiNoData,
      "no devices found" => uiNoDevicesFound,
      "no elevation yet — the profile needs a driven lap" =>
        uiNoElevationYetTheProfileNeedsADrivenLap,
      "no events available." => uiNoEventsAvailable,
      "no load data" => uiNoLoadData,
      "no matches. try another name or region." =>
        uiNoMatchesTryAnotherNameOrRegion,
      "no official data available." => uiNoOfficialDataAvailable,
      "no official description available." => uiNoOfficialDescriptionAvailable,
      "no packets received yet." => uiNoPacketsReceivedYet,
      "no photo" => uiNoPhoto,
      "no race events found" => uiNoRaceEventsFound,
      "no reference lap yet" => uiNoReferenceLapYet,
      "no route yet — gt7 sends the car's position in every packet," =>
        uiNoRouteYetGt7SendsTheCarSPositionIn,
      "no route yet — gt7 sends the car's position in every packet, so the map appears as soon as you move" =>
        uiAdditional004,
      "no surface data" => uiNoSurfaceData,
      "no. of laps" => uiNoOfLaps,
      "north america" => uiNorthAmerica,
      "north up" => uiNorthUp,
      "nose" => uiNose,
      "nose down" => uiNoseDown,
      "nose left" => uiNoseLeft,
      "nose right" => uiNoseRight,
      "nose up" => uiNoseUp,
      "not compatible" => uiNotCompatible,
      "not connected to gt7" => uiNotConnectedToGt7,
      "not documented" => uiNotDocumented,
      "not in this packet" => uiNotInThisPacket,
      "off" => uiOff,
      "off track" => uiOffTrack,
      "official catalogue preview" => uiOfficialCataloguePreview,
      "official gran turismo car catalogue" =>
        uiOfficialGranTurismoCarCatalogue,
      "official gt7 car list" => uiOfficialGt7CarList,
      "official gt7 catalogue" => uiOfficialGt7Catalogue,
      "official photography" => uiOfficialPhotography,
      "offline" => uiOffline,
      "oil" => uiOil,
      "oil change" => uiOilChange,
      "oil press" => uiOilPress,
      "oil temp" => uiOilTemp,
      "open dashboard" => uiOpenDashboard,
      "open official source" => uiOpenOfficialSource,
      "open official website" => uiOpenOfficialWebsite,
      "open original" => uiOpenOriginal,
      "opening sign-in…" => uiOpeningSignIn,
      "options" => uiAdditional057,
      "other" => uiOther,
      "oversteer" => uiOversteer,
      "packet" => uiPacket,
      "packet a has no attitude" => uiPacketAHasNoAttitude,
      "paint colour" => uiAdditional028,
      "parts & body" => uiPartsBody,
      "past" => uiPast,
      "per lap" => uiPerLap,
      "performance points" => uiPerformancePoints,
      "personalise your cars with new wheels, a fresh coat of paint or custom external parts. parts differ for each car." =>
        uiAdditional025,
      "photo unavailable" => uiPhotoUnavailable,
      "photos taken" => uiPhotosTaken,
      "pit stops" => uiPitStops,
      "plan changes could not be saved. try again." =>
        uiPlanChangesCouldNotBeSavedTryAgain,
      "play time" => uiPlayTime,
      "playstation ip" => uiPlaystationIp,
      "please wait…" => uiPleaseWait,
      "points" => uiPoints,
      "pole positions" => uiPolePositions,
      "position" => uiPosition,
      "positive = accelerating" => uiPositiveAccelerating,
      "positive = to the right" => uiPositiveToTheRight,
      "power" => uiPower,
      "power · hp" => uiPowerHp,
      "powered by" => uiPoweredBy,
      "pre-aid input" => uiPreAidInput,
      "press" => uiPressure,
      "previous" => uiPrevious,
      "previous photo" => uiPreviousPhoto,
      "privacy" => uiPrivacy,
      "profile" => uiProfile,
      "psn login flow" => uiPsnLoginFlow,
      "pts" => uiPts,
      "purchase bonnet pins, roll cages and other racing items." =>
        uiAdditional033,
      "purchase front spoilers, wings and other external parts." =>
        uiAdditional031,
      "purchase light bulbs, number plates, front grills and caliper colours." =>
        uiAdditional034,
      "purchase paint in a wide spectrum of colour and texture." =>
        uiAdditional029,
      "purchase wheels made by different brands from around the world." =>
        uiAdditional027,
      "quick scan (arp)" => uiQuickScanArp,
      "races" => uiRaces,
      "racing items" => uiAdditional032,
      "rad/s" => uiRadS,
      "recent races" => uiRecentRaces,
      "reference times" => uiReferenceTimes,
      "refresh workshop data" => uiRefreshWorkshopData,
      "refuelling" => uiRefuelling,
      "regulations" => uiRegulations,
      "remaining" => uiRemaining,
      "remove" => uiRemove,
      "remove dirt and debris so that your car shines like new." =>
        uiAdditional015,
      "restore body rigidity" => uiRestoreBodyRigidity,
      "restore rigidity" => uiAdditional018,
      "retry" => uiRetry,
      "retry catalogue" => uiRetryCatalogue,
      "retry gallery" => uiRetryGallery,
      "retry photo" => uiRetryPhoto,
      "ride height" => uiRideHeight,
      "right of travel" => uiRightOfTravel,
      "route" => uiRoute,
      "rpm ↑" => uiRpm,
      "safety rating" => uiSafetyRating,
      "sand" => uiSand,
      "save and share any piece of modified content." => uiAdditional038,
      "save style" => uiAdditional037,
      "saved cars and favorites" => uiSavedCarsAndFavorites,
      "saved engine · source currently unavailable" =>
        uiSavedEngineSourceCurrentlyUnavailable,
      "saved on this device" => uiSavedOnThisDevice,
      "scan failed" => uiAdditional054,
      "scan for playstation" => uiScanForPlaystation,
      "scanning local network for playstation devices..." =>
        uiScanningLocalNetworkForPlaystationDevices,
      "scanning network..." => uiScanningNetwork,
      "screen a" => uiScreenA,
      "screen b" => uiScreenB,
      "search brands or cars" => uiSearchBrandsOrCars,
      "search the official catalogue" => uiSearchTheOfficialCatalogue,
      "select a manufacturer" => uiSelectAManufacturer,
      "select a region" => uiSelectARegion,
      "selected car / stock" => uiSelectedCarStock,
      "services" => uiServices,
      "session best" => uiSessionBest,
      "session cleared — reloading sign-in page" =>
        uiSessionClearedReloadingSignInPage,
      "settings" => settings,
      "show the page" => uiShowThePage,
      "show trace" => uiShowTrace,
      "sign in to playstation" => uiSignInToPlaystation,
      "sign in to see your race history" => uiSignInToSeeYourRaceHistory,
      "sign in via psn" => uiSignInViaPsn,
      "sign in with playstation" => uiSignInWithPlaystation,
      "sign out" => uiSignOut,
      "sign out of the site and reload" => uiSignOutOfTheSiteAndReload,
      "silver finishes" => uiSilverFinishes,
      "sliding" => uiSliding,
      "slipstream" => uiSlipstream,
      "snow" => uiSnow,
      "so the map appears as soon as you move" =>
        uiSoTheMapAppearsAsSoonAsYouMove,
      "social" => uiSocial,
      "sold out" => uiSoldOut,
      "sound" => audio,
      "source" => uiSource,
      "sources" => uiSources,
      "sources and licences" => uiSourcesAndLicences,
      "south korea" => uiSouthKorea,
      "special parts" => uiSpecialParts,
      "special upgrades" => uiSpecialUpgrades,
      "specifications" => uiSpecifications,
      "speed / rpm" => uiSpeedRpm,
      "speed →" => uiSpeed,
      "spent on cars" => uiSpentOnCars,
      "spent on customisation" => uiSpentOnCustomisation,
      "spent on tuning" => uiSpentOnTuning,
      "sport" => uiSport,
      "stage 5 weight reduction" => uiAdditional053,
      "start" => uiStart,
      "start type" => uiStartType,
      "steering" => uiSteering,
      "steering · packet" => uiAdditional056,
      "stint" => uiStint,
      "stock" => uiStock,
      "stock → swap" => uiStockSwap,
      "stroke up s" => uiAdditional050,
      "success! redirecting…" => uiSuccessRedirecting,
      "suggested" => uiSuggested,
      "sweden" => uiSweden,
      "system default" => uiSystemDefault,
      "system language" => systemLanguage,
      "tank" => uiTank,
      "tarmac" => uiTarmac,
      "telemetry" => uiTelemetry,
      "temps & pressures" => uiTempsPressures,
      "the fastest lap of the session" => uiTheFastestLapOfTheSession,
      "the gallery is loading or unavailable. use retry gallery to try again." =>
        uiTheGalleryIsLoadingOrUnavailableUseRetryGalleryTo,
      "the game tracks these three per car. the app cannot read them" =>
        uiTheGameTracksTheseThreePerCarTheAppCannot,
      "the game tracks these three per car. the app cannot read them — it has no access to your save." =>
        uiAdditional002,
      "the gran turismo magazine" => uiTheGranTurismoMagazine,
      "the load vector and the body attitude come from packet" =>
        uiTheLoadVectorAndTheBodyAttitudeComeFromPacket,
      "the longer you drive a car, the more its oil degrades, which in turn will make its engine run slower." =>
        uiAdditional016,
      "the profile comes from the car's height in every packet —" =>
        uiTheProfileComesFromTheCarSHeightInEvery,
      "the profile comes from the car's height in every packet — it appears as soon as you move" =>
        uiAdditional005,
      "the route comes from the position gt7 sends in every packet (x/z), so" =>
        uiTheRouteComesFromThePositionGt7SendsInEvery,
      "the route comes from the position gt7 sends in every packet (x/z), so it is built by driving — no course data, no rivals. gt7 sends no track id, so the circuit is named only when a driven lap matches one" =>
        uiAdditional008,
      "theoretical best needs sector times, which gt7 does not send" =>
        uiTheoreticalBestNeedsSectorTimesWhichGt7DoesNotSend,
      "this car has no uniquely matched record in the special-parts source. compatibility is unknown." =>
        uiThisCarHasNoUniquelyMatchedRecordInTheSpecial,
      "this is your preparation checklist, not the installed state of the game. pp and combined part effects must be checked in gt7." =>
        uiThisIsYourPreparationChecklistNotTheInstalledStateOf,
      "thr" => uiThr,
      "throttle" => uiThrottle,
      "throttle / brake" => uiThrottleBrake,
      "time" => uiTime,
      "time driving" => uiTimeDriving,
      "titanium connecting rods and pistons" => uiAdditional048,
      "to the left" => uiToTheLeft,
      "to the right" => uiToTheRight,
      "token extraction failed" => uiAdditional060,
      "too close to call" => uiTooCloseToCall,
      "top 100" => uiTop100,
      "top 1000" => uiTop1000,
      "top 5 finishes" => uiTop5Finishes,
      "torque" => uiTorque,
      "torque · kgf·m" => uiTorqueKgfM,
      "total distance" => uiTotalDistance,
      "trace psn sign-in pages" => uiTracePsnSignInPages,
      "track" => uiTrack,
      "track map" => uiTrackMap,
      "tyre compound" => uiTyreCompound,
      "tyre sets" => uiTyreSets,
      "tyre wear" => uiTyreWear,
      "tyres" => uiTyres,
      "tyres & vehicle" => uiTyresVehicle,
      "tyres, race requirements, settings…" => uiTyresRaceRequirementsSettings,
      "u.s." => uiUS,
      "ultra-high rpm turbo" => uiAdditional046,
      "understeer" => uiUndersteer,
      "united kingdom" => uiUnitedKingdom,
      "united states" => uiUnitedStates,
      "unknown" => uiUnknown,
      "unknown error" => uiAdditional061,
      "unlocked at collector level 50. a car that has undergone an engine swap cannot undergo another." =>
        uiAdditional023,
      "unsupported system languages use english." =>
        uiUnsupportedSystemLanguagesUseEnglish,
      "updated" => uiUpdated,
      "used car dealer" => uiUsedCarDealer,
      "used car dealership" => uiUsedCarDealership,
      "used cars" => uiUsedCars,
      "vehicle passport" => uiVehiclePassport,
      "vehicle specifications" => uiVehicleSpecifications,
      "view full image" => uiViewFullImage,
      "waiting for a completed lap" => uiWaitingForACompletedLap,
      "waiting for input data" => uiWaitingForInputData,
      "waiting for telemetry" => uiWaitingForTelemetry,
      "water" => uiWater,
      "water temp" => uiWaterTemp,
      "weight" => uiWeight,
      "weight · kg" => uiWeightKg,
      "wheel" => uiWheel,
      "wheelbase" => uiWheelbase,
      "wheels" => uiAdditional026,
      "when an oil change is not enough to restore an under-performing engine, an overhaul will bring it back." =>
        uiAdditional017,
      "wide body" => uiWideBody,
      "width" => uiWidth,
      "wins" => uiWins,
      "wishlist" => uiWishlist,
      "workshop" => uiWorkshop,
      "x1000 rpm" => uiX1000Rpm,
      "your plan is empty. add an engine from engine swaps or choose compatible special parts." =>
        uiYourPlanIsEmptyAddAnEngineFromEngineSwaps,
      "your preparation checklist" => uiYourPreparationChecklist,
      "— it has no access to your save." => uiItHasNoAccessToYourSave,
      _ => null,
    };
    if (translated != null) {
      final upper =
          trimmed == trimmed.toUpperCase() &&
          RegExp(r'[A-Z]').hasMatch(trimmed);
      final value = upper ? translated.toUpperCase() : translated;
      return source.replaceRange(
        source.indexOf(trimmed),
        source.indexOf(trimmed) + trimmed.length,
        value,
      );
    }
    return _dynamicUiText(source, this);
  }
}

String _dynamicUiText(String source, AppLocalizations l10n) {
  RegExpMatch? match;
  match = RegExp(
    r"^THE LOAD VECTOR AND THE BODY ATTITUDE COME FROM PACKET (.*); STEERING AND DRIFT ARE ON THE CAR'S CARD BELOW$",
  ).firstMatch(source);
  if (match != null) {
    return l10n.uiMotionPacket(match[1]!);
  }
  match = RegExp(
    r'^YAW UNIT MEASURED AT (.*) RAD/PACKET \((.*)°\)$',
  ).firstMatch(source);
  if (match != null) {
    return l10n.uiYawCalibration(l10n.uiText(match[1]!), match[2]!);
  }
  match = RegExp(
    r'^MATCHED FROM THE LAP · (.*) km · (.*) CORNERS · (.*)%$',
  ).firstMatch(source);
  if (match != null) {
    return l10n.uiMatchedLap(l10n.uiText(match[1]!), match[2]!, match[3]!);
  }
  match = RegExp(r'^ALSO FITS (.*) — TOO CLOSE TO CALL$').firstMatch(source);
  if (match != null) {
    return l10n.uiAmbiguousTrack(match[1]!);
  }
  // Numeric readouts use the active locale; IPs, version strings and lap clocks
  // are passed as identifiers/templates rather than through this number branch.
  if (RegExp(r'^[+−-]?\d+(?:,\d{3})*(?:\.\d+)?[%°]?$').hasMatch(source)) {
    return source.replaceAll(',', '\u00a0').replaceAll('.', ',');
  }

  match = RegExp(
    r'^(\d+) cars · (\d+) marques( · Official GT7 catalogue)?$',
  ).firstMatch(source);
  if (match != null) {
    return '${l10n.carCount(int.parse(match[1]!))} · ${l10n.marqueCount(int.parse(match[2]!))}${match[3] == null ? '' : ' · ${l10n.uiOfficialGt7Catalogue}'}';
  }
  match = RegExp(r'^(\d+) results$').firstMatch(source);
  if (match != null) {
    return l10n.resultCount(int.parse(match[1]!));
  }
  match = RegExp(r'^(\d+) cars$').firstMatch(source);
  if (match != null) {
    return l10n.carCount(int.parse(match[1]!));
  }
  match = RegExp(r'^(.*) · (\d+) cars$').firstMatch(source);
  if (match != null) {
    return '${match[1]} · ${l10n.carCount(int.parse(match[2]!))}';
  }
  match = RegExp(r'^Change region · (.*)$').firstMatch(source);
  if (match != null) {
    return '${l10n.uiChangeRegion} · ${l10n.uiText(match[1]!)}';
  }
  match = RegExp(r'^Added in update (.*)$').firstMatch(source);
  if (match != null) {
    return l10n.uiAddedInUpdate(match[1]!);
  }
  match = RegExp(
    r'^Found (\d+) device\(s\). Tap to select\.$',
  ).firstMatch(source);
  if (match != null) {
    return l10n.uiFoundDevices(match[1]!);
  }
  match = RegExp(r'^TOP SPEED EST. (.*) KM/H$').firstMatch(source);
  if (match != null) {
    return l10n.uiTopSpeedHint(match[1]!);
  }
  match = RegExp(r'^PACKET (.*) HAS NO G — ASK FOR B OR C$').firstMatch(source);
  if (match != null) {
    return l10n.uiPacketNoG(match[1]!);
  }
  match = RegExp(r'^NO AID DATA IN PACKET (.*)$').firstMatch(source);
  if (match != null) {
    return l10n.uiNoAidData(match[1]!);
  }
  match = RegExp(r'^CAR ID (.*) IS NOT IN THE CATALOGUE$').firstMatch(source);
  if (match != null) {
    return l10n.uiCarNotInCatalogue(match[1]!);
  }
  match = RegExp(r'^GHOST: LAP (.*) OF THE SESSION$').firstMatch(source);
  if (match != null) {
    return l10n.uiGhostLap(match[1]!);
  }
  match = RegExp(
    r'^GT AUTO / GT7 COMPANION · (.*) cars · (.*) confirmed swap records$',
  ).firstMatch(source);
  if (match != null) {
    return l10n.uiWorkshopSummary(match[1]!, match[2]!);
  }
  match = RegExp(r'^Copied (.*) trace lines$').firstMatch(source);
  if (match != null) {
    return l10n.uiCopiedTrace(match[1]!);
  }
  match = RegExp(r'^(.*) events  ·  newest first$').firstMatch(source);
  if (match != null) {
    return l10n.uiEventsCount(match[1]!);
  }
  match = RegExp(r'^RACE (.*)$').firstMatch(source);
  if (match != null) {
    return l10n.uiRaceLabel(match[1]!);
  }
  match = RegExp(r'^\+(.*) more, $').firstMatch(source);
  if (match != null) {
    return l10n.uiMoreCount(match[1]!);
  }
  match = RegExp(r'^(.*) entrants$').firstMatch(source);
  if (match != null) {
    return l10n.uiEntrantsCount(match[1]!);
  }
  // App-owned prefixes and unit suffixes around values, never vehicle IDs.
  for (final prefix in [
    'Token extraction failed: ',
    'Failed to load daily races: ',
    'Error loading unified car data: ',
    'Donor: ',
    'Track: ',
    'Car: ',
    'Position: ',
    'Time: ',
    'Retry ',
    'Remove ',
    'Updated ',
    'Error: ',
    'Scan failed: ',
    'GRAPH ERROR: ',
    'STEERING · PACKET ',
    'BEST ',
    'LAST ',
    'BOOST ',
    'SUGGESTED ',
  ]) {
    if (source.startsWith(prefix)) {
      final raw = prefix.trim().replaceAll(RegExp(r'[: ]+$'), '');
      final translated = switch (raw) {
        'Scan failed' => l10n.uiText('Scan failed'),
        'GRAPH ERROR' => l10n.uiText('GRAPH ERROR'),
        'STEERING · PACKET' => l10n.uiText('STEERING · PACKET'),
        _ => l10n.uiText(raw),
      };
      return '$translated${prefix.contains(':') ? ': ' : ' '}${l10n.uiText(source.substring(prefix.length))}';
    }
  }
  for (final suffix in [
    '% REMAINING',
    ' followers',
    ' OPTIONS',
    ' LAPS',
    ' km/h',
    ' KM/H',
    ' L/km',
    ' HP',
    ' lbs.',
    ' cc',
    ' kgfm',
    ' g',
    ' rad/s',
    ' miles',
    ' pts',
    ' mi',
    ' km',
    ' mm',
    ' kg',
    ' L',
    ' m',
  ]) {
    if (source.endsWith(suffix)) {
      final raw = suffix.trim();
      final translated = switch (raw) {
        'OPTIONS' => l10n.uiText('OPTIONS'),
        'followers' => l10n.uiText('followers'),
        '% REMAINING' => l10n.uiText('% REMAINING'),
        _ => l10n.uiText(raw),
      };
      return '${l10n.uiText(source.substring(0, source.length - suffix.length))}${suffix.startsWith(' ') ? ' ' : ''}$translated';
    }
  }
  if (source.startsWith('Cr. ')) {
    return 'Кр. ${l10n.uiText(source.substring(4))}';
  }
  if (source.contains(' · fetched ')) {
    return source.replaceFirst(' · fetched ', ' · получено ');
  }
  if (source.startsWith('Official GT7 Car List · ')) {
    return source.replaceFirst(
      'Official GT7 Car List',
      l10n.uiOfficialGt7CarList,
    );
  }
  if (source.startsWith('→ ')) {
    return '→ ${l10n.uiText(source.substring(2))}';
  }
  if (source.startsWith('PP ')) {
    return 'PP ${l10n.uiText(source.substring(3))}';
  }
  if (source.startsWith('from Cr. ')) {
    return '${l10n.uiFromCredits} ${l10n.uiText(source.substring(9))}';
  }
  for (final separator in ['  ·  ', ' · ', ' / ', ': ']) {
    final parts = source.split(separator);
    if (parts.length > 1) {
      final translated = parts.map(l10n.uiText).join(separator);
      if (translated != source) {
        return translated;
      }
    }
  }
  return source;
}

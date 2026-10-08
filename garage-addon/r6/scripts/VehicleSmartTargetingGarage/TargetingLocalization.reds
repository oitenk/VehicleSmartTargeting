// Vehicle Smart Targeting - Garage add-on
// Text shown by the add-on, registered with Codeware's localization system so it
// can be translated.
//
// To add a language, copy TargetingLanguageEnglish into a new class (in a file of its
// own), translate the second string of every line and leave the first alone, then
// return the new class for that language from TargetingLocalizationProvider.GetPackage
// below. {NAME}, {PRICE} and {AMOUNT} are filled in by the add-on, so keep them in.
// The vehicle name comes from the game and is already translated.
module VehicleSmartTargeting.Garage

import Codeware.Localization.*

public class TargetingLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      // case n"fr-fr": return new TargetingLanguageFrench();
      default: return new TargetingLanguageEnglish();
    }
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

public class TargetingLanguageEnglish extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    // Service button in the garage hub, and the screen's title
    this.Text("VehicleSmartTargetingGarage-Title", "Targeting");

    // The two upgrades
    this.Text("VehicleSmartTargetingGarage-SmartLock", "Smart Lock");
    this.Text("VehicleSmartTargetingGarage-GimbalAim", "Gimbal Aim");

    // Buttons
    this.Text("VehicleSmartTargetingGarage-Install", "Install");
    this.Text("VehicleSmartTargetingGarage-Remove", "Remove");
    this.Text("VehicleSmartTargetingGarage-Refit", "Refit");

    // Lines on the screen
    this.Text("VehicleSmartTargetingGarage-NoGuns", "No mounted guns to fit");
    this.Text("VehicleSmartTargetingGarage-Balance", "Balance: {AMOUNT}");
    this.Text("VehicleSmartTargetingGarage-ForSale", "{NAME} - {PRICE} eddies");
    this.Text("VehicleSmartTargetingGarage-Installed", "{NAME} - installed");
    this.Text("VehicleSmartTargetingGarage-RefitFor", "{NAME} - refit for {PRICE} eddies");

    // Garage's notification after a purchase
    this.Text("VehicleSmartTargetingGarage-Fitted", "{NAME} fitted");
  }
}

// Text in the language the game is set to.
public func TargetingText(key: String) -> String {
  let text: String = GetLocalizedTextByKey(StringToName(key));
  return Equals(text, "") || Equals(text, key) ? key : text;
}

// Vehicle Smart Targeting: text shown by the mod, registered with Codeware's
// localization system so it can be translated.
//
// To add a language, copy VSTLanguageEnglish into a new class (in a file of its own),
// translate the second string of every line and leave the first alone, then return
// the new class for that language from VSTLocalizationProvider.GetPackage below.
//
// Codeware is optional for the core mod. Without it the English text at the bottom
// of this file is used. The Mod Settings page is written in English only.
module VehicleSmartTargeting

@if(ModuleExists("Codeware.Localization"))
import Codeware.Localization.*

@if(ModuleExists("Codeware.Localization"))
public class VSTLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      // case n"fr-fr": return new VSTLanguageFrench();
      default: return new VSTLanguageEnglish();
    }
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

@if(ModuleExists("Codeware.Localization"))
public class VSTLanguageEnglish extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    // On-screen message when a mode is selected
    this.Text("VehicleSmartTargeting-SmartLock-Selected", "Mounted guns: Smart Lock");
    this.Text("VehicleSmartTargeting-GimbalAim-Selected", "Mounted guns: Gimbal Aim");

    // On-screen message when the vehicle does not have the mode
    this.Text("VehicleSmartTargeting-SmartLock-Missing", "Smart Lock not installed");
    this.Text("VehicleSmartTargeting-GimbalAim-Missing", "Gimbal Aim not installed");
  }
}

// Text in the language the game is set to.
@if(ModuleExists("Codeware.Localization"))
public func VST_Text(key: String) -> String {
  let text: String = GetLocalizedTextByKey(StringToName(key));
  return Equals(text, "") || Equals(text, key) ? key : text;
}

// Upper case for on-screen messages, in any alphabet.
@if(ModuleExists("Codeware.Localization"))
public func VST_Upper(text: String) -> String {
  return UTF8StrUpper(text);
}

@if(!ModuleExists("Codeware.Localization"))
public func VST_Upper(text: String) -> String {
  return StrUpper(text);
}

// Without Codeware: the same English as VSTLanguageEnglish. Keep the two in step.
@if(!ModuleExists("Codeware.Localization"))
public func VST_Text(key: String) -> String {
  switch key {
    case "VehicleSmartTargeting-SmartLock-Selected": return "Mounted guns: Smart Lock";
    case "VehicleSmartTargeting-GimbalAim-Selected": return "Mounted guns: Gimbal Aim";
    case "VehicleSmartTargeting-SmartLock-Missing": return "Smart Lock not installed";
    case "VehicleSmartTargeting-GimbalAim-Missing": return "Gimbal Aim not installed";
  }
  return key;
}

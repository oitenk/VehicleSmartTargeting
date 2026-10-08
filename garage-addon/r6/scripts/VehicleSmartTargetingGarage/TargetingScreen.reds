// Vehicle Smart Targeting - Garage add-on
// The Targeting screen: one row per upgrade, each with its own action button.
module VehicleSmartTargeting.Garage

import VehicleSmartTargeting.*
import GarageCore.*
import GarageCore.Bridge.*
import GarageCore.Screens.*
import GarageCore.UI.*
import Codeware.UI.*

// What is for sale and what it costs.
public abstract class TargetingCatalog {
  public static func Label(feature: VSTFeature) -> String {
    if Equals(feature, VSTFeature.SmartLock) {
      return UTF8StrUpper(TargetingText("VehicleSmartTargetingGarage-SmartLock"));
    }
    return UTF8StrUpper(TargetingText("VehicleSmartTargetingGarage-GimbalAim"));
  }

  public static func Price(feature: VSTFeature) -> Int32 {
    if Equals(feature, VSTFeature.SmartLock) {
      return 50000;
    }
    return 35000;
  }

  // Labour for putting back an upgrade the vehicle has already paid for.
  public static func RefitFee(feature: VSTFeature) -> Int32 {
    return TargetingCatalog.Price(feature) / 10;
  }

  public static func HasMountedGuns(vehicle: wref<VehicleObject>) -> Bool {
    let record: ref<Vehicle_Record>;
    let package: wref<VehicleDataPackage_Record>;
    if !IsDefined(vehicle) {
      return false;
    }
    record = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
    if !IsDefined(record) {
      return false;
    }
    package = record.VehDataPackage();
    if !IsDefined(package) || !IsDefined(package.DriverCombat()) {
      return false;
    }
    return Equals(package.DriverCombat().Type(), gamedataDriverCombatType.MountedWeapons);
  }
}

public class TargetingScreen extends GarageScreen {
  private let m_screenManager: wref<ScreenManager>;
  private let m_root: wref<inkCanvas>;
  private let m_vehicleText: wref<inkText>;
  private let m_balanceText: wref<inkText>;
  private let m_smartText: wref<inkText>;
  private let m_gimbalText: wref<inkText>;
  private let m_smartBtn: ref<SimpleButton>;
  private let m_gimbalBtn: ref<SimpleButton>;

  public func SetScreenManager(manager: ref<ScreenManager>) -> Void {
    this.m_screenManager = manager;
  }

  protected cb func OnCreate() {
    let root = new inkCanvas();
    root.SetName(n"vstTargetingScreen");
    root.SetAnchor(inkEAnchor.Fill);
    root.SetVisible(false);

    this.CreateBackButton(root);
    this.CreateTitle(root, UTF8StrUpper(TargetingText("VehicleSmartTargetingGarage-Title")), 60.0);

    let column = new inkVerticalPanel();
    column.SetName(n"vstColumn");
    column.SetAnchor(inkEAnchor.Centered);
    column.SetAnchorPoint(new Vector2(0.5, 0.5));
    column.SetChildMargin(new inkMargin(0.0, 12.0, 0.0, 12.0));
    column.Reparent(root);

    this.m_vehicleText = this.AddText(column, n"vstVehicle", 48, n"Bold", GarageColors.AccentBlue());
    this.m_balanceText = this.AddText(column, n"vstBalance", 30, n"Regular", GarageColors.AccentBlue());
    this.m_smartText = this.AddText(column, n"vstSmartText", 36, n"Regular", new HDRColor(1.0, 0.81, 0.06, 1.0));
    this.m_smartBtn = this.CreateStandardButton(n"vstSmartBtn", this.ButtonText("Install"), 300.0, this.AddButtonHolder(column, n"vstSmartHolder"), n"OnSmartClick");
    this.m_gimbalText = this.AddText(column, n"vstGimbalText", 36, n"Regular", new HDRColor(1.0, 0.81, 0.06, 1.0));
    this.m_gimbalBtn = this.CreateStandardButton(n"vstGimbalBtn", this.ButtonText("Install"), 300.0, this.AddButtonHolder(column, n"vstGimbalHolder"), n"OnGimbalClick");

    this.m_root = root;
    this.SetRootWidget(root);
  }

  private func AddText(parent: ref<inkCompoundWidget>, name: CName, size: Int32, style: CName, tint: HDRColor) -> ref<inkText> {
    let text = new inkText();
    text.SetName(name);
    text.SetText("");
    text.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    text.SetFontStyle(style);
    text.SetFontSize(size);
    text.SetTintColor(tint);
    text.SetHorizontalAlignment(textHorizontalAlignment.Center);
    text.Reparent(parent);
    return text;
  }

  // A centred holder so each button sits under its own line of text.
  private func AddButtonHolder(parent: ref<inkCompoundWidget>, name: CName) -> ref<inkHorizontalPanel> {
    let holder = new inkHorizontalPanel();
    holder.SetName(name);
    holder.SetHAlign(inkEHorizontalAlign.Center);
    holder.Reparent(parent);
    return holder;
  }

  private func ButtonText(name: String) -> String {
    return UTF8StrUpper(TargetingText("VehicleSmartTargetingGarage-" + name));
  }

  // One of the upgrade lines, with the upgrade's name and a price filled in.
  private func LineText(name: String, label: String, price: Int32) -> String {
    let text = TargetingText("VehicleSmartTargetingGarage-" + name);
    return StrReplace(StrReplace(text, "{NAME}", label), "{PRICE}", FormatPrice(price));
  }

  public func Show() -> Void {
    this.m_isVisible = true;
    this.m_root.SetVisible(true);
    this.Populate();
  }

  public func Hide() -> Void {
    this.m_isVisible = false;
    this.m_root.SetVisible(false);
  }

  // The vehicle in the garage, if it is one that can be fitted.
  private func GetFittableVehicle() -> wref<VehicleObject> {
    let settings = GarageSettings.GetInstance(this.GetGameInstance());
    if !IsDefined(settings) || !IsDefined(settings.garageVehicle) {
      return null;
    }
    if !settings.garageVehicle.IsPlayerVehicle() || !TargetingCatalog.HasMountedGuns(settings.garageVehicle) {
      return null;
    }
    return settings.garageVehicle;
  }

  // What pressing the button would cost: nothing to remove, the fee to refit, else full price.
  private func CostOf(vehicle: wref<VehicleObject>, feature: VSTFeature) -> Int32 {
    let installs = VSTInstallSystem.Get(vehicle.GetGame());
    if installs.IsInstalled(vehicle.GetRecordID(), feature) {
      return 0;
    }
    if installs.IsOwned(vehicle.GetRecordID(), feature) {
      return TargetingCatalog.RefitFee(feature);
    }
    return TargetingCatalog.Price(feature);
  }

  private func Populate() -> Void {
    let settings = GarageSettings.GetInstance(this.GetGameInstance());
    let vehicle = this.GetFittableVehicle();
    let balance = LuaBridge.GetPlayerMoney();
    if IsDefined(vehicle) && IsDefined(settings) {
      this.m_vehicleText.SetText(settings.sellVehicleDisplayName);
    } else {
      this.m_vehicleText.SetText(TargetingText("VehicleSmartTargetingGarage-NoGuns"));
    }
    this.m_balanceText.SetText(StrReplace(TargetingText("VehicleSmartTargetingGarage-Balance"), "{AMOUNT}", FormatPrice(balance)));
    this.PopulateRow(vehicle, VSTFeature.SmartLock, balance, this.m_smartText, this.m_smartBtn);
    this.PopulateRow(vehicle, VSTFeature.GimbalAim, balance, this.m_gimbalText, this.m_gimbalBtn);
  }

  private func PopulateRow(vehicle: wref<VehicleObject>, feature: VSTFeature, balance: Int32, line: wref<inkText>, btn: ref<SimpleButton>) -> Void {
    let label = TargetingCatalog.Label(feature);
    let usable = false;
    let installs: ref<VSTInstallSystem>;
    let cost: Int32;
    let btnRoot: wref<inkWidget>;
    if !IsDefined(vehicle) {
      line.SetText(this.LineText("ForSale", label, TargetingCatalog.Price(feature)));
      btn.SetText(this.ButtonText("Install"));
    } else {
      installs = VSTInstallSystem.Get(vehicle.GetGame());
      cost = this.CostOf(vehicle, feature);
      if installs.IsInstalled(vehicle.GetRecordID(), feature) {
        line.SetText(this.LineText("Installed", label, 0));
        btn.SetText(this.ButtonText("Remove"));
        usable = true;
      } else {
        if installs.IsOwned(vehicle.GetRecordID(), feature) {
          line.SetText(this.LineText("RefitFor", label, cost));
          btn.SetText(this.ButtonText("Refit"));
        } else {
          line.SetText(this.LineText("ForSale", label, cost));
          btn.SetText(this.ButtonText("Install"));
        }
        usable = balance >= cost;
      }
    }
    btn.SetDisabled(!usable);
    btnRoot = btn.GetRootWidget();
    if IsDefined(btnRoot) {
      btnRoot.SetOpacity(usable ? 1.0 : 0.35);
    }
  }

  // Removes the upgrade if it is fitted; otherwise charges for it and fits it.
  private func Act(feature: VSTFeature) -> Void {
    let vehicle = this.GetFittableVehicle();
    let installs: ref<VSTInstallSystem>;
    let cost: Int32;
    if !IsDefined(vehicle) {
      return;
    }
    installs = VSTInstallSystem.Get(vehicle.GetGame());
    if installs.IsInstalled(vehicle.GetRecordID(), feature) {
      installs.Remove(vehicle.GetRecordID(), feature);
    } else {
      cost = this.CostOf(vehicle, feature);
      if LuaBridge.GetPlayerMoney() >= cost && TargetingBridge.Charge(cost) {
        installs.Install(vehicle.GetRecordID(), feature);
        TargetingBridge.Complete(StrReplace(TargetingText("VehicleSmartTargetingGarage-Fitted"), "{NAME}", TargetingCatalog.Label(feature)));
      }
    }
    // Stay on the screen so the other upgrade can be bought in the same visit.
    this.Populate();
  }

  protected cb func OnSmartClick(widget: wref<inkWidget>) -> Bool {
    this.Act(VSTFeature.SmartLock);
    return false;
  }

  protected cb func OnGimbalClick(widget: wref<inkWidget>) -> Bool {
    this.Act(VSTFeature.GimbalAim);
    return false;
  }

  // Registered by CreateBackButton
  protected cb func OnBackClick(widget: wref<inkWidget>) -> Bool {
    if IsDefined(this.m_screenManager) {
      this.m_screenManager.GoBack();
    }
    return false;
  }
}

// Vehicle Smart Targeting - Garage add-on
// Registers the "Targeting" service with the Garage hub.
module VehicleSmartTargeting.Garage

import GarageCore.Services.*
import GarageCore.Screens.*
import GarageCore.UI.*

public class TargetingRegistrar extends ServiceModuleRegistrar {
  public func Register(screenManager: ref<ScreenManager>, frame: ref<GarageFrame>) -> Void {
    let screen = new TargetingScreen();
    screen.CreateInstance();
    screen.SetScreenManager(screenManager);
    frame.AddScreen(screen);
    screenManager.RegisterScreen(n"vst_targeting", screen);
  }

  public func GetDescriptors() -> array<ref<ServiceDescriptor>> {
    let descriptors: array<ref<ServiceDescriptor>>;
    let desc = new ServiceDescriptor();
    let cond = new TargetingVisibility();
    cond.requireOwned = true;
    desc.id = n"vst_targeting";
    desc.label = "TARGETING";
    // Between Quick (30) and Repair (40).
    desc.priority = 36;
    desc.visibilityConditions = cond;
    desc.clickHandler = new TargetingClickHandler();
    ArrayPush(descriptors, desc);
    return descriptors;
  }
}

// Only owned vehicles that carry mounted guns have anything to upgrade.
public class TargetingVisibility extends VisibilityConditions {
  public func IsMet(context: ref<GarageContext>) -> Bool {
    if !super.IsMet(context) {
      return false;
    }
    return TargetingCatalog.HasMountedGuns(context.vehicle);
  }
}

public class TargetingClickHandler extends ServiceClickHandler {
  public func OnClick(screenManager: ref<ScreenManager>, context: ref<GarageContext>) -> Void {
    screenManager.ShowScreen(n"vst_targeting");
  }
}

// Vehicle Smart Targeting - Garage add-on
// Payment bridge. On Garage versions that provide GC.Payment, init.lua overrides
// these so the charge goes through the garage's own payment flow. On older
// versions the bodies below run as written.
module VehicleSmartTargeting.Garage

import GarageCore.Bridge.*

public abstract class TargetingBridge {
  // Takes the eddies from the player. Returns true on success.
  public static func Charge(amount: Int32) -> Bool {
    return LuaBridge.DeductMoney(amount);
  }

  // Called once the paid-for work has been applied to the vehicle.
  public static func Complete(title: String) -> Void {}
}

// Vehicle Smart Targeting
// Gives mounted vehicle machine guns the lock-on that vehicle missile launchers
// already have, and makes their rounds home on the locked target.
module VehicleSmartTargeting

// Player-facing options. With the Mod Settings mod installed they appear in its
// in-game menu; without it the defaults below apply.
public class VSTSettings {
  @runtimeProperty("ModSettings.mod", "Vehicle Smart Targeting")
  @runtimeProperty("ModSettings.category", "Smart Lock")
  @runtimeProperty("ModSettings.displayName", "Miss chance (%)")
  @runtimeProperty("ModSettings.description", "Chance for each guided round to stray wide of the locked target.")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  @runtimeProperty("ModSettings.step", "1")
  public let smartMissChance: Int32 = 10;

  @runtimeProperty("ModSettings.mod", "Vehicle Smart Targeting")
  @runtimeProperty("ModSettings.category", "Smart Lock")
  @runtimeProperty("ModSettings.displayName", "Jammer effect (%)")
  @runtimeProperty("ModSettings.description", "How much enemy smart-weapon jammers throw off the mounted guns. 100 is the same penalty on-foot smart guns take, 0 ignores jammers.")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  @runtimeProperty("ModSettings.step", "5")
  public let jammerEffect: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "Vehicle Smart Targeting")
  @runtimeProperty("ModSettings.category", "Smart Lock")
  @runtimeProperty("ModSettings.displayName", "Guidance arc (degrees)")
  @runtimeProperty("ModSettings.description", "Rounds only home on a locked target within this angle either side of straight ahead. Outside it they fire straight.")
  @runtimeProperty("ModSettings.min", "10")
  @runtimeProperty("ModSettings.max", "90")
  @runtimeProperty("ModSettings.step", "5")
  public let smartArc: Int32 = 45;

  @runtimeProperty("ModSettings.mod", "Vehicle Smart Targeting")
  @runtimeProperty("ModSettings.category", "Gimbal Aim")
  @runtimeProperty("ModSettings.displayName", "Gimbal arc (degrees)")
  @runtimeProperty("ModSettings.description", "How far the guns can swing to follow the crosshair, either side of straight ahead and up or down. Past that they stop at the edge.")
  @runtimeProperty("ModSettings.min", "10")
  @runtimeProperty("ModSettings.max", "90")
  @runtimeProperty("ModSettings.step", "5")
  public let gimbalArc: Int32 = 45;

  @runtimeProperty("ModSettings.mod", "Vehicle Smart Targeting")
  @runtimeProperty("ModSettings.category", "Troubleshooting")
  @runtimeProperty("ModSettings.displayName", "Debug logging")
  @runtimeProperty("ModSettings.description", "Writes details of each shot to the Cyber Engine Tweaks game log (up to 400 lines per session).")
  public let debugLogging: Bool = false;

  public static func Get() -> ref<VSTSettings> {
    let system: ref<VSTSystem> = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"VehicleSmartTargeting.VSTSystem") as VSTSystem;
    if IsDefined(system) {
      return system.GetSettings();
    }
    return new VSTSettings();
  }
}

// Owns the settings for the session and keeps them in step with the Mod Settings menu.
public class VSTSystem extends ScriptableSystem {
  private let m_settings: ref<VSTSettings>;

  private func OnAttach() -> Void {
    this.GetSettings();
  }

  private func OnDetach() -> Void {
    if IsDefined(this.m_settings) {
      VST_UnregisterSettings(this.m_settings);
    }
  }

  public func GetSettings() -> ref<VSTSettings> {
    if !IsDefined(this.m_settings) {
      this.m_settings = new VSTSettings();
      VST_RegisterSettings(this.m_settings);
    }
    return this.m_settings;
  }
}

@if(ModuleExists("ModSettingsModule"))
func VST_RegisterSettings(settings: ref<VSTSettings>) -> Void {
  ModSettings.RegisterListenerToClass(settings);
}

@if(!ModuleExists("ModSettingsModule"))
func VST_RegisterSettings(settings: ref<VSTSettings>) -> Void {}

@if(ModuleExists("ModSettingsModule"))
func VST_UnregisterSettings(settings: ref<VSTSettings>) -> Void {
  ModSettings.UnregisterListenerToClass(settings);
}

@if(!ModuleExists("ModSettingsModule"))
func VST_UnregisterSettings(settings: ref<VSTSettings>) -> Void {}

public enum VSTFeature {
  SmartLock = 0,
  GimbalAim = 1
}

public enum VSTMode {
  Plain = 0,
  SmartLock = 1,
  GimbalAim = 2
}

public class VSTInstallEntry {
  public persistent let vehicleRecord: TweakDBID;
  public persistent let smartInstalled: Bool;
  public persistent let smartOwned: Bool;
  public persistent let gimbalInstalled: Bool;
  public persistent let gimbalOwned: Bool;
}

// Which targeting upgrades each of the player's cars has, saved with the game.
// Only consulted when the Garage add-on is installed; without it every armed car
// has both modes.
public class VSTInstallSystem extends ScriptableSystem {
  private persistent let m_entries: array<ref<VSTInstallEntry>>;

  public static func Get(game: GameInstance) -> ref<VSTInstallSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"VehicleSmartTargeting.VSTInstallSystem") as VSTInstallSystem;
  }

  private func Find(record: TweakDBID, create: Bool) -> ref<VSTInstallEntry> {
    let entry: ref<VSTInstallEntry>;
    let i: Int32 = 0;
    while i < ArraySize(this.m_entries) {
      if this.m_entries[i].vehicleRecord == record {
        return this.m_entries[i];
      }
      i += 1;
    }
    if !create {
      return null;
    }
    entry = new VSTInstallEntry();
    entry.vehicleRecord = record;
    ArrayPush(this.m_entries, entry);
    return entry;
  }

  public func IsInstalled(record: TweakDBID, feature: VSTFeature) -> Bool {
    let entry: ref<VSTInstallEntry> = this.Find(record, false);
    if !IsDefined(entry) {
      return false;
    }
    return Equals(feature, VSTFeature.SmartLock) ? entry.smartInstalled : entry.gimbalInstalled;
  }

  // True once the upgrade has been bought for this car, installed or not.
  public func IsOwned(record: TweakDBID, feature: VSTFeature) -> Bool {
    let entry: ref<VSTInstallEntry> = this.Find(record, false);
    if !IsDefined(entry) {
      return false;
    }
    return Equals(feature, VSTFeature.SmartLock) ? entry.smartOwned : entry.gimbalOwned;
  }

  public func Install(record: TweakDBID, feature: VSTFeature) -> Bool {
    let entry: ref<VSTInstallEntry> = this.Find(record, true);
    if Equals(feature, VSTFeature.SmartLock) {
      if entry.smartInstalled {
        return false;
      }
      entry.smartInstalled = true;
      entry.smartOwned = true;
    } else {
      if entry.gimbalInstalled {
        return false;
      }
      entry.gimbalInstalled = true;
      entry.gimbalOwned = true;
    }
    return true;
  }

  public func Remove(record: TweakDBID, feature: VSTFeature) -> Bool {
    let entry: ref<VSTInstallEntry> = this.Find(record, false);
    if !IsDefined(entry) {
      return false;
    }
    if Equals(feature, VSTFeature.SmartLock) {
      if !entry.smartInstalled {
        return false;
      }
      entry.smartInstalled = false;
    } else {
      if !entry.gimbalInstalled {
        return false;
      }
      entry.gimbalInstalled = false;
    }
    return true;
  }

  // Whether this car can use the given mode right now.
  public static func HasFeature(vehicle: wref<VehicleObject>, feature: VSTFeature) -> Bool {
    let system: ref<VSTInstallSystem>;
    if !VST_UpgradesMustBeBought() {
      return true;
    }
    if !IsDefined(vehicle) || !vehicle.IsPlayerVehicle() {
      return false;
    }
    system = VSTInstallSystem.Get(vehicle.GetGame());
    return IsDefined(system) && system.IsInstalled(vehicle.GetRecordID(), feature);
  }
}

@if(ModuleExists("VehicleSmartTargeting.Garage"))
public func VST_UpgradesMustBeBought() -> Bool {
  return true;
}

@if(!ModuleExists("VehicleSmartTargeting.Garage"))
public func VST_UpgradesMustBeBought() -> Bool {
  return false;
}

// Tuning values. The ones a player might want to change read from VSTSettings.
public abstract class VSTConfig {
  public static func Debug() -> Bool {
    return VSTSettings.Get().debugLogging;
  }

  // Used when the weapon record carries no smart gun stats (see the tweak file).
  public static func FallbackVelocity() -> Float {
    return 150.0;
  }

  // Chance, 0 to 1, for a guided round to stray wide of its target.
  public static func SmartMissChance() -> Float {
    return Cast<Float>(VSTSettings.Get().smartMissChance) / 100.0;
  }

  // Scales the target's own smart-weapon jamming chance, 0 to 1.
  public static func JammerEffect() -> Float {
    return Cast<Float>(VSTSettings.Get().jammerEffect) / 100.0;
  }

  // How fast a guided round can turn towards its target, in degrees per second.
  // Lower makes wider, more visible curves and more misses on close or fast targets.
  public static func TurnRate() -> Float {
    return 1200.0;
  }

  // Guided rounds aim at a random point this many metres around the target, so a
  // burst spreads over it instead of stacking on one spot.
  public static func HitScatter() -> Float {
    return 0.25;
  }

  // Same, for the rounds that roll a miss.
  public static func MissScatter() -> Float {
    return 2.0;
  }

  // Rounds are only guided when the locked target is within this many degrees of
  // where the guns point; beyond it they fire straight. The guns are fixed forward,
  // so a round sent at a target beside or behind the car just hits the car or the road.
  public static func GuidanceCone() -> Float {
    return Cast<Float>(VSTSettings.Get().smartArc);
  }

  // Gimbal aim: how far, in degrees either side of straight ahead (and up or down),
  // the guns can swing to follow the crosshair. Past that they stop at the edge.
  public static func GimbalArc() -> Float {
    return Cast<Float>(VSTSettings.Get().gimbalArc);
  }

  // Gimbal aim: where rounds converge when the crosshair is on open sky, in metres.
  public static func GimbalRange() -> Float {
    return 300.0;
  }
}

public abstract class VSTUtils {
  public static func IsMountedPowerWeapon(weapon: wref<GameObject>) -> Bool {
    let weaponObject: wref<WeaponObject> = weapon as WeaponObject;
    if !IsDefined(weaponObject) {
      return false;
    }
    return Equals(WeaponObject.GetWeaponType(weaponObject.GetItemID()), gamedataItemType.Wea_VehiclePowerWeapon);
  }

  public static func IsFiredByPlayer(owner: wref<GameObject>) -> Bool {
    let player: ref<PlayerPuppet>;
    let vehicle: wref<VehicleObject>;
    if !IsDefined(owner) {
      return false;
    }
    if owner.IsPlayer() {
      return true;
    }
    player = GetPlayer(owner.GetGame());
    if !IsDefined(player) {
      return false;
    }
    VehicleComponent.GetVehicle(owner.GetGame(), player, vehicle);
    return IsDefined(vehicle) && Equals(vehicle.GetEntityID(), owner.GetEntityID());
  }

  // The same tracked target the missile launcher locks on to.
  public static func GetLockedTarget(owner: wref<GameObject>) -> wref<TargetingComponent> {
    let player: ref<PlayerPuppet> = GetPlayer(owner.GetGame());
    if !IsDefined(player) {
      return null;
    }
    return GameInstance.GetTargetingSystem(owner.GetGame()).GetTrackedTargetComponent(player);
  }

  // The mode the player's current car is actually in: the one they selected if the
  // car has it, otherwise the other one, otherwise plain straight fire.
  public static func GetMode(game: GameInstance) -> VSTMode {
    let player: ref<PlayerPuppet> = GetPlayer(game);
    let vehicle: wref<VehicleObject>;
    let smart: Bool;
    let gimbal: Bool;
    if !IsDefined(player) {
      return VSTMode.Plain;
    }
    VehicleComponent.GetVehicle(game, player, vehicle);
    smart = VSTInstallSystem.HasFeature(vehicle, VSTFeature.SmartLock);
    gimbal = VSTInstallSystem.HasFeature(vehicle, VSTFeature.GimbalAim);
    if gimbal && (player.m_vstGimbalAim || !smart) {
      return VSTMode.GimbalAim;
    }
    if smart {
      return VSTMode.SmartLock;
    }
    return VSTMode.Plain;
  }

  // The point in the world under the centre of the screen, as seen from the camera.
  // The search starts level with the muzzle so the player's own car is never picked.
  public static func GetCrosshairAimPoint(game: GameInstance, muzzle: Vector4) -> Vector4 {
    let groups: array<CName> = [n"Static", n"Terrain", n"Vehicle", n"AI", n"Dynamic", n"Destructible"];
    let cameraSystem: ref<CameraSystem> = GameInstance.GetCameraSystem(game);
    let queries: ref<SpatialQueriesSystem> = GameInstance.GetSpatialQueriesSystem(game);
    let cameraTransform: Transform;
    let cameraPosition: Vector4;
    let forward: Vector4;
    let along: Float;
    let start: Vector4;
    let end: Vector4;
    let best: Vector4;
    let bestDistance: Float;
    let distance: Float;
    let hit: TraceResult;
    let hitPosition: Vector4;
    let i: Int32 = 0;
    cameraSystem.GetActiveCameraWorldTransform(cameraTransform);
    cameraPosition = Transform.GetPosition(cameraTransform);
    forward = Vector4.Normalize(cameraSystem.GetActiveCameraForward());
    along = MaxF(Vector4.Dot(muzzle - cameraPosition, forward), 0.0);
    start = cameraPosition + forward * (along + 2.0);
    end = cameraPosition + forward * (along + VSTConfig.GimbalRange());
    best = end;
    bestDistance = VSTConfig.GimbalRange();
    while i < ArraySize(groups) {
      if queries.SyncRaycastByCollisionGroup(start, end, groups[i], hit, false, false) {
        hitPosition = Vector4.Vector3To4(hit.position);
        distance = Vector4.Distance(start, hitPosition);
        if distance < bestDistance {
          bestDistance = distance;
          best = hitPosition;
        }
      }
      i += 1;
    }
    return best;
  }

  public static func Log(owner: wref<GameObject>, message: String) -> Void {
    let player: ref<PlayerPuppet>;
    if !VSTConfig.Debug() || !IsDefined(owner) {
      return;
    }
    player = GetPlayer(owner.GetGame());
    if !IsDefined(player) || player.m_vstLogCount >= 400 {
      return;
    }
    player.m_vstLogCount += 1;
    FTLog("[VehicleSmartTargeting] " + message);
  }
}

@addField(PlayerPuppet)
public let m_vstLogCount: Int32;

@addField(PlayerPuppet)
public let m_vstGunPresetActive: Bool;

// Which of the two mounted gun modes is selected: smart lock-on (false) or gimbal aim.
@addField(PlayerPuppet)
public let m_vstGimbalAim: Bool;

@addMethod(PlayerPuppet)
public func VST_ShowMessage(text: String) -> Void {
  let message: SimpleScreenMessage;
  message.isShown = true;
  message.duration = 2.0;
  message.message = text;
  GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications).SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(message), true);
}

// Selects gimbal aim (true) or smart lock (false), if the current car has it.
@addMethod(PlayerPuppet)
public func VST_SelectGimbalAim(enabled: Bool) -> Void {
  let vehicle: wref<VehicleObject>;
  VehicleComponent.GetVehicle(this.GetGame(), this, vehicle);
  if !VSTInstallSystem.HasFeature(vehicle, enabled ? VSTFeature.GimbalAim : VSTFeature.SmartLock) {
    this.VST_ShowMessage(VST_Upper(VST_Text(enabled ? "VehicleSmartTargeting-GimbalAim-Missing" : "VehicleSmartTargeting-SmartLock-Missing")));
    return;
  }
  if Equals(this.m_vstGimbalAim, enabled) {
    return;
  }
  this.m_vstGimbalAim = enabled;
  // Drop whatever preset is active so the lock-on is picked up or released right away.
  this.m_vstGunPresetActive = false;
  this.m_aimAssistListener.m_currentConfig = AimAssistSettingConfig.Count;
  this.UpdateAimAssist();
  this.VST_ShowMessage(VST_Upper(VST_Text(enabled ? "VehicleSmartTargeting-GimbalAim-Selected" : "VehicleSmartTargeting-SmartLock-Selected")));
  VSTUtils.Log(this, "mode: gimbalAim=" + BoolToString(enabled));
}

// The crosshair belongs to the gun's item record, which every car shares, so it is
// switched to suit the car the player has just got into: the missile HUD if the car
// has a targeting mode, the stock gun crosshair if it has none.
@addMethod(PlayerPuppet)
public func VST_SyncCrosshair(vehicle: wref<VehicleObject>) -> Void {
  let record: ref<Vehicle_Record>;
  let weapons: array<wref<VehicleWeapon_Record>>;
  let item: wref<WeaponItem_Record>;
  let crosshair: TweakDBID;
  let i: Int32 = 0;
  if !IsDefined(vehicle) {
    return;
  }
  record = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
  if !IsDefined(record) {
    return;
  }
  if VSTInstallSystem.HasFeature(vehicle, VSTFeature.SmartLock) || VSTInstallSystem.HasFeature(vehicle, VSTFeature.GimbalAim) {
    crosshair = t"Crosshairs.Driver_Combat_Missile_Launcher";
  } else {
    crosshair = t"Crosshairs.Driver_Combat_Power_Weapon";
  }
  record.Weapons(weapons);
  while i < ArraySize(weapons) {
    item = weapons[i].Item() as WeaponItem_Record;
    if IsDefined(item) && Equals(item.ItemType().Type(), gamedataItemType.Wea_VehiclePowerWeapon) && item.Crosshair().GetID() != crosshair {
      TweakDBManager.SetFlat(item.GetID() + t".crosshair", ToVariant(crosshair));
      TweakDBManager.UpdateRecord(item.GetID());
      VSTUtils.Log(this, "crosshair: set to " + (crosshair == t"Crosshairs.Driver_Combat_Missile_Launcher" ? "missile HUD" : "stock gun crosshair"));
    }
    i += 1;
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnVehicleStateChange(newState: Int32) -> Bool {
  let vehicle: wref<VehicleObject>;
  let result: Bool = wrappedMethod(newState);
  // On getting in or settling into the seat, before the guns can be drawn.
  if newState != EnumInt(gamePSMVehicle.Default) && newState != EnumInt(gamePSMVehicle.DriverCombat) {
    VehicleComponent.GetVehicle(this.GetGame(), this, vehicle);
    this.VST_SyncCrosshair(vehicle);
  }
  return result;
}

// The gun modes are picked like weapons while the mounted guns are out:
//   - on a car with only guns: 1 selects smart lock, 2 selects gimbal aim, and the
//     switch-weapon key (Alt / Triangle / Y) flips between them;
//   - on a car that also has missiles those keys already switch guns and missiles,
//     so pressing the guns' own key (1) again while they are out flips the mode.
@wrapMethod(DriverCombatMountedWeaponsEvents)
protected func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  let vehicle: ref<VehicleObject> = scriptInterface.owner as VehicleObject;
  let gunsWereOut: Bool = IsDefined(vehicle) && Equals(this.GetVehicleWeaponType(vehicle), gamedataItemType.Wea_VehiclePowerWeapon);
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  if !gunsWereOut || !IsDefined(player) {
    return;
  }
  if vehicle.CanSwitchWeapons() {
    if scriptInterface.IsActionJustPressed(n"MountedWeapons_WeaponSlot1") {
      player.VST_SelectGimbalAim(NotEquals(VSTUtils.GetMode(player.GetGame()), VSTMode.GimbalAim));
    }
  } else {
    if scriptInterface.IsActionJustPressed(n"MountedWeapons_SwitchWeapons") {
      player.VST_SelectGimbalAim(NotEquals(VSTUtils.GetMode(player.GetGame()), VSTMode.GimbalAim));
    } else {
      if scriptInterface.IsActionJustPressed(n"MountedWeapons_WeaponSlot1") {
        player.VST_SelectGimbalAim(false);
      } else {
        if scriptInterface.IsActionJustPressed(n"MountedWeapons_WeaponSlot2") {
          player.VST_SelectGimbalAim(true);
        }
      }
    }
  }
}

// Mounted machine guns normally get the plain Vehicle preset, which never tracks
// a target. Give them their own lock-on preset (defined in the tweak file), which
// is the missile launcher's with a quicker, stickier lock.
@wrapMethod(PlayerPuppet)
public func ApplyAimAssistSettings(config: AimAssistSettingConfig) -> Void {
  let presetID: TweakDBID = t"AimAssist.VST_ConfigPreset_MountedGuns";
  let newConfig: AimAssistSettingConfig = config;
  if Equals(config, AimAssistSettingConfig.Vehicle)
    && Equals(VSTUtils.GetMode(this.GetGame()), VSTMode.SmartLock)
    && Equals(this.m_vehicleState, gamePSMVehicle.DriverCombat)
    && this.m_inMountedWeaponVehicle
    && Equals(this.m_driverCombatWeaponType, gamedataItemType.Wea_VehiclePowerWeapon) {
    if IsDefined(TweakDBInterface.GetAimAssistConfigPresetRecord(presetID)) {
      if !this.m_vstGunPresetActive {
        this.m_vstGunPresetActive = true;
        // Count is the game's "nothing applied" value, so the next real preset always goes through.
        this.m_aimAssistListener.m_currentConfig = AimAssistSettingConfig.Count;
        GameInstance.GetTargetingSystem(this.GetGame()).SetAimAssistConfig(this, presetID);
        VSTUtils.Log(this, "aim assist: mounted gun lock-on preset applied");
      }
      return;
    }
    // Tweak file missing: fall back to the stock missile launcher presets.
    if this.m_isAiming {
      newConfig = AimAssistSettingConfig.DriverCombatMissilesAiming;
    } else {
      newConfig = AimAssistSettingConfig.DriverCombatMissiles;
    }
  }
  this.m_vstGunPresetActive = false;
  wrappedMethod(newConfig);
}

// The lock-on diamond plays a long "locking" animation unless a perk shortens it.
// The guns guide as soon as the lock exists, so always show the short one for them.
//
// The game passes the locked target to the crosshair through a blackboard value, and
// in some setups that value cannot be read back even though the lock exists.
// So for the guns the diamond takes its target straight from the targeting system,
// both when the game signals a change and every frame while the crosshair is drawn.
@addMethod(gameuiDriverCombatMountedMissileLauncherCrosshairGameController)
private func VST_GunsAreOut() -> Bool {
  return IsDefined(this.m_playerPuppet)
    && this.m_psmBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.DriverCombatWeaponType) == EnumInt(gamedataItemType.Wea_VehiclePowerWeapon);
}

@addMethod(gameuiDriverCombatMountedMissileLauncherCrosshairGameController)
private func VST_ShowLockOn(target: wref<IPlacedComponent>) -> Void {
  let options: inkAnimOptions;
  if IsDefined(this.m_lockingAnimationProxy) && this.m_lockingAnimationProxy.IsValid() {
    this.m_lockingAnimationProxy.GotoStartAndStop();
  }
  this.m_currentTarget = target;
  if IsDefined(target) {
    this.m_lockingAnimationProxy = this.PlayLibraryAnimation(n"locking_short", options);
    inkWidgetRef.SetVisible(this.m_lockingAnimationWidget, true);
  } else {
    inkWidgetRef.SetVisible(this.m_lockingAnimationWidget, false);
  }
}

@wrapMethod(gameuiDriverCombatMountedMissileLauncherCrosshairGameController)
protected cb func OnPSMTrackedTargetChanged(value: Variant) -> Bool {
  let result: Bool = wrappedMethod(value);
  if this.VST_GunsAreOut() {
    this.VST_ShowLockOn(GameInstance.GetTargetingSystem(this.m_playerPuppet.GetGame()).GetTrackedTargetComponent(this.m_playerPuppet));
  }
  return result;
}

@wrapMethod(gameuiDriverCombatMountedMissileLauncherCrosshairGameController)
protected func UpdateLockingAnimationWidgetTranslation(uiScreenResolution: Vector2) -> Void {
  let tracked: wref<IPlacedComponent>;
  if this.VST_GunsAreOut() {
    tracked = GameInstance.GetTargetingSystem(this.m_playerPuppet.GetGame()).GetTrackedTargetComponent(this.m_playerPuppet);
    if NotEquals(IsDefined(tracked), IsDefined(this.m_currentTarget)) || (IsDefined(tracked) && tracked != this.m_currentTarget) {
      VSTUtils.Log(this.m_playerPuppet, "crosshair: lock state corrected, locked=" + BoolToString(IsDefined(tracked)));
      this.VST_ShowLockOn(tracked);
    }
  }
  wrappedMethod(uiScreenResolution);
}

@wrapMethod(sampleSmartBullet)
protected cb func OnProjectileInitialize(eventData: ref<gameprojectileSetUpEvent>) -> Bool {
  let result: Bool = wrappedMethod(eventData);
  let velocity: Float;
  if VSTUtils.IsMountedPowerWeapon(this.m_weapon) {
    // Vanilla only reads the velocity stat when the owner is the player or an NPC puppet.
    if this.m_startVelocity <= 1.0 {
      velocity = this.m_statsSystem.GetStatValue(Cast<StatsObjectID>(this.m_weapon.GetEntityID()), gamedataStatType.SmartGunPlayerProjectileVelocity);
      if velocity <= 1.0 {
        velocity = VSTConfig.FallbackVelocity();
      }
      this.m_startVelocity = velocity;
      this.m_randStartVelocity = velocity;
    }
  }
  return result;
}

@addMethod(sampleSmartBullet)
private func VST_ShouldGuide() -> Bool {
  return VSTUtils.IsMountedPowerWeapon(this.m_weapon) && VSTUtils.IsFiredByPlayer(this.m_owner);
}

// The locked target, or null when it is outside the arc the guns can reach.
@addMethod(sampleSmartBullet)
private func VST_GetReachableTarget(eventData: ref<gameprojectileShootEvent>) -> wref<TargetingComponent> {
  let target: wref<TargetingComponent> = VSTUtils.GetLockedTarget(this.m_owner);
  let angle: Float;
  if !IsDefined(target) {
    return null;
  }
  angle = Vector4.GetAngleBetween(Matrix.GetDirectionVector(eventData.localToWorld), Matrix.GetTranslation(target.GetLocalToWorld()) - eventData.startPoint);
  if angle > VSTConfig.GuidanceCone() {
    VSTUtils.Log(this.m_owner, "locked target is " + FloatToString(angle) + "deg off the guns, firing straight");
    return null;
  }
  return target;
}

@addField(sampleSmartBullet)
private let m_vstGuided: Bool;

@addField(sampleSmartBullet)
private let m_vstHeading: Vector4;

@addField(sampleSmartBullet)
private let m_vstAimOffset: Vector4;

// The game's own follow curve dips on launch, which is harmless from shoulder height
// but puts most rounds into the road from a gun mounted just above it. So guided
// rounds fly a plain straight trajectory that is re-pointed at the target every tick.
@addMethod(sampleSmartBullet)
private func VST_ShootAtLockedTarget(eventData: ref<gameprojectileShootEvent>, target: wref<TargetingComponent>) -> Void {
  let scatter: Float = VSTConfig.HitScatter();
  let barrel: Vector4 = Matrix.GetDirectionVector(eventData.localToWorld);
  let toTarget: Vector4;
  let missed: Bool;
  this.Reset();
  this.m_targeted = true;
  this.m_startPosition = eventData.startPoint;
  this.m_trackedTargetComponent = target;
  this.m_targetID = target.GetEntity().GetEntityID();
  this.SetupCommonParams(eventData.weaponVelocity);
  this.m_followPhaseParams = new FollowCurveTrajectoryParams();
  this.m_followPhaseParams.targetComponent = target;
  // A round misses on its own hit roll, or when the target is jamming smart weapons.
  missed = RandF() < VSTConfig.SmartMissChance()
    || RandF() < ClampF(this.m_statsSystem.GetStatValue(Cast<StatsObjectID>(this.m_targetID), gamedataStatType.SmartTargetingDisruptionProbability), 0.0, 1.0) * VSTConfig.JammerEffect();
  if missed {
    scatter = VSTConfig.MissScatter();
  }
  this.m_vstAimOffset = new Vector4(RandRangeF(-scatter, scatter), RandRangeF(-scatter, scatter), RandRangeF(-scatter, scatter) * 0.5, 0.0);
  toTarget = Matrix.GetTranslation(target.GetLocalToWorld()) + this.m_vstAimOffset - eventData.startPoint;
  this.m_vstGuided = true;
  this.m_vstHeading = Vector4.Normalize(barrel);
  this.m_phase = ESmartBulletPhase.Linear;
  this.m_timeInPhase = 0.0;
  this.VST_PointAlong(eventData.startPoint);
  this.StartTrailEffect();
  this.m_projectileComponent.SetOnCollisionAction(gameprojectileOnCollisionAction.Stop);
  VSTUtils.Log(this.m_owner, "guided: distance=" + FloatToString(Vector4.Length(toTarget)) + " barrelOffTarget=" + FloatToString(Vector4.GetAngleBetween(barrel, toTarget)) + "deg missRoll=" + BoolToString(missed) + " headingCheck=" + FloatToString(this.VST_HeadingError()) + "deg");
}

@addField(sampleSmartBullet)
private let m_vstGimbalRound: Bool;

// Gimbal aim: no lock and no homing. The round leaves the gun pointed at whatever is
// under the crosshair, as far as the arc allows, and flies straight.
@addMethod(sampleSmartBullet)
private func VST_ShootGimbal(eventData: ref<gameprojectileShootEvent>) -> Void {
  let angle: Float;
  this.Reset();
  this.m_targeted = false;
  this.m_vstGimbalRound = true;
  this.m_startPosition = eventData.startPoint;
  this.SetupCommonParams(eventData.weaponVelocity);
  this.m_followPhaseParams = new FollowCurveTrajectoryParams();
  this.m_vstBarrel = Vector4.Normalize(Matrix.GetDirectionVector(eventData.localToWorld));
  this.m_vstAimPoint = VSTUtils.GetCrosshairAimPoint(this.m_owner.GetGame(), eventData.startPoint);
  // The game overwrites a heading set during launch, so it is set again on the
  // round's first ticks (see OnTick).
  this.m_vstGimbalTicks = 2;
  angle = this.VST_AimGimbal(eventData.startPoint);
  this.m_phase = ESmartBulletPhase.Linear;
  this.m_timeInPhase = 0.0;
  this.VST_PointAlong(eventData.startPoint);
  this.StartTrailEffect();
  this.m_projectileComponent.SetOnCollisionAction(gameprojectileOnCollisionAction.Stop);
  VSTUtils.Log(this.m_owner, "gimbal: aimPointDistance=" + FloatToString(Vector4.Distance(this.m_vstAimPoint, eventData.startPoint)) + " offBarrel=" + FloatToString(angle) + "deg clamped=" + BoolToString(angle > VSTConfig.GimbalArc()));
}

@addField(sampleSmartBullet)
private let m_vstBarrel: Vector4;

@addField(sampleSmartBullet)
private let m_vstAimPoint: Vector4;

@addField(sampleSmartBullet)
private let m_vstGimbalTicks: Int32;

// Sets the heading from the given position towards the aim point, held within the
// gimbal arc around the barrel. Returns how far off the barrel the aim point is.
@addMethod(sampleSmartBullet)
private func VST_AimGimbal(from: Vector4) -> Float {
  let aim: Vector4 = Vector4.Normalize(this.m_vstAimPoint - from);
  let angle: Float = Vector4.GetAngleBetween(this.m_vstBarrel, aim);
  let arc: Float = VSTConfig.GimbalArc();
  if angle > arc {
    // Rotate from the barrel towards the aim direction, but only as far as the arc.
    this.m_vstHeading = Vector4.Normalize(this.m_vstBarrel * SinF(Deg2Rad(angle - arc)) + aim * SinF(Deg2Rad(arc)));
  } else {
    this.m_vstHeading = aim;
  }
  return angle;
}

// Debug: angle between the heading asked for and the one the transform actually holds.
@addMethod(sampleSmartBullet)
private func VST_HeadingError() -> Float {
  let transform: Transform;
  Transform.SetOrientationFromDir(transform, this.m_vstHeading);
  return Vector4.GetAngleBetween(Transform.GetForward(transform), this.m_vstHeading);
}

// Restarts the straight trajectory from the given position along the current heading.
// Same calls the vanilla smart bullet uses to veer off when it misses.
@addMethod(sampleSmartBullet)
private func VST_PointAlong(position: Vector4) -> Void {
  let transform: Transform;
  Transform.SetPosition(transform, position);
  // Not Vector4.ToRotation + SetOrientationEuler: that pair flips the pitch, which
  // sent every round aimed up at a target down into the road instead.
  Transform.SetOrientationFromDir(transform, this.m_vstHeading);
  this.m_projectileComponent.ClearTrajectories();
  this.m_projectileComponent.SetDesiredTransform(transform);
  this.m_projectileComponent.AddLinear(this.m_linearPhaseParams);
  this.m_projectileComponent.LockOrientation(false);
}

@wrapMethod(sampleSmartBullet)
protected cb func OnTick(eventData: ref<gameprojectileTickEvent>) -> Bool {
  let toTarget: Vector4;
  let angle: Float;
  let maxStep: Float;
  if this.m_vstGimbalRound && this.m_vstGimbalTicks > 0 && this.m_alive {
    this.m_vstGimbalTicks -= 1;
    this.VST_AimGimbal(eventData.position);
    this.VST_PointAlong(eventData.position);
    if this.m_vstGimbalTicks == 0 {
      VSTUtils.Log(this.m_owner, "gimbal: heading set " + FloatToString(Vector4.Distance(this.m_startPosition, eventData.position)) + "m out, " + FloatToString(Vector4.GetAngleBetween(this.m_vstBarrel, this.m_vstHeading)) + "deg off barrel");
    }
  }
  if this.m_vstGuided && this.m_alive {
    if !IsDefined(this.m_followPhaseParams.targetComponent) {
      this.m_vstGuided = false;
    } else {
      toTarget = Matrix.GetTranslation(this.m_followPhaseParams.targetComponent.GetLocalToWorld()) + this.m_vstAimOffset - eventData.position;
      angle = Vector4.GetAngleBetween(this.m_vstHeading, toTarget);
      if angle > 90.0 || Vector4.Length(toTarget) < 1.0 {
        // Past the target or about to arrive: stop steering and let it fly on.
        this.m_vstGuided = false;
      } else {
        if angle > 0.5 {
          maxStep = VSTConfig.TurnRate() * eventData.deltaTime;
          if angle <= maxStep {
            this.m_vstHeading = Vector4.Normalize(toTarget);
          } else {
            this.m_vstHeading = Vector4.Normalize(Vector4.Interpolate(this.m_vstHeading, Vector4.Normalize(toTarget), maxStep / angle));
          }
          this.VST_PointAlong(eventData.position);
        }
      }
    }
  }
  return wrappedMethod(eventData);
}

@wrapMethod(sampleSmartBullet)
protected cb func OnCollision(projectileHitEvent: ref<gameprojectileHitEvent>) -> Bool {
  if (this.m_targeted || this.m_vstGimbalRound) && ArraySize(projectileHitEvent.hitInstances) > 0 && this.VST_ShouldGuide() {
    let hitPosition: Vector4 = projectileHitEvent.hitInstances[0].position;
    let details: String = " travelled=" + FloatToString(Vector4.Distance(this.m_startPosition, hitPosition)) + " heightChange=" + FloatToString(hitPosition.Z - this.m_startPosition.Z) + " stopped=" + BoolToString(this.m_BulletCollisionEvaluator.HasReportedStopped()) + " flightTime=" + FloatToString(this.m_countTime);
    if IsDefined(projectileHitEvent.hitInstances[0].hitObject) {
      VSTUtils.Log(this.m_owner, "hit: " + NameToString(projectileHitEvent.hitInstances[0].hitObject.GetClassName()) + " onTarget=" + BoolToString(Equals(projectileHitEvent.hitInstances[0].hitObject.GetEntityID(), this.m_targetID)) + details);
    } else {
      VSTUtils.Log(this.m_owner, "hit: world" + details);
    }
  }
  return wrappedMethod(projectileHitEvent);
}

@wrapMethod(sampleSmartBullet)
protected cb func OnShoot(eventData: ref<gameprojectileShootEvent>) -> Bool {
  let target: wref<TargetingComponent>;
  let mode: VSTMode;
  // Projectiles are pooled, so clear the flag left by this round's previous flight.
  this.m_vstGuided = false;
  this.m_vstGimbalRound = false;
  if this.VST_ShouldGuide() {
    mode = VSTUtils.GetMode(this.m_owner.GetGame());
    if Equals(mode, VSTMode.GimbalAim) {
      this.VST_ShootGimbal(eventData);
      return true;
    }
    if Equals(mode, VSTMode.SmartLock) {
      target = this.VST_GetReachableTarget(eventData);
      if IsDefined(target) {
        this.VST_ShootAtLockedTarget(eventData, target);
        return true;
      }
    }
  }
  return wrappedMethod(eventData);
}

@wrapMethod(sampleSmartBullet)
protected cb func OnShootTarget(eventData: ref<gameprojectileShootTargetEvent>) -> Bool {
  // The game hands mounted guns no usable target or aim point, and the vanilla handler
  // would curve the round towards it anyway. OnShoot picks gimbal, guided or straight.
  if this.VST_ShouldGuide() {
    return this.OnShoot(eventData);
  }
  this.m_vstGuided = false;
  this.m_vstGimbalRound = false;
  return wrappedMethod(eventData);
}

@wrapMethod(DriverCombatEvents)
protected cb func OnDriverCombatTargetChange(value: Variant) -> Bool {
  let result: Bool = wrappedMethod(value);
  let tracked: wref<TargetingComponent>;
  if IsDefined(this.m_targetComponent) {
    VSTUtils.Log(this.m_executionOwner, "lock acquired: " + NameToString(this.m_targetComponent.GetEntity().GetClassName()));
  } else {
    // Says whether the game's signal was really "no target" or arrived empty while a lock exists.
    tracked = GameInstance.GetTargetingSystem(this.m_executionOwner.GetGame()).GetTrackedTargetComponent(this.m_executionOwner);
    VSTUtils.Log(this.m_executionOwner, "lock signal empty: valueType=" + NameToString(VariantTypeName(value)) + " lockExists=" + BoolToString(IsDefined(tracked)));
  }
  return result;
}

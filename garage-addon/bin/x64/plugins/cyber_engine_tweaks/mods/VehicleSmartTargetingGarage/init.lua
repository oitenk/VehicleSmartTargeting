-- Vehicle Smart Targeting - Garage add-on
-- Wires the Targeting service into the Garage hub. The screen and the upgrade
-- logic live in r6/scripts/VehicleSmartTargetingGarage.

local BRIDGE = "VehicleSmartTargeting.Garage.TargetingBridge"

registerForEvent("onInit", function()
    local GC = GetMod("GarageCore")
    if not GC then
        print("[VehicleSmartTargetingGarage] GarageCore not found - add-on disabled")
        return
    end

    -- The string is the fully-qualified Redscript class name: "Module.ClassName"
    GC.registerModuleRegistrar("VehicleSmartTargeting.Garage.TargetingRegistrar")

    local function currentGarage()
        local State = GC.getSharedState()
        return State and State.currentGarageLocation and State.currentGarageLocation.filename
    end

    -- Where GarageCore provides GC.Payment, it takes the eddies, pays the garage's
    -- cash pool, updates the economy HUD and fires the transaction event in one call.
    local Payment = GC.Payment
    if type(Payment) == "table" and type(Payment.charge) == "function" then
        local lastReceipt = nil

        Override(BRIDGE, "Charge;Int32", function(amount)
            lastReceipt = nil
            if amount <= 0 then return true end
            lastReceipt = Payment.charge({
                amount = amount,
                garageFilename = currentGarage(),
                kind = "Service",
                source = "vst_targeting",
            })
            return lastReceipt ~= nil
        end)

        Override(BRIDGE, "Complete;String", function(title)
            if lastReceipt and GC.Notify and type(GC.Notify.service) == "function" then
                GC.Notify.service({ title = title, receipt = lastReceipt })
            end
            lastReceipt = nil
        end)
        return
    end

    -- Without GC.Payment, let the Redscript stub take the eddies, then pay them
    -- into the garage's cash pool through the SDK's economy table.
    Override(BRIDGE, "Charge;Int32", function(amount, wrapped)
        if not wrapped(amount) then return false end
        local garage = currentGarage()
        local economy = GC.getEconomy()
        if amount > 0 and garage and economy and type(economy.addToPool) == "function" then
            economy.addToPool(garage, amount)
            local hud = GC.EconomyHUD
            if hud and type(hud.update) == "function" and type(economy.getPool) == "function" then
                hud.update(economy.getPool(garage))
            end
        end
        return true
    end)
end)

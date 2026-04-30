CigaretteVending = CigaretteVending or {}

CigaretteVending.WorldSprite = CigaretteVending.WorldSprite or "cigarette_vending_01a_9"
CigaretteVending.AutoGiveDebugMachine = true
CigaretteVending.AutoGiveDone = CigaretteVending.AutoGiveDone or {}

local function cigaretteVendingRequireMoveables()
    if not ISMoveableSpriteProps then
        pcall(require, "Moveables/ISMoveableSpriteProps")
    end
end

function CigaretteVending.createMoveable(spriteName)
    spriteName = spriteName or CigaretteVending.WorldSprite
    cigaretteVendingRequireMoveables()

    local props = ISMoveableSpriteProps and ISMoveableSpriteProps.new(spriteName) or nil
    if props then
        print("CigaretteVending: sprite props", spriteName, "sprite=", tostring(props.sprite ~= nil), "isMoveable=", tostring(props.isMoveable), "name=", tostring(props.name))
    else
        print("CigaretteVending: ISMoveableSpriteProps unavailable")
    end

    local item = instanceItem("Moveables.Moveable")
    if not item then
        print("CigaretteVending: failed to create Moveables.Moveable")
        return nil
    end

    local ok = false
    ok = item:ReadFromWorldSprite(spriteName)

    item:getModData().CigaretteVendingWorldSprite = spriteName

    print("CigaretteVending: created moveable item", item:getFullType(), item:getDisplayName(), "worldSprite=", tostring(item:getWorldSprite()), "readFromSprite=", tostring(ok), "instanceofMoveable=", tostring(instanceof(item, "Moveable")))
    return item
end

function CigaretteVending.inventoryHasSprite(player, spriteName)
    if not player then
        return false
    end

    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Moveable") and item.getWorldSprite and item:getWorldSprite() == spriteName then
            return true
        end
    end
    return false
end

function CigaretteVending.giveMoveable(playerIndex, spriteName)
    local player = getSpecificPlayer(playerIndex or 0) or getPlayer()
    if not player then
        print("CigaretteVending: no player found")
        return nil
    end

    local item = CigaretteVending.createMoveable(spriteName)
    if item then
        player:getInventory():AddItem(item)
        if sendAddItemToContainer then
            sendAddItemToContainer(player:getInventory(), item)
        end
        print("CigaretteVending: added moveable to inventory", item:getFullType(), tostring(item:getWorldSprite()))
    end
    return item
end

function CigaretteVending.autoGiveMoveable(playerIndex)
    if not CigaretteVending.AutoGiveDebugMachine then
        return
    end

    playerIndex = playerIndex or 0
    if CigaretteVending.AutoGiveDone[playerIndex] then
        return
    end

    local player = getSpecificPlayer(playerIndex) or getPlayer()
    if not player then
        print("CigaretteVending: auto-give waiting for player")
        return
    end

    CigaretteVending.AutoGiveDone[playerIndex] = true
    if CigaretteVending.inventoryHasSprite(player, CigaretteVending.WorldSprite) then
        print("CigaretteVending: player already has debug moveable", CigaretteVending.WorldSprite)
        return
    end

    print("CigaretteVending: auto-giving debug moveable", CigaretteVending.WorldSprite)
    CigaretteVending.giveMoveable(playerIndex, CigaretteVending.WorldSprite)
end

function CigaretteVending.inspectVendingItems(playerIndex)
    local player = getSpecificPlayer(playerIndex or 0) or getPlayer()
    if not player then
        print("CigaretteVending: no player found")
        return
    end

    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local name = tostring(item:getDisplayName())
        local fullType = tostring(item:getFullType())
        local worldSprite = ""

        if item.getWorldSprite then
            worldSprite = tostring(item:getWorldSprite())
        end

        if string.find(string.lower(name), "vending") or string.find(string.lower(fullType), "moveable") then
            print("CigaretteVending ITEM:", fullType, name, "worldSprite=", worldSprite)

            local modData = item:getModData()
            for k, v in pairs(modData) do
                print("CigaretteVending MODDATA:", tostring(k), tostring(v))
            end
        end
    end
end

CVGiveMachine = CigaretteVending.giveMoveable
CVInspectVending = CigaretteVending.inspectVendingItems

local cigaretteVendingTickCount = 0
local function cigaretteVendingOnTick()
    cigaretteVendingTickCount = cigaretteVendingTickCount + 1
    if cigaretteVendingTickCount >= 120 then
        Events.OnTick.Remove(cigaretteVendingOnTick)
        CigaretteVending.autoGiveMoveable(0)
    end
end

Events.OnTick.Add(cigaretteVendingOnTick)

print("CigaretteVending moveable helpers loaded")

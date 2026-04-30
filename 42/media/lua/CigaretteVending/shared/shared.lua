CigaretteVending = CigaretteVending or {}

CigaretteVending.WorldSprite = "cigarette_vending_01a_18"
CigaretteVending.ScriptItem = "Base.cigarette_vending_01a_18"

function CigaretteVending.createMoveable(spriteName)
    spriteName = spriteName or CigaretteVending.WorldSprite

    local props = ISMoveableSpriteProps and ISMoveableSpriteProps.new(spriteName) or nil
    if props then
        print("CigaretteVending: sprite props", spriteName, "sprite=", tostring(props.sprite ~= nil), "isMoveable=", tostring(props.isMoveable), "name=", tostring(props.name))
    else
        print("CigaretteVending: ISMoveableSpriteProps unavailable")
    end

    local item = instanceItem(CigaretteVending.ScriptItem)
    if not item then
        print("CigaretteVending: failed to create", CigaretteVending.ScriptItem)
        return nil
    end

    local ok = false
    if item.ReadFromWorldSprite then
        ok = item:ReadFromWorldSprite(spriteName)
    end

    item:getModData().CigaretteVendingWorldSprite = spriteName

    local worldSprite = item.getWorldSprite and item:getWorldSprite() or nil
    print("CigaretteVending: created moveable item", item:getFullType(), item:getDisplayName(), "worldSprite=", tostring(worldSprite), "readFromSprite=", tostring(ok), "instanceofMoveable=", tostring(instanceof(item, "Moveable")))
    return item
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
        local worldSprite = item.getWorldSprite and item:getWorldSprite() or nil
        print("CigaretteVending: added moveable to inventory", item:getFullType(), tostring(worldSprite))
    end
    return item
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

print("CigaretteVending moveable helpers loaded")

CigaretteVending = CigaretteVending or {}
CigaretteVending.WorldSpawn = CigaretteVending.WorldSpawn or {}

local WorldSpawn = CigaretteVending.WorldSpawn

WorldSpawn.Enabled = WorldSpawn.Enabled ~= false
WorldSpawn.Debug = WorldSpawn.Debug ~= false
WorldSpawn.ReplaceChance = WorldSpawn.ReplaceChance or 35
WorldSpawn.ProcessedFlag = WorldSpawn.ProcessedFlag or "AshboroCigsChecked"
WorldSpawn.ObjectProcessedFlag = WorldSpawn.ObjectProcessedFlag or "AshboroCigsObjectChecked"

WorldSpawn.VanillaVendingSprites = WorldSpawn.VanillaVendingSprites or {
    ["location_shop_accessories_01_16"] = true,
    ["location_shop_accessories_01_17"] = true,
    ["location_shop_accessories_01_18"] = true,
    ["location_shop_accessories_01_19"] = true,
    ["location_shop_accessories_01_28"] = true,
    ["location_shop_accessories_01_29"] = true,
    ["location_shop_accessories_01_30"] = true,
    ["location_shop_accessories_01_31"] = true,
}

WorldSpawn.Replacements = WorldSpawn.Replacements or {
    ["location_shop_accessories_01_16"] = "cigarette_vending_01a_18",
    ["location_shop_accessories_01_17"] = "cigarette_vending_01a_19",
    ["location_shop_accessories_01_18"] = "cigarette_vending_01a_18",
    ["location_shop_accessories_01_19"] = "cigarette_vending_01a_19",
    ["location_shop_accessories_01_28"] = "cigarette_vending_01a_30",
    ["location_shop_accessories_01_29"] = "cigarette_vending_01a_31",
    ["location_shop_accessories_01_30"] = "cigarette_vending_01a_30",
    ["location_shop_accessories_01_31"] = "cigarette_vending_01a_31",
}

local function debugLog(...)
    if WorldSpawn.Debug then
        print("[CigaretteVending.WorldSpawn]", ...)
    end
end

local function getSpriteName(obj)
    if not obj or not obj.getSprite or not obj:getSprite() then
        return nil
    end
    return obj:getSprite():getName()
end

local function fillAshboroContainer(container)
    if not container then
        return
    end

    if container:getItems() and container:getItems():size() > 0 then
        return
    end

    local cigaretteCount = 1 + ZombRand(4)
    for _ = 1, cigaretteCount do
        container:AddItem("Base.CigarettePack")
    end

    if ZombRand(100) < 35 then
        container:AddItem("Base.Lighter")
    end

    if ZombRand(100) < 45 then
        container:AddItem("Base.Matches")
    end

    if ZombRand(100) < 20 then
        container:AddItem("Base.Money")
    end

    container:setExplored(true)
end

local function requireMoveables()
    if not ISMoveableSpriteProps then
        pcall(require, "Moveables/ISMoveableSpriteProps")
    end
end

local function findObjectIndex(square, obj)
    local objects = square and square:getObjects()
    if not objects then
        return nil
    end

    for i = 0, objects:size() - 1 do
        if objects:get(i) == obj then
            return i
        end
    end

    return nil
end

local function findObjectBySprite(square, spriteName)
    local objects = square and square:getObjects()
    if not objects then
        return nil
    end

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if getSpriteName(obj) == spriteName then
            return obj
        end
    end

    return nil
end

local function removeObject(square, obj)
    if not square or not obj then
        return false
    end

    if isClient and isClient() and square.transmitRemoveItemFromSquare then
        square:transmitRemoveItemFromSquare(obj)
    elseif isServer and isServer() and square.transmitRemoveItemFromSquareOnClients then
        square:transmitRemoveItemFromSquareOnClients(obj)
    end

    if square.RemoveTileObject then
        return square:RemoveTileObject(obj) ~= false
    end

    if obj.removeFromSquare then
        obj:removeFromSquare()
        return true
    end

    return false
end

local function createMoveableItem(spriteName)
    local fullType = "Base." .. spriteName
    local item = instanceItem(fullType)

    if not item then
        debugLog("Cannot create moveable item", fullType)
        return nil
    end

    if item.ReadFromWorldSprite then
        item:ReadFromWorldSprite(spriteName)
    end

    return item
end

local function placeAshboroObject(square, newSprite, insertIndex)
    requireMoveables()

    if not ISMoveableSpriteProps then
        debugLog("ISMoveableSpriteProps unavailable; cannot place", newSprite)
        return nil
    end

    local props = ISMoveableSpriteProps.new(newSprite)
    local item = createMoveableItem(newSprite)

    if not props or not item then
        return nil
    end

    local ok, err = pcall(function()
        props:placeMoveableInternal(square, item, newSprite)
    end)

    if not ok then
        debugLog("Replacement failed for", newSprite, tostring(err))
        return nil
    end

    local newObj = findObjectBySprite(square, newSprite)
    if not newObj then
        debugLog("Placed sprite not found after replacement", newSprite)
        return nil
    end

    if newObj.getModData then
        newObj:getModData().AshboroCigsWorldSpawned = true
    end

    if newObj.getContainer and newObj:getContainer() then
        newObj:getContainer():setType("AshboroCigs")
        fillAshboroContainer(newObj:getContainer())
    end

    if square.RecalcProperties then
        square:RecalcProperties()
    end
    if square.RecalcAllWithNeighbours then
        square:RecalcAllWithNeighbours(true)
    end

    return newObj
end

local function replaceObject(square, obj, oldSprite, newSprite)
    local insertIndex = findObjectIndex(square, obj)

    if not removeObject(square, obj) then
        debugLog("Could not remove vanilla vending machine", oldSprite)
        return false
    end

    local newObj = placeAshboroObject(square, newSprite, insertIndex)
    if not newObj then
        debugLog("Could not place Ashboro vending machine", newSprite)
        return false
    end

    debugLog(
        "Replaced vending machine",
        oldSprite,
        "with",
        newSprite,
        "at",
        square:getX(),
        square:getY(),
        square:getZ()
    )

    return true
end

local function shouldReplace()
    if WorldSpawn.ReplaceChance <= 0 then
        return false
    end

    if WorldSpawn.ReplaceChance >= 100 then
        return true
    end

    return ZombRand(100) < WorldSpawn.ReplaceChance
end

local function scanSquare(square)
    if not WorldSpawn.Enabled or not square then
        return
    end

    local objects = square:getObjects()
    if not objects then
        return
    end

    for i = objects:size() - 1, 0, -1 do
        local obj = objects:get(i)
        local spriteName = getSpriteName(obj)
        local newSprite = spriteName and WorldSpawn.Replacements[spriteName] or nil

        if newSprite then
            if obj.getModData and obj:getModData()[WorldSpawn.ObjectProcessedFlag] then
                return
            end

            debugLog(
                "Found vanilla vending machine",
                spriteName,
                "at",
                square:getX(),
                square:getY(),
                square:getZ()
            )

            if WorldSpawn.ReplaceChance > 0 then
                local md = square:getModData()
                if md[WorldSpawn.ProcessedFlag] then
                    return
                end

                md[WorldSpawn.ProcessedFlag] = true
                if obj.getModData then
                    obj:getModData()[WorldSpawn.ObjectProcessedFlag] = true
                end

                if shouldReplace() then
                    replaceObject(square, obj, spriteName, newSprite)
                end
            end

            return
        end
    end
end

if Events and Events.LoadGridsquare then
    Events.LoadGridsquare.Add(scanSquare)
    debugLog("Loaded. ReplaceChance=", tostring(WorldSpawn.ReplaceChance))
else
    print("[CigaretteVending.WorldSpawn] Events.LoadGridsquare unavailable")
end

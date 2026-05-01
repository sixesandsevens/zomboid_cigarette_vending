CigaretteVending = CigaretteVending or {}
CigaretteVending.WorldSpawn = CigaretteVending.WorldSpawn or {}

local WorldSpawn = CigaretteVending.WorldSpawn

WorldSpawn.Enabled = WorldSpawn.Enabled ~= false
WorldSpawn.Debug = WorldSpawn.Debug == true
WorldSpawn.SpawnBesideChance = WorldSpawn.SpawnBesideChance or 35
WorldSpawn.ReplaceChance = WorldSpawn.ReplaceChance or 0
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
    ["location_shop_accessories_01_16"] = "cigarette_vending_ashboro_18",
    ["location_shop_accessories_01_17"] = "cigarette_vending_ashboro_19",
    ["location_shop_accessories_01_18"] = "cigarette_vending_ashboro_18",
    ["location_shop_accessories_01_19"] = "cigarette_vending_ashboro_19",
    ["location_shop_accessories_01_28"] = "cigarette_vending_ashboro_30",
    ["location_shop_accessories_01_29"] = "cigarette_vending_ashboro_31",
    ["location_shop_accessories_01_30"] = "cigarette_vending_ashboro_30",
    ["location_shop_accessories_01_31"] = "cigarette_vending_ashboro_31",
}

WorldSpawn.AshboroSprites = WorldSpawn.AshboroSprites or {
    ["cigarette_vending_ashboro_18"] = true,
    ["cigarette_vending_ashboro_19"] = true,
    ["cigarette_vending_ashboro_30"] = true,
    ["cigarette_vending_ashboro_31"] = true,
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

local function rollChance(chance)
    if not chance or chance <= 0 then
        return false
    end

    if chance >= 100 then
        return true
    end

    return ZombRand(100) < chance
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

local function placeAshboroObject(square, newSprite)
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
    if not removeObject(square, obj) then
        debugLog("Could not remove vanilla vending machine", oldSprite)
        return false
    end

    local newObj = placeAshboroObject(square, newSprite)
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

local function squareHasVending(square)
    local objects = square and square:getObjects()
    if not objects then
        return false
    end

    for i = 0, objects:size() - 1 do
        local spriteName = getSpriteName(objects:get(i))
        if spriteName and (WorldSpawn.VanillaVendingSprites[spriteName] or WorldSpawn.AshboroSprites[spriteName]) then
            return true
        end
    end

    return false
end

local function safeSquareBool(square, methodName, ...)
    if not square or not square[methodName] then
        return false
    end

    local ok, result = pcall(square[methodName], square, ...)
    return ok and result or false
end

local function isValidAdjacentSquare(sourceSquare, testSquare)
    if not sourceSquare or not testSquare or testSquare == sourceSquare then
        return false
    end

    if testSquare:getZ() ~= sourceSquare:getZ() then
        return false
    end

    if sourceSquare.getRoom and testSquare.getRoom and sourceSquare:getRoom() ~= testSquare:getRoom() then
        return false
    end

    if squareHasVending(testSquare) then
        return false
    end

    if safeSquareBool(testSquare, "isSolid") or safeSquareBool(testSquare, "isSolidTrans") then
        return false
    end

    if testSquare.isFree and not testSquare:isFree(false) then
        return false
    end

    return true
end

local function getAdjacentSquares(square)
    local cell = getCell()
    if not cell or not square then
        return {}
    end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local offsets = {
        { x = 1, y = 0 },
        { x = -1, y = 0 },
        { x = 0, y = 1 },
        { x = 0, y = -1 },
    }
    local results = {}

    for _, offset in ipairs(offsets) do
        local testSquare = cell:getGridSquare(x + offset.x, y + offset.y, z)
        if isValidAdjacentSquare(square, testSquare) then
            table.insert(results, testSquare)
        end
    end

    return results
end

local function pickAdjacentSquare(square)
    local candidates = getAdjacentSquares(square)
    if #candidates == 0 then
        return nil
    end

    return candidates[ZombRand(#candidates) + 1]
end

local function spawnBesideObject(square, oldSprite, newSprite)
    local targetSquare = pickAdjacentSquare(square)
    if not targetSquare then
        debugLog(
            "No valid adjacent square for Ashboro machine near",
            oldSprite,
            "at",
            square:getX(),
            square:getY(),
            square:getZ()
        )
        return false
    end

    local newObj = placeAshboroObject(targetSquare, newSprite)
    if not newObj then
        return false
    end

    debugLog(
        "Spawned Ashboro vending machine beside",
        oldSprite,
        "using",
        newSprite,
        "at",
        targetSquare:getX(),
        targetSquare:getY(),
        targetSquare:getZ()
    )

    return true
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

            local md = square:getModData()
            if md[WorldSpawn.ProcessedFlag] then
                return
            end

            md[WorldSpawn.ProcessedFlag] = true
            if obj.getModData then
                obj:getModData()[WorldSpawn.ObjectProcessedFlag] = true
            end

            if rollChance(WorldSpawn.SpawnBesideChance) then
                if spawnBesideObject(square, spriteName, newSprite) then
                    return
                end
            end

            if rollChance(WorldSpawn.ReplaceChance) then
                replaceObject(square, obj, spriteName, newSprite)
            end

            return
        end
    end
end

if Events and Events.LoadGridsquare then
    Events.LoadGridsquare.Add(scanSquare)
    debugLog(
        "Loaded. SpawnBesideChance=",
        tostring(WorldSpawn.SpawnBesideChance),
        "ReplaceChance=",
        tostring(WorldSpawn.ReplaceChance)
    )
else
    print("[CigaretteVending.WorldSpawn] Events.LoadGridsquare unavailable")
end

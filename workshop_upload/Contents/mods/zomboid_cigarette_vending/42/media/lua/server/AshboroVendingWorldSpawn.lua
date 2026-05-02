CigaretteVending = CigaretteVending or {}
CigaretteVending.WorldSpawn = CigaretteVending.WorldSpawn or {}

local WorldSpawn = CigaretteVending.WorldSpawn

WorldSpawn.Enabled = WorldSpawn.Enabled ~= false
WorldSpawn.Debug = WorldSpawn.Debug == true
WorldSpawn.SpawnBesideChance = WorldSpawn.SpawnBesideChance or 35
WorldSpawn.ReplaceChance = WorldSpawn.ReplaceChance or 0

-- Per-location tuning. These keep the mod flavorful without turning every soda machine into Ashboro.
-- The names are intentionally fuzzy because room/zone names vary between vanilla, maps, and B42 updates.
WorldSpawn.SpawnChanceByRoomKeyword = WorldSpawn.SpawnChanceByRoomKeyword or {
    bar = 55,
    liquor = 65,
    gas = 45,
    convenience = 45,
    market = 40,
    grocery = 35,
    store = 30,
}

-- Hard no-spawn areas. If a room/zone/building name contains one of these, Ashboro skips it.
WorldSpawn.NoSpawnRoomKeywords = WorldSpawn.NoSpawnRoomKeywords or {
    school = true,
    classroom = true,
    daycare = true,
    nursery = true,
    kindergarten = true,
}

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

local SandboxKeywordOptions = {
    BarSpawnChance = "bar",
    LiquorSpawnChance = "liquor",
    GasSpawnChance = "gas",
    ConvenienceSpawnChance = "convenience",
    MarketSpawnChance = "market",
    GrocerySpawnChance = "grocery",
    StoreSpawnChance = "store",
}

local function clampChance(value, fallback)
    local chance = tonumber(value)
    if not chance then
        return fallback
    end

    if chance < 0 then
        return 0
    end
    if chance > 100 then
        return 100
    end

    return chance
end

local function getSandboxOptions()
    if not SandboxVars then
        return nil
    end

    return SandboxVars.AshboroCigaretteVending
end

local function applySandboxOptions()
    local options = getSandboxOptions()
    if not options then
        return
    end

    if options.EnableWorldSpawns ~= nil then
        WorldSpawn.Enabled = options.EnableWorldSpawns == true
    end

    WorldSpawn.SpawnBesideChance = clampChance(options.BaseSpawnChance, WorldSpawn.SpawnBesideChance)
    WorldSpawn.ReplaceChance = clampChance(options.ReplaceChance, WorldSpawn.ReplaceChance)

    for optionName, keyword in pairs(SandboxKeywordOptions) do
        if options[optionName] ~= nil then
            WorldSpawn.SpawnChanceByRoomKeyword[keyword] = clampChance(
                options[optionName],
                WorldSpawn.SpawnChanceByRoomKeyword[keyword]
            )
        end
    end
end

applySandboxOptions()

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

local function getRandomCount(min, max)
    if max <= min then
        return min
    end

    return min + ZombRand((max - min) + 1)
end

local function pickAshboroStockProfile()
    local roll = ZombRand(100)

    if roll < 20 then
        return "empty", 0, 0
    elseif roll < 70 then
        return "low", 1, 3
    elseif roll < 95 then
        return "normal", 4, 8
    end

    return "well stocked", 9, 14
end

local function addAshboroBonusItem(container, cigaretteCount)
    if cigaretteCount <= 0 then
        return
    end

    local roll = ZombRand(100)

    if roll < 12 then
        container:AddItem("Base.Matches")
    elseif roll < 18 then
        container:AddItem("Base.Lighter")
    end
end

local function fillAshboroContainer(container)
    if not container then
        return
    end

    if container:getItems() and container:getItems():size() > 0 then
        return
    end

    local stockProfile, minPacks, maxPacks = pickAshboroStockProfile()
    local cigaretteCount = getRandomCount(minPacks, maxPacks)

    for _ = 1, cigaretteCount do
        container:AddItem("Base.CigarettePack")
    end

    addAshboroBonusItem(container, cigaretteCount)
    debugLog("Filled Ashboro vending stock", stockProfile, "packs=", tostring(cigaretteCount))

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

local function findVanillaVendingObject(square)
    local objects = square and square:getObjects()
    if not objects then
        return nil, nil, nil
    end

    for i = objects:size() - 1, 0, -1 do
        local obj = objects:get(i)
        local spriteName = getSpriteName(obj)
        local newSprite = spriteName and WorldSpawn.Replacements[spriteName] or nil

        if newSprite then
            return obj, spriteName, newSprite
        end
    end

    return nil, nil, nil
end

local function safeSquareBool(square, methodName, ...)
    if not square or not square[methodName] then
        return false
    end

    local ok, result = pcall(square[methodName], square, ...)
    return ok and result or false
end


local function lowerText(value)
    if value == nil then
        return nil
    end
    return string.lower(tostring(value))
end

local function appendText(parts, value)
    local text = lowerText(value)
    if text and text ~= "" then
        table.insert(parts, text)
    end
end

local function callNoArg(obj, methodName)
    if not obj or not obj[methodName] then
        return nil
    end

    local ok, result = pcall(obj[methodName], obj)
    if ok then
        return result
    end

    return nil
end

local function getLocationText(square)
    local parts = {}

    local room = callNoArg(square, "getRoom")
    if room then
        appendText(parts, callNoArg(room, "getName"))
        appendText(parts, callNoArg(room, "getRoomName"))

        local roomDef = callNoArg(room, "getRoomDef") or callNoArg(room, "getDef")
        if roomDef then
            appendText(parts, callNoArg(roomDef, "getName"))
            appendText(parts, callNoArg(roomDef, "getRoomName"))
        end
    end

    local building = callNoArg(square, "getBuilding")
    if building then
        appendText(parts, callNoArg(building, "getName"))
        local buildingDef = callNoArg(building, "getDef")
        if buildingDef then
            appendText(parts, callNoArg(buildingDef, "getName"))
        end
    end

    local zone = callNoArg(square, "getZone")
    if zone then
        appendText(parts, callNoArg(zone, "getName"))
        appendText(parts, callNoArg(zone, "getType"))
    end

    return table.concat(parts, " ")
end

local function containsKeyword(text, keyword)
    return text and keyword and string.find(text, string.lower(tostring(keyword)), 1, true) ~= nil
end

local function isNoSpawnLocation(square)
    local locationText = getLocationText(square)

    for keyword, enabled in pairs(WorldSpawn.NoSpawnRoomKeywords) do
        if enabled and containsKeyword(locationText, keyword) then
            debugLog("Skipping no-spawn location", keyword, "at", square:getX(), square:getY(), square:getZ(), locationText)
            return true
        end
    end

    return false
end

local function getEffectiveSpawnBesideChance(square)
    local baseChance = WorldSpawn.SpawnBesideChance or 0
    local matchedChance = nil
    local locationText = getLocationText(square)

    for keyword, keywordChance in pairs(WorldSpawn.SpawnChanceByRoomKeyword) do
        if containsKeyword(locationText, keyword) and keywordChance then
            if not matchedChance or keywordChance > matchedChance then
                matchedChance = keywordChance
            end
        end
    end

    return matchedChance or baseChance
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

local AdjacentDirections = {
    { name = "east", x = 1, y = 0, axis = "x" },
    { name = "west", x = -1, y = 0, axis = "x" },
    { name = "south", x = 0, y = 1, axis = "y" },
    { name = "north", x = 0, y = -1, axis = "y" },
}

local function getOffsetSquare(square, offset)
    local cell = getCell()
    if not cell or not square or not offset then
        return nil
    end

    return cell:getGridSquare(square:getX() + offset.x, square:getY() + offset.y, square:getZ())
end

local function getSquareKey(square)
    return tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
end

local function getVendingCluster(startSquare)
    local cluster = {}
    local queue = {}
    local visited = {}

    if not startSquare or not squareHasVending(startSquare) then
        return cluster
    end

    table.insert(queue, startSquare)
    visited[getSquareKey(startSquare)] = true

    while #queue > 0 do
        local square = table.remove(queue, 1)
        table.insert(cluster, square)

        for _, dir in ipairs(AdjacentDirections) do
            local nextSquare = getOffsetSquare(square, dir)
            if nextSquare and squareHasVending(nextSquare) then
                local key = getSquareKey(nextSquare)
                if not visited[key] then
                    visited[key] = true
                    table.insert(queue, nextSquare)
                end
            end
        end
    end

    return cluster
end

local function vendingClusterWasProcessed(cluster)
    for _, clusterSquare in ipairs(cluster) do
        if clusterSquare:getModData()[WorldSpawn.ProcessedFlag] then
            return true
        end

        local obj = findVanillaVendingObject(clusterSquare)
        if obj and obj.getModData and obj:getModData()[WorldSpawn.ObjectProcessedFlag] then
            return true
        end
    end

    return false
end

local function markVendingClusterProcessed(cluster)
    for _, clusterSquare in ipairs(cluster) do
        clusterSquare:getModData()[WorldSpawn.ProcessedFlag] = true

        local obj = findVanillaVendingObject(clusterSquare)
        if obj and obj.getModData then
            obj:getModData()[WorldSpawn.ObjectProcessedFlag] = true
        end
    end
end

local function isBlockedByWallOrRoom(sourceSquare, testSquare)
    if not sourceSquare or not testSquare then
        return true
    end

    if testSquare:getZ() ~= sourceSquare:getZ() then
        return true
    end

    if sourceSquare.getRoom and testSquare.getRoom and sourceSquare:getRoom() ~= testSquare:getRoom() then
        return true
    end

    if safeSquareBool(testSquare, "isSolid") or safeSquareBool(testSquare, "isSolidTrans") then
        return true
    end

    return false
end

local function getPreferredAdjacentAxes(square)
    local hasVendingOnX = false
    local hasVendingOnY = false
    local blockedOnX = false
    local blockedOnY = false

    for _, dir in ipairs(AdjacentDirections) do
        local testSquare = getOffsetSquare(square, dir)

        if squareHasVending(testSquare) then
            if dir.axis == "x" then
                hasVendingOnX = true
            else
                hasVendingOnY = true
            end
        end

        if isBlockedByWallOrRoom(square, testSquare) then
            if dir.axis == "x" then
                blockedOnX = true
            else
                blockedOnY = true
            end
        end
    end

    -- If the vanilla vending machines already form a row, extend that row.
    -- This prevents a machine beside every vanilla machine from becoming a machine in front of every vanilla machine.
    if hasVendingOnX and not hasVendingOnY then
        return { x = true }
    end
    if hasVendingOnY and not hasVendingOnX then
        return { y = true }
    end

    -- If one axis is blocked by a wall/room boundary, the other axis is usually the left/right side of the machine.
    -- Example: vending machine against a north/south wall => do not use the open floor tile in front of it.
    if blockedOnY and not blockedOnX then
        return { x = true }
    end
    if blockedOnX and not blockedOnY then
        return { y = true }
    end

    -- Freestanding/ambiguous vending machine. Be conservative: skip it rather than blocking the front.
    return {}
end

local function getAdjacentSquares(square)
    if not square then
        return {}
    end

    local preferredAxes = getPreferredAdjacentAxes(square)
    local results = {}

    for _, dir in ipairs(AdjacentDirections) do
        if preferredAxes[dir.axis] then
            local testSquare = getOffsetSquare(square, dir)
            if isValidAdjacentSquare(square, testSquare) then
                table.insert(results, testSquare)
            end
        end
    end

    return results
end

local function pickClusterAdjacentSquare(cluster)
    local candidates = {}
    local seen = {}

    for _, clusterSquare in ipairs(cluster) do
        local adjacentSquares = getAdjacentSquares(clusterSquare)
        for _, adjacentSquare in ipairs(adjacentSquares) do
            local key = getSquareKey(adjacentSquare)
            if not seen[key] then
                seen[key] = true
                table.insert(candidates, adjacentSquare)
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[ZombRand(#candidates) + 1]
end

local function spawnBesideCluster(cluster, sourceSquare, oldSprite, newSprite)
    local targetSquare = pickClusterAdjacentSquare(cluster)
    if not targetSquare then
        debugLog(
            "No valid adjacent square for Ashboro machine near vending cluster",
            oldSprite,
            "at",
            sourceSquare:getX(),
            sourceSquare:getY(),
            sourceSquare:getZ()
        )
        return false
    end

    local newObj = placeAshboroObject(targetSquare, newSprite)
    if not newObj then
        return false
    end

    debugLog(
        "Spawned Ashboro vending machine beside vending cluster",
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
    applySandboxOptions()

    if not WorldSpawn.Enabled or not square then
        return
    end

    local objects = square:getObjects()
    if not objects then
        return
    end

    local obj, spriteName, newSprite = findVanillaVendingObject(square)
    if not newSprite then
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

    local cluster = getVendingCluster(square)
    if vendingClusterWasProcessed(cluster) then
        return
    end

    markVendingClusterProcessed(cluster)

    if isNoSpawnLocation(square) then
        return
    end

    local effectiveSpawnBesideChance = getEffectiveSpawnBesideChance(square)
    debugLog(
        "Effective spawn chance",
        tostring(effectiveSpawnBesideChance),
        "for",
        spriteName,
        "clusterSize=",
        tostring(#cluster),
        "at",
        square:getX(),
        square:getY(),
        square:getZ(),
        getLocationText(square)
    )

    if rollChance(effectiveSpawnBesideChance) then
        if spawnBesideCluster(cluster, square, spriteName, newSprite) then
            return
        end
    end

    if rollChance(WorldSpawn.ReplaceChance) then
        replaceObject(square, obj, spriteName, newSprite)
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

local function cigaretteVendingRequireMoveables()
    if not ISMoveableSpriteProps then
        pcall(require, "Moveables/ISMoveableSpriteProps")
    end
end

local function dumpSpriteProperties(spriteName)
    local sprite = getSprite(spriteName)

    print("[CigaretteVending] sprite test:", spriteName, sprite)

    if not sprite then
        return
    end

    cigaretteVendingRequireMoveables()

    local props = ISMoveableSpriteProps and ISMoveableSpriteProps.new(spriteName) or nil
    if props then
        print(
            "[CigaretteVending] moveable props",
            spriteName,
            "sprite",
            tostring(props.sprite ~= nil),
            "isMoveable",
            tostring(props.isMoveable),
            "name",
            tostring(props.name),
            "customName",
            tostring(props.customName),
            "groupName",
            tostring(props.groupName),
            "pickUpWeight",
            tostring(props.pickUpWeight)
        )
    else
        print("[CigaretteVending] moveable props unavailable", spriteName)
    end
end

Events.OnGameStart.Add(function()
    print("[CigaretteVending] mod is alive")

    local spriteNames = {
        "cigarette_vending_01a_9",
        "cigarette_vending_01a_18",
        "cigarette_vending_01a_19",
    }

    for _, spriteName in ipairs(spriteNames) do
        dumpSpriteProperties(spriteName)
    end

    for index = 0, 31 do
        local spriteName = "cigarette_vending_01a_" .. index
        local sprite = getSprite(spriteName)

        if sprite then
            cigaretteVendingRequireMoveables()
            local props = ISMoveableSpriteProps and ISMoveableSpriteProps.new(spriteName) or nil
            local isMoveable = props and props.isMoveable or false
            local name = props and props.name or nil

            print("[CigaretteVending] range", spriteName, "isMoveable", tostring(isMoveable), "name", tostring(name))
        else
            print("[CigaretteVending] range", spriteName, "nil")
        end
    end
end)

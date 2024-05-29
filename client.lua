ao = {
    id = "ao-id-example",
    send = function(message)
        if message.Action == "Broadcast" then
            local usernameColor = AODevChat.getColorForUsername(message.Username)
            print(usernameColor .. message.Username .. AODevChat.Colors.reset .. ": " .. message.Data)
            io.write("::discord::" .. message.Username .. ": " .. message.Data .. "\n")
        else
            print("Unknown action: " .. message.Action)
        end
    end
}

Handlers = Handlers or {}

Handlers.utils = {
    hasMatchingTag = function(tagKey, tagValue)
        return function(message)
            return message[tagKey] == tagValue
        end
    end
}

Handlers.add = function(action, condition, callback)
    if not Handlers[action] then
        Handlers[action] = {}
    end
    table.insert(Handlers[action], { condition = condition, callback = callback })
end

function Say(message, username)
    if not message then
        print("Error: No message provided.")
        return
    end
    if not username then
        print("Error: No username provided.")
        return
    end
    local formattedMessage = "Message from \"" .. username .. "\": " .. message
    print(formattedMessage)
    ao.send({
        Action = "Broadcast",
        Data = message,
        Username = username,
        Target = "7WTand2sxu1x_9bepuWfeJNmQLA0dx88CkRnwJpKkDU"
    })
end

AODevChat = {}

AODevChat.Colors = {
    cyan = "\27[36m",
    magenta = "\27[35m",
    yellow = "\27[33m",
    brightRed = "\27[91m",
    brightGreen = "\27[92m",
    brightBlue = "\27[94m",
    brightYellow = "\27[93m",
    brightMagenta = "\27[95m",
    brightCyan = "\27[96m",
    reset = "\27[0m",
    brightGray = "\27[97m"
}

AODevChat.getColorForUsername = function(username)
    local colors = {
        AODevChat.Colors.brightRed,
        AODevChat.Colors.brightGreen,
        AODevChat.Colors.brightBlue,
        AODevChat.Colors.brightYellow,
        AODevChat.Colors.brightMagenta,
        AODevChat.Colors.brightCyan
    }
    local sum = 0
    for i = 1, #username do
        sum = sum + username:byte(i)
    end
    return colors[(sum % #colors) + 1]
end

AODevChat.Router = "sKazG_eg_iiRMB1gS2aL8Q44Rx1x_64Mm95mXIvD1R0"
AODevChat.InitRoom = "9HcpHEhi3Di4ai8cO-D7srR7KLmV5U7_TLDBIAfLPXs"
AODevChat.LastSend = AODevChat.InitRoom

AODevChat.LastReceive = {
    Room = AODevChat.InitRoom,
    Sender = nil
}

AODevChat.InitRooms = { [AODevChat.InitRoom] = "DevChat-Main" }
AODevChat.Rooms = AODevChat.Rooms or AODevChat.InitRooms

AODevChat.Confirmations = AODevChat.Confirmations or true

AODevChat.findRoom = function(target)
    for address, name in pairs(AODevChat.Rooms) do
        if target == name then
            return address
        end
    end
end

List = function()
    ao.send({ Target = AODevChat.Router, Action = "Get-List" })
    return(AODevChat.Colors.brightGray .. "Getting the room list from the DevChat index..." .. AODevChat.Colors.reset)
end

Tip = function(...)
    local arg = {...}
    local room = arg[2] or AODevChat.LastReceive.Room
    local roomName = AODevChat.Rooms[room] or room
    local qty = tostring(arg[3] or 1)
    local recipient = arg[1] or AODevChat.LastReceive.Sender
    ao.send({
        Action = "Transfer",
        Target = room,
        Recipient = recipient,
        Quantity = qty
    })
    return(AODevChat.Colors.brightGray .. "Sent tip of " ..
        AODevChat.Colors.brightGreen .. qty .. AODevChat.Colors.brightGray ..
        " to " .. AODevChat.Colors.brightRed .. recipient .. AODevChat.Colors.b
        return(AODevChat.Colors.brightGray .. "Sent tip of " ..
        AODevChat.Colors.brightGreen .. qty .. AODevChat.Colors.brightGray ..
        " to " .. AODevChat.Colors.brightRed .. recipient .. AODevChat.Colors.brightGray ..
        " in room " .. AODevChat.Colors.brightBlue .. roomName .. AODevChat.Colors.brightGray ..
        "."
    )
end

Replay = function(...)
    local arg = {...}
    local room = nil
    if arg[2] then
        room = AODevChat.findRoom(arg[2]) or arg[2]
    else
        room = AODevChat.LastReceive.Room
    end
    local roomName = AODevChat.Rooms[room] or room
    local depth = arg[1] or 3

    ao.send({
        Target = room,
        Action = "Replay",
        Depth = tostring(depth)
    })
    return(
        AODevChat.Colors.brightGray ..
         "Requested replay of the last " ..
        AODevChat.Colors.brightGreen .. depth .. 
        AODevChat.Colors.brightGray .. " messages from " .. AODevChat.Colors.brightBlue ..
        roomName .. AODevChat.Colors.reset .. ".")
end

Leave = function(id)
    local addr = AODevChat.findRoom(id) or id
    ao.send({ Target = addr, Action = "Unregister" })
    return(
        AODevChat.Colors.brightGray ..
         "Leaving room " ..
        AODevChat.Colors.brightBlue .. id ..
        AODevChat.Colors.brightGray .. "..." .. AODevChat.Colors.reset)
end

Handlers.add(
    "AODevChat-Broadcasted",
    Handlers.utils.hasMatchingTag("Action", "Broadcasted"),
    function (m)
        local shortRoom = AODevChat.Rooms[m.From] or string.sub(m.From, 1, 6)
        if m.Broadcaster == ao.id then
            if AODevChat.Confirmations == true then
                io.write(
                    AODevChat.Colors.brightGray .. "[Received confirmation of your broadcast in "
                    .. AODevChat.Colors.brightBlue .. shortRoom .. AODevChat.Colors.brightGray .. ".]"
                    .. AODevChat.Colors.reset .. "\n")
            end
        else
            local nick = string.sub(m.Nickname, 1, 10)
            if m.Broadcaster ~= m.Nickname then
                nick = nick .. AODevChat.Colors.brightGray .. "#" .. string.sub(m.Broadcaster, 1, 3)
            end
            io.write(
                "[" .. AODevChat.Colors.brightRed .. nick .. AODevChat.Colors.reset
                .. "@" .. AODevChat.Colors.brightBlue .. shortRoom .. AODevChat.Colors.reset
                .. "]> " .. AODevChat.Colors.brightGreen .. m.Data .. AODevChat.Colors.reset .. "\n")

            AODevChat.LastReceive.Room = m.From
            AODevChat.LastReceive.Sender = m.Broadcaster
        end
    end
)

Handlers.add(
    "AODevChat-List",
    function(m)
        if m.Action == "Room-List" and m.From == AODevChat.Router then
            return true
        end
        return false
    end,
    function(m)
        local intro = "👋 The following rooms are currently available on AODevChat:\n\n"
        local rows = ""
        AODevChat.Rooms = AODevChat.InitRooms

        for i = 1, #m.TagArray do
            local filterPrefix = "Room-"
            local tagPrefix = string.sub(m.TagArray[i].name, 1, #filterPrefix)
            local name = string.sub(m.TagArray[i].name, #filterPrefix + 1, #m.TagArray[i].name)
            local address = m.TagArray[i].value

            if tagPrefix == filterPrefix then
                rows = rows .. AODevChat.Colors.brightBlue .. "        " .. name .. AODevChat.Colors.reset .. "\n"
                AODevChat.Rooms[address] = name
            end
        end

        io.write(
            intro .. rows .. "\nJoin a chat by running `Join(\"chatName\"[, \"yourNickname\"])`! You can leave chats with `Leave(\"name\")`.\n")
    end
)

if AODevChatRegistered == nil then
    AODevChatRegistered = true
end

return(
    AODevChat.Colors.brightBlue .. "\n\nWelcome to AO DevChat v0.1!\n\n" .. AODevChat.Colors.reset ..
    "AODevChat is a simple service that helps the AO community communicate as we build our new computer.\n" ..
    "The interface is simple. Run...\n\n" ..
    AODevChat.Colors.brightGreen .. "\t\t`List()`" .. AODevChat.Colors.reset .. " to see which rooms are available.\n" .. 
    AODevChat.Colors.brightGreen .. "\t\t`Join(\"RoomName\")`" .. AODevChat.Colors.reset .. " to join a room.\n" .. 
    AODevChat.Colors.brightGreen .. "\t\t`Say(\"Msg\"[, \"RoomName\"])`" .. AODevChat.Colors.reset .. " to post to a room (remembering your last choice for next time).\n" ..
    AODevChat.Colors.brightGreen .. "\t\t`Replay([\"Count\"])`" .. AODevChat.Colors.reset .. " to reprint the most recent messages from a chat.\n" ..
    AODevChat.Colors.brightGreen .. "\t\t`Leave(\"RoomName\")`" .. AODevChat.Colors.reset .. " at any time to unsubscribe from a chat.\n" ..
    AODevChat.Colors.brightGreen .. "\t\t`Tip([\"Recipient\"])`" .. AODevChat.Colors.reset .. " to send a token from the chatroom to the sender of the last message.\n\n" ..
    "Have fun, be respectful, and remember: Cypherpunks ship code! 🫡\n")

ao = ao or {
    send = function(data)
        print("Sending data: ")
        for k, v in pairs(data) do
            print(k .. ": " .. tostring(v))
        end
    end,
    id = "ao-id-example"
}

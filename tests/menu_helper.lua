-- Drive a deliberate menu selection through the native-menu substitute.
return function(open, label)
    local previous, callbacks = MenuUtil, {}
    MenuUtil = { CreateContextMenu = function(_, generate)
        generate(nil, { CreateRadio = function(_, text, selected, callback)
            callbacks[text] = callback
        end })
    end }
    local ok, reason = pcall(open)
    MenuUtil = previous
    assert(ok, reason)
    assert(callbacks[label], "missing menu choice: " .. label)
    callbacks[label]()
    return callbacks
end

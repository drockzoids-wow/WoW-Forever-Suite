local Suite = ...
-- Drive a deliberate menu selection through the Suite-menu substitute.
return function(open, label)
    local previous, callbacks = Suite.Menus, {}
    Suite.Menus = { CreateContextMenu = function(_, generate)
        generate(nil, { CreateRadio = function(_, text, selected, callback)
            callbacks[text] = callback
        end })
    end }
    local ok, reason = pcall(open)
    Suite.Menus = previous
    assert(ok, reason)
    assert(callbacks[label], "missing menu choice: " .. label)
    callbacks[label]()
    return callbacks
end

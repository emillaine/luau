table = {
    freeze = function(t)
        t.which = "early"
        return t
    end,
}

export value = 42

table = {
    freeze = function(t)
        t.which = "late"
        return t
    end,
}

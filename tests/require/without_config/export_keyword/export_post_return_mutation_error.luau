-- exported locals should become readonly once the module returns
export counter = 0

export function increment()
    counter += 1
end

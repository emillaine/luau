# export inside else if block should error
if false then
    print("skip")
else if true then
    export inside = "else if block"
end

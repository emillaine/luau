-- export inside if/else if/else blocks should error
if false then
    print("skip")
else if false then
    print("skip")
else
    export local inside = "else block"
end

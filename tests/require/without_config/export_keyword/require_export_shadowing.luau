-- verify exported bindings follow shadowing rules (bare `x = ...` reuses the
-- in-scope binding, so same-scope assigns update the export)
m = require("./export_shadowing")

assert(m.foo() == "exported", "exported function should shadow the non-exported local")
assert(m.fruit == nil, "export fruit should create a new nil-initialized binding")
assert(m.animal == "bird", "same-scope assigns reuse (and update) the exported binding")

return true

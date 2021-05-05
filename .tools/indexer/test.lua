local data = require('data')

for k,v in pairs(data.schematics) do
    print(v.name)
end

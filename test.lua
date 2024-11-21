local scanner = peripheral.wrap("back")
local res = scanner.scan(2)
for key, value in pairs(res) do
print(unpack(value.tags))
end

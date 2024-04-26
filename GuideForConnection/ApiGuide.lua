-- here we create api like module

local api = {}

function api.test()
  print("test")
end

return api

-- OR ====


-- local api2 = {
--   test = function()
--     print("test")
--   end
-- }

-- return api2
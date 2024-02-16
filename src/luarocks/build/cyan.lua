local cyan = {}

local fs = require("luarocks.fs")
local cfg = require("luarocks.core.cfg")
local dir = require("luarocks.dir")
local path = require("luarocks.path")

local function build(rockspec, build_dir)
   local gen_target = cfg.lua_version
   if gen_target == "5.2" then
      gen_target = "5.1"
   end

   if not fs.execute("cyan build -v quiet --build-dir " .. build_dir .. " --gen-target " .. gen_target) then
      return nil, "Failed building."
   end
   
   local luadir = path.lua_dir(rockspec.name, rockspec.version)
   
   for _, file in ipairs(fs.find(build_dir)) do
      local src = dir.path(build_dir, file)
      local dst = dir.path(luadir, file)
      
      fs.make_dir(dir.dir_name(dst))
      local ok, err = fs.copy(src, dst)
      if not ok then
         return nil, "Failed installing "..src.." in "..dst..": "..err
      end
   end
   
   return true
end

function cyan.run(rockspec)
   assert(rockspec:type() == "rockspec")

   if not fs.is_tool_available("cyan", "Cyan", "--help") then
      return nil, "'cyan' is not installed.\n" ..
                  "This rock uses the cyan build tool for the Teal language.\n " ..
                  "It should have been installed as a dependency for this LuaRocks plugin,\n " ..
                  "so make sure your PATH includes LuaRocks-installed executables:\n " ..
                  "see 'luarocks path --help' for details."
   end

   local build_dir = fs.make_temp_dir("cyan-build")
   
   local ok, err = build(rockspec, build_dir)
   
   fs.delete(build_dir)
   
   return ok, err
end

return cyan

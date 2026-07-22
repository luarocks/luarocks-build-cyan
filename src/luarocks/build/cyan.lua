local cyan = {}

local fs = require("luarocks.fs")
local cfg = require("luarocks.core.cfg")
local dir = require("luarocks.dir")
local path = require("luarocks.path")

local function get_gen_target_from_lua_version()
   local lua_version = cfg.lua_version
   if lua_version == "5.2" then
      return "--gen-target 5.1"
   else
      return "--gen-target " .. lua_version
   end
end

local function build(rockspec, build_dir)
   local pok, tlconfig = pcall(require, "tlconfig")
   if not pok then
      tlconfig = nil
   end

   local gen_target = ""

   -- attempts to respect a developer's tlconfig file
   if tlconfig then

      -- however, if gen_compat is not "off", and gen_target hasn't been set
      if tlconfig.gen_compat ~= "off" and tlconfig.gen_target == nil then
         gen_target = get_gen_target_from_lua_version()
      end
   
   -- no tlconfig is present, try and set gen-target accordingly
   else
      gen_target = get_gen_target_from_lua_version()
   end

   local build_command = "cyan build -v quiet --build-dir " .. build_dir  .. " " .. gen_target
   if not fs.execute(build_command) then
      return nil, "Failed building. Unable to run build command: " .. build_command
   end
   
   local luadir = path.lua_dir(rockspec.name, rockspec.version)

   -- install lua files
   for _, file in ipairs(fs.find(build_dir)) do
      local src = dir.path(build_dir, file)
      if fs.is_file(src) then
         local dst = dir.path(luadir, file)
         local dst_dir = dir.dir_name(dst)

         local ok, err = fs.make_dir(dst_dir)
         if not ok then return nil, "Failed creating directory to install files in: " .. dst_dir ..": " .. err end

         local ok, err = fs.copy(src, dst)
         if not ok then
            return nil, "Failed installing "..src.." in "..dst..": "..err
         end
      end
   end

   -- install tl files
   if tlconfig and tlconfig.source_dir then
      for _, file in ipairs(fs.find(tlconfig.source_dir)) do
         local src = dir.path(tlconfig.source_dir, file)

         -- ensure it's a file, not a hidden tl file, and not a .d.tl
         if fs.is_file(src) and src:find("^[^%.].-%.tl$") and not src:find("%.d%.tl$") then
            local dst = dir.path(luadir, file)

            local ok, err = fs.make_dir(dir.dir_name(dst))
            if not ok then return nil, "Failed creating directory to install files in: " .. dir.dir_name(dst) .. ": " .. err end

            local ok, err = fs.copy(src, dst)
            if not ok then
               return nil, "Failed installing " .. src .. " in " .. dst .. ": " .. err
            end 
         end
      end
   end

   return true
end

function cyan.run(rockspec)
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

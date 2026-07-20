local fs = require("filesystem")
local shell = require("shell")

local sandbox_root = "/home/sandbox"

print("Installing OpenVM Environment...")
print("----------------------------------------------------------------")

-- 1. Create the necessary directory tree inside the sandbox path
local dirs = {
    sandbox_root,
    sandbox_root .. "/lib/core",
    sandbox_root .. "/bin",
    sandbox_root .. "/etc"
}

for _, dir in ipairs(dirs) do
    if not fs.exists(dir) then
        print("Creating directory: " .. dir)
        fs.makeDirectory(dir)
    end
end

-- 2. Mirror critical operating system files from the host
print("Copying core system files...")
local files_to_copy = {
    ["/init.lua"] = sandbox_root .. "/init.lua",
    ["/lib/core/boot.lua"] = sandbox_root .. "/lib/core/boot.lua",
    ["/bin/sh.lua"] = sandbox_root .. "/bin/sh.lua",
    ["/etc/profile.lua"] = sandbox_root .. "/etc/profile.lua"
}

for src, dest in pairs(files_to_copy) do
    if fs.exists(src) then
        if fs.exists(dest) then fs.remove(dest) end 
        fs.copy(src, dest)
    else
        print("Warning: Host file missing: " .. src)
    end
end

-- 3. Automatically generate the upgraded openvm.lua script with hardware passthrough
print("Generating virtual machine runner (bin/openvm.lua)...")
local runner_code = [[local fs = require("filesystem")
local shell = require("shell")
local component = require("component")
local computer = require("computer")

local sandbox_path = "/home/sandbox"

print("Booting OpenVM with Network & Floppy Passthrough...")
print("----------------------------------------------------------------")

-- 1. Hardware Passthrough Logic
local intercepted_component = {}
for k, v in pairs(component) do intercepted_component[k] = v end

-- Filter component discovery so OpenVM only catches explicit hardware hooks
intercepted_component.list = function(filter_type, exact)
    local raw_list = component.list(filter_type, exact)
    local filtered = {}
    
    for addr, ctype in pairs(raw_list) do
        -- Expose only the sandbox's virtual hard drive, network modems, and floppy inputs
        if ctype == "modem" or ctype == "floppy" or addr == computer.getBootAddress() then
            filtered[addr] = ctype
        end
    end
    return filtered
end

-- 2. Build the abstraction layer sandbox environment
local sandbox_env = setmetatable({
    loadfile = function(file, mode, env)
        local clean_file = file:gsub("^/", "")
        local full_path = sandbox_path .. "/" .. clean_file
        return loadfile(full_path, mode, env or _G)
    end,
    dofile = function(file)
        local clean_file = file:gsub("^/", "")
        local full_path = sandbox_path .. "/" .. clean_file
        return dofile(full_path)
    end,
    component = intercepted_component -- Inject the custom hardware ruleset
}, { __index = _G })

-- 3. Pass sandbox_env directly to the boot loader sequence
local boot_func = loadfile(sandbox_path .. "/lib/core/boot.lua", "t", sandbox_env)
if boot_func then
    pcall(boot_func, sandbox_env.loadfile)
end

-- 4. Launch the interactive virtual machine terminal environment
local sh_func = loadfile(sandbox_path .. "/bin/sh.lua", "t", sandbox_env)
if sh_func then
    pcall(sh_func)
else
    print("Could not find sandboxed shell binary.")
end

print("----------------------------------------------------------------")
print("OpenVM environment terminated. Back in Host OS.")
]]

-- Save it straight into bin/ so users can call it globally as a command
local runner_file = io.open("/bin/openvm.lua", "w")
if runner_file then
    runner_file:write(runner_code)
    runner_file:close()
    print("Successfully generated /bin/openvm.lua!")
else
    print("Error: Could not write runner script to /bin/openvm.lua")
end

print("----------------------------------------------------------------")
print("OpenVM Setup complete! Type 'openvm' from anywhere to launch.")

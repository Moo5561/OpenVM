local fs = require("filesystem")

local sandbox_root = "/home/sandbox"
local binary_path = "/bin/openvm.lua"

print("Uninstalling OpenVM Environment...")
print("----------------------------------------------------------------")

-- 1. Remove the global binary command if it exists
if fs.exists(binary_path) then
    print("Removing executable binary: " .. binary_path)
    fs.remove(binary_path)
else
    print("Binary not found at " .. binary_path .. " (Skipping)")
end

-- 2. Clean up the sandbox filesystem tree recursively
if fs.exists(sandbox_root) then
    print("Removing sandbox directory tree: " .. sandbox_root)
    
    -- OpenOS requires recursively removing contents before deleting folders
    local function clear_directory(path)
        for file in fs.list(path) do
            local full_item = path .. "/" .. file:gsub("/$", "")
            if fs.isDirectory(full_item) then
                clear_directory(full_item)
            else
                fs.remove(full_item)
            end
        end
        fs.remove(path)
    end
    
    local success, err = pcall(clear_directory, sandbox_root)
    if success then
        print("Successfully wiped sandbox directories.")
    else
        print("Error clearing directories: " .. tostring(err))
    end
else
    print("Sandbox root not found at " .. sandbox_root .. " (Skipping)")
end

print("----------------------------------------------------------------")
print("OpenVM has been completely uninstalled from your host system!")
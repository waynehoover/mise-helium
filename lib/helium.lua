-- Shared helpers for the Helium package hooks.
--
-- Helium is Chromium based and keeps Chromium's "External Extensions"
-- provider: a <id>.json file in that directory asks the browser to install the
-- extension from the given update URL on its next start, in every profile.
-- Deleting the file makes the browser uninstall it again. That file is the
-- only state this plugin owns, so it is also what "installed" means here.

local json = require("json")

local M = {}

-- Chrome Web Store update endpoint. Helium records this same URL for the
-- extensions it installs from the store, so it is what the browser expects.
M.UPDATE_URL = "https://clients2.google.com/service/update2/crx"

-- MISE_HELIUM_DATA_DIR points the plugin at a disposable directory for tests.
function M.data_dir()
  local override = os.getenv("MISE_HELIUM_DATA_DIR")
  if override and override ~= "" then
    return override
  end
  local home = os.getenv("HOME")
  if not home or home == "" then
    error("helium: HOME is not set")
  end
  return home .. "/Library/Application Support/net.imput.helium"
end

function M.external_dir()
  return M.data_dir() .. "/External Extensions"
end

-- Chromium extension IDs are exactly 32 characters from a to p. Checking this
-- before building a path also keeps a declared name from reaching any other
-- file.
function M.validate_id(id)
  if type(id) ~= "string" or not id:match("^[a-p]+$") or #id ~= 32 then
    error("helium: '" .. tostring(id) .. "' is not an extension ID (32 letters a-p)")
  end
  return id
end

function M.external_file(id)
  return M.external_dir() .. "/" .. M.validate_id(id) .. ".json"
end

function M.exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function read(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local body = f:read("*a")
  f:close()
  return body
end

-- The directory is created with mkdir because the Lua runtime has no mkdir.
-- The path is single-quoted for the shell, so refuse one that contains a
-- single quote rather than try to escape it.
function M.ensure_external_dir()
  local dir = M.external_dir()
  if dir:find("'", 1, true) then
    error("helium: refusing a data directory containing a single quote: " .. dir)
  end
  local ok = os.execute("mkdir -p '" .. dir .. "'")
  if ok ~= 0 and ok ~= true then
    error("helium: could not create " .. dir)
  end
end

function M.write_external_file(id)
  local path = M.external_file(id)
  local f, err = io.open(path, "w")
  if not f then
    error("helium: could not write " .. path .. ": " .. tostring(err))
  end
  f:write(json.encode({ external_update_url = M.UPDATE_URL }))
  f:write("\n")
  f:close()
end

function M.remove_external_file(id)
  local path = M.external_file(id)
  if M.exists(path) then
    local ok, err = os.remove(path)
    if not ok then
      error("helium: could not remove " .. path .. ": " .. tostring(err))
    end
  end
end

-- Profile directories named in Local State, falling back to Default.
local function profile_dirs()
  local dirs = {}
  local body = read(M.data_dir() .. "/Local State")
  if body then
    local ok, state = pcall(json.decode, body)
    if ok and type(state) == "table" and type(state.profile) == "table"
      and type(state.profile.info_cache) == "table" then
      for dir, _ in pairs(state.profile.info_cache) do
        table.insert(dirs, dir)
      end
    end
  end
  if #dirs == 0 then
    dirs = { "Default" }
  end
  table.sort(dirs)
  return dirs
end

-- Installed versions by extension ID, read from every profile's Secure
-- Preferences. Informational only: a missing or unreadable profile is
-- skipped, never an error, so status stays side-effect free and cannot fail
-- on browser state it does not own.
function M.profile_versions()
  local versions = {}
  for _, dir in ipairs(profile_dirs()) do
    local body = read(M.data_dir() .. "/" .. dir .. "/Secure Preferences")
    if body then
      local ok, prefs = pcall(json.decode, body)
      if ok and type(prefs) == "table" and type(prefs.extensions) == "table"
        and type(prefs.extensions.settings) == "table" then
        for id, entry in pairs(prefs.extensions.settings) do
          if type(entry) == "table" and type(entry.manifest) == "table"
            and type(entry.manifest.version) == "string" and versions[id] == nil then
            versions[id] = entry.manifest.version
          end
        end
      end
    end
  end
  return versions
end

return M

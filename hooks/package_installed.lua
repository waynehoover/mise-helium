local helium = require("helium")

-- Side-effect free: only reads files. A package counts as installed once its
-- External Extensions file exists, since that request is the state this
-- plugin owns; the browser installs it on its next start. The version comes
-- from whichever profile already has the extension, when one does.
function PLUGIN:PackageInstalled(ctx)
  local versions = helium.profile_versions()
  local results = {}
  for _, package in ipairs(ctx.packages) do
    local id = helium.validate_id(package.name)
    local installed = helium.exists(helium.external_file(id))
    table.insert(results, {
      name = package.name,
      state = installed and "installed" or "missing",
      version = installed and versions[id] or nil,
    })
  end
  return { packages = results }
end

local helium = require("helium")

-- Only called by `mise bootstrap packages prune --manager helium`, and only
-- with IDs mise approved for removal. Deleting the request file makes Helium
-- uninstall the extension on its next start.
function PLUGIN:PackageUninstall(ctx)
  for _, package in ipairs(ctx.packages) do
    helium.validate_id(package.name)
  end
  for _, package in ipairs(ctx.packages) do
    helium.remove_external_file(package.name)
  end
  return {}
end

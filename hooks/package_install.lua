local helium = require("helium")

function PLUGIN:PackageInstall(ctx)
  -- Validate the whole batch before writing anything.
  for _, package in ipairs(ctx.packages) do
    helium.validate_id(package.name)
  end
  if ctx.dry_run then
    for _, package in ipairs(ctx.packages) do
      print("would request " .. package.name .. " in " .. helium.external_dir())
    end
    return {}
  end
  if #ctx.packages > 0 then
    helium.ensure_external_dir()
  end
  for _, package in ipairs(ctx.packages) do
    helium.write_external_file(package.name)
  end
  return {}
end

-- Helium updates Web Store extensions itself, and the store only serves the
-- current version, so there is nothing to do for an installed package.
-- Defining this hook stops mise from falling back to PackageInstall, which
-- would rewrite every request file on each upgrade run.
function PLUGIN:PackageUpgrade(ctx)
  return {}
end

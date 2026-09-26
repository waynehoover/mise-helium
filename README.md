# mise-helium

A [mise](https://mise.jdx.dev) package plugin that manages [Helium](https://helium.computer) browser extensions from the Chrome Web Store through `[bootstrap.packages]`.

```toml
[bootstrap.plugins]
helium = "https://github.com/waynehoover/mise-helium"

[bootstrap.packages]
"helium:dbepggeogbaibhgnhhndojpepiihcmeb" = "latest" # Vimium
"helium:nngceckbapebfimnlniiiahkandclblb" = "latest" # Bitwarden
```

Package names are Chrome Web Store extension IDs: the 32-letter ID in the extension's store URL.

## How it works

Helium keeps Chromium's "External Extensions" provider. For each declared extension the plugin writes `<id>.json` into `~/Library/Application Support/net.imput.helium/External Extensions/`, pointing at the Web Store update URL. On its next start Helium installs the extension, and it may ask you to enable it.

| Command | Effect |
|---|---|
| `mise bootstrap packages status` | `installed` once the request file exists, with the version from any profile that has the extension |
| `mise bootstrap packages apply` | writes the request file for each missing extension |
| `mise bootstrap packages upgrade` | nothing: Helium updates Web Store extensions itself |
| `mise bootstrap packages prune --manager helium` | deletes the request file for extensions this plugin installed; Helium uninstalls them on its next start |

## Limitations

- **Every profile.** Chromium applies External Extensions to all profiles, and there is no supported way to target one. Install profile-specific extensions by hand.
- **Restart required.** Helium reads the directory at startup.
- **No version pins.** The Web Store only serves the current version.
- **macOS only.**

## Security

The plugin only writes extension IDs and the Web Store update URL, which any process running as you can already do. Names that are not valid extension IDs (32 letters, a to p) are rejected before any path is built. Keep Helium's enable prompt as the human check on what your config adds.

## Testing

Set `MISE_HELIUM_DATA_DIR` to a scratch directory to run the hooks without touching your real Helium data.

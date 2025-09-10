# Copilot Instructions for Shop_GrenadeTrails

## Repository Overview
This is a SourcePawn plugin for SourceMod that adds customizable trail effects to grenades in Source engine games. The plugin integrates with the Shop-Core system to allow players to purchase different colored grenade trails. It demonstrates modern SourcePawn development practices and shop system integration.

## Technical Environment

### Core Technologies
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ (minimum supported version)
- **Build System**: SourceKnight (modern SourcePawn build tool)
- **Dependencies**: 
  - SourceMod base
  - Shop-Core plugin (for shop integration)
  - MultiColors include (for color utilities)

### Build Process
- **Build Tool**: SourceKnight (configured in `sourceknight.yaml`)
- **Build Command**: Uses GitHub Actions with `maxime1907/action-sourceknight@v1`
- **Output**: Compiled `.smx` files in `/addons/sourcemod/plugins/`
- **Dependencies**: Auto-downloaded during build process

## Project Structure

```
├── addons/sourcemod/
│   ├── scripting/
│   │   └── Shop_GrenadeTrails.sp     # Main plugin source code
│   └── configs/
│       └── grenade_trails.txt        # KeyValues config for trail definitions
├── .github/
│   └── workflows/ci.yml              # Build and release automation
├── sourceknight.yaml                 # Build configuration and dependencies
└── .gitignore                        # Excludes .smx files and build artifacts
```

## Code Style & Standards

### SourcePawn Specific
- Use `#pragma semicolon 1` and `#pragma newdecls required` (already implemented)
- Prefix global variables with `g_` (e.g., `g_iSpriteIndex`, `g_hKv`)
- Use PascalCase for functions (e.g., `OnPluginStart`, `Timer_Trail`)
- Use camelCase for local variables (e.g., `iClient`, `sBuffer`)
- Indentation: 4 spaces (use tabs configured as 4 spaces)

### Memory Management
- **Modern approach**: Use `delete` instead of `CloseHandle()` where possible
- **Critical**: Always check for `INVALID_HANDLE` before operations
- **Pattern**: Set handles to `null` after deletion
- **Example**: 
  ```sourcepawn
  if (g_hKv != null) {
      delete g_hKv;
      g_hKv = null;
  }
  ```

### Plugin Integration Patterns
- **Shop Integration**: Use Shop-Core callbacks (`OnEquipItem`, `Shop_Started`)
- **Entity Handling**: Use `EntIndexToEntRef()` and `EntRefToEntIndex()` for safe entity references
- **Event Timing**: Use timers for delayed operations (e.g., `CreateTimer(0.0, Timer_Trail)`)

## Key Components

### 1. Shop System Integration
- **Category Registration**: `Shop_RegisterCategory("grenade_trails", ...)`
- **Item Registration**: Uses KeyValues config to define purchasable trail effects
- **State Management**: Tracks equipped items per client in `g_iClientSpriteIndex[]`
- **Toggle Behavior**: Items can be turned on/off (Item_Togglable)

### 2. Configuration System
- **File**: `addons/sourcemod/configs/grenade_trails.txt`
- **Format**: KeyValues with nested sections for each trail type
- **Properties**: name, color (RGBA), price, sellprice, duration, material
- **Loading**: Uses `FileToKeyValues()` and `Shop_GetCfgFile()`

### 3. Visual Effects System
- **Sprite Loading**: Precaches materials using `PrecacheModel()`
- **Trail Creation**: Uses `TE_SetupBeamFollow()` for visual trails
- **Entity Detection**: Hooks `OnEntityCreated()` for projectile entities
- **Performance**: Uses entity references to prevent invalid entity access

## Development Guidelines

### Making Changes
1. **Plugin Logic**: Modify `Shop_GrenadeTrails.sp` for functionality changes
2. **Trail Options**: Edit `grenade_trails.txt` to add/modify available trails
3. **Dependencies**: Update `sourceknight.yaml` if new includes are needed
4. **Testing**: No automated tests - requires manual testing on game server

### Build and Test Process
```bash
# Build is handled by GitHub Actions
# Local development requires SourceKnight setup
# Test by deploying to development server
```

### Common Patterns

#### Adding New Trail Effects
1. Add entry to `grenade_trails.txt` with unique key
2. Define color, price, and material properties
3. Plugin automatically registers new items via Shop system

#### Performance Considerations
- **Entity Loops**: Minimize iterations in frequently called functions
- **Timer Usage**: Use single-shot timers for delayed operations
- **Memory Cleanup**: Always clean up handles and references
- **Client Arrays**: Use `MAXPLAYERS+1` sizing for client-specific data

### Error Handling
- **Config Loading**: Use `SetFailState()` for critical config failures
- **Entity Validation**: Check entity validity before operations
- **Shop Integration**: Return appropriate `ShopAction` values
- **Client Validation**: Validate client indices (1 to MaxClients)

## Integration Points

### Shop-Core Dependencies
- **Required Callbacks**: `Shop_Started()`, `OnEquipItem()`
- **Registration Flow**: Category → Items → Callbacks
- **State Management**: Use `Shop_ToggleClientCategoryOff()` for exclusivity

### SourceMod Hooks
- **OnEntityCreated**: Detects grenade entities for trail attachment
- **OnClientConnect/Disconnect**: Manages client-specific state
- **OnMapStart**: Reloads configuration and precaches resources

## Security & Best Practices

### Input Validation
- **Config Files**: Validate all KeyValues entries with defaults
- **Client Data**: Always validate client indices and connectivity
- **Entity References**: Use EntRef system to prevent crashes

### Performance
- **Avoid O(n) in Hot Paths**: Entity creation hooks should be efficient
- **Cache Resources**: Precache sprites once per map
- **Memory Management**: Clean up on plugin end and client disconnect

## Troubleshooting

### Common Issues
1. **Trail not appearing**: Check sprite precaching and client state
2. **Shop integration broken**: Verify Shop-Core dependency and callbacks
3. **Config errors**: Validate KeyValues syntax in grenade_trails.txt
4. **Build failures**: Check SourceKnight configuration and dependencies

### Debug Approaches
- **Console Output**: Use `PrintToServer()` for server-side debugging
- **Client Messages**: Use `PrintToChat()` for client-side feedback
- **Entity Validation**: Check entity validity before operations
- **Shop State**: Verify item registration and client purchase state

This plugin demonstrates modern SourcePawn development with shop integration, proper memory management, and visual effects programming for Source engine games.
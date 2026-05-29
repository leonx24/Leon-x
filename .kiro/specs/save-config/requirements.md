# Requirements Document

## Introduction

The Save Config system for Leon X allows users to persist, restore, and manage named configuration snapshots of all stateful UI components (Toggle, Slider, Dropdown, Keybind). Configs are stored as JSON files in the executor's local workspace under `Leon X/configs/{name}.json`. A `ConfigManager` module handles all file I/O and component state restoration. The UI Library registers components by a `Flag` key automatically, and a dedicated Settings tab section exposes Save, Load, Delete, and config-selection controls to the user. A `"default"` config is loaded automatically on hub startup.

---

## Glossary

- **ConfigManager**: The module at `modules/core/configmanager.lua` responsible for serializing, persisting, and restoring component state.
- **Flag**: A unique string key assigned to a stateful UI component in its data table (e.g. `Flag = "Fly"`). Used as the identifier in saved config files.
- **Registry**: The in-memory table maintained by `ui/library.lua` that maps Flag strings to component API tables.
- **Config File**: A JSON-encoded file stored at `Leon X/configs/{name}.json` in the executor workspace.
- **Default Config**: The config file named `"default"`. Loaded automatically when the hub initializes.
- **Stateful Component**: A UI component that holds persistent user-configurable state — specifically Toggle (boolean), Slider (number), Dropdown (string), and Keybind (KeyCode).
- **Silent Set**: Calling a component's `Set(v)` method without firing its `Callback`, used during config load to avoid side-effects.
- **Library**: The `ui/library.lua` module that constructs the UI and exposes `Library:CreateTab()`.
- **Executor Workspace**: The sandboxed file system accessible via the `writefile(path, content)` and `readfile(path)` globals provided by the Roblox exploit executor.
- **HttpGet**: `game:HttpGet(url)` — the only mechanism for loading remote Lua files; not used for config I/O.

---

## Requirements

### Requirement 1: Flag-Based Component Registration

**User Story:** As a developer, I want to assign a `Flag` key to any stateful component so that ConfigManager can identify and address it by name.

#### Acceptance Criteria

1. WHEN `Tab:AddToggle(data)` is called and `data.Flag` is a non-empty string, THE Library SHALL insert the returned component API into the Registry under the key `data.Flag`.
2. WHEN `Tab:AddSlider(data)` is called and `data.Flag` is a non-empty string, THE Library SHALL insert the returned component API into the Registry under the key `data.Flag`.
3. WHEN `Tab:AddDropdown(data)` is called and `data.Flag` is a non-empty string, THE Library SHALL insert the returned component API into the Registry under the key `data.Flag`.
4. WHEN `Tab:AddKeybind(data)` is called and `data.Flag` is a non-empty string, THE Library SHALL insert the returned component API into the Registry under the key `data.Flag`.
5. WHEN a component is created without a `Flag` field or with `Flag = nil`, THE Library SHALL not insert that component into the Registry and SHALL not alter the component's behavior.
6. THE Library SHALL expose the Registry as `Library.Registry` so that ConfigManager can read it without modifying `library.lua`'s component constructors.
7. IF two components are registered with the same Flag string, THEN THE Library SHALL overwrite the earlier Registry entry with the later one and SHALL not error.

---

### Requirement 2: Config Serialization

**User Story:** As a developer, I want ConfigManager to serialize the current state of all registered components into a JSON string so that it can be written to disk.

#### Acceptance Criteria

1. WHEN `ConfigManager:Save(name)` is called, THE ConfigManager SHALL iterate over every entry in `Library.Registry` and call `Get()` on each component API to collect its current value.
2. WHEN serializing a Toggle value, THE ConfigManager SHALL encode the boolean as a JSON boolean (`true` or `false`).
3. WHEN serializing a Slider value, THE ConfigManager SHALL encode the number as a JSON number.
4. WHEN serializing a Dropdown value, THE ConfigManager SHALL encode the selected string as a JSON string.
5. WHEN serializing a Keybind value, THE ConfigManager SHALL encode the `KeyCode.Name` string (e.g. `"F"`) as a JSON string.
6. THE ConfigManager SHALL produce a JSON object where each key is a Flag string and each value is the serialized component state.
7. THE ConfigManager SHALL use the `HttpService:JSONEncode` Roblox API for JSON serialization.

---

### Requirement 3: Config Persistence

**User Story:** As a user, I want my configs saved to disk so that they survive between executor sessions.

#### Acceptance Criteria

1. WHEN `ConfigManager:Save(name)` is called, THE ConfigManager SHALL write the serialized JSON string to the path `Leon X/configs/{name}.json` using `writefile`.
2. WHEN the directory `Leon X/configs/` does not exist at save time, THE ConfigManager SHALL create it by calling `makefolder("Leon X/configs")` before writing.
3. WHEN `name` contains characters that are invalid in a file path (any of `\ / : * ? " < > |`), THEN THE ConfigManager SHALL replace each invalid character with an underscore before constructing the file path.
4. THE ConfigManager SHALL store config files exclusively under the `Leon X/configs/` subdirectory and SHALL not write to any other path.
5. IF a constructed file path resolves to a location outside `Leon X/configs/` (e.g. due to path traversal characters in `name`), THEN THE ConfigManager SHALL abort the save operation and return `false` without writing any file.

---

### Requirement 4: Config Loading

**User Story:** As a user, I want to load a saved config so that all my component states are restored to the saved values.

#### Acceptance Criteria

1. WHEN `ConfigManager:Load(name)` is called and the file `Leon X/configs/{name}.json` exists, THE ConfigManager SHALL read the file using `readfile`, decode the JSON, and apply each value to the matching registered component.
2. WHEN applying a loaded value to a component, THE ConfigManager SHALL call `component:Set(value)` using the Silent Set path so that the direct Callback of the component being set is not fired; indirect callbacks on other components that observe state changes through their own mechanisms are permitted to fire.
3. WHEN a loaded Keybind value is a string (e.g. `"F"`), THE ConfigManager SHALL convert it to the corresponding `Enum.KeyCode` member before calling `Set`.
4. WHEN a Flag key present in the JSON file has no matching entry in `Library.Registry`, THE ConfigManager SHALL skip that key and continue loading remaining keys without error.
5. WHEN a Flag key present in `Library.Registry` has no matching entry in the loaded JSON, THE ConfigManager SHALL leave that component's current value unchanged.
6. IF `ConfigManager:Load(name)` is called and the file does not exist, THEN THE ConfigManager SHALL return `false` and SHALL not modify any component state.
7. IF the file content is not valid JSON, THEN THE ConfigManager SHALL wrap the decode in `pcall`, return `false`, and SHALL not modify any component state.

---

### Requirement 5: Keybind Silent Set

**User Story:** As a developer, I want the Keybind component to support silent programmatic setting so that config loads can restore keybind values without triggering rebind callbacks.

#### Acceptance Criteria

1. THE Keybind component's `Set(keyCode)` method SHALL update the internal `cur` value and the button label text to `keyCode.Name` without firing the `Callback`, regardless of when `Set` is called or what state the component is in.
2. WHEN `Set` is called on a Keybind component while the component is in waiting-for-input state (`waiting = true`), THE Keybind SHALL exit the waiting state and apply the provided value.

---

### Requirement 6: Default Config Auto-Load

**User Story:** As a user, I want my default config loaded automatically when the hub starts so that my preferred settings are active immediately.

#### Acceptance Criteria

1. WHEN the hub finishes constructing all UI components and registering all Flags, THE ConfigManager SHALL call `ConfigManager:Load("default")`.
2. WHEN the default config file does not exist, THE ConfigManager SHALL proceed without error and SHALL leave all components at their declared `Default` values.
3. THE auto-load of the default config SHALL occur after all `Tab:Add*` calls in `main.lua` have completed so that the Registry is fully populated before any values are applied.

---

### Requirement 7: Config Listing

**User Story:** As a user, I want to see all saved configs so that I can choose which one to load or delete.

#### Acceptance Criteria

1. WHEN `ConfigManager:List()` is called, THE ConfigManager SHALL return a Lua array of strings, each being the name of a saved config (filename without the `.json` extension).
2. WHEN the `Leon X/configs/` directory does not exist, THE ConfigManager SHALL return an empty array without error or logging.
3. THE ConfigManager SHALL use `listfiles("Leon X/configs")` to enumerate files and SHALL filter the result to include only entries whose filename ends with `.json`.
4. THE ConfigManager SHALL strip the `.json` suffix from each filename before including it in the returned array.

---

### Requirement 8: Config Deletion

**User Story:** As a user, I want to delete a saved config so that I can remove configs I no longer need.

#### Acceptance Criteria

1. WHEN `ConfigManager:Delete(name)` is called and the file `Leon X/configs/{name}.json` exists, THE ConfigManager SHALL delete the file using `delfile` and SHALL return `true`.
2. IF `ConfigManager:Delete(name)` is called and the file does not exist, THEN THE ConfigManager SHALL return `false` without error.

---

### Requirement 9: Default Config Assignment

**User Story:** As a user, I want to designate any saved config as the default so that it loads automatically on the next hub start.

#### Acceptance Criteria

1. WHEN `ConfigManager:SetDefault(name)` is called and the file `Leon X/configs/{name}.json` exists, THE ConfigManager SHALL write the string `name` to `Leon X/configs/.default` using `writefile` and SHALL return `true`.
2. WHEN the hub performs its auto-load on startup, THE ConfigManager SHALL first check whether `Leon X/configs/.default` exists; IF it does, THE ConfigManager SHALL read the file and use its content as the config name to load instead of the literal string `"default"`.
3. IF `ConfigManager:SetDefault(name)` is called and the named config file does not exist, THEN THE ConfigManager SHALL return `false` and SHALL not write to `Leon X/configs/.default`.

---

### Requirement 10: Settings Tab UI

**User Story:** As a user, I want a dedicated UI section in the Settings tab so that I can save, load, and delete configs without leaving the hub.

#### Acceptance Criteria

1. THE Settings tab SHALL contain a section labeled `"Config"` that groups all config management controls.
2. THE Settings tab SHALL contain a Dropdown component with Flag `"ConfigSelect"` that lists all currently saved config names, populated by calling `ConfigManager:List()` at UI construction time.
3. THE Settings tab SHALL contain a Button labeled `"Save Config"` that, when clicked, reads the current value of the config name input and calls `ConfigManager:Save(name)`, then refreshes the ConfigSelect Dropdown options.
4. THE Settings tab SHALL contain a Button labeled `"Load Config"` that, when clicked, reads the selected value from the ConfigSelect Dropdown and calls `ConfigManager:Load(name)`.
5. THE Settings tab SHALL contain a Button labeled `"Delete Config"` that, when clicked, reads the selected value from the ConfigSelect Dropdown, calls `ConfigManager:Delete(name)`, and refreshes the ConfigSelect Dropdown options.
6. THE Settings tab SHALL contain a Button labeled `"Set as Default"` that, when clicked, reads the selected value from the ConfigSelect Dropdown and calls `ConfigManager:SetDefault(name)`.
7. WHEN `ConfigManager:Save` or `ConfigManager:Delete` completes, THE Settings tab SHALL update the ConfigSelect Dropdown's option list by calling `ConfigManager:List()` again so the displayed list stays current.
8. THE Settings tab SHALL contain a TextBox-style input (implemented as a Keybind-free component or a dedicated text input) for the user to type a new config name before saving; IF the Library does not expose a TextBox component, THE Settings tab SHALL use a Button whose label reflects the current typed name via a separate input mechanism consistent with the existing UI API.

---

### Requirement 11: ConfigManager Module Structure

**User Story:** As a developer, I want ConfigManager to follow the Leon X module conventions so that it integrates cleanly with the existing codebase.

#### Acceptance Criteria

1. THE ConfigManager module SHALL be located at `modules/core/configmanager.lua`.
2. THE ConfigManager module SHALL begin with the comment header `-- Leon X | ConfigManager` followed by a one-line description.
3. THE ConfigManager module SHALL be loaded in `main.lua` via `loadstring(game:HttpGet(RAW_URL))()` and SHALL not use `require()`.
4. THE ConfigManager module SHALL accept the `Library` table as a constructor argument (e.g. `ConfigManager:Init(Library)`) so it can access `Library.Registry` without a global dependency.
5. THE ConfigManager module SHALL use `game:GetService("HttpService")` for JSON encoding and decoding and SHALL not use any other JSON library.
6. THE ConfigManager module SHALL expose exactly the following public methods: `Init(library)`, `Save(name)`, `Load(name)`, `List()`, `Delete(name)`, `SetDefault(name)`.

---

### Requirement 12: Backward Compatibility

**User Story:** As a developer, I want the save-config feature to be additive so that all existing features continue to work without modification.

#### Acceptance Criteria

1. THE Library SHALL preserve all existing `Tab:Add*` method signatures; the `Flag` field SHALL be optional and its absence SHALL not change any existing behavior.
2. WHEN `Flag` is absent from a component data table, THE component Callback, Default, Set, and Get behavior SHALL be identical to the pre-save-config implementation.
3. THE ConfigManager module SHALL not modify any Roblox Instance properties, game services, or character state during `Save`, `Load`, `List`, `Delete`, or `SetDefault` operations.
4. THE existing features (Fly, WalkSpeed, JumpPower, InfiniteJump, FullBright, ESP, AntiAFK, Rejoin, CopyID) SHALL continue to function correctly when ConfigManager is loaded and a config is applied.

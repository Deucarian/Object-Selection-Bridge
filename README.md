# JorisHoef ObjectSelection CoreState Bridge

## Overview

JorisHoef ObjectSelection CoreState Bridge is a standalone Unity package that synchronizes keyed selection between:

- `JorisHoef Object Selection`
- `JorisHoef Core State`

ObjectSelection owns world-object selection. CoreState owns data/application selection. This bridge only synchronizes shared keys.

Package ID: `com.jorishoef.objectselection-corestate-bridge`

## Installation

Install the dependencies and this bridge through Unity Package Manager:

```json
{
  "dependencies": {
    "com.jorishoef.object-selection": "https://github.com/JorisHoef/Object-Selection.git#main",
    "com.jorishoef.core.state": "https://github.com/JorisHoef/Core-State.git#main",
    "com.jorishoef.objectselection-corestate-bridge": "https://github.com/JorisHoef/Object-Selection-Bridge.git#main"
  }
}
```

For local development:

```json
{
  "dependencies": {
    "com.jorishoef.object-selection": "file:C:/Repositories/ObjectSelection",
    "com.jorishoef.core.state": "file:C:/Repositories/Core-State",
    "com.jorishoef.objectselection-corestate-bridge": "file:C:/Repositories/JorisHoef.ObjectSelection-CoreState-Bridge"
  }
}
```

The bridge requires Unity `2021.3` or newer.

## Core Flow

World object clicked:

```text
ObjectSelectionService<TKey> selects key
-> ObjectSelectionCoreStateBridge<TKey, T>
-> CoreState ISelectionService<TKey, T> selects key
```

Data/application selection changed:

```text
CoreState ISelectionService<TKey, T> selects key
-> ObjectSelectionCoreStateBridge<TKey, T>
-> ObjectSelectionService<TKey> selects key
```

## Public API

`ObjectSelectionCoreStateBridge<TKey, T>` subscribes to both selection services and forwards changes by key.

```csharp
using JorisHoef.Core.State;
using JorisHoef.ObjectSelection;
using JorisHoef.ObjectSelection.CoreState;

ObjectSelectionService<string> objectSelection = new ObjectSelectionService<string>(objectRegistry);
ISelectionService<string, ProjectData> coreSelection = new SelectionService<string, ProjectData>(repository);

using var bridge = new ObjectSelectionCoreStateBridge<string, ProjectData>(
    objectSelection,
    coreSelection);
```

The two-argument constructor binds immediately. You can also control lifecycle explicitly:

```csharp
var bridge = new ObjectSelectionCoreStateBridge<string, ProjectData>(
    objectSelection,
    coreSelection,
    bindImmediately: false);

bridge.Bind();
bridge.Unbind();
bridge.Dispose();
```

## Behavior

- If ObjectSelection selects key `x`, CoreState tries to select key `x`.
- If CoreState selects key `x`, ObjectSelection tries to select key `x`.
- If either side clears selection, the other side clears selection.
- Same-key changes are idempotent.
- A guard prevents recursive feedback loops.
- Missing keys are handled with `TrySelect` and do not throw.
- The bridge does not duplicate selection state.
- The bridge does not use ServiceLocator, singletons, UI Toolkit, UGUI, GenericUIItems, APIHelper, SessionHelper, or backend/application code.

## Samples

The package contains one sample:

- `Core State Bridge Sample`: `Samples~/CoreStateBridgeSample/CoreStateBridgeSample.unity`

Open the scene and enter Play Mode. The sample creates a cube, sphere, capsule, and cylinder with matching ObjectSelection keys and CoreState repository keys.

Click a primitive to select it through ObjectSelection and watch CoreState selection update. Use the sample's CoreState buttons to programmatically select data and watch ObjectSelection update the world highlight.

## Validation

Run structural validation from the package root:

```powershell
powershell -ExecutionPolicy Bypass -File ./Tools/Validate-Package.ps1
```

For Unity validation, use a separate test project that references this package and its dependencies by file path, then run EditMode tests for `JorisHoef.ObjectSelection.CoreState.Tests`.

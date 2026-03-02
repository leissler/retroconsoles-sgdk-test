# ResComp Extension Template

This folder contains a project-local SGDK `rescomp` extension jar template.

## Build flow

- Java sources are in `src/dev/retro/template/`
- `scripts/build-rescomp-ext.sh` compiles them against `SGDK/bin/rescomp.jar`
- output jar is written to `res/rescomp_ext.jar`
- SGDK `rescomp` auto-loads that jar when compiling resources in `res/`

## Implemented resource type

- `PALANIM`

Syntax in `.res`:

`PALANIM name file palette firstColor colorCount [frameDelay]`

## Next steps for your own extensions

1. Copy `PalAnimProcessor.java` / `PalAnimResource.java`
2. Change `getId()` to your new token
3. Parse your custom source format
4. Emit SGDK-compatible resource structs from `out(...)`

# Next Steps

## Summary

The transformation appears to have been successful. No build errors were detected across any of the projects in the solution, including the core project `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to an appropriate cross-platform target, such as:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple targets are needed, verify they are listed under `<TargetFrameworks>` (plural).

### 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay particular attention to:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **`System.Configuration` usage**: `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- **Windows-specific APIs**: Any APIs marked with `[SupportedOSPlatform("windows")]` will throw `PlatformNotSupportedException` on non-Windows systems.
- **File path separators**: Ensure no hardcoded backslashes (`\`) are used in file path logic.

### 6. Inspect Output Artifacts

After a Release build, inspect the output directory to confirm the expected assemblies and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of `./publish` to ensure no unexpected files are missing or extraneous legacy binaries are included.

### 7. Verify Third-Party Package Compatibility

Check that all third-party NuGet packages referenced in `AdoCore.csproj` support the target framework. You can use the following command to identify potential compatibility concerns:

```bash
dotnet list package --outdated
```

Consider updating any packages that have newer versions with explicit cross-platform .NET support.
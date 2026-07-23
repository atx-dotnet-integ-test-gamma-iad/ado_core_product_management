# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including the core project `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project previously targeted `net472` or another .NET Framework version, verify the new TFM aligns with your intended runtime environment.

### 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET that were not surfaced as build errors.

### 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for platform-specific calls:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific I/O paths
- COM interop
- `System.Drawing` usage (requires additional packages on Linux/macOS)

### 6. Verify Runtime Behavior Manually

Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement:

```bash
dotnet run --project AdoCore.csproj
```

Confirm that all expected functionality operates correctly and that no runtime exceptions surface from APIs that compile successfully but fail at runtime on non-Windows systems.

### 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the new TFM. Packages that only target `net45`, `net472`, or similar older monikers may fall back to compatibility mode, which can cause runtime issues. Review the assets file at:

```
obj/project.assets.json
```

Look for any packages resolving under `net4x` compatibility rather than a native `netstandard2.x` or `net6+` target.

### 8. Update Assembly and Package Metadata

If `AdoCore` is published as a NuGet package or referenced by other solutions, update the version metadata in the `.csproj` file to reflect the new framework target:

```xml
<PropertyGroup>
  <Version>x.y.z</Version>
  <Authors>Your Team</Authors>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```
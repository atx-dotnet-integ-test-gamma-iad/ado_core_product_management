# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues that did not surface as hard errors.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Runtime-Only Issues
Some issues do not surface at build time. Pay attention to the following areas when running the application:

- **File path separators**: Ensure no hardcoded backslashes (`\`) are used where `Path.Combine` or `Path.DirectorySeparatorChar` should be used instead.
- **Registry access**: Any code using `Microsoft.Win32.Registry` will not function on Linux or macOS.
- **Windows-specific APIs**: Review usage of APIs such as `System.Drawing`, WCF, or WPF components, as these have limited or no cross-platform support.
- **Configuration files**: Confirm that `app.config` or `web.config` based configuration has been migrated to `appsettings.json` or environment-based configuration where applicable.

### 6. Review Nullable Reference Type Warnings
If the projects have `<Nullable>enable</Nullable>` set, review any nullable warnings in the build output. While these are not errors by default, addressing them improves code correctness.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:

- The expected assemblies and dependencies are present.
- No unintended `.dll` files from legacy references remain.

## Deployment

### Publish the Application
Use the `dotnet publish` command to produce deployable output:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

### Verify the Published Output
Run the published output on the target platform and confirm the application behaves as expected, paying particular attention to any platform-specific functionality identified in step 5 above.
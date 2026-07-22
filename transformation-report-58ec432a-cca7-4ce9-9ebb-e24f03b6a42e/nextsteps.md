# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The solution compiles without issues.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Verify that no warnings or errors appear during the restore process.

### 2. Build the Solution

Perform a full build to confirm the solution compiles cleanly:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to an appropriate and supported version, such as `net8.0` or `net9.0`. Avoid using end-of-life versions.

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 5. Check for Runtime Behavioral Differences

Even without build errors, certain APIs behave differently on cross-platform .NET compared to .NET Framework. Review the following areas manually:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in the codebase.
- **Registry access**: `Microsoft.Win32.Registry` is not supported on Linux/macOS. Remove or conditionally compile any registry usage.
- **Windows-only APIs**: Check for any use of APIs under `System.Windows` or `System.Drawing` that may require additional compatibility packages.
- **Serialization**: `BinaryFormatter` is disabled by default in modern .NET. Replace any usage with a supported alternative such as `System.Text.Json` or `System.Xml.Serialization`.
- **Thread culture and globalization**: Verify globalization behavior, particularly if the app was relying on `System.Globalization` with `Invariant` mode disabled.

### 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent, and that the application reads configuration correctly at runtime.

### 7. Run the Application

Execute the application manually and walk through its primary workflows to confirm end-to-end functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Observe runtime output and logs for any exceptions or unexpected behavior.

### 8. Verify NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package targets `netstandard2.0`, `netstandard2.1`, or the specific .NET version in use. Packages that only target `net4x` may still resolve but can cause runtime issues.

You can inspect resolved packages with:

```bash
dotnet list package
```

Flag any packages marked as deprecated or with known compatibility issues and update them to their current supported versions.
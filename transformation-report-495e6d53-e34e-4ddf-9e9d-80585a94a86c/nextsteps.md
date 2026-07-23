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

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns with the target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the transformation:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated before proceeding further.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple target frameworks are required, verify that `<TargetFrameworks>` is used instead and includes all necessary entries.

### 5. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently in cross-platform .NET compared to .NET Framework. Review the following areas manually:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., backslashes) are used. Use `Path.Combine` or `Path.DirectorySeparatorChar` where appropriate.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux or macOS. If the project uses registry access, it will need to be replaced with a cross-platform alternative.
- **Windows-specific APIs**: Any usage of `System.Drawing`, `System.Windows.Forms`, or similar namespaces should be reviewed if cross-platform support is a goal.
- **Configuration**: If the project previously used `ConfigurationManager` or `app.config`, confirm that configuration has been migrated to `appsettings.json` or another supported mechanism.

### 6. Run on Target Platforms

If cross-platform execution is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at build time.

```bash
dotnet run --configuration Release
```

### 7. Review Output Artifacts

Confirm that the published output is correct by running a publish command:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all expected files, assemblies, and dependencies are present.

### 8. Address Nullable Reference Type Warnings (Optional)

If the project has `<Nullable>enable</Nullable>` set in the project file, review any nullable warnings that appear during build. While these do not cause build failures by default, resolving them improves code correctness and maintainability.
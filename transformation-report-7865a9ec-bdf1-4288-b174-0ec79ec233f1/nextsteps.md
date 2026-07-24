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

Perform a full solution build to confirm the error-free state holds across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to a currently supported version of .NET (e.g., `net8.0`). Avoid `netstandard2.0` or `netstandard2.1` unless cross-compatibility with .NET Framework is still a hard requirement.

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that were previously passing and are now failing, as these may indicate behavioral differences between .NET Framework and modern .NET.

### 5. Audit Removed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to check for any APIs that were available in .NET Framework but are absent or behave differently in modern .NET:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 6. Check for Platform-Specific Code

Search the codebase for any usage of Windows-specific APIs (e.g., `System.Drawing`, `Microsoft.Win32`, registry access, COM interop) that may compile successfully but fail at runtime on non-Windows platforms. These areas will require either conditional compilation guards or cross-platform alternatives.

### 7. Validate Runtime Behavior Manually

Execute the application and exercise its primary workflows manually. Confirm that:

- Data access operations complete without exception.
- Any file I/O uses platform-neutral path separators (`Path.Combine` rather than hardcoded `\`).
- Configuration loading (e.g., `app.config` vs `appsettings.json`) functions as expected under the new host model.

### 8. Review Output Artifacts

Confirm the build output directory contains the expected assemblies and that no unintended `.dll` files from the old framework are being referenced or copied:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure only the expected files are present.
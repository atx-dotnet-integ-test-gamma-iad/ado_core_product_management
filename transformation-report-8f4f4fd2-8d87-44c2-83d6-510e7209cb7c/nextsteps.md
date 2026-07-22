# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The solution compiles without issues, which indicates the migration to cross-platform .NET was completed without introducing any breaking changes at the build level.

## Validation Steps

### 1. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that the output reports zero errors and zero warnings (or review any warnings that may indicate deprecated APIs or compatibility concerns).

### 2. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to a supported and intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure the chosen framework version aligns with your organization's support and compatibility requirements.

### 3. Run Existing Tests

If the solution contains test projects, execute the test suite to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures, as build success does not guarantee correct runtime behavior.

### 4. Verify Platform-Specific Code

Inspect the codebase for any APIs that were previously Windows-specific, such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- Windows-specific file path assumptions (e.g., backslash separators)
- P/Invoke calls targeting Windows libraries

Use `RuntimeInformation.IsOSPlatform()` guards where platform-specific code paths must be retained.

### 5. Check for Removed or Changed APIs

Review any usage of APIs that were present in .NET Framework but have changed or been removed in .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims may help identify these at runtime.

### 6. Validate NuGet Dependencies

Confirm that all NuGet packages referenced in `AdoCore.csproj` support the target framework:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support, and remove any packages that were only required for .NET Framework compatibility.

### 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

### 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific platform (example: Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the output directory to confirm all expected assemblies and assets are present before deploying to the target environment.
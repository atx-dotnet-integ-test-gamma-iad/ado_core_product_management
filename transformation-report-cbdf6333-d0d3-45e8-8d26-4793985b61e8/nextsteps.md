# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, platform compatibility (`CA1416`), or obsolete APIs.

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Investigate any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` platform compatibility warnings. APIs such as those in `Microsoft.Win32`, `System.Windows.Forms`, or `System.Drawing` may require additional packages or may not be available on non-Windows platforms.

Run the analyzer explicitly if needed:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

### 6. Verify Runtime Behavior on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to confirm there are no platform-specific runtime exceptions.

```bash
dotnet run --configuration Release
```

### 7. Review `app.config` / `web.config` Migrations
Configuration files from .NET Framework projects are not used in the same way in cross-platform .NET. Confirm that any settings previously in `app.config` have been migrated to `appsettings.json` or the appropriate `IConfiguration` provider.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the contents of the `publish` output folder to confirm all required assets are present.
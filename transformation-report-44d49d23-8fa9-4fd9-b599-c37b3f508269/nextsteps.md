# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Runtime-Specific APIs
Even with a clean build, some APIs behave differently or are unsupported on non-Windows platforms at runtime. Review the code for usage of the following and test on each target platform:

- `System.Drawing` (requires additional native dependencies on Linux/macOS)
- `Microsoft.Win32` registry APIs
- Windows-specific interop (`DllImport` with Windows-only DLLs)
- `AppDomain` features that are no longer fully supported

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface these issues statically.

### 6. Review Configuration Files
- Ensure any `App.config` or `Web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model.
- Verify connection strings and environment-specific settings are correctly handled.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:

- The expected assemblies are present.
- No legacy `.config` files are being relied upon at runtime.
- Any embedded resources are included correctly.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment-ready output:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment.

### 2. Verify the Published Output
Run the published application from the output directory to confirm it starts and behaves correctly before deploying to a production environment:

```bash
cd ./publish
dotnet AdoCore.dll
```

Or, if published as a self-contained executable, run the binary directly.

### 3. Review Logging and Diagnostics
Confirm that logging is functioning as expected in the published output. If the project previously used `log4net`, `NLog`, or similar, verify those configurations are still valid or migrate to `Microsoft.Extensions.Logging`.
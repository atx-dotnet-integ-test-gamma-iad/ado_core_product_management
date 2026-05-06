# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that were not caught as hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package supports the target framework. You can use the following command to identify outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Replace or update any packages that do not have a compatible version for your target framework.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any API usage that may compile but behave differently at runtime on non-Windows platforms.

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Platform-specific file path assumptions (backslashes vs. forward slashes)
- `AppDomain` and reflection APIs that have changed behavior

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to surface any platform-specific runtime issues that would not appear at compile time:

```bash
dotnet run --configuration Release
```

### 7. Publish a Self-Contained Build
Produce a release build targeting each platform to confirm the publish pipeline works correctly:

```bash
dotnet publish -c Release -r win-x64 --self-contained true
dotnet publish -c Release -r linux-x64 --self-contained true
dotnet publish -c Release -r osx-x64 --self-contained true
```

Review the output directory to ensure all required assets and dependencies are present.

### 8. Review Configuration Files
Check that any configuration previously handled by `app.config` or `web.config` has been migrated to `appsettings.json` or environment variables, as the legacy XML-based configuration system has limited support in cross-platform .NET.
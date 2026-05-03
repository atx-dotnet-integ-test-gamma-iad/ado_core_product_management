# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that behavior has not changed after the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Platform-Specific API Usage
Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review the code for usage of APIs such as:

- `System.Drawing` (GDI+)
- `Microsoft.Win32.Registry`
- Windows-specific P/Invoke calls
- `System.Windows.Forms` or `System.Web`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues statically.

### 5. Review NuGet Package Compatibility
Confirm that all NuGet dependencies have versions compatible with the target framework. Run:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages, and replace any packages that do not support the target framework with their modern equivalents.

### 6. Validate Configuration Files
Check that any configuration previously handled by `app.config` or `web.config` has been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 7. Smoke Test on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime-only issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

### 8. Publish a Self-Contained Build
Produce a release build targeting each intended runtime identifier to confirm the output is valid:

```bash
dotnet publish -c Release -r win-x64 --self-contained true
dotnet publish -c Release -r linux-x64 --self-contained true
```

Review the publish output for any trimming warnings if `PublishTrimmed` is enabled.
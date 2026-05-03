# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net4x` or `netstandard` frameworks unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate runtime issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific APIs
Even without build errors, some APIs that compiled successfully may not behave correctly or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review usages of the following areas in particular:

- `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- Windows Communication Foundation (WCF) server-side components
- `System.Security.Permissions` and Code Access Security (CAS)
- COM interop

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues statically.

### 6. Run the Application and Perform Smoke Testing
Start the application and exercise its primary workflows manually or through integration tests. Pay attention to:

- Configuration loading (e.g., `app.config` vs `appsettings.json`)
- Logging behavior
- Database connectivity if applicable
- Any file path assumptions that may be OS-specific (e.g., backslash vs forward slash separators)

### 7. Review `app.config` / `web.config` Migration
.NET no longer uses `app.config` or `web.config` in the same way as .NET Framework. Confirm that any configuration values have been moved to `appsettings.json` or environment variables, and that the application reads them using `Microsoft.Extensions.Configuration` where appropriate.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files are present, and test the published output in the target deployment environment.
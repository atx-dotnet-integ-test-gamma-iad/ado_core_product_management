# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, especially after a framework migration.

### 5. Check for Platform-Specific API Usage
Search the codebase for APIs that were Windows-specific in .NET Framework and may behave differently or throw `PlatformNotSupportedException` on non-Windows platforms. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (now requires the `System.Drawing.Common` package and has platform limitations)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify these usages.

### 6. Review NuGet Package Compatibility
Open the NuGet package manager or inspect each `.csproj` file and verify that all referenced packages have versions compatible with the target .NET version. Replace any packages that have official successors, for example:

- `Newtonsoft.Json` → still supported, but `System.Text.Json` is the built-in alternative
- `Microsoft.AspNet.*` → should be replaced with `Microsoft.AspNetCore.*`

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis would not catch.

### 8. Review Output and Configuration Files
Confirm that configuration files (e.g., `appsettings.json`, environment variables) are correctly read at runtime. .NET no longer uses `app.config` or `web.config` in the same way as .NET Framework. If the project previously relied on `ConfigurationManager`, verify the appropriate NuGet package (`System.Configuration.ConfigurationManager`) is referenced or that the configuration has been migrated to `Microsoft.Extensions.Configuration`.

### 9. Deployment
Once all validation steps pass, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required assets, dependencies, and configuration files are present before deploying to the target environment.
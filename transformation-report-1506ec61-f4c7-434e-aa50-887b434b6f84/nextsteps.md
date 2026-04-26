# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs, missing platform support, or compatibility concerns.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the old and new frameworks.

### 4. Check for Platform-Specific API Usage
Search the codebase for APIs that may have been available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to review include:

- `System.Windows.Forms` or `System.Web` usage (not supported cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)
- P/Invoke calls targeting Windows-specific native libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling if needed.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. Confirm that each package:

- Supports the target framework (check on [nuget.org](https://www.nuget.org))
- Is updated to a version that provides a `netstandard2.0`, `net6.0`, `net8.0`, or equivalent target

Replace any packages that only support `net4x` with their modern equivalents.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where appropriate.

### 7. Smoke Test the Application
Run the application manually and exercise its primary functionality to confirm there are no runtime errors that were not caught at build time:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Check application logs and console output for unhandled exceptions or unexpected behavior.

### 8. Publish a Release Build
Once validation is complete, produce a published output to confirm the deployment artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assemblies, configuration files, and assets are present.
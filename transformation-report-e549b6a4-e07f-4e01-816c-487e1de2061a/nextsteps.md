# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns even if they are not hard errors.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior after a framework migration.

### 5. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to identify any API usage that may have changed behavior between .NET Framework and modern .NET, even if it compiles without errors.

### 6. Review Platform-Specific Code
Search the codebase for any usage of the following, which may compile but fail at runtime on non-Windows platforms:

- `Registry` (Microsoft.Win32)
- `System.Drawing` (GDI+ dependent)
- `System.Windows.Forms` or `System.Web`
- P/Invoke calls to Windows-specific native libraries
- `AppDomain.CreateDomain` (not supported in .NET Core+)

### 7. Validate Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate modern .NET configuration model, and that the application reads configuration correctly at runtime.

### 8. Run the Application
Execute the application directly and exercise its primary workflows to confirm end-to-end behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 9. Publish a Release Build
Once runtime validation is complete, produce a published output to confirm the deployment artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory contain all expected assemblies and assets.
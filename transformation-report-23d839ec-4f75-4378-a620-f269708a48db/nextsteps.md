# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no residual issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers (CA1416), as these can indicate runtime issues on specific operating systems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original .NET Framework version:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests. Pay particular attention to tests that exercise I/O, networking, or platform-specific APIs, as these are common sources of behavioral differences after migration.

### 5. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to identify any API usage that may compile successfully but behave differently at runtime on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Focus on areas such as:
- `System.Drawing` (requires `libgdiplus` on Linux or replacement with `SkiaSharp`/`ImageSharp`)
- `System.Security.Cryptography` APIs with platform-specific limitations
- Registry access (`Microsoft.Win32.Registry`) which is Windows-only
- `System.IO.Ports` which has platform-specific driver requirements

### 6. Validate Configuration and App Settings
Confirm that any `app.config` or `web.config` files have been correctly translated to `appsettings.json` or environment-based configuration. Verify that connection strings, logging settings, and feature flags load correctly at runtime.

### 7. Smoke Test on Target Platforms
Run the application on each operating system you intend to support (Windows, Linux, macOS) and verify core functionality. Use the following to publish a self-contained executable for a specific runtime if needed:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment.

### 8. Review Warnings as Errors Policy
If the project has `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` set, resolve all remaining compiler warnings before considering the migration complete, as these may surface as build failures in stricter build environments.
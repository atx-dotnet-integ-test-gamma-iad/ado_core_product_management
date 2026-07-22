# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated package versions that may need to be updated.

### 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to an appropriate and currently supported version, such as `net8.0`:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Refer to the [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) to ensure the targeted version is not end-of-life.

### 5. Review Removed or Changed APIs

Cross-platform .NET removes or modifies certain APIs that were available in .NET Framework. Run the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tool to surface any runtime-level API incompatibilities that do not manifest as build errors:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze AdoCore.csproj
```

### 6. Validate Platform-Specific Behavior

If `AdoCore` previously relied on any of the following, manual validation is required:

- **Windows Registry access** (`Microsoft.Win32.Registry`) — not available on Linux/macOS.
- **`System.Drawing`** — requires additional native dependencies on non-Windows platforms.
- **COM Interop or P/Invoke** — platform availability must be verified explicitly.
- **`app.config` / `web.config`** — configuration in cross-platform .NET uses `appsettings.json` and `IConfiguration`.

### 7. Run on Target Platform

If cross-platform support is a goal, execute the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime failures:

```bash
dotnet run --configuration Release
```

### 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent deployment
dotnet publish -c Release -o ./publish

# Self-contained deployment for a specific runtime
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
dotnet publish -c Release -r win-x64 --self-contained true -o ./publish/win-x64
```

Verify the contents of the output directory to confirm all required assets are present before deploying to the target environment.
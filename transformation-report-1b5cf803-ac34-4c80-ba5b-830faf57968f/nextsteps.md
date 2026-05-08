# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that could indicate runtime issues even if the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but will throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- `System.Drawing` (requires additional native dependencies on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM usage

### 6. Validate Configuration and App Settings
Confirm that any configuration files (e.g., `app.config`, `web.config`) have been migrated to the appropriate `appsettings.json` format or are being read correctly by the new hosting model, if applicable.

### 7. Smoke Test Core Functionality
Run the application manually and exercise the primary workflows to confirm end-to-end behavior matches the legacy version. Focus on:
- Data access and connection strings
- External service integrations
- File I/O paths (watch for hardcoded Windows-style paths)
- Localization and date/number formatting if applicable

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment.

### 2. Verify the Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present before copying to the target environment.

### 3. Test on the Target Environment
Deploy the published output to a staging environment that mirrors production and repeat the smoke tests described above before promoting to production.
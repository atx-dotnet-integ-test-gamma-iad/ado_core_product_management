# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results, paying attention to any tests that were previously passing but now fail.

### 4. Check for Platform-Specific Code
Search the codebase for APIs that are known to be Windows-only or otherwise platform-specific, such as:

- `System.Windows.Forms`
- `System.Drawing` (GDI+ based)
- `Microsoft.Win32.Registry`
- P/Invoke calls to native Windows DLLs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues if they exist.

### 5. Review NuGet Package Compatibility
Open each `.csproj` and verify that all referenced NuGet packages have versions that support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their modern equivalents.

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET.

### 7. Smoke Test the Application
Run the application directly and exercise its primary functionality:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that the application behaves as expected at runtime, not just at compile time.

## Deployment

### 1. Publish a Self-Contained or Framework-Dependent Build
Depending on your deployment target, publish the application using one of the following approaches:

**Framework-dependent (smaller output, requires .NET runtime on host):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (larger output, no runtime dependency on host):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`).

### 2. Verify the Published Output
Navigate to the `./publish` directory and confirm all expected files are present, including configuration files, static assets, and any required native dependencies.

### 3. Test the Published Artifact
Run the published artifact directly on the target platform to confirm it operates correctly outside of the development environment:

```bash
./publish/AdoCore
```

or on Windows:

```bash
.\publish\AdoCore.exe
```
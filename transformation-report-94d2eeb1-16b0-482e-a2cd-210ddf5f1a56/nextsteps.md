# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are properly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages. Replace any packages that do not support the target framework with their cross-platform equivalents.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to platform compatibility (e.g., `CA1416` platform-specific API warnings).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is intact:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage (requires additional packages on non-Windows platforms)
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `System.Web` namespace usage

Run the following to check for platform compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement:

```bash
dotnet run --configuration Release
```

Confirm that all core workflows produce the same results as the original legacy application.

## 7. Publish the Application

Once validation is complete, publish the application for the desired target runtime:

**Framework-dependent (smaller output, requires .NET runtime installed):**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained (includes runtime, no external dependency):**
```bash
dotnet publish -c Release -f net8.0 --self-contained true -r linux-x64
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all required files, configuration files, and assets are present before deploying to the target environment.
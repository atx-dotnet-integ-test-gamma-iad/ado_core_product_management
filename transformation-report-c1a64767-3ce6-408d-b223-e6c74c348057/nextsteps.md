# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that may surface at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but are not fully supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires the `System.Drawing.Common` NuGet package on non-Windows platforms)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- WCF server-side components (not available in .NET Core/5+)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform .NET support.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not appear during a build.

## 7. Review Output and Configuration Files

- Confirm that `appsettings.json` or other configuration files are present and correctly structured if the project previously relied on `App.config` or `Web.config`.
- Verify that the build output directory contains all expected files, including dependencies and runtime assets.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the contents of the `publish` output folder before deploying to the target environment.
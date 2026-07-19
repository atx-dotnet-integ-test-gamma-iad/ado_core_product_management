# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework does not match your intended version, update it and rebuild the solution.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failures. Pay particular attention to tests that exercise database access, file I/O, or platform-specific behavior, as these areas are most likely to surface cross-platform issues at runtime.

## 5. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify core functionality. Areas to check include:

- **File paths**: Ensure no hardcoded backslashes (`\`) are used; use `Path.Combine` or `Path.DirectorySeparatorChar` instead.
- **Database connectivity**: Confirm connection strings and ADO.NET providers are compatible with the target platform.
- **Configuration files**: Verify that `app.config` or `web.config` references have been replaced with `appsettings.json` or equivalent .NET configuration mechanisms if applicable.
- **Registry access**: If the original project used the Windows registry, those calls will fail on non-Windows platforms and must be replaced with cross-platform alternatives.

## 6. Review Removed or Changed APIs

Check the code for any APIs that were available in .NET Framework but have changed or been removed in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility package can help identify these at development time.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required files are present before deploying.
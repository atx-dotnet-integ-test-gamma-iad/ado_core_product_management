# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific framework such as `net48`, update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no lingering issues:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns even if the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully, paying attention to any tests that were previously passing but now fail.

## 5. Verify Platform-Specific API Usage

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- `Microsoft.Win32` registry access
- `System.Security.Permissions` attributes
- COM interop calls
- `AppDomain` usage patterns that differ between .NET Framework and modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining issues.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended platform:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Confirm that runtime behavior matches expectations on each platform.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Verify the contents of the output directory before deploying to the target environment.

## 8. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system behaves differently in modern .NET.
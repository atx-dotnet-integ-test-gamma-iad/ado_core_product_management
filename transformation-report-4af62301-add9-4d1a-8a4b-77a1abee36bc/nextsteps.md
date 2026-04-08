# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate compatibility issues, such as obsolete API usage or platform-specific calls.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can inspect this with:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that are outdated or have known compatibility issues with cross-platform .NET.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that were available in .NET Framework but are not fully supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining issues.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime behavior:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and environment variable differences across platforms.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target platform:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific platform (e.g., Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Review the contents of the output directory to confirm all required assemblies and configuration files are present.

## 8. Validate Configuration Files

Ensure that any configuration files (e.g., `appsettings.json`, environment-specific configs) are correctly included in the publish output and that the application reads them as expected at runtime. If the project previously used `App.config` or `Web.config`, verify that settings have been migrated appropriately to the new configuration system.
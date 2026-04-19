# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to review include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `AppDomain` usage
- `ConfigurationManager` (should be replaced with `Microsoft.Extensions.Configuration`)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where needed.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and verify all referenced NuGet packages have versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages, paying particular attention to packages that previously targeted `net45`, `net472`, or similar legacy monikers.

## 6. Validate Configuration Files

- Confirm that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or equivalent.
- Verify connection strings, logging configuration, and environment-specific settings are correctly represented in the new format.

## 7. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the output in the `publish` folder before distributing.
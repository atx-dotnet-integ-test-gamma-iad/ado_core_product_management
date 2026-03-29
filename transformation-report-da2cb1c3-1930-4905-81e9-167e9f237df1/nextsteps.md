# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the value still references a Windows-only framework such as `net48` or `net472`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may point to behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization).

## 4. Check for Platform-Specific Code

Search the codebase for APIs that are known to behave differently or are unavailable on non-Windows platforms:

- `System.Data.OleDb` — not available on Linux/macOS without additional packages
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls targeting Windows-only DLLs
- `System.Drawing` — requires `libgdiplus` on Linux or replacement with a cross-platform library

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` NuGet package to identify these areas.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and verify that all referenced NuGet packages support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their modern equivalents.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that do not appear during compilation.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying.
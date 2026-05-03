# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-only file path assumptions (e.g., backslash separators)
- `AppDomain` usage that behaves differently in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface remaining compatibility concerns.

## 6. Check for Removed or Changed APIs

Cross-reference any usages of APIs that were removed or altered between .NET Framework and modern .NET. The official reference for this is:

- [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes)

Pay particular attention to changes in `System.Data`, `System.Configuration`, and serialization namespaces if `AdoCore` is a data-access layer.

## 7. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your deployment target. A full list of RIDs is available at:

- [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog)

## 9. Review Output Artifacts

Inspect the contents of the `publish` output directory to confirm all required assemblies, configuration files, and assets are present before deploying to the target environment.
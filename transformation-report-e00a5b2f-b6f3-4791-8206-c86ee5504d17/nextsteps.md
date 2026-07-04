# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NET Framework` with their cross-platform equivalents where necessary.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after a framework migration are often caused by:
- Behavioral differences in APIs between .NET Framework and modern .NET
- Missing configuration files (e.g., `app.config` vs `appsettings.json`)
- Changes in how reflection, serialization, or threading works

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were Windows-only under .NET Framework and may not be available cross-platform. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages or is unsupported on non-Windows)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server code
- `System.Security.Permissions` and Code Access Security (CAS), which is no longer enforced

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility issues.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay attention to:
- File path separator differences (`\` vs `/`)
- Case sensitivity in file system operations on Linux
- Environment variable handling differences

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets and configuration files are present before deploying to the target environment.
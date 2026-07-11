# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can verify your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility fallbacks.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run the Test Suite

If the solution contains a test project, execute all tests to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Audit Platform-Specific Code

Search the codebase for APIs that were available in .NET Framework but have limited or no support in cross-platform .NET, including:

- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side components
- `AppDomain.CreateDomain`
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface these systematically.

## 6. Review Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that settings have been migrated to the appropriate .NET configuration model, typically `appsettings.json` with `Microsoft.Extensions.Configuration`.

## 7. Validate on Target Operating Systems

Since the goal is cross-platform support, run the build and test steps on each intended operating system (Windows, Linux, macOS) to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assets are present before deploying to the target environment.
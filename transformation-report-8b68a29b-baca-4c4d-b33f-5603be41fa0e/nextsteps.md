# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist prior to migration may indicate runtime behavioral differences between .NET Framework and cross-platform .NET.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` references (not supported outside of Windows/ASP.NET Core)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- Remoting APIs
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended target operating system (Windows, Linux, macOS) to surface any OS-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 6. Review Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` or `<TargetFrameworks>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multi-targeting is required, ensure all target frameworks are listed and tested individually.

## 7. Check Output and Publish

Publish the application to verify the output is complete and runnable:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the output directory to confirm all required assemblies, configuration files, and assets are present. Run the published output directly to validate it functions correctly outside of the development environment.

## 8. Review Configuration Files

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated appropriately to `appsettings.json` or environment-based configuration, as `ConfigurationManager` behavior differs in some scenarios under cross-platform .NET.
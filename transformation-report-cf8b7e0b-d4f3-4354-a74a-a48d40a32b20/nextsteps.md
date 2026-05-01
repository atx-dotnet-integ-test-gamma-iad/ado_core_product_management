# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced by the migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution to avoid inter-project compatibility issues.

## 5. Review Removed or Replaced APIs

Check the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to review include:

- `System.Web` usages (not available in .NET Core and later)
- Windows-specific APIs (e.g., registry access, WCF server-side hosting)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended platform (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at build time:

```bash
dotnet run --configuration Release
```

## 7. Review Configuration Files

Ensure that configuration files such as `appsettings.json` or environment-specific configurations are correctly structured for the new hosting model. Legacy `app.config` or `web.config` files may need to be migrated to the `appsettings.json` pattern or the `Microsoft.Extensions.Configuration` model.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment requirements. A self-contained deployment includes the .NET runtime, while a framework-dependent deployment requires the runtime to be installed on the target machine.
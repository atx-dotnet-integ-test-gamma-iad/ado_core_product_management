# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues that may surface at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not regressed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Pay attention to any tests that were previously passing in the legacy project but now fail, as these may indicate behavioral differences between the old .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Review any code that previously relied on Windows-specific APIs, such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- COM interop
- Windows-specific file path assumptions (e.g., backslash separators)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining platform-specific dependencies.

## 5. Review Configuration Files

Check that any configuration previously handled by `App.config` or `Web.config` has been correctly migrated to the appropriate modern equivalents:

- `appsettings.json` for application settings
- `Microsoft.Extensions.Configuration` for configuration access patterns

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Compare the output and behavior against the legacy version to confirm functional equivalence.

## 7. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the application is intended to run only on Windows, ensure the appropriate TFM is used:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 8. Publish the Application

Once validation is complete, publish the application using the following command:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and assets are present before deploying to the target environment.
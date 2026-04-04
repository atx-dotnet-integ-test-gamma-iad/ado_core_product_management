# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests that previously passed may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` usage (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage, particularly `AppDomain.CreateDomain`
- WCF server-side components
- Binary serialization via `BinaryFormatter`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining compatibility concerns.

## 5. Run the Application and Perform Smoke Testing

Start the application and manually verify that core functionality behaves as expected:

```bash
dotnet run --configuration Release
```

Focus on areas of the application that rely on I/O, networking, configuration, or any Windows-specific behavior that may differ across platforms.

## 6. Review Configuration Files

Check that configuration files have been properly migrated. In cross-platform .NET, `app.config` and `web.config` are replaced or supplemented by `appsettings.json` and the `Microsoft.Extensions.Configuration` infrastructure. Confirm that:

- Connection strings are correctly read at runtime
- Environment-specific settings are properly handled
- Any XML-based configuration that was previously auto-loaded is now explicitly wired up

## 7. Validate Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to an appropriate and currently supported version, such as `net8.0`:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Refer to the [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) to ensure you are targeting a version that is not end-of-life.

## 8. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the output directory to confirm all required assets, binaries, and configuration files are present before deploying to the target environment.
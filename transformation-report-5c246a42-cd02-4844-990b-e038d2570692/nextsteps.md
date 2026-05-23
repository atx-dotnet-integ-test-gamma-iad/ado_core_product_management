# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Check the output for any warnings that, while non-breaking, may indicate areas that need attention (e.g., nullable reference warnings, obsolete API usage).

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine if they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but are not supported or behave differently in cross-platform .NET. Common areas include:

- `System.Web` (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM components
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist in identifying these issues.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at build time.

## 7. Review Configuration Files

Ensure that configuration files have been properly migrated. In cross-platform .NET, `app.config` and `web.config` are replaced by `appsettings.json` and the `Microsoft.Extensions.Configuration` infrastructure. Verify that all configuration values are accessible at runtime.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <runtime-identifier> --output ./publish
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, such as `win-x64`, `linux-x64`, or `osx-x64`. A full list of runtime identifiers is available in the [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).
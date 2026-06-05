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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET differs from .NET Framework in several areas. Manually verify the following:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in configuration files or code.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the code uses the registry, it will need to be replaced with an alternative configuration mechanism.
- **Windows Communication Foundation (WCF)**: WCF server-side is not supported in cross-platform .NET. If WCF is used, consider migrating to gRPC or ASP.NET Core.
- **`System.Drawing`**: On non-Windows platforms, `System.Drawing.Common` requires native dependencies. Consider replacing it with a cross-platform alternative such as `SkiaSharp` if non-Windows support is needed.
- **`AppDomain`**: Some `AppDomain` members are not supported. Review any usage of `AppDomain.CreateDomain` or similar APIs.

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple target frameworks are required, use `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 6. Check Configuration Files

- `app.config` files are not automatically used in cross-platform .NET in the same way as .NET Framework. Migrate any configuration to `appsettings.json` and use `Microsoft.Extensions.Configuration` where applicable.
- Connection strings and environment-specific settings should be reviewed and updated accordingly.

## 7. Validate Runtime Behavior

Run the application in a development environment and exercise its primary workflows. Pay attention to:

- Exception messages that reference unsupported platform features.
- Any `PlatformNotSupportedException` thrown at runtime.
- Differences in globalization behavior. Cross-platform .NET uses ICU libraries by default rather than Windows NLS. If the application relies on specific culture or sorting behavior, test this explicitly.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) if deploying to a non-Windows environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.
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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET differs from .NET Framework in several areas. Manually verify the following:

- **File path handling**: Ensure no hardcoded Windows-style paths (e.g., backslashes) exist in the codebase.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the project uses the registry, this will need to be replaced with an alternative configuration mechanism.
- **Windows-only APIs**: Check for any usage of APIs under `System.Windows` or `System.Drawing` that may require additional compatibility packages such as `System.Drawing.Common`.
- **AppDomain and Reflection**: Some `AppDomain` APIs have been removed or altered. Test any dynamic loading or plugin-style functionality thoroughly.

## 5. Review the Target Framework

Open the `.csproj` file(s) and confirm the target framework moniker (TFM) is set appropriately for your intended deployment targets:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If you need to support multiple frameworks simultaneously, consider using `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 6. Check Configuration and App Settings

.NET Framework used `App.config` and `Web.config`. Cross-platform .NET uses `appsettings.json` and the `Microsoft.Extensions.Configuration` stack. Confirm that:

- Configuration files have been migrated or are being read correctly.
- Connection strings and environment-specific settings are accessible at runtime.

## 7. Validate Runtime Behavior

Run the application in a staging or local environment and exercise its primary workflows. Pay particular attention to:

- Serialization and deserialization (e.g., `Newtonsoft.Json` vs `System.Text.Json` differences).
- Thread and async behavior, which can differ subtly between runtimes.
- Any third-party libraries that may have separate .NET Framework and .NET builds.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (RID) for your target platform (e.g., `linux-x64`, `osx-x64`).

## 9. Review Published Output

Inspect the contents of the publish output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.
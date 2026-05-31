# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failures should be investigated before proceeding, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs. Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any remaining platform-specific calls:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, review the code manually for usage of APIs such as:
- `System.Windows.Forms`
- `System.Drawing` (requires additional packages on non-Windows)
- `Microsoft.Win32.Registry`
- COM interop

If the application is intended to run only on Windows, you can annotate the project with the target platform in the `.csproj` file:

```xml
<PropertyGroup>
  <TargetFramework>net8.0-windows</TargetFramework>
</PropertyGroup>
```

## 5. Review Configuration Files

Check that any configuration previously handled by `App.config` or `Web.config` has been properly migrated to `appsettings.json` or environment-based configuration, depending on the application type. The `System.Configuration.ConfigurationManager` NuGet package is available if legacy configuration access is still required.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:
- File path handling, as path separators differ across operating systems
- Culture and encoding behavior, which may differ slightly between runtimes
- Reflection-based code, which may be affected by trimming or assembly loading differences

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate profile:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Review Target Framework Version

Confirm that the target framework in each `.csproj` file is set to the intended version. If you are targeting .NET 8 (current LTS), the entry should appear as:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Upgrading to the latest LTS version is recommended for long-term support and security updates.
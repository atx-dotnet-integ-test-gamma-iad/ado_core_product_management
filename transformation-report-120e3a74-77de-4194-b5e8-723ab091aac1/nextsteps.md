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

Review test results carefully. Any failing tests should be investigated to determine whether the failure is due to a migration issue or a pre-existing problem.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless explicitly required.

## 5. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer or review the build output for platform compatibility warnings (CA1416). APIs such as the Windows Registry, certain `System.Drawing` methods, or WinForms components will not function on non-Windows platforms.

If any such APIs are present and cross-platform support is required, identify suitable replacements or add platform guards:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

## 6. Review Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where applicable. The `System.Configuration.ConfigurationManager` package is available for backward compatibility but may not be the preferred long-term approach.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay attention to:

- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Case-sensitive file systems on Linux/macOS
- Environment-specific behavior differences between .NET Framework and modern .NET

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific platform, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) based on your deployment target.

## 9. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all required files, assets, and dependencies are present before deploying to the target environment.
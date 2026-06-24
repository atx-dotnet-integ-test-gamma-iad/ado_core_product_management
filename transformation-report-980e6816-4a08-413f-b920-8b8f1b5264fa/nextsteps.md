# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting `net4x` or `netstandard`.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been suppressed during the transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the compatibility analyzer to identify any APIs that may behave differently or are unavailable on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the platform compatibility analyzer by ensuring your project has the appropriate TFM set, which will surface `[SupportedOSPlatform]` warnings automatically during build.

## 6. Review `app.config` / `web.config` Migrations

If the original project used `app.config` or `web.config`, verify that settings have been correctly migrated to `appsettings.json` or environment-based configuration, as the legacy config system has limited support in cross-platform .NET.

## 7. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Registry access or Windows-specific interop calls

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier (RID) for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the contents of the `publish` output folder before deploying to confirm all required assets are present.
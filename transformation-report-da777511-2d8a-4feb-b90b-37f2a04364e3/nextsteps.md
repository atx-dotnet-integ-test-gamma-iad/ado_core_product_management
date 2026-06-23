# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are properly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test output for any failures that may indicate behavioral regressions introduced during the migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which indicate calls to Windows-only APIs. If `AdoCore` interacts with any Windows-specific libraries (e.g., `System.Drawing`, COM interop, or registry access), those areas will require additional attention to function correctly on non-Windows platforms.

You can also run the following to surface platform compatibility diagnostics:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Environment variable access
- Any database or ADO.NET connection strings that may be environment-specific

## 7. Review `app.config` or `web.config` Migrations

If the original project used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration providers, as the legacy config system has limited support in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application for the desired target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.
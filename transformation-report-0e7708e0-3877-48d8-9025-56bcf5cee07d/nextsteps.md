# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no residual issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent runtime issues.

## 4. Run the Test Suite

Execute all unit and integration tests to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any test failures. Pay particular attention to tests that cover platform-specific functionality, such as file I/O paths, registry access, or Windows-specific APIs, as these are common sources of failure after cross-platform migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining calls to Windows-only APIs:

```bash
dotnet build --configuration Release /p:PlatformTarget=AnyCPU
```

Additionally, search the codebase for usages of APIs such as `System.Windows.Forms`, `Microsoft.Win32.Registry`, or `System.Drawing` (non-cross-platform version) and replace or conditionally compile them where necessary.

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that:

- File paths use `Path.Combine` and `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- Environment-specific configuration (e.g., `appsettings.json`, environment variables) loads correctly.
- Any external dependencies (databases, file shares, etc.) are reachable from each target platform.

## 7. Review Configuration and Startup

If the project uses `appsettings.json` or a similar configuration system, confirm that:

- All configuration keys referenced in code are present in the configuration files.
- Any configuration that previously relied on `app.config` or `web.config` has been properly migrated to the .NET configuration system.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target. Review the publish output directory to confirm all required files are present before deploying.
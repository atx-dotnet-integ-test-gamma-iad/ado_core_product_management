# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command in the root of your solution to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist before the migration may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Validate Platform-Specific Behavior

Cross-platform .NET differs from .NET Framework in several areas. Manually verify the following:

- **File system paths**: Ensure no hardcoded backslash (`\`) path separators are used. Use `Path.Combine` or `Path.DirectorySeparatorChar` instead.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the project uses the registry, this will require an alternative configuration mechanism.
- **Windows-only APIs**: Any use of `System.Drawing`, WCF, or other Windows-specific libraries should be reviewed and replaced with cross-platform alternatives where necessary.
- **Configuration files**: Confirm that any `app.config` or `web.config` usage has been properly transitioned to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

## 5. Check for Removed or Changed APIs

Review the code for any APIs that were available in .NET Framework but have been removed or changed in .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API compatibility tool](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-compat) can assist with this.

Common areas to check:
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- `Thread.Abort`
- Reflection APIs with changed behavior

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for 64-bit Windows
- `linux-x64` for 64-bit Linux
- `osx-x64` for macOS on Intel
- `osx-arm64` for macOS on Apple Silicon

Review the publish output directory to confirm all required files and dependencies are present before deploying.
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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after migration are often caused by:
- Behavioral differences between .NET Framework and cross-platform .NET in areas such as globalization, file path handling, or reflection.
- Missing platform-specific APIs that were available in .NET Framework but are absent or behave differently in .NET.

## 4. Verify Platform-Specific Behavior

Since this is a cross-platform migration, manually verify the following areas if they are relevant to your project:

- **File I/O**: Ensure file paths use `Path.Combine` and do not rely on Windows-style backslashes.
- **Registry Access**: Any use of `Microsoft.Win32.Registry` will not function on Linux or macOS.
- **Windows-only APIs**: Check for any remaining usage of APIs guarded by the `[SupportedOSPlatform]` attribute warnings.
- **Encoding and Globalization**: If your application uses `CultureInfo` or specific encodings, verify behavior under the `Invariant` globalization mode if it has been enabled.

## 5. Check the Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` value is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple platform targets are required, consider using `<TargetFrameworks>` (plural) to build for more than one target.

## 6. Review Removed or Replaced APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any API usage that may have been silently replaced or stubbed during transformation. Run the following if the analyzer is available:

```bash
dotnet analyze
```

## 7. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target environment, for example `win-x64`, `linux-x64`, or `osx-x64`.

Review the publish output directory to confirm all expected assemblies and configuration files are present before deploying to the target environment.
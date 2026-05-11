# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may not be fully compatible with the target framework.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some may indicate compatibility concerns that did not manifest as hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected after the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine if the failure is caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET differs from .NET Framework in several areas. Manually review the following in your codebase:

- **Registry access**: `Microsoft.Win32.Registry` APIs are Windows-only. If the code uses registry access, ensure it is either guarded with a platform check or replaced with a cross-platform alternative such as a configuration file.
- **Windows Communication Foundation (WCF)**: Full WCF server-side support is not available on cross-platform .NET. If WCF services are present, consider migrating to `CoreWCF` or replacing with a REST-based approach.
- **`System.Drawing`**: GDI+-based drawing is Windows-only by default. If image processing is used, consider `SkiaSharp` or `ImageSharp` as cross-platform alternatives.
- **`AppDomain`**: Some `AppDomain` members are no longer supported. Review any usage and replace where necessary.
- **Reflection and serialization**: Behavior differences exist in some edge cases. Validate any code that relies heavily on reflection or binary serialization (`BinaryFormatter` is obsolete and disabled by default).

## 5. Run on Target Platforms

If cross-platform support is a goal, test the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and case-sensitive file system behavior on Linux.

## 6. Review Output and Configuration Files

- Confirm that `appsettings.json` or other configuration files are present and correctly read at runtime.
- Verify that the output directory contains all expected assets and that no files are missing due to changes in the build output structure.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS 64-bit

Review the published output directory to confirm all required files are present before deploying to the target environment.
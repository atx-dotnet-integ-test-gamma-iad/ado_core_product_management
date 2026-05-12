# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command in the root of your solution to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while not blocking the build, may indicate compatibility concerns with the new target framework.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that runtime behavior has not changed as a result of the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, particularly around areas such as:

- Reflection behavior
- Globalization and encoding defaults
- File path handling across operating systems
- `System.Configuration` or `app.config` usage

## 4. Verify Platform-Specific Code

Review the codebase for any APIs that were available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires additional packages on non-Windows platforms)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage
- COM interop

## 5. Check Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project needs to remain Windows-specific, ensure the TFM reflects that:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 6. Review Nullable Reference Type Warnings

Cross-platform .NET projects often enable nullable reference types by default. If the project was not previously using this feature, review and address any nullable warnings to improve code correctness:

```xml
<Nullable>enable</Nullable>
```

You may choose to set this to `warnings` or `disable` initially and address them incrementally.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime issues that do not surface during compilation.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assets are present before deploying.
# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures here may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, even when the build succeeds.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared libraries.

## 5. Check for Runtime-Specific API Usage

Even with a clean build, some APIs behave differently or are unsupported on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility warnings to identify any calls to Windows-only APIs:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific UI frameworks
- COM interop
- `System.Drawing` (GDI+)

## 6. Test on Target Platform

If cross-platform support is a goal, run and test the application explicitly on each target operating system (Linux, macOS, Windows) to surface any platform-specific runtime issues that static analysis may not catch.

## 7. Review Configuration and File Paths

Inspect any hardcoded file paths, directory separators, or environment-specific configuration values in the codebase. Replace hardcoded backslashes with `Path.Combine` or `Path.DirectorySeparatorChar` where applicable.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`).
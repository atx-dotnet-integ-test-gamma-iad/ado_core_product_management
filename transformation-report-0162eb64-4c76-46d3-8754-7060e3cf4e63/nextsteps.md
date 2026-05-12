# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review test output carefully. A successful build does not guarantee correct runtime behavior, especially after a cross-platform migration.

## 4. Verify Platform-Specific Behavior

Check any areas of the codebase that previously relied on Windows-specific APIs or behaviors. Common areas to review include:

- File path separators (`\` vs `/`) — use `Path.Combine` and `Path.DirectorySeparatorChar` where applicable.
- Registry access — not available on Linux/macOS.
- Windows-specific libraries such as `System.Drawing` or `Microsoft.Win32` — confirm cross-platform alternatives are in place.
- `Environment.SpecialFolder` paths — behavior differs across operating systems.

## 5. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify functional correctness:

```bash
dotnet run --configuration Release
```

If publishing a self-contained executable, use:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`.

## 6. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net4x` or `netstandard` targets unless intentionally required for compatibility.

## 7. Review NuGet Package Versions

Check that all NuGet dependencies are up to date and compatible with the target framework. Use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and re-run the build and tests after doing so.

## 8. Validate Configuration and App Settings

If the project uses configuration files such as `App.config` or `Web.config`, confirm these have been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that all configuration values are correctly read at runtime.
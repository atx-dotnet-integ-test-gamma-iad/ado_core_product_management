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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced during migration or a pre-existing issue.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element references the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects still reference `net48` or other Windows-only frameworks unless that is intentional.

## 5. Check for Windows-Specific APIs

Use the .NET Compatibility Analyzer or review the code manually for any usage of Windows-specific APIs such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- `System.Drawing` (requires additional packages on non-Windows)
- P/Invoke calls targeting Windows-only system libraries

If any are found, evaluate whether a cross-platform alternative exists or whether a platform guard (`OperatingSystem.IsWindows()`) is appropriate.

## 6. Review Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET.

## 7. Validate Runtime Behavior

Run the application manually on the target platform(s) and exercise the primary workflows to confirm runtime behavior matches expectations from the legacy version.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier for your target platform, for example:

- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS Intel
- `osx-arm64` for macOS Apple Silicon

Review the publish output directory to confirm all required assets are present before deploying.
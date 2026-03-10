# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs with:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet package restore to ensure all dependencies are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output for any failures. Pay particular attention to tests that cover database access, file I/O, or platform-specific APIs, as these are common areas affected by cross-platform migration.

## 5. Check for Platform-Specific API Usage

Even without build errors, runtime issues can arise from APIs that behave differently across operating systems. Review the codebase for usage of:

- `System.Windows.Forms` or `System.Drawing` (not fully supported cross-platform without additional packages)
- Windows registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., hardcoded backslashes)
- `Environment.SpecialFolder` paths that differ per OS

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

## 7. Review Nullable Reference Type Warnings

If the project has nullable reference types enabled (`<Nullable>enable</Nullable>`), review any warnings introduced during transformation. These are not build errors but can indicate potential null reference issues at runtime.

## 8. Validate Output Artifacts

Publish the project and inspect the output to confirm all required files and dependencies are included:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the `./publish` directory to ensure all expected assemblies, configuration files, and assets are present.
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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific API Usage

Cross-platform .NET does not support certain Windows-specific APIs. Check the code for usage of the following, which may compile but fail at runtime on non-Windows platforms:

- `System.Windows.Forms` or `System.Drawing` (without the `System.Drawing.Common` package)
- Registry access via `Microsoft.Win32.Registry`
- COM interop
- `System.Security.Permissions` attributes

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify these usages if a manual review is not practical.

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project only needs to run on Windows, ensure the appropriate target is set:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 6. Test Runtime Behavior

Run the application manually and exercise the primary workflows. Pay particular attention to:

- File path handling, as .NET on Linux and macOS uses case-sensitive paths
- Configuration file loading (e.g., `app.config` vs `appsettings.json`)
- Any reflection-based code, which may behave differently under .NET's trimming or AOT scenarios

## 7. Review Output Artifacts

After a Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:

- All expected assemblies are present
- No unintended dependencies on legacy assemblies (e.g., `.NET Framework` reference assemblies) are included

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment.
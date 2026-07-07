# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about packages that are not compatible with the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to platform compatibility (e.g., `CA1416` platform-specific API warnings).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures before proceeding.

## 5. Check for Platform-Specific API Usage

Since this is a migration to cross-platform .NET, audit the codebase for any APIs that are Windows-only. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `System.Security.Principal.WindowsIdentity`

Use the .NET Upgrade Assistant or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with this audit.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) and verify that runtime behavior matches expectations from the legacy version:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling (`Path.Combine` vs hardcoded separators), line endings, and any environment-specific configuration.

## 7. Review Configuration Files

Check that `app.config` or `web.config` settings have been migrated to `appsettings.json` or environment variables where appropriate, as the legacy configuration system has limited support in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required files are present.
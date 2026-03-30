# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet for updated versions that support the target TFM.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly:
- Nullable reference type warnings
- Obsolete API usage
- Platform compatibility warnings (CA1416)

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Note any failing tests and compare behavior against the original .NET Framework version to determine if failures are due to breaking changes in the new runtime.

## 5. Check for Windows-Specific API Usage

If cross-platform support is a goal, audit the codebase for APIs that are Windows-only. Common areas to check include:

- `Microsoft.Win32` namespace usage
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- Registry access (`RegistryKey`)
- COM interop

Use the .NET Upgrade Assistant compatibility analyzer or the `dotnet-compatibility` tool to assist:

```bash
dotnet tool install -g dotnet-compatibility
```

## 6. Validate Runtime Behavior on Target Platforms

If the application is intended to run on Linux or macOS, test it explicitly on those platforms. Pay attention to:

- File path separators (`\` vs `/`)
- Case-sensitive file systems on Linux
- Environment variable differences
- Line ending differences (`\r\n` vs `\n`)

## 7. Review Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration mechanisms. Verify the configuration is loaded correctly at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

**Framework-dependent deployment:**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish -c Release -f net8.0 -r linux-x64 --self-contained true
```

Review the contents of the `publish` output directory to confirm all required assets are present before distributing.